# レビュー結果: このログだけではまだ「信じてよい」とは言えません

## 確認したこと

`harness_log.txt`（このrunの生transcript全体、`OpenAI Codex v0.148.0` のヘッダーから `tokens used` まで）に対して、以下をgrepしました。

```
grep -ni "goal-first" harness_log.txt   # → ヒットはすべてディレクトリ名 (goal-first-20260820-230916/...) のみ
grep -ni "skill"      harness_log.txt   # → 同上、ディレクトリ名のみ
grep -ni "CODEX_HOME|codex/skills|\.codex" harness_log.txt  # → 0件
```

結果、モデルの発言・実行コマンド・出力のどこにも `goal-first` の内容や `SKILL.md` らしき文言は出てきません。モデルが自発的にファイル探索した唯一のコマンドは

```
rg --files -g 'AGENTS.md' -g 'incident.md' . ..
```

で、`incident.md` と `AGENTS.md` しか探しておらず、`~/.codex/skills` やスキル発見用ディレクトリを覗いた形跡はありません。

## これでは不十分な理由

1. **「言及がない」は「読めなかった」の証明にならない**
   前回の汚染は「プロンプトに書いていないのに、Codex自身のスキル発見機構がグローバルシンボリックリンク経由で `goal-first` を見つけて読んでいた」というものでした。今回のログにはCodexが起動時に検出したskill一覧を出す行が元々存在しないため、「discoveryが0件だった」という**直接証拠**はこのログから得られません。「モデルが言及しなかった」という**間接証拠**しかありません。

2. **修正（`CODEX_HOME`を隔離ディレクトリに向ける）が今回のrunに実際に効いたか、ログのどこにも書かれていない**
   `CODEX_HOME` という文字列がログに一度も出てこないため、「この特定のプロセスに隔離済みの `CODEX_HOME` が渡っていたか」「その隔離ディレクトリに `skills/` が存在しないことを確認したか」は、このtranscriptだけからは検証できません。これはまさに verify-control-condition の言う「オーバーライドしたこと自体を検証していない」状態です。harnessの起動コマンド・環境変数（agent-bench側が `codex exec` をどう呼び出したか）を別途確認する必要があります。

3. **n=1でしかない**
   1回のrunで「汚染なし」と結論づけるのは時期尚早です。単発サンプルは分布の広さを示しているだけで、再現性を保証しません。

4. **（別軸の懸念）このfixtureはそもそも弁別力が低いかもしれない**
   `incident.md` 自体が「仮説に固執せず1回で切り分けろ」「中途半端なログの積み重ねが原因」と明示的に書いており、これは `goal-first` skill が教える振る舞いとほぼ同じです。つまりスキルが無くても、incident.mdの文面だけでモデルが同じような振る舞いを取る可能性が高く、`hypothesis-lock-in` というfixture名からもそれが伺えます。汚染とは別の話ですが、with/withoutの差が出にくい設計になっていないかは要確認です。

## 次にやるべきこと

1. **プロセスレベルで隔離を確認する**: agent-bench が実際に `codex exec` を呼び出したコマンド・環境変数ダンプを見て、このtrialに `CODEX_HOME=<隔離dir>` が渡っていたことを確認する。
2. **隔離用ホームの中身を直接確認する**: `ls -la $CODEX_HOME` `find $CODEX_HOME -iname '*skill*'` などで、`skills/` ディレクトリが存在しない（auth.jsonのみ）ことを実際に確認する。
3. **できれば raw log 自体に検証コマンドを残す**: harness側で各trial開始時に `echo $CODEX_HOME && ls -la $CODEX_HOME 2>&1` のようなデバッグ出力をログに吐かせておけば、今後は毎回このgrep一発で判定できるようになります。
4. **isolationが確認できてから複数trialに進める**: 1〜4を確認できたら、n=1のこの結果ではなく5〜10 trial程度回して分布を見てから判断する。
5. **fixture設計の見直し**: `hypothesis-lock-in` シナリオがincident.mdの文面自体でgoal-first的振る舞いを誘導していないか、他のfixtureでの差も含めて確認する。

**結論**: 現状のログは「モデルがgoal-firstに言及していない」ことしか示しておらず、「隔離が実際に効いていた」ことは示していません。まず1〜3の確認を行い、それが通ってから複数trialのベンチマークに進めることを推奨します。
