# PowerShell (pwsh) のプロファイルの実体。setup.ps1 が $PROFILE にこのファイルを dot-source する 1 行だけを書く。
# 中身を $PROFILE へ直接書き込まないのは、書き込むと後から直しても既に setup したマシンに反映されないため。

# mise の shim を PATH に通す。setup.ps1 の途中 (mise を入れる前) に開いたシェルでもエラーにしない
if (Get-Command mise -ErrorAction SilentlyContinue) {
    (&mise activate pwsh) | Out-String | Invoke-Expression
}

# 常用ツールの一括更新 (中身は update-tools.ps1。choco の更新に管理者権限が要るので、必要なら自分で昇格し直す)
Set-Alias -Name update-tools -Value (Join-Path $PSScriptRoot "update-tools.ps1")

# Antigravity の permissions だけを書き直す (中身は update-permissions.ps1。dotmine を取り込んでから流す。管理者権限は要らない)
Set-Alias -Name update-permissions -Value (Join-Path $PSScriptRoot "update-permissions.ps1")
