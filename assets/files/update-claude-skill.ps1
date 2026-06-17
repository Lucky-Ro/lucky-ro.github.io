<#
  从 GitHub 拉取最新的 skill 到本地 Claude skills 目录；
  GitHub 网络不畅时自动回退到 Gitee。

  来源优先级（谁先成功用谁）：
    1) GitHub  下载 zip（无需 git）
    2) Gitee   git clone（最稳；找不到 git 时会自动“找 git → 临时装 git”，见下）
    3) Gitee   下载 zip（没装 git 时的兜底；Gitee 归档常被异步打包/验证码拦截）

  关于第 2 步的 git：按顺序解析一个可用的 git.exe——
    a) 先看 PATH 上有没有 git；
    b) 没有就去上一个「安装 Claude Code」脚本装的便携目录里找
       （%LOCALAPPDATA%\claude-code-installer\PortableGit\cmd\git.exe）；
    c) 还找不到，就从国内镜像临时下载一份便携 git，解压到临时目录使用，
       脚本结束时随临时目录一并删除（不污染系统、不改 PATH）。

  重复运行即可获取最新版本。仅适用于「公开仓库」。
#>

# ===== 按需修改的配置 =====
$GitHubRepo = "Lucky-Ro/zjkju_Copilot"    # GitHub: owner/name
$GiteeRepo  = "lucky_ro/zjkju_Copilot"    # Gitee:  owner/name
$Branch     = "main"                        # 分支名（远端默认分支不是它时，git 克隆会自动改用默认分支）
$SkillName  = "hadoop-lab-report"           # 要拉的 skill 文件夹名；留空 "" = 拉取 skill/ 下全部

# 临时 git 用的便携版版本（与「安装 Claude Code」脚本保持一致，国内镜像已验证可下）
$GitVersion = "2.54.0"
$GitTag     = "v2.54.0.windows.1"
# ==========================

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"   # 关掉下载进度条，避免与 Write-Host 抢屏造成“文字重影”
$script:ExitCode = 0
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 解析到的 git.exe（缓存，避免同一次运行重复查找/重复下载）
$script:GitExe      = $null
$script:GitResolved = $false
$script:TempGitDir  = $null   # 临时下载的 git 解压目录（位于 $TmpDir 下，结束随之删除）

# 目标目录：C:\Users\<你>\.claude\skills
$SkillsDir = Join-Path $env:USERPROFILE ".claude\skills"

# 临时工作目录
$TmpDir = Join-Path ([IO.Path]::GetTempPath()) ("skill-sync-" + [guid]::NewGuid().ToString("N"))

# ---------------- zip 来源 ----------------

# 判断一个文件是否为真 zip（前两字节应为 PK）。Gitee 偶尔返回验证页/等待页而非 zip。
function Test-IsZip {
    param([string]$Path)
    try {
        $fs = [IO.File]::OpenRead($Path)
        $b0 = $fs.ReadByte(); $b1 = $fs.ReadByte(); $fs.Close()
    } catch { return $false }
    return ($b0 -eq 0x50 -and $b1 -eq 0x4B)
}

# 下载 zip 并解压，返回解压出的仓库根目录；失败返回 $null
# Gitee 的归档是「异步生成」：首次请求常返回一个 HTML 等待页（预计等待 <3s），
# 需要稍后再请求同一地址才拿到真 zip，因此这里带重试。
function Get-FromZip {
    param([string]$Name, [string]$Url, [string]$WorkDir)
    $zip = Join-Path $WorkDir "repo.zip"
    Write-Host "==> 尝试从 $Name 下载：$Url" -ForegroundColor Cyan

    $maxTry = 4
    $gotZip = $false
    for ($i = 1; $i -le $maxTry; $i++) {
        try {
            Invoke-WebRequest -Uri $Url -OutFile $zip -UseBasicParsing -TimeoutSec 30
        } catch {
            # 下载本身就抛异常（如断网/404），没必要长时间重试，直接放弃这个来源
            Write-Host "    $Name 下载失败：$($_.Exception.Message)" -ForegroundColor DarkYellow
            return $null
        }
        if (Test-IsZip $zip) { $gotZip = $true; break }
        # 拿到的不是 zip（多半是 Gitee 的「正在准备压缩包」等待页），稍候重试同一地址
        if ($i -lt $maxTry) {
            Write-Host "    $Name 返回的还不是 zip（可能在异步打包），3 秒后第 $($i+1)/$maxTry 次重试…" -ForegroundColor DarkYellow
            Start-Sleep -Seconds 3
        }
    }
    if (-not $gotZip) {
        Write-Host "    $Name 多次重试仍未拿到有效 zip（可能需要验证码/登录），跳过。" -ForegroundColor DarkYellow
        return $null
    }

    try {
        Expand-Archive -Path $zip -DestinationPath $WorkDir -Force
    } catch {
        Write-Host "    $Name 解压失败：$($_.Exception.Message)" -ForegroundColor DarkYellow
        return $null
    }
    # 取解压出来的唯一顶层目录（GitHub/Gitee 都是 <repo>-<branch> 之类）
    $root = Get-ChildItem -Path $WorkDir -Directory | Select-Object -First 1
    if ($root) { return $root.FullName } else { return $null }
}

# ---------------- git 解析 / 获取 ----------------

function Get-LocalAppData {
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) { return $env:LOCALAPPDATA }
    if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) { return (Join-Path $env:USERPROFILE "AppData\Local") }
    return ([IO.Path]::GetTempPath().TrimEnd('\'))
}

# 在「安装 Claude Code」脚本装的便携目录里找 git.exe
function Get-PortableGitFromInstaller {
    $root = Join-Path (Get-LocalAppData) "claude-code-installer"
    $exe  = Join-Path $root "PortableGit\cmd\git.exe"
    if (Test-Path $exe) { return $exe }
    # 万一目录布局不同，在该目录下兜底搜一把 cmd\git.exe
    if (Test-Path $root) {
        $hit = Get-ChildItem -Path $root -Recurse -Filter git.exe -ErrorAction SilentlyContinue |
               Where-Object { $_.FullName -match '\\cmd\\git\.exe$' } | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

# 选定与本机架构匹配的 PortableGit 自解压包文件名
function Get-PortableGitFileName {
    $arch = ""
    try { $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant() } catch {}
    if ($arch -eq "arm64" -or $env:PROCESSOR_ARCHITECTURE -match "ARM64" -or $env:PROCESSOR_ARCHITEW6432 -match "ARM64") {
        return "PortableGit-$GitVersion-arm64.7z.exe"
    }
    return "PortableGit-$GitVersion-64-bit.7z.exe"
}

# 从国内镜像临时下载一份便携 git，解压到 $WorkDir 下（随 $TmpDir 一起删）。成功返回 git.exe 路径。
function Install-TempGit {
    param([string]$WorkDir)
    $fileName = Get-PortableGitFileName
    $dlDir  = Join-Path $WorkDir "git-download"
    $gitDir = Join-Path $WorkDir "PortableGit"
    New-Item -ItemType Directory -Force -Path $dlDir | Out-Null
    $sfx = Join-Path $dlDir $fileName

    # 与「安装 Claude Code」脚本相同的镜像顺序（国内优先，GitHub 兜底）
    $sources = @(
        "https://registry.npmmirror.com/-/binary/git-for-windows/$GitTag/$fileName",
        "https://cdn.npmmirror.com/binaries/git-for-windows/$GitTag/$fileName",
        "https://mirrors.tuna.tsinghua.edu.cn/github-release/git-for-windows/git/LatestRelease/$fileName",
        "https://github.com/git-for-windows/git/releases/download/$GitTag/$fileName"
    )

    Write-Host "    本机找不到 git，临时从国内镜像下载一份便携 git（用完即删，不改 PATH）…" -ForegroundColor DarkYellow
    $got = $false
    foreach ($url in $sources) {
        try {
            Write-Host "    下载：$url" -ForegroundColor DarkGray
            Invoke-WebRequest -Uri $url -OutFile $sfx -UseBasicParsing -TimeoutSec 180
            if ((Test-Path $sfx) -and ((Get-Item $sfx).Length -gt 1MB)) { $got = $true; break }
        } catch {
            Write-Host "    该源失败：$($_.Exception.Message)" -ForegroundColor DarkGray
        }
        Remove-Item $sfx -Force -ErrorAction SilentlyContinue
    }
    if (-not $got) {
        Write-Host "    临时 git 下载失败（所有镜像都不可用）。" -ForegroundColor DarkYellow
        return $null
    }

    try {
        New-Item -ItemType Directory -Force -Path $gitDir | Out-Null
        # PortableGit 是 7-Zip 自解压包：-y 全部确认，-o 指定输出目录
        $p = Start-Process -FilePath $sfx -ArgumentList "-y -o`"$gitDir`"" -Wait -PassThru
        if ($p.ExitCode -ne 0) {
            Write-Host "    临时 git 解压失败（退出码 $($p.ExitCode)）。" -ForegroundColor DarkYellow
            return $null
        }
    } catch {
        Write-Host "    临时 git 解压异常：$($_.Exception.Message)" -ForegroundColor DarkYellow
        return $null
    }

    $exe = Join-Path $gitDir "cmd\git.exe"
    if (Test-Path $exe) {
        $script:TempGitDir = $gitDir
        Write-Host "    临时 git 就绪：$exe" -ForegroundColor DarkGray
        return $exe
    }
    Write-Host "    临时 git 解压后未找到 git.exe。" -ForegroundColor DarkYellow
    return $null
}

# 解析链：PATH 上的 git -> 安装器里的便携 git -> 临时下载。结果缓存。
function Resolve-GitExe {
    param([string]$WorkDir)
    if ($script:GitResolved) { return $script:GitExe }
    $script:GitResolved = $true

    # a) PATH 上的 git
    $cmd = Get-Command git -ErrorAction SilentlyContinue
    if ($cmd -and -not [string]::IsNullOrWhiteSpace($cmd.Source)) {
        $script:GitExe = $cmd.Source
        Write-Host "    git 来源：PATH（$($script:GitExe)）" -ForegroundColor DarkGray
        return $script:GitExe
    }

    # b) 「安装 Claude Code」脚本装的便携 git
    $portable = Get-PortableGitFromInstaller
    if ($portable) {
        $script:GitExe = $portable
        Write-Host "    PATH 上没有 git，改用安装器里的便携 git：$portable" -ForegroundColor DarkGray
        return $script:GitExe
    }

    # c) 临时下载一份
    $script:GitExe = Install-TempGit -WorkDir $WorkDir
    return $script:GitExe
}

# 用 git clone 拉取（git 由 Resolve-GitExe 提供），返回克隆出的目录；失败返回 $null
function Get-FromGit {
    param([string]$Name, [string]$CloneUrl, [string]$WorkDir)
    $git = Resolve-GitExe -WorkDir $WorkDir
    if ([string]::IsNullOrWhiteSpace($git)) {
        Write-Host "    没有可用的 git，跳过 $Name 克隆。" -ForegroundColor DarkYellow
        return $null
    }
    $dest = Join-Path $WorkDir "repo"
    Write-Host "==> 尝试用 git 从 $Name 克隆：$CloneUrl" -ForegroundColor Cyan
    # git clone 会把进度写到 stderr；在 $ErrorActionPreference='Stop' 下，
    # Windows PowerShell 5.1 容易把 stderr 当成终止性错误抛出。这里临时降级为 Continue。
    $oldEAP = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        # 先按指定分支浅克隆；若分支名对不上（如远端默认是 master 而非 main），
        # 再退回「不指定分支」克隆默认分支，避免因分支名导致整个 Gitee 兜底白白失效。
        & $git clone --quiet --depth 1 --branch $Branch $CloneUrl $dest 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    指定分支 '$Branch' 克隆失败（退出码 $LASTEXITCODE），改用默认分支重试…" -ForegroundColor DarkYellow
            if (Test-Path $dest) { Remove-Item -Recurse -Force $dest -ErrorAction SilentlyContinue }
            & $git clone --quiet --depth 1 $CloneUrl $dest 2>&1 | Out-Null
        }
    } catch {
        Write-Host "    $Name 克隆异常：$($_.Exception.Message)" -ForegroundColor DarkYellow
        return $null
    } finally {
        $ErrorActionPreference = $oldEAP
    }
    if ($LASTEXITCODE -eq 0 -and (Test-Path $dest)) { return $dest }
    Write-Host "    $Name 克隆失败（git 退出码 $LASTEXITCODE）。" -ForegroundColor DarkYellow
    return $null
}

# ---------------- 主流程 ----------------

try {
    Write-Host "==> 准备目录..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $TmpDir    | Out-Null
    New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null

    # 依次尝试各来源，谁先成功用谁。
    # Gitee 优先用 git clone（稳），把 Gitee 的 zip 降为最后兜底。
    $repoRoot = $null
    $usedFrom = $null
    $attempts = @(
        @{ Kind = "zip"; Name = "GitHub"; Arg = "https://github.com/$GitHubRepo/archive/refs/heads/$Branch.zip" },
        @{ Kind = "git"; Name = "Gitee";  Arg = "https://gitee.com/$GiteeRepo.git" },
        @{ Kind = "zip"; Name = "Gitee";  Arg = "https://gitee.com/$GiteeRepo/repository/archive/$Branch.zip" }
    )

    foreach ($a in $attempts) {
        $work = Join-Path $TmpDir ("$($a.Name)-$($a.Kind)")
        New-Item -ItemType Directory -Force -Path $work | Out-Null
        if ($a.Kind -eq "zip") {
            $repoRoot = Get-FromZip -Name $a.Name -Url $a.Arg -WorkDir $work
        } else {
            $repoRoot = Get-FromGit -Name $a.Name -CloneUrl $a.Arg -WorkDir $work
        }
        if ($repoRoot) { $usedFrom = "$($a.Name)（$($a.Kind)）"; break }
    }

    if (-not $repoRoot) { throw "GitHub 和 Gitee 都拉取失败，请检查网络或仓库地址。" }
    Write-Host "==> 来源：$usedFrom" -ForegroundColor Green

    $SkillSrcRoot = Join-Path $repoRoot "skill"
    if (-not (Test-Path $SkillSrcRoot)) { throw "仓库里没有找到 skill 目录：$SkillSrcRoot" }

    # 确定要复制哪些 skill
    if ([string]::IsNullOrWhiteSpace($SkillName)) {
        $ToCopy = Get-ChildItem -Path $SkillSrcRoot -Directory
    } else {
        $one = Join-Path $SkillSrcRoot $SkillName
        if (-not (Test-Path $one)) { throw "没找到指定 skill：$SkillName" }
        $ToCopy = @(Get-Item $one)
    }

    # 复制到 .claude\skills（先删同名再拷，保证是干净的最新版）
    foreach ($s in $ToCopy) {
        $dest = Join-Path $SkillsDir $s.Name
        if (Test-Path $dest) {
            Write-Host "==> 更新: $($s.Name)" -ForegroundColor Yellow
            Remove-Item -Recurse -Force $dest
        } else {
            Write-Host "==> 新增: $($s.Name)" -ForegroundColor Green
        }
        Copy-Item -Path $s.FullName -Destination $dest -Recurse -Force
    }

    Write-Host ""
    Write-Host "[完成] skill 已更新到：$SkillsDir" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "[错误] $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ScriptStackTrace) {
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    $script:ExitCode = 1
}
finally {
    # 清理临时目录：临时下载的 git 也在这里面，一并删除（满足“用完即删”）
    if (Test-Path $TmpDir) { Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue }
    if ($script:TempGitDir) {
        Write-Host "（本次临时下载的 git 已随临时目录一并删除）" -ForegroundColor DarkGray
    }
    # 双击运行时窗口会自动关闭，错误会「一闪而过」。这里停一下，让成功/失败信息都看得清。
    if ([Environment]::UserInteractive) {
        Write-Host ""
        Read-Host "按回车键退出" | Out-Null
    }
}

exit ([int]$script:ExitCode)
