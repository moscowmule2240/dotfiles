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
