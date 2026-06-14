$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "OK: $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "! $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "FAIL: $msg" -ForegroundColor Red }
function Write-Dim($msg)  { Write-Host $msg -ForegroundColor DarkGray }

$InstallLog = if ($env:CC_INSTALL_LOG) { $env:CC_INSTALL_LOG } else { Join-Path $env:TEMP "claude-code-install.log" }
$GitForWindowsVersion = "2.54.0"
$GitForWindowsTag = "v2.54.0.windows.1"
$DownloadTimeoutSec = if ($env:CC_DOWNLOAD_TIMEOUT_SEC) { [int]$env:CC_DOWNLOAD_TIMEOUT_SEC } else { 180 }

function Get-WindowsArchLabel {
  try {
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
    if ($arch -eq "arm64") { return "arm64" }
    if ($arch -eq "x86") { return "x86" }
  } catch {}
  if ($env:PROCESSOR_ARCHITECTURE -match "ARM64" -or $env:PROCESSOR_ARCHITEW6432 -match "ARM64") { return "arm64" }
  if ($env:PROCESSOR_ARCHITECTURE -match "86") { return "x86" }
  return "64-bit"
}

$MinNodeMajor = if ($env:CC_MIN_NODE_MAJOR) { [int]$env:CC_MIN_NODE_MAJOR } else { 18 }

# Node version recommended by the hint. Bump occasionally; patch level
# doesn't matter for the >= MinNodeMajor gate.
$RecommendedNodeVersion = if ($env:CC_RECOMMENDED_NODE_VERSION) { $env:CC_RECOMMENDED_NODE_VERSION } else { "v20.18.0" }

function Get-NodeMsiMirrorUrl {
  $archLabel = Get-WindowsArchLabel
  switch ($archLabel) {
    "arm64" { return "https://mirrors.aliyun.com/nodejs-release/$RecommendedNodeVersion/node-$RecommendedNodeVersion-arm64.msi" }
    "x86"   { return "https://mirrors.aliyun.com/nodejs-release/$RecommendedNodeVersion/node-$RecommendedNodeVersion-x86.msi" }
    default { return "https://mirrors.aliyun.com/nodejs-release/$RecommendedNodeVersion/node-$RecommendedNodeVersion-x64.msi" }
  }
}

function Get-NodeMajor {
  try {
    $v = & node -v 2>$null
    if ([string]::IsNullOrWhiteSpace($v)) { return 0 }
    if ($v -match 'v(\d+)\.') { return [int]$Matches[1] }
    return 0
  } catch { return 0 }
}

function Write-NodeHint($current) {
  Write-Fail "Claude Code requires Node.js $MinNodeMajor or newer."
  Write-Host "  Current Node: $current"
  Write-Host ""
  Write-Host "  " -NoNewline
  Write-Host "Step 1" -ForegroundColor White -NoNewline
  Write-Host "  Install Node.js (Windows, pick one):"
  Write-Host ""
  Write-Host "    # Option A: winget (Windows 10/11)"
  Write-Host "    winget install OpenJS.NodeJS.LTS"
  Write-Host ""
  $msiUrl = Get-NodeMsiMirrorUrl
  Write-Host "    # Option B: Aliyun mirror MSI direct (~26 MB, China-friendly, works on older Windows too)"
  Write-Host "    iwr '$msiUrl' -OutFile `"`$env:TEMP\node.msi`""
  Write-Host "    Start-Process `"`$env:TEMP\node.msi`""
  Write-Host ""
  Write-Host "  " -NoNewline
  Write-Host "Step 2" -ForegroundColor White -NoNewline
  Write-Host "  Restart PowerShell so 'node' is on PATH, then re-run this installer."
  Write-Host ""
  Write-Host "  Other options:" -ForegroundColor DarkGray
  Write-Host "    - Official Node.js download page:"
  Write-Host "        Start-Process 'https://nodejs.org/zh-cn/download'"
  Write-Host "    - nvm-windows: https://github.com/coreybutler/nvm-windows/releases"
  Write-Host "    - Chocolatey:  choco install nodejs-lts"
  Write-Host ""
}

function Update-ProcessPathFromRegistry {
  $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
  $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$machinePath;$userPath"
}

function Get-LocalAppDataDir {
  if (-not [string]::IsNullOrWhiteSpace($env:LocalAppData)) { return $env:LocalAppData }
  if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) { return (Join-Path $env:USERPROFILE "AppData\Local") }
  return [System.IO.Path]::GetTempPath().TrimEnd('\')
}

function Get-InstallHome {
  return (Join-Path (Get-LocalAppDataDir) "claude-code-installer")
}

function Get-PortableGitDir {
  return (Join-Path (Get-InstallHome) "PortableGit")
}

function Add-ProcessPathEntry($entry) {
  if ([string]::IsNullOrWhiteSpace($entry)) { return }
  $pathParts = ($env:Path -split ';') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  foreach ($part in $pathParts) {
    if ($part.TrimEnd('\').Equals($entry.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)) {
      return
    }
  }
  $env:Path = "$entry;$env:Path"
}

function Get-GitInstallRoots {
  $roots = @()
  $registryKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
  )
  foreach ($key in $registryKeys) {
    try {
      if (-not (Test-Path $key)) { continue }
      $props = Get-ItemProperty -Path $key -ErrorAction Stop
      if (-not [string]::IsNullOrWhiteSpace($props.InstallLocation)) {
        $roots += $props.InstallLocation.TrimEnd('\')
      }
      if (-not [string]::IsNullOrWhiteSpace($props.UninstallString) -and $props.UninstallString -match '^"?([^"]*\\Git)\\unins') {
        $roots += $Matches[1]
      }
    } catch {}
  }
  return ($roots | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
}

function Get-GitBashCandidates {
  $programFilesX86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
  $candidates = @()
  if (-not [string]::IsNullOrWhiteSpace($env:CLAUDE_CODE_GIT_BASH_PATH)) {
    $candidates += $env:CLAUDE_CODE_GIT_BASH_PATH
  }
  $portableGitDir = Get-PortableGitDir
  $candidates += (Join-Path $portableGitDir "bin\bash.exe")
  try {
    $whereBash = (& where.exe bash 2>$null)
    foreach ($bashPath in $whereBash) {
      if (-not [string]::IsNullOrWhiteSpace($bashPath) -and $bashPath -notmatch '\\Windows\\System32\\bash\.exe$') {
        $candidates += $bashPath
      }
    }
  } catch {}
  if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
    $candidates += (Join-Path $env:ProgramFiles "Git\bin\bash.exe")
  }
  if ($programFilesX86) {
    $candidates += (Join-Path $programFilesX86 "Git\bin\bash.exe")
  }
  if (-not [string]::IsNullOrWhiteSpace($env:LocalAppData)) {
    $candidates += (Join-Path $env:LocalAppData "Programs\Git\bin\bash.exe")
  }
  foreach ($root in (Get-GitInstallRoots)) {
    $candidates += (Join-Path $root "bin\bash.exe")
    $candidates += (Join-Path $root "usr\bin\bash.exe")
  }
  $git = Get-Command git -ErrorAction SilentlyContinue
  if ($git -and (-not [string]::IsNullOrWhiteSpace($git.Source))) {
    $gitDir = Split-Path -Parent $git.Source
    $gitRoot = Split-Path -Parent $gitDir
    if (-not [string]::IsNullOrWhiteSpace($gitDir)) {
      $candidates += (Join-Path $gitDir "bash.exe")
    }
    if (-not [string]::IsNullOrWhiteSpace($gitRoot)) {
      $candidates += (Join-Path $gitRoot "bin\bash.exe")
      $candidates += (Join-Path $gitRoot "usr\bin\bash.exe")
    }
  }
  try {
    $whereGit = (& where.exe git 2>$null)
    foreach ($gitPath in $whereGit) {
      if ([string]::IsNullOrWhiteSpace($gitPath)) { continue }
      $gitDir = Split-Path -Parent $gitPath
      $gitRoot = Split-Path -Parent $gitDir
      if (-not [string]::IsNullOrWhiteSpace($gitDir)) {
        $candidates += (Join-Path $gitDir "bash.exe")
      }
      if (-not [string]::IsNullOrWhiteSpace($gitRoot)) {
        $candidates += (Join-Path $gitRoot "bin\bash.exe")
        $candidates += (Join-Path $gitRoot "usr\bin\bash.exe")
      }
    }
  } catch {}
  return ($candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
}

function Find-GitBash {
  $bash = Get-Command bash -ErrorAction SilentlyContinue
  if ($bash -and $bash.Source -notmatch '\\Windows\\System32\\bash\.exe$') {
    return $bash.Source
  }

  foreach ($candidate in (Get-GitBashCandidates)) {
    if ((-not [string]::IsNullOrWhiteSpace($candidate)) -and (Test-Path $candidate)) {
      return $candidate
    }
  }
  return ""
}

function Write-GitBashDiagnostics {
  $git = Get-Command git -ErrorAction SilentlyContinue
  $bash = Get-Command bash -ErrorAction SilentlyContinue
  if ($git) { Write-Warn "Found git.exe at $($git.Source), but Git Bash was not found." }
  if ($bash) { Write-Warn "Found bash.exe at $($bash.Source), but it is not Git Bash." }
  Write-Dim "Checked Git Bash paths:"
  foreach ($candidate in (Get-GitBashCandidates)) {
    Write-Dim "  $candidate"
  }
}

function Set-GitBashPath($bashPath) {
  if ([string]::IsNullOrWhiteSpace($bashPath)) { return }
  try { [Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", $bashPath, "User") } catch {}
  $env:CLAUDE_CODE_GIT_BASH_PATH = $bashPath
  $bashDir = Split-Path -Parent $bashPath
  if ([string]::IsNullOrWhiteSpace($bashDir)) { return }
  Add-ProcessPathEntry $bashDir
  $gitCmdDir = Join-Path (Split-Path -Parent $bashDir) "cmd"
  if (Test-Path $gitCmdDir) { Add-ProcessPathEntry $gitCmdDir }
}

function Test-GitBashExecutable($bashPath) {
  if ([string]::IsNullOrWhiteSpace($bashPath)) { return $false }
  if (-not (Test-Path $bashPath)) { return $false }
  try {
    $version = (& $bashPath --version 2>$null | Select-Object -First 1)
    return (-not [string]::IsNullOrWhiteSpace($version))
  } catch {
    return $false
  }
}

function Get-PortableGitFileName {
  $archLabel = Get-WindowsArchLabel
  switch ($archLabel) {
    "arm64" { return "PortableGit-$GitForWindowsVersion-arm64.7z.exe" }
    "64-bit" { return "PortableGit-$GitForWindowsVersion-64-bit.7z.exe" }
    default { return "" }
  }
}

function Install-PortableGit {
  $fileName = Get-PortableGitFileName
  if ([string]::IsNullOrWhiteSpace($fileName)) {
    throw "Git Bash was not found. Please install Git for Windows manually, then run this installer again."
  }

  $portableGitDir = Get-PortableGitDir
  $portableBash = Join-Path $portableGitDir "bin\bash.exe"
  if (Test-GitBashExecutable $portableBash) {
    Set-GitBashPath $portableBash
    return $portableBash
  }

  $portableGitParent = Split-Path -Parent $portableGitDir
  $downloadDir = Join-Path $portableGitParent "downloads"
  New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
  $tempFile = Join-Path $downloadDir $fileName
  $sources = @(
    @{ name = "npmmirror"; url = "https://registry.npmmirror.com/-/binary/git-for-windows/$GitForWindowsTag/$fileName" },
    @{ name = "npmmirror_cdn"; url = "https://cdn.npmmirror.com/binaries/git-for-windows/$GitForWindowsTag/$fileName" },
    @{ name = "tuna"; url = "https://mirrors.tuna.tsinghua.edu.cn/github-release/git-for-windows/git/LatestRelease/$fileName" },
    @{ name = "github"; url = "https://github.com/git-for-windows/git/releases/download/$GitForWindowsTag/$fileName" }
  )

  Write-Step "Preparing Git Bash for Windows (portable, installer-local)"

  $downloaded = $false
  Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
  foreach ($source in $sources) {
    try {
      Write-Dim "Trying PortableGit download from $($source.name)..."
      Invoke-WebRequest -Uri $source.url -OutFile $tempFile -UseBasicParsing -TimeoutSec $DownloadTimeoutSec
      if ((Test-Path $tempFile) -and ((Get-Item $tempFile).Length -gt 1048576)) {
        $downloaded = $true
        break
      }
      Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    } catch {
      $message = $_.Exception.Message
      if (-not [string]::IsNullOrWhiteSpace($message)) {
        Write-Warn "PortableGit download from $($source.name) failed: $message"
      }
      Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
  }

  if (-not $downloaded) {
    throw "PortableGit download failed. Please install Git for Windows manually from https://git-scm.com/download/win, then retry."
  }

  try {
    if (Test-Path $portableGitDir) { Remove-Item -Recurse -Force $portableGitDir -ErrorAction Stop }
    New-Item -ItemType Directory -Force -Path $portableGitDir | Out-Null
    Write-Dim "Extracting PortableGit to $portableGitDir..."
    $extractArgs = "-y -o`"$portableGitDir`""
    $process = Start-Process -FilePath $tempFile -ArgumentList $extractArgs -Wait -PassThru
    if ($process.ExitCode -ne 0) {
      throw "PortableGit extractor exited with code $($process.ExitCode)."
    }
  } catch {
    throw "PortableGit extraction failed: $($_.Exception.Message)"
  }

  if (-not (Test-GitBashExecutable $portableBash)) {
    throw "PortableGit was extracted, but Git Bash is not executable at $portableBash."
  }

  Set-GitBashPath $portableBash
  return $portableBash
}

function Test-NodeRuntimeReady {
  $node = Get-Command node -ErrorAction SilentlyContinue
  if (-not $node) { return $false }
  return ((Get-NodeMajor) -ge $MinNodeMajor)
}

function Install-NodeRuntime {
  Write-Warn "Node.js is missing or too old. Trying to install Node.js 20 LTS automatically..."

  $winget = Get-Command winget -ErrorAction SilentlyContinue
  if ($winget) {
    try {
      Write-Step "Installing Node.js via winget"
      winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
      Update-ProcessPathFromRegistry
      if (Test-NodeRuntimeReady) { return $true }
    } catch {
      Write-Warn "winget Node.js install failed; trying Aliyun MSI fallback."
    }
  }

  $msiUrl = Get-NodeMsiMirrorUrl
  $msiPath = Join-Path $env:TEMP "node-lts.msi"
  try {
    Write-Step "Downloading Node.js MSI from Aliyun mirror"
    Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing
    Write-Step "Launching Node.js MSI installer"
    Start-Process -FilePath $msiPath -Wait
    Update-ProcessPathFromRegistry
    if (Test-NodeRuntimeReady) { return $true }
    Write-Warn "Node.js installer finished, but this PowerShell session still cannot find Node.js."
  } catch {
    Write-Warn "Aliyun Node.js MSI install failed."
  }

  return $false
}

function Test-NodeRuntime {
  $node = Get-Command node -ErrorAction SilentlyContinue
  $current = "not installed"
  if ($node) {
    try { $current = (& node -v 2>$null) } catch { $current = "unknown" }
    if ([string]::IsNullOrWhiteSpace($current)) { $current = "unknown" }
    if ((Get-NodeMajor) -ge $MinNodeMajor) {
      return $true
    }
  }

  if (Install-NodeRuntime) {
    try { $current = (& node -v 2>$null) } catch { $current = "installed" }
    Write-Ok "Node.js is ready ($current)"
    return $true
  }

  Write-NodeHint $current
  return $false
}

function Install-GitForWindowsIfMissing {
  Update-ProcessPathFromRegistry

  $gitBash = Find-GitBash
  if (-not [string]::IsNullOrWhiteSpace($gitBash)) {
    Set-GitBashPath $gitBash
    return
  }

  $git = Get-Command git -ErrorAction SilentlyContinue
  if ($git) {
    Write-GitBashDiagnostics
  }
  $gitBash = Install-PortableGit
  if ([string]::IsNullOrWhiteSpace($gitBash)) {
    throw "PortableGit was installed, but this PowerShell session cannot find Git Bash."
  }
  Set-GitBashPath $gitBash
}

Write-Host "Installing Claude Code..." -ForegroundColor White

# Node preflight: fail fast if Node is missing or too old.
# Test-NodeRuntime already prints the hint, so exit quietly here.
if (-not (Test-NodeRuntime)) {
  return
}

Write-Step "Downloading and installing"

Install-GitForWindowsIfMissing

Write-Step "Installing official Claude Code"
Set-Content -Path $InstallLog -Value "" -ErrorAction SilentlyContinue
npm config set registry https://registry.npmmirror.com | Out-Null
npm install -g @anthropic-ai/claude-code *>> $InstallLog
if ($LASTEXITCODE -ne 0) { throw "npm install failed (exit $LASTEXITCODE). See $InstallLog" }
npm config set registry https://registry.npmjs.org | Out-Null

$claudeDir = Join-Path $HOME ".claude"
New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null

# --- DeepSeek API configuration ---
Write-Host ""
Write-Step "Configuring DeepSeek API"
Write-Dim "  Get your API key at https://platform.deepseek.com (it starts with sk-)"

$deepSeekKey = ""
while ([string]::IsNullOrWhiteSpace($deepSeekKey)) {
  $deepSeekKey = (Read-Host "  Paste your DeepSeek API Key").Trim()
  if ([string]::IsNullOrWhiteSpace($deepSeekKey)) {
    Write-Warn "API key cannot be empty. Please try again."
  }
}

$settings = [ordered]@{
  hasCompletedOnboarding = $true
  env = [ordered]@{
    ANTHROPIC_BASE_URL   = "https://api.deepseek.com/anthropic"
    ANTHROPIC_AUTH_TOKEN = $deepSeekKey
    ANTHROPIC_MODEL      = "deepseek-chat"
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
  }
  includeCoAuthoredBy = $false
}
$settings | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $claudeDir "settings.json") -Encoding UTF8
Write-Ok "DeepSeek API configured"

$claudeVersion = ""
try { $claudeVersion = (& claude --version) 2>$null | Select-Object -First 1 } catch {}
Write-Host ""
if ($claudeVersion) {
  Write-Ok "Claude Code installed successfully ($claudeVersion)"
} else {
  Write-Ok "Claude Code installed successfully"
}
Write-Host ""
Write-Host "  " -NoNewline; Write-Host "Start" -ForegroundColor White -NoNewline; Write-Host "      Open a NEW terminal, then run " -NoNewline; Write-Host "claude" -ForegroundColor Cyan -NoNewline; Write-Host " (DeepSeek is already configured)"
Write-Host "  " -NoNewline; Write-Host "Docs" -ForegroundColor White -NoNewline; Write-Host "       https://docs.claude.com" -ForegroundColor Cyan
Write-Host ""
