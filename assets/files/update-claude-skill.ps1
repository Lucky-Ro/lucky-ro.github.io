<#
  从 GitHub 拉取最新的 skill 到本地 Claude skills 目录；
  GitHub 网络不畅时自动回退到 Gitee。

  原理：下载仓库 zip -> 解压 -> 把 skill 复制到
        C:\Users\<你>\.claude\skills\ 下（覆盖同名）。无需安装 git。
  （若 Gitee 的 zip 被验证码拦下，会在装了 git 时自动改用 git clone。）

  重复运行即可获取最新版本。仅适用于「公开仓库」。
#>

# ===== 按需修改的配置 =====
$GitHubRepo = "Lucky-Ro/zjkju_Copilot"    # GitHub: owner/name
$GiteeRepo  = "lucky_ro/zjkju_Copilot"    # Gitee:  owner/name
$Branch     = "main"                        # 分支名
$SkillName  = "hadoop-lab-report"           # 要拉的 skill 文件夹名；留空 "" = 拉取 skill/ 下全部
# ==========================

$ErrorActionPreference = "Stop"
$script:ExitCode = 0
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 目标目录：C:\Users\<你>\.claude\skills
$SkillsDir = Join-Path $env:USERPROFILE ".claude\skills"

# 临时工作目录
$TmpDir = Join-Path ([IO.Path]::GetTempPath()) ("skill-sync-" + [guid]::NewGuid().ToString("N"))

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

# 用 git clone 兜底（需已安装 git），返回克隆出的目录；失败返回 $null
function Get-FromGit {
    param([string]$Name, [string]$CloneUrl, [string]$WorkDir)
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "    未检测到 git，跳过 $Name 克隆。" -ForegroundColor DarkYellow
        return $null
    }
    $dest = Join-Path $WorkDir "repo"
    Write-Host "==> 尝试用 git 从 $Name 克隆：$CloneUrl" -ForegroundColor Cyan
    # git clone 会把进度写到 stderr；在 $ErrorActionPreference='Stop' 下，
    # Windows PowerShell 5.1 容易把 stderr 当成终止性错误抛出，从而拖崩整个脚本。
    # 因此临时降级为 Continue、吞掉 stderr，并用 try/catch 兜底，确保失败也只是干净返回 $null。
    $oldEAP = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        git clone --quiet --depth 1 --branch $Branch $CloneUrl $dest 2>&1 | Out-Null
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

try {
    Write-Host "==> 准备目录..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $TmpDir    | Out-Null
    New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null

    # 依次尝试各来源，谁先成功用谁
    $repoRoot = $null
    $usedFrom = $null
    $attempts = @(
        @{ Kind = "zip"; Name = "GitHub"; Arg = "https://github.com/$GitHubRepo/archive/refs/heads/$Branch.zip" },
        @{ Kind = "zip"; Name = "Gitee";  Arg = "https://gitee.com/$GiteeRepo/repository/archive/$Branch.zip" },
        @{ Kind = "git"; Name = "Gitee";  Arg = "https://gitee.com/$GiteeRepo.git" }
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
    if (Test-Path $TmpDir) { Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue }
    # 双击运行时窗口会自动关闭，错误会「一闪而过」。这里停一下，让成功/失败信息都看得清。
    if ([Environment]::UserInteractive) {
        Write-Host ""
        Read-Host "按回车键退出" | Out-Null
    }
}

exit ([int]$script:ExitCode)
