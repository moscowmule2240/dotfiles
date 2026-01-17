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
Get-ChildItem "$env:USERPROFILE\.ssh\conf.d\*" | Get-Content | Set-Content "$env:USERPROFILE\.ssh\config"
$linesToRemovePatterns = "^ControlPath|^ControlMaster|^ControlPersist"
$lines = Get-Content "$env:USERPROFILE\.ssh\config" | Where-Object { $_.Trim() -notmatch $linesToRemovePatterns }
$lines | Set-Content "$env:USERPROFILE\.ssh\config"

# claude-code
irm https://claude.ai/install.ps1 | iex
