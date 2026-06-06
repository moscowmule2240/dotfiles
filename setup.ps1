#!/usr/bin/env pwsh

# Check if running on Windows and require admin privileges for symbolic links
if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) {
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

# mise activation in PowerShell profile
$miseActivate = '(&mise activate pwsh) | Out-String | Invoke-Expression'
$currentProfileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if ($null -eq $currentProfileContent -or $currentProfileContent -notmatch "mise activate pwsh") {
    Add-Content -Path $profilePath -Value "`n$miseActivate"
    Write-Host "Added mise activation to $profilePath"
} else {
    Write-Host "mise activation already exists in $profilePath"
}
