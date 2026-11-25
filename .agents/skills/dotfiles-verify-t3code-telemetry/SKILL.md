---
name: dotfiles-verify-t3code-telemetry
description: Use when T3 Code has been updated or installed on macOS or Windows and you need to verify that telemetry, relay traces, and agent activity publishing remain disabled. Triggers 「T3 Code のテレメトリーを確認」「T3 Code をアップデートしたので検証」「テレメトリーが止まっているか確認」「verify t3code telemetry」.
---

# T3 Code テレメトリー停止の検証（macOS / Windows）

T3 Code (`pingdotgg/t3code`) のアップデート後に、テレメトリー・リレートレース・エージェント活動公開が止まったままかを読み取り専用で検証し、必要なら履歴へ追記する手順。

## 原則

- **検証フェーズは読み取り専用**: ポリシー・hosts・T3 Code 設定は書き換えない。対応が必要な場合は提案と実行コマンドの提示にとどめる（管理者権限 / `sudo` が要るため）。
- **必ず導入済みのタグでソースを読む**: `main` ではなく、ローカルに入っている版と同じタグを `.temp/t3code-telemetry/src-<タグ>/` へ shallow clone して読む。
- **前回版と埋め込み URL の基準を先に読む**: ワークスペース配下（サブモジュールを含む）に検証履歴ファイル（配置先はリポジトリの指示ファイル等に従う）があれば、その「最新検証の要約」から前回検証版と埋め込み URL 一覧を取る。無ければユーザーへ確認する。
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

1. **導入版の特定とタグの shallow clone**
   - OS 対応表のアプリメタデータと `userdata/desktop-last-started-version`・`userdata/server-runtime.json` の `serverVersion` から導入版を確定する。
   - `.temp/t3code-telemetry/src-v<版>/` へ `git clone --depth 1 --branch v<版> https://github.com/pingdotgg/t3code.git` し、差分用に前回タグも `git fetch --depth 1 origin tag <前回タグ>` する。
   - Windows で `.repos/` 配下がパス長上限で checkout 失敗しても、`git checkout HEAD -- apps docs packages` で検証対象を展開できる。

2. **managed policy と起動時刻**
   - ポリシー（ファイルまたはネイティブポリシー。WSL バックエンド利用時は WSL 側も）に `limits.telemetry: false`（必要に応じ `settings["agentFeedback.mode"]` が `off` / `locked: true`）があることを確認する。
   - `server-runtime.json` の `managedPolicy.source` にそのパスが載り、`startedAt` がアプリ配置・更新時刻およびポリシー更新時刻より後であることを確認する。`t3 policy show` が使える場合は稼働中サーバーの読み込み一致も確かめる。

3. **ソース上の停止経路**
   - 製品イベント（`apps/server/src/telemetry/AnalyticsService.ts`）、Agent feedback（`apps/server/src/feedback/FeedbackStore.ts`）、リレートレース（`apps/server/src/cloud/relayTracing.ts`・`packages/shared/src/relayTracing.ts`・`apps/desktop/src/ipc/methods/window.ts`・`apps/web/src/cloud/publicConfig.ts`）を読む。
   - `limits.telemetry: false` で確実に止まり、環境変数（`T3CODE_TELEMETRY_ENABLED=true` 等）やユーザー設定でオンに戻せる抜け道が増えていないことを確認する。

4. **バンドル内の埋め込み URL**
   - `app.asar` に加え、Windows（や分割構成）では **`server.asar` も必ず検査**する。サーバー本体・Web バンドル側の `ingest.t3.codes` / `relay.t3.codes` / `axiom.co` は `server.asar` 側に入る。
   - 既知ホストの検索だけで済ませず、`https?://`・`wss?://` の URL を全抽出してホスト一覧を作り、前回一覧（基準: `t3.codes`, `app.t3.codes`, `relay.t3.codes`, `ingest.t3.codes`, `us-east-1.aws.edge.axiom.co`）と比較して送り先の追加・ホスト名変更がないか確認する。
   - `@clerk/shared` 内の `clerk-telemetry.com` のようにライブラリ由来の文字列が出た場合は、本番鍵（`pk_live_`）での発火条件をバンドル内で確認する。

5. **hosts と名前解決**
   - `ingest.t3.codes` と `us-east-1.aws.edge.axiom.co` の IPv4 (`0.0.0.0`)・IPv6 (`::`) 計 4 行が残っていることを確認する。
   - OS 対応表のコマンドで両ホストとも `0.0.0.0` と `::` を返すことを確認する（`dig` は hosts を見ないため使わない）。

6. **アップデート後起動からのログ集計**
   - `server-runtime.json` の `startedAt` を Unix ナノ秒に変換し、`server.trace.ndjson` だけでなく **ローテーション済みの `server.trace.ndjson.1` 等も含めて** `startTimeUnixNano >= startedAt` のスパンを抽出する。
   - `url.full` / `server.address` ごとに外向き宛先をホスト別集計し、`ingest.t3.codes` と `axiom` 宛てが 0 件であること、見慣れないホストがないことを確認する。可能なら `logs/desktop.trace.ndjson*` の起動後分も確認する。

7. **`cloud-publish-agent-activity.bin` の判定**
   - `secrets/cloud-publish-agent-activity.bin` だけを確認し、ファイルが存在しない（未設定＝オフ）か中身が `false` であることを確認する（`true` のときのみ有効）。`secrets/` 配下の他ファイルは読まない。

8. **前回版からの差分確認**
   - `git diff --name-only <前回タグ>..v<今回版>` を `telemetry|trace|tracing|analytics|policy|axiom|posthog|ingest|feedback|observability` 等で絞り、新設モジュールや変更ファイルを見落とさないようにする。
   - そのうえで `git diff <前回タグ>..v<今回版>` で `docs/user/telemetry.md`、`docs/user/managed-policy.md`、`apps/server/src/telemetry/`、`apps/server/src/feedback/`、`apps/server/src/cloud/relayTracing.ts`、`apps/server/src/relay/AgentAwarenessRelay.ts`、`apps/server/src/policy/`、`apps/desktop/src/ipc/methods/window.ts`、`apps/web/src/cloud/publicConfig.ts`、`apps/mobile/src/features/observability/`、`packages/shared/src/otelEnvironment.ts`、`packages/shared/src/relayTracing.ts` を読む。
   - 送信項目の増加、新規の送信経路（フィードバック等）、新しいポリシー項目、アプリ内スイッチ（モバイルの **Send connection traces** 等）の有無を確認する。

## 報告フォーマット（必須要素）

1. **8 項目ごとの判定表**: 各項目を「問題なし / 要対応 / 確認できず」で示し、根拠（ファイルと行番号、コマンド出力）を添える。
2. **ログ検証の限界**: 集計対象はアプリ自身が記録したスパンであり、OS ネットワーク層のパケットキャプチャではない点（スパン外通信・別プロセスは載らない点）を必ず明記する。
3. **対応提案**: 対応が要る場合のみ、追加すべき hosts 行やポリシー項目と実行コマンドを提案する（実行はしない）。
4. **次回用メモ**: 「今回検証した版（タグ・コミット SHA）」と「埋め込み URL の一覧」を末尾に明記する。

## 履歴への追記（依頼された場合のみ）

履歴の保存・コミットを求められた場合は、リポジトリの規約（worktree 隔離・private/public の棲み分け）に従い、検証履歴ファイルの「最新検証の要約」を更新して新しい版の節を先頭へ追記する。
