#!/usr/bin/env pwsh

# 本体は pwsh (PowerShell 7) 前提で書いている (dotmine/setup.ps1 の 3 引数以上の Join-Path 等は
# Windows PowerShell 5.1 では動かない)。素の Windows には pwsh が無いため、5.1 で起動されたら
# choco で powershell-core を入れてから pwsh で起動し直す。choco install は管理者権限が要るので、
# 昇格は 5.1 のうちに済ませる。choco 自体は README の手順で先に入れておく。
if ($PSVersionTable.PSEdition -ne "Core") {
    $scriptPath = $MyInvocation.MyCommand.Path
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "Restarting with administrator privileges..."
        Start-Process powershell -Verb RunAs -ArgumentList "-NoExit", "-File", "`"$scriptPath`""
        exit
    }

    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Error "choco not found. Install Chocolatey first (see README), then run setup.ps1 again."
            exit 1
        }
        Write-Host "choco install powershell-core -y"
        choco install powershell-core -y
        # 3010 はインストール成功・再起動推奨。pwsh 自体はこのまま起動できる
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 3010) {
            Write-Error "choco install powershell-core failed (exit code $LASTEXITCODE)."
            exit 1
        }
        # choco が足した PATH は実行中のプロセスに反映されないため、レジストリから読み直す
        $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
    }

    # PATH を読み直しても見つからない場合に備え、既定のインストール先も見る
    $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if (-not $pwsh) {
        $pwsh = Join-Path $env:ProgramFiles "PowerShell\7\pwsh.exe"
    }
    Write-Host "Restarting with pwsh..."
    # 既に管理者なので RunAs は付けない (子プロセスは昇格を引き継ぐ)
    Start-Process $pwsh -ArgumentList "-NoExit", "-File", "`"$scriptPath`""
    exit
}

# Windows ではシンボリックリンクの作成に管理者権限が要る
if ($IsWindows) {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "This script requires administrator privileges to create symbolic links on Windows."
        Write-Host "Restarting with administrator privileges..."

        $scriptPath = $MyInvocation.MyCommand.Path
        Start-Process pwsh -Verb RunAs -ArgumentList "-NoExit", "-File", "`"$scriptPath`""
        exit
    }
}

# .file
Get-ChildItem -Path "$PSScriptRoot\files\.git*" -Force | ForEach-Object {
    $fileName = $_.Name
    if ($fileName -ne "." -and $fileName -ne "..") {
        $source = $_.FullName
        $target = "$HOME\$fileName"
        Write-Host "execute New-Item -ItemType SymbolicLink -Path $target -Target $source"

        # Remove existing link/file if it exists
        if (Test-Path $target) {
            Remove-Item $target -Force
        }

        New-Item -ItemType SymbolicLink -Path $target -Target $source -Force | Out-Null
    }
}

# ssh
$sshConfDir = "$HOME\.ssh\conf.d"
if (-not (Test-Path $sshConfDir)) {
    New-Item -ItemType Directory -Path $sshConfDir -Force | Out-Null
}

$sshConfigSource = "$PSScriptRoot\files\ssh\conf.d\config"
$sshConfigTarget = "$sshConfDir\config"
if (Test-Path $sshConfigTarget) {
    Remove-Item $sshConfigTarget -Force
}
New-Item -ItemType SymbolicLink -Path $sshConfigTarget -Target $sshConfigSource -Force | Out-Null

# dotmine
& "$PSScriptRoot\dotmine\setup.ps1"

# ssh config
# Inject SSH config auto-generation into PowerShell profile
$profilePath = $PROFILE
if (-not (Test-Path $profilePath)) {
    if (-not (Test-Path (Split-Path $profilePath))) {
        New-Item -ItemType Directory -Path (Split-Path $profilePath) -Force | Out-Null
    }
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$sshConfigFunctions = @'

# SSH Config Auto-generation
function Update-SshConfig {
    $sshHome = "$env:USERPROFILE\.ssh"
    $confDir = Join-Path $sshHome "conf.d"
    $targetConfig = Join-Path $sshHome "config"
    
    if (Test-Path $confDir) {
        # Get content from files only
        $content = Get-ChildItem (Join-Path $confDir "*") -File | Get-Content
        $filtered = $content | Where-Object { $_ -notmatch "^\s*(ControlPath|ControlMaster|ControlPersist)" }
        $filtered | Set-Content $targetConfig
    }
}

function ssh {
    Update-SshConfig
    ssh.exe @args
}

function scp {
    Update-SshConfig
    scp.exe @args
}
'@

$currentProfileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if ($null -eq $currentProfileContent -or $currentProfileContent -notmatch "function Update-SshConfig") {
    Add-Content -Path $profilePath -Value $sshConfigFunctions
    Write-Host "Added SSH config automation to $profilePath"
} else {
    Write-Host "SSH config automation already exists in $profilePath"
}

# mise config (symlink ~/.config/mise/config.toml -> dotfiles)
$miseConfigDir = "$HOME\.config\mise"
if (-not (Test-Path $miseConfigDir)) {
    New-Item -ItemType Directory -Path $miseConfigDir -Force | Out-Null
}
$miseConfigSource = "$PSScriptRoot\files\.config\mise\config.toml"
$miseConfigTarget = "$miseConfigDir\config.toml"
if (Test-Path $miseConfigTarget) {
    Remove-Item $miseConfigTarget -Force
}
New-Item -ItemType SymbolicLink -Path $miseConfigTarget -Target $miseConfigSource -Force | Out-Null

# uv config (Windows は %APPDATA%\uv\uv.toml。python-preference = only-managed)
$uvConfigDir = Join-Path $env:APPDATA "uv"
if (-not (Test-Path $uvConfigDir)) {
    New-Item -ItemType Directory -Path $uvConfigDir -Force | Out-Null
}
$uvConfigSource = "$PSScriptRoot\files\.config\uv\uv.toml"
$uvConfigTarget = Join-Path $uvConfigDir "uv.toml"
if (Test-Path $uvConfigTarget) {
    Remove-Item $uvConfigTarget -Force
}
New-Item -ItemType SymbolicLink -Path $uvConfigTarget -Target $uvConfigSource -Force | Out-Null

# mise install (config.toml の tool を一括導入。mas/redis は os 指定で Windows ではスキップ)
choco install mise -y
mise install

# choco packages (GUI アプリ等。mise で扱えない Windows ソフトを choco で管理)
# '#' 始まりの行と空行はスキップする。行末の '#' 以降もコメントとして落とすので、
# パッケージ名の後に choco のオプションと、それを付ける理由を並べて書ける。
$chocoPackagesFile = "$PSScriptRoot\choco\packages.txt"
if (Test-Path $chocoPackagesFile) {
    Get-Content $chocoPackagesFile |
        ForEach-Object { ($_ -replace '#.*$', '').Trim() } |
        Where-Object { $_ } |
        ForEach-Object {
            # 空白区切りにして splat で渡す。1 つの文字列のまま渡すと
            # 「パッケージ名 + オプション」全体が 1 つのパッケージ名として解釈される。
            $chocoArgs = $_ -split '\s+'
            Write-Host "choco install $chocoArgs -y"
            choco install @chocoArgs -y
        }
}

# mise activation in PowerShell profile
$miseActivate = '(&mise activate pwsh) | Out-String | Invoke-Expression'
$currentProfileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if ($null -eq $currentProfileContent -or $currentProfileContent -notmatch "mise activate pwsh") {
    Add-Content -Path $profilePath -Value "`n$miseActivate"
    Write-Host "Added mise activation to $profilePath"
} else {
    Write-Host "mise activation already exists in $profilePath"
}
