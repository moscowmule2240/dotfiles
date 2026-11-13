#!/usr/bin/env pwsh

# Antigravity の permissions (~/.gemini/config/config.json の userSettings.globalPermissionGrants) だけを書き直す (Windows)。
# files/powershell/profile.ps1 が update-permissions の alias を張り、このスクリプトを直接呼ぶ。
#
# 許可リストの実体は private な dotmine にあるので、dotmine の main を origin/main から ff で取り込んでから
# dotmine/antigravity/update-permissions.ps1 を流す。update-tools も最後に同じものを流すが、そちらは dotmine を
# 取り込まず、choco・mise の更新と管理者権限も伴う。許可リストの変更だけを反映したいときはこちらで足りる。
# 引数は dotmine/antigravity/update-permissions.ps1 へそのまま渡す。
#
# 取り込む変更は取り込む前に表示し、y と答えたときだけ取り込んで書き直す。origin に入ったものが、中身を見ないまま
# agy の allow (確認なしで実行できるコマンド) になるのを防ぐため。表示と取り込みは fetch の直後に控えた 1 つのコミットに
# 対して行い (確認を待つ間に別の fetch が origin/main を進めても、見せていないコミットまで進めない)、ローカルの main が
# origin/main に無いコミットを持つときは止める (表示されない変更がそのまま流れるため)。

# git を呼べないなどのときに、前のコマンドの $LASTEXITCODE を見て先へ進まないよう、エラーで止める
$ErrorActionPreference = "Stop"

# 理由を stderr に出して、書き直さずに終える
function Stop-Update([string]$Reason) {
    [Console]::Error.WriteLine("update-permissions: $Reason")
    exit 1
}

# 未コミットの変更・未追跡のファイルがあると、取り込む版と違う中身のまま書き直してしまう
function Assert-CleanDotmine {
    $dirty = git -C $dotmine status --porcelain
    if ($LASTEXITCODE -ne 0) { Stop-Update "dotmine の状態を読めなかった" }
    if ($dirty) {
        Stop-Update "dotmine に未コミットの変更か未追跡のファイルがある。git -C `"$dotmine`" status で確かめてから流し直す"
    }
}

$dotmine = Join-Path (Split-Path (Split-Path $PSScriptRoot)) "dotmine"
if (-not (Test-Path -LiteralPath (Join-Path $dotmine ".git"))) {
    Stop-Update "dotmine が無い: $dotmine"
}

# 取り込むのは origin/main を追う main だけ。detached HEAD (submodule の既定) や作業ブランチ・別の upstream のまま取り込むと、
# 止まるか未マージの許可リストを流してしまう。PowerShell の -ne は大文字小文字を区別しないので -cne で比べる
$branch = git -C $dotmine symbolic-ref -q --short HEAD
if ($branch -cne "main") {
    $now = if ($branch) { $branch } else { "detached HEAD" }
    Stop-Update "dotmine が main に居ない (今は $now)。git -C `"$dotmine`" switch main してから流し直す"
}
$upstream = git -C $dotmine rev-parse --abbrev-ref "@{u}"
if ($LASTEXITCODE -ne 0 -or $upstream -cne "origin/main") {
    $now = if ($upstream) { $upstream } else { "無し" }
    Stop-Update "dotmine の main が origin/main を追っていない (今は $now)。git -C `"$dotmine`" branch -u origin/main してから流し直す"
}

Assert-CleanDotmine

git -C $dotmine fetch origin
if ($LASTEXITCODE -ne 0) { Stop-Update "dotmine を fetch できなかった (origin に繋がらない・SSH の鍵が使えない)" }

# 取り込む先を 1 つのコミットに固定する
$target = git -C $dotmine rev-parse --verify "origin/main^{commit}"
if ($LASTEXITCODE -ne 0) { Stop-Update "origin/main を読めなかった" }

$ahead = git -C $dotmine rev-list --count "$target..HEAD"
if ($LASTEXITCODE -ne 0) { Stop-Update "origin/main との差を読めなかった" }
if ([int]$ahead -gt 0) {
    Stop-Update "dotmine の main に origin/main に無いコミットが $ahead 個ある。push するか取り除いてから流し直す"
}

# ここでは HEAD が $target の祖先なので、HEAD...$target は取り込むコミットの変更そのもの
$changed = git -C $dotmine diff --name-only "HEAD...$target"
if ($LASTEXITCODE -ne 0) { Stop-Update "取り込む変更を読めなかった" }
if ($changed) {
    # 一覧は全部を見せる (antigravity/ の外にも、dotfiles の setup.ps1 から管理者で流れるスクリプトがある)。
    # 中身は許可リストを組み立てる antigravity/ だけを見せる
    git -C $dotmine --no-pager diff --stat "HEAD...$target"
    git -C $dotmine --no-pager diff "HEAD...$target" -- antigravity
    $answer = Read-Host "上の変更を取り込んで permissions を書き直すなら y"
    if ($answer -cne "y") { Stop-Update "取り込まずに止めた" }
}

# 確認を待つ間に作業ツリーが書き換わっていないかを、取り込む直前にもう一度見る
Assert-CleanDotmine

git -C $dotmine merge -q --ff-only $target
if ($LASTEXITCODE -ne 0) {
    Stop-Update "dotmine を ff で取り込めなかった。git -C `"$dotmine`" status で確かめてから流し直す"
}
$head = git -C $dotmine rev-parse HEAD
if ($head -cne $target) { Stop-Update "dotmine の HEAD が取り込んだ先と一致しない ($head)" }

& pwsh -NoProfile -File (Join-Path $dotmine "antigravity" "update-permissions.ps1") @args
exit $LASTEXITCODE
