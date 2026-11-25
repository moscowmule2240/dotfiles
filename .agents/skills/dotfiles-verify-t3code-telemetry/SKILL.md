---
name: dotfiles-verify-t3code-telemetry
description: Use when T3 Code has been updated or installed on macOS or Windows and you need to verify that telemetry, relay traces, and agent activity publishing remain disabled. Triggers 「T3 Code のテレメトリーを確認」「T3 Code をアップデートしたので検証」「テレメトリーが止まっているか確認」「verify t3code telemetry」.
---

# T3 Code テレメトリー停止の検証（macOS / Windows）

T3 Code (`pingdotgg/t3code`) のアップデート後に、テレメトリー・リレートレース・エージェント活動公開が止まったままかを読み取り専用で検証し、必要なら履歴へ追記する手順。

## 原則

- **検証フェーズは読み取り専用**: ポリシー・hosts・T3 Code 設定は書き換えない。対応が必要な場合は提案と実行コマンドの提示にとどめる（管理者権限 / `sudo` が要るため）。
- **ソースを読むときは必ず導入済みのタグで読む**: `main` は使わず、ローカルに入っている版と同じタグを `.temp/t3code-telemetry/src-<タグ>/` へ shallow clone して読む。
- **履歴の基準を先に読む**: ワークスペース配下（サブモジュールを含む）に検証履歴ファイル（配置先はリポジトリの指示ファイル等に従う）があれば、導入版と同じ版のセクション（無ければ導入版より古い最新の既検証版と「現在の基準 (最新検証版)」）および「前提 (導入済みの対策)」を読む。無ければユーザーへ確認する。
- **複数台で同じ版を検証するときは「版共通」と「マシン固有」を分ける**: 履歴の該当版で項目 3・8 がともに「問題なし」として記録済み、かつ `git ls-remote` で取得したタグのコミット SHA が履歴と一致する場合（2 台目以降）、項目 3・8 は履歴を参照して **マシン固有の 6 項目（1・2・4・5・6・7）** を実測する。SHA 不一致・未解消の「要対応」/「確認できず」・項目 2/4/6 での想定外（ポリシー未適用・新 URL・想定外ホスト）が出た場合は clone して項目 3・8 も実行する。
- **`secrets/` の他ファイルは絶対に読まない**: `cloud-publish-agent-activity.bin` の存在確認と値判定だけ行い、他の `.bin` ファイルの中身は出力も読み取りもしない。

## OS ごとのパス・コマンド対応表

| 対象 | macOS | Windows |
|---|---|---|
| 導入済みアプリ | `/Applications/T3 Code (Beta).app` または `T3 Code.app`（`Contents/Info.plist`） | `%LOCALAPPDATA%\Programs\t3code\T3 Code (Beta).exe` または `T3 Code.exe`（`VersionInfo`） |
| バンドル (`asar`) | `Contents/Resources/app.asar`（あれば `server.asar` も） | `resources\app.asar` **および `resources\server.asar`** |
| managed policy | `/Library/Application Support/T3Code/policy.json`（または構成プロファイル `/Library/Managed Preferences/com.t3tools.t3code.plist`） | `C:\Program Files\T3Code\policy.json`（またはレジストリ `HKLM\SOFTWARE\Policies\T3Tools\T3Code`。WSL バックエンド利用時は WSL 内の `/etc/t3code/policy.json` も対象） |
| hosts ファイル | `/etc/hosts` | `C:\Windows\System32\drivers\etc\hosts` |
| OS 名前解決 | `dscacheutil -q host -a name <ホスト>`（`dig` は使わない） | `Resolve-DnsName -Name <ホスト>`（`GetHostAddresses` は `0.0.0.0`/`::` で例外になる） |
| ランタイム・版情報 | `~/.t3/userdata/server-runtime.json`, `desktop-last-started-version` | `%USERPROFILE%\.t3\userdata\server-runtime.json`, `desktop-last-started-version` |
| トレースログ | `~/.t3/userdata/logs/server.trace.ndjson*`, `desktop.trace.ndjson*` | `%USERPROFILE%\.t3\userdata\logs\server.trace.ndjson*`, `desktop.trace.ndjson*` |
| 活動公開フラグ | `~/.t3/userdata/secrets/cloud-publish-agent-activity.bin` | `%USERPROFILE%\.t3\userdata\secrets\cloud-publish-agent-activity.bin` |

※ `T3CODE_HOME` 環境変数が設定されている環境では `~/.t3` の代わりに `$T3CODE_HOME`（または両方）を確認する。managed policy はファイルとネイティブポリシーが両方あると T3 Code が起動しないため片方のみ配置する。

## 検証手順（8 項目）

項目 1・2・4・5・6・7 は **マシン固有（端末ごとに毎回実施）**、項目 3・8 は **版共通（同版が履歴で「問題なし」記録済みかつタグ SHA 一致なら参照のみで可）**。

1. **導入版の特定とタグ確認 / shallow clone**（マシン固有／clone は版共通が未検証または SHA 不一致・異常時）
   - OS 対応表のアプリメタデータと `userdata/desktop-last-started-version`・`userdata/server-runtime.json` の `serverVersion` から導入版を確定する。
   - 2 台目以降で clone を省く場合も、`git ls-remote --tags https://github.com/pingdotgg/t3code.git refs/tags/v<版> refs/tags/v<版>^{}` でタグのコミット SHA を取得し、履歴の該当版 SHA と一致することを確認する（不一致ならタグ差し替えとして clone し項目 3・8 を実行する）。
   - 版共通が未検証のとき（または SHA 不一致・異常時）は、`.temp/t3code-telemetry/src-v<版>/` へ `git clone --depth 1 --branch v<版> https://github.com/pingdotgg/t3code.git` し、差分用に「導入版より古い最新の既検証タグ」を `git fetch --depth 1 origin tag <前回タグ>` する。
   - Windows で `.repos/` 配下がパス長上限で checkout 失敗しても、`git checkout HEAD -- apps docs packages` で検証対象を展開できる。

2. **managed policy と起動時刻**（マシン固有）
   - ポリシー（ファイルまたはネイティブポリシー。WSL バックエンド利用時は WSL 側も）に `limits.telemetry: false`、および履歴の「前提 (導入済みの対策)」や該当版の「版共通」で必須とされている設定（`settings["agentFeedback.mode"]` の `off` / `locked: true` 等）があることを確認する。
   - `server-runtime.json` の `managedPolicy.source` と `managedPolicy.fingerprint` を確認し、`startedAt` がアプリ配置・更新時刻およびポリシー更新時刻より後であることを確認する。`t3 policy show` が使える場合は稼働中サーバーの読み込み一致も確かめる。

3. **ソース上の停止経路**（版共通：同版が「問題なし」既検証かつ SHA 一致なら履歴を参照）
   - 製品イベント（`apps/server/src/telemetry/AnalyticsService.ts`）、Agent feedback（`apps/server/src/feedback/FeedbackStore.ts`）、リレートレース（`apps/server/src/cloud/relayTracing.ts`・`packages/shared/src/relayTracing.ts`・`apps/desktop/src/ipc/methods/window.ts`・`apps/web/src/cloud/publicConfig.ts`）、および macOS / Windows 両 OS のポリシー読み込み分岐（`apps/server/src/policy/` 等）を読む。
   - `limits.telemetry: false` で確実に止まり、環境変数（`T3CODE_TELEMETRY_ENABLED=true` 等）やユーザー設定でオンに戻せる抜け道が増えていないことを確認する。

4. **バンドル内の埋め込み URL**（マシン固有：OS ごとにビルド成果物が異なるため毎回実施）
   - `app.asar` に加え、Windows（や分割構成）では **`server.asar` も必ず検査**する。サーバー本体・Web バンドル側の `ingest.t3.codes` / `relay.t3.codes` / `axiom.co` は `server.asar` 側に入る。
   - 既知ホストの検索だけで済ませず、`https?://`・`wss?://` の URL を全抽出してホスト一覧を作り、履歴の該当版の「埋め込み URL の一覧」（未記録版なら比較元の前回一覧。基準: `t3.codes`, `app.t3.codes`, `relay.t3.codes`, `ingest.t3.codes`, `us-east-1.aws.edge.axiom.co`）と比較して送り先の追加・ホスト名変更がないか確認する。
   - `@clerk/shared` 内の `clerk-telemetry.com` のようにライブラリ由来の文字列が出た場合は、本番鍵（`pk_live_`）での発火条件をバンドル内で確認する。

5. **hosts と名前解決**（マシン固有）
   - `ingest.t3.codes` と `us-east-1.aws.edge.axiom.co`（および履歴の「前提」や該当版の「版共通」に追加されたブロック対象ホストすべて）の IPv4 (`0.0.0.0`)・IPv6 (`::`) 行が残っていることを確認する。
   - OS 対応表のコマンドで対象ホストすべてが `0.0.0.0` と `::` を返すことを確認する（`dig` は hosts を見ないため使わない）。

6. **アップデート後起動からのログ集計**（マシン固有）
   - `server-runtime.json` の `startedAt` を Unix ナノ秒に変換し、`server.trace.ndjson` だけでなく **ローテーション済みの `server.trace.ndjson.1` 等も含めて** `startTimeUnixNano >= startedAt` のスパンを抽出する。
   - `url.full` / `server.address` ごとに外向き宛先をホスト別集計し、`ingest.t3.codes`・`axiom`・履歴上の追加ブロック対象ホスト宛てが 0 件であること、見慣れないホストがないことを確認する。可能なら `logs/desktop.trace.ndjson*` の起動後分も確認する。

7. **`cloud-publish-agent-activity.bin` の判定**（マシン固有）
   - `secrets/cloud-publish-agent-activity.bin` だけを確認し、ファイルが存在しない（未設定＝オフ）か中身が `false` であることを確認する（`true` のときのみ有効）。`secrets/` 配下の他ファイルは読まない。

8. **前回版からの差分確認**（版共通：同版が「問題なし」既検証かつ SHA 一致なら履歴を参照）
   - `git diff --name-only <前回タグ>..v<今回版>` を `telemetry|trace|tracing|analytics|policy|axiom|posthog|ingest|feedback|observability` 等で絞り、新設モジュールや変更ファイルを見落とさないようにする。
   - そのうえで `git diff <前回タグ>..v<今回版>` で `docs/user/telemetry.md`、`docs/user/managed-policy.md`、`apps/server/src/telemetry/`、`apps/server/src/feedback/`、`apps/server/src/cloud/relayTracing.ts`、`apps/server/src/relay/AgentAwarenessRelay.ts`、`apps/server/src/policy/`、`apps/desktop/src/ipc/methods/window.ts`、`apps/web/src/cloud/publicConfig.ts`、`apps/mobile/src/features/observability/`、`packages/shared/src/otelEnvironment.ts`、`packages/shared/src/relayTracing.ts` を読む。
   - 送信項目の増加、新規の送信経路（フィードバック等）、新しいポリシー項目、アプリ内スイッチ（モバイルの **Send connection traces** 等）の有無を確認する。

## 報告フォーマット（必須要素）

1. **8 項目ごとの判定表**: 各項目を「問題なし / 要対応 / 確認できず」で示し、根拠（ファイルと行番号、コマンド出力）を添える。2 台目以降で項目 3・8 を履歴から参照した場合は、その旨と参照元の版・一致確認済み SHA を明記する。
2. **ログ検証の限界**: 集計対象はアプリ自身が記録したスパンであり、OS ネットワーク層のパケットキャプチャではない点（スパン外通信・別プロセスは載らない点）を必ず明記する。
3. **対応提案**: 対応が要る場合のみ、追加すべき hosts 行やポリシー項目と実行コマンドを提案する（実行はしない）。
4. **次回用メモ**: 「今回検証した版（タグ・コミット SHA）」と「埋め込み URL の一覧」を末尾に明記する（2 台目以降は `git ls-remote` で一致確認した履歴の SHA を使う）。

## 履歴への追記（依頼された場合のみ）

- 複数台での競合を避けるため、追記前に履歴ファイルが属するリポジトリを最新化（`fetch` / ff-only）し、最新化後の履歴に該当版が既に増えていないかを再確認してから、リポジトリの規約（worktree 隔離・private/public の棲み分け）に従って編集する。ホスト名は private 側の履歴ファイルにのみ記載する。
- **未記録の版**: 版の節（`版共通`［項目 3・8 と埋め込み URL の一覧］・`マシン別検証結果` テーブル・`観測された外向き宛先の内訳と限界`）を作る。検証した版が既存の最新検証版より新しいときのみ「現在の基準 (最新検証版)」を更新して先頭へ追記し、既存より古い未記録版は「現在の基準 (最新検証版)」を変えずにバージョン降順の位置へ挿入する。
- **既記録の版（2 台目以降）**: 「版共通」は重複して書かず、その版の `マシン別検証結果` テーブルへ自マシン（ホスト名 / OS・検証日・`policy fingerprint`・各項目判定）の 1 行を、`観測された外向き宛先の内訳と限界` へ自マシンの外向き宛先の要約を追記する。項目 4 で別 OS 固有の新 URL が見つかった場合は該当版の「埋め込み URL の一覧」（テレメトリー関連なら「現在の基準 (最新検証版)」も）へ反映する。
- **同一マシン・同版での再検証（ポリシー更新・再起動後など）**: 該当マシンの既存行を最新結果で更新し、必要なら旧 fingerprint 時点の要点を備考または外向き宛先欄に残す。
