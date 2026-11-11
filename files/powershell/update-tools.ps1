#!/usr/bin/env pwsh

# よく使うソフトウェアをまとめて最新化する (Windows 版。Mac 版は files/.zfunc/update-tools.zsh)。
# setup.ps1 が $PROFILE に update-tools の alias を足し、このスクリプトを直接呼ぶ。
# 関数の中身を $PROFILE へ書き込まないのは、書き込むと後から直しても既に入っているマシンに反映されないため。
#
# 対象は Mac 版の並びにそろえる (Mac 版を変えたらこちらも見直す)。Windows に相当するものが無い
# iterm2・htop・zsh・zsh-completions・zsh-git-prompt と、config.toml で Windows を外している mise の
# mitmproxy は持たない。claude (デスクトップ版)・onedrive は choco/packages.txt に無いので持たない。

# choco upgrade は管理者権限が要る。setup.ps1 と同じく、管理者でなければ管理者の pwsh で起動し直す
# (更新は新しいウィンドウで進むので、-NoExit で結果を読めるように残す)
if ($IsWindows) {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "Restarting with administrator privileges..."
        Start-Process pwsh -Verb RunAs -ArgumentList "-NoExit", "-File", "`"$PSCommandPath`""
        return
    }
}

# choco upgrade は既定だと未導入のパッケージを新しく入れる。--skip-if-not-installed で飛ばし、
# そのマシンで入れていない・手で消したアプリが、更新のたびに入ってくるのを防ぐ。
# --fail-on-not-installed (Mac の brew upgrade が未導入の cask で失敗するのに近い) にしないのは、
# 意図して入れていないマシンで毎回失敗が出て、本当の失敗が埋もれるため。
$chocoPackages = @(
    # Mac 版の cask に当たるもの
    "antigravity-cli"
    "antigravity-ide"
    "bitwarden"
    "claude-code"
    "comet"
    "docker-desktop"
    "googlechrome"
    "mysql.workbench"
    "pycharm"
    "typeless"
    "vscode"
    # Mac 版の formula に当たるもの (下の mise upgrade より先に mise 自体を上げる)
    "mise"
)
choco upgrade @chocoPackages -y --skip-if-not-installed

# mise 管理に移したもの (Mac 版と同じ。--yes で確認プロンプトを自動承諾する)
mise upgrade --yes bitwarden gh

# Antigravity の setup を流し直す (共有の設定とプラグインをそろえ直す)。何度流しても同じ結果になる作りで、実体は
# private な dotmine 側にあり、dotmine が無いマシンでは飛ばす。
# Mac 版はこの後で ~/.gemini/config の symlink を確かめているが、dotmine の antigravity/setup.ps1 は違う先を指すリンクを
# 張り直し、張れなかったもの・実ファイルで残したものを自分で stderr に出すので、ここでは重ねて確かめない。
$agySetup = Join-Path (Split-Path (Split-Path $PSScriptRoot)) "dotmine" "antigravity" "setup.ps1"
if (Test-Path -LiteralPath $agySetup) {
    & $agySetup
}
