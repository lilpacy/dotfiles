## 結論

いいえ、このtrial-1だけを根拠に「without_skillの隔離修正は効いている」と判断するのは早計です。実際にログの中身を確認したところ、CODEX_HOME/symlinkの修正（`~/.codex/skills/goal-first` 経由の汚染）は正しく直っていますが、**同じバッチ内の他のtrialで、それとは別系統の汚染が実際に発生している**ことが確認できました。渡されたtrial-1は3件中もっとも「クリーンに見える」1件を切り出しただけです。

## 確認した事実

### 1. CODEX_HOME隔離自体は実装として正しい

- `src/core/harness.ts` の `ensureIsolatedCodexHome()` は `auth.json` だけをsymlinkし、`skills` ディレクトリは作っていません。
- 実機の `.codex-home-isolated/skills/` を見ると `.system` しかなく、`goal-first` のsymlinkは存在しません（`~/.codex/skills/goal-first` には存在する）。
- `env: { CODEX_HOME: ... }` は `run.ts`/`grade.ts` 側で `{ ...process.env, ...cmd.env }` として`spawnSync`に渡っており、PATH等を壊さずCODEX_HOMEだけ上書きできています。

→ ここは想定通り機能しています。

### 2. しかし、渡されたtrial-1は同一バッチの一部に過ぎない

このharness_log.txtは `results/goal-first-20260820-230916/codex__gpt-5.6-sol__without_skill__medium/hypothesis-lock-in__trial-1/harness_log.txt` と完全に一致します。同ディレクトリには `trial-2`, `trial-3` も存在し、**同条件・同修正後**で実行されています。

### 3. trial-2, trial-3 では実際に "goal-first" 文字列が漏れている

trial-2・trial-3のログを`grep`すると、モデル自身が実行した `git log --oneline -5` の出力に、以下の行がそのまま出ています。

```
11f98ea feat: goal-first suite を追加（対立仮説をゼロコストで検証してから動くskillの効果測定）
```

これは`SKILL.md`本文の漏洩ではありませんが、**「このタスクはgoal-firstスキルの効果測定ベンチである」というメタ情報そのものがモデルに見えてしまっている**ということです。しかもwith_skill/without_skillどちらの条件にも影響します。

### 4. 根本原因: fixtureがagent-bench自身のgit履歴を継承してしまっている

`suites/goal-first/fixture/repo` 自体は `.git` を持たないプレーンなファイル置き場ですが、実行時に `cpSync` でコピーされる先 (`results/.../_fixture`) が **agent-benchリポジトリの内部** にあるため、そこで`git log`/`git status`を打つと git は境界の`.git`が見つからず親方向へ探索し、agent-bench本体の `.git`（origin: `git@github.com:lilpacy/agent-bench.git`）にたどり着きます。実際に検証しました。

```
$ git -C .../_fixture rev-parse --git-dir
/Users/lilpacy/go/src/github.com/lilpacy/agent-bench/.git
```

つまり、モデルが（診断の一環として自然に）`git log`を叩けば、常にベンチマーク自体のコミット履歴——goal-firstスキルの意図まで書かれた文——が見える状態になっています。trial-1で汚染が見えなかったのは、たまたまそのtrialが`git log`系コマンドを実行しなかったからで、「隔離が効いている証拠」ではありません。

## この結果は信じられるか

信じられません。理由は2つです。

1. **サンプル選択の問題**: 3trial中2trialで実際に汚染が起きている状況で、1trial（しかも汚染が見えなかった方）だけを見て判断するのはチェリーピッキングになります。
2. **n=1で効果を語れない**: そもそも1 runでは、たとえ全trialがクリーンでも「skillの効果」を主張できるサンプルサイズではありません。

## 次にどう進めるべきか

1. **fixtureのgit境界を切る**（本質的な修正）
   - 一番シンプルなのは、`cpSync`後に `_fixture` 配下へ空の `.git`（`git init` 相当のダミー）を置くか、`GIT_CEILING_DIRS=<workdir>` を該当harnessの `env` に追加して上方向への探索を止めることです。symlink修正と同じ発想で、`fixture`単体では汚染源が閉じるようにします。
2. **既存3trialを汚染フラグ付きで無効化**
   - trial-2, trial-3は「goal-firstという語が漏れた」という理由で今回の比較対象からは除外（もしくは注記付きで別枠）にする。trial-1のみを「クリーンな1件」として扱うのも、上記の通りn=1では結論を出せないので保留。
3. **汚染検出を自動化する**
   - 目視ではなく、`run.ts`側で各`harness_log.txt`を書き出した直後に `goal-first` / `対立仮説` / `効果測定` などのキーワードをgrepし、ヒットしたら`meta.json`に`contaminated: true`を立てる仕組みを入れる。目視チェックに依存すると今回のように見落とします。
4. **修正後に十分なtrial数で再実行**
   - git境界の修正後、最低でも今回と同じ3trial（できれば増やす）を再実行し、全trialのraw logをgrepしてキーワードゼロを確認した上で、初めてwith_skill/without_skillの比較に進む。

要するに、「symlinkは直ったが、gitの境界という別の穴が同じバッチの中で実際に踏まれている」状態です。この1trialの結果だけでは何も結論できません。
