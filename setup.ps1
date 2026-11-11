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

# PowerShell のプロファイル (実体は files/powershell/profile.ps1。SSH の関数・mise activate・update-tools の alias)
# $PROFILE にはその dot-source の 1 行だけを書く (中身を書き込むと、後から直しても既に setup したマシンに反映されないため)。
# 以前の setup.ps1 が $PROFILE に書き込んだもの (SSH の関数・mise activate・update-tools の alias) は profile.ps1 へ移したので取り除く。
# 消すのは以前の setup.ps1 が書いた形の行だけで、消した行は表示する。SSH の関数は、書き込んだときと同じ並び
# (行末の空白は見ない) のときだけ取り除き、手で直してあれば残して知らせる。
# dot-source の行は、既にあれば位置を動かさない。無ければ以前の mise activate の位置 (無ければ最初に取り除いた行の位置) に
# 差し込み、何も取り除かなければ末尾に足す。mise activate の前後の行は、mise の PATH や prompt の上書きの前後関係を当てにして
# いるので、その位置を保つ。以前の SSH の関数は mise activate より前に書いていたので、手で直して残した関数より dot-source の方が
# 後になり、profile.ps1 の定義が勝つ。
# リポジトリの置き場が変わったときに古いパスの行が残らないよう、古い dot-source の行はその位置で差し替える。
# パスの ' は '' に二重化する (そのままだと $PROFILE 全体が構文エラーになる)。
# 読み出しに失敗したら止める (空として扱うと、$PROFILE 全体を上書きしてしまう)。
$profilePath = $PROFILE
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}
$profileSource = ". '$($PSScriptRoot.Replace("'", "''"))\files\powershell\profile.ps1'"
$legacySshFunctions = @(
    '# SSH Config Auto-generation'
    'function Update-SshConfig {'
    '    $sshHome = "$env:USERPROFILE\.ssh"'
    '    $confDir = Join-Path $sshHome "conf.d"'
    '    $targetConfig = Join-Path $sshHome "config"'
    ''
    '    if (Test-Path $confDir) {'
    '        # Get content from files only'
    '        $content = Get-ChildItem (Join-Path $confDir "*") -File | Get-Content'
    '        $filtered = $content | Where-Object { $_ -notmatch "^\s*(ControlPath|ControlMaster|ControlPersist)" }'
    '        $filtered | Set-Content $targetConfig'
    '    }'
    '}'
    ''
    'function ssh {'
    '    Update-SshConfig'
    '    ssh.exe @args'
    '}'
    ''
    'function scp {'
    '    Update-SshConfig'
    '    scp.exe @args'
    '}'
)
$currentLines = @(Get-Content $profilePath -ErrorAction Stop)

# 以前の SSH の関数を探す (書き込んだときは直前に空行を 1 行足していたので、あればそれも取り除く)
$legacyStart = -1
$legacyEnd = -1
for ($i = 0; $i -le $currentLines.Count - $legacySshFunctions.Count; $i++) {
    $same = $true
    for ($j = 0; $j -lt $legacySshFunctions.Count; $j++) {
        if ($currentLines[$i + $j].TrimEnd() -cne $legacySshFunctions[$j]) { $same = $false; break }
    }
    if ($same) { $legacyStart = $i; $legacyEnd = $i + $legacySshFunctions.Count; break }
}
if ($legacyStart -gt 0 -and $currentLines[$legacyStart - 1].Trim() -eq '') { $legacyStart-- }
if ($legacyStart -lt 0 -and $currentLines -match '^\s*function Update-SshConfig\b') {
    Write-Host "Left the hand-edited SSH functions in $profilePath (the ones in files\powershell\profile.ps1 override them)"
}

# 以前の setup.ps1 が書いた行を取り除き、dot-source の行を置く位置を決める
# (mise activate は直前に空行を 1 行足して書いていたので、あればそれも取り除く)
$legacyMise = '(&mise activate pwsh) | Out-String | Invoke-Expression'
$legacyAlias = "^Set-Alias -Name update-tools -Value '.*[\\/]files[\\/]powershell[\\/]update-tools\.ps1'$"
$oldSource = "^\. '.*[\\/]files[\\/]powershell[\\/]profile\.ps1'$"
$keptLines = [System.Collections.Generic.List[string]]::new()
$insertAt = -1
$miseAt = -1
$hasSource = $false
for ($i = 0; $i -lt $currentLines.Count; $i++) {
    $line = $currentLines[$i]
    if ($i -ge $legacyStart -and $i -lt $legacyEnd) {
        if ($i -eq $legacyStart) { Write-Host "Removed the SSH functions written by an earlier setup.ps1 from $profilePath" }
        if ($insertAt -lt 0) { $insertAt = $keptLines.Count }
        continue
    }
    if ($line -ceq $profileSource) {
        if (-not $hasSource) { $keptLines.Add($line) }
        $hasSource = $true
        continue
    }
    # mise activate は字下げせずに書いていたので、字下げした行 (手で if の中などに書いたもの) は対象にしない
    $isLegacyMise = $line.TrimEnd() -ceq $legacyMise
    if ($isLegacyMise -or $line -match $legacyAlias -or $line -match $oldSource) {
        Write-Host "Removed from ${profilePath}: $line"
        if ($isLegacyMise) {
            if ($keptLines.Count -gt 0 -and $keptLines[$keptLines.Count - 1].Trim() -eq '') { $keptLines.RemoveAt($keptLines.Count - 1) }
            if ($miseAt -lt 0) { $miseAt = $keptLines.Count }
        }
        # 空行を取り除いたぶん、先に決めた位置が行数を超えることがあるので詰める
        if ($miseAt -gt $keptLines.Count) { $miseAt = $keptLines.Count }
        if ($insertAt -lt 0 -or $insertAt -gt $keptLines.Count) { $insertAt = $keptLines.Count }
        continue
    }
    $keptLines.Add($line)
}
if (-not $hasSource) {
    if ($miseAt -ge 0) {
        $keptLines.Insert($miseAt, $profileSource)
    } elseif ($insertAt -ge 0) {
        $keptLines.Insert($insertAt, $profileSource)
    } else {
        while ($keptLines.Count -gt 0 -and $keptLines[$keptLines.Count - 1].Trim() -eq '') { $keptLines.RemoveAt($keptLines.Count - 1) }
        $keptLines.Add($profileSource)
    }
}
$profileLines = @($keptLines)

if (($profileLines -join "`n") -cne ($currentLines -join "`n")) {
    Set-Content -Path $profilePath -Value $profileLines
    Write-Host "Set $profileSource in $profilePath"
} else {
    Write-Host "$profilePath already loads files\powershell\profile.ps1"
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
