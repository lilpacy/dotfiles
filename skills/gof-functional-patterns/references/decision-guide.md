# GoF FP パターン選定ガイド

設計課題から、最小の FP 表現を選ぶためのガイドです。

## まず確認すること

1. **変化するものは何か**  
   アルゴリズム、生成方法、外部形式、状態、通知先、出力形式、処理順序など。

2. **固定したいものは何か**  
   ワークフローの骨格、ドメイン型、呼び出し側 API、サブシステム境界など。

3. **副作用はどこにあるか**  
   HTTP、DB、ファイル、ログ、時刻、乱数、キャッシュ、メッセージキューなど。

4. **本当にパターンが必要か**  
   1つの関数、1つのデータ型、1つの `map` / `reduce` で済むなら、それを優先する。

## 症状別の候補

| 症状 / 要件 | まず検討する FP 形 | 対応する GoF パターン |
|---|---|---|
| アルゴリズムを差し替えたい | 関数を引数にする | Strategy |
| 複数の関連実装をまとめて切り替えたい | 関数レコード / module | Abstract Factory |
| 種類に応じて生成処理を選びたい | registry / constructor function | Factory Method |
| 設定やクエリを段階的に作りたい | immutable builder pipeline | Builder |
| テンプレートから少し変えた値を作りたい | immutable template + copy/update | Prototype |
| 共有依存を1回だけ初期化したい | DI / module-level value / memoized factory | Singleton |
| 外部APIの型が内部型と合わない | 変換関数 / wrapper | Adapter |
| 抽象ロジックと実装を独立に増やしたい | algebra + interpreter | Bridge |
| 木構造を扱いたい | recursive ADT + fold | Composite |
| ログ・認証・キャッシュを重ねたい | middleware / HOF wrapper | Decorator |
| 複雑な処理群を簡単なAPIにしたい | use-case function | Facade |
| 大量の同一値を共有したい | immutable sharing / interning | Flyweight |
| アクセス制御・遅延・キャッシュを挟みたい | proxy function / thunk | Proxy |
| 複数 handler から担当を探したい | handler list / first success | Chain of Responsibility |
| 操作を保存・再実行・undoしたい | Command ADT + interpreter | Command |
| 小さな言語・ルールを解釈したい | AST ADT + evaluator | Interpreter |
| 大量データを順次処理したい | lazy sequence / generator | Iterator |
| 多数の部品の相互作用を整理したい | event loop / reducer | Mediator |
| 状態履歴を保存・復元したい | immutable snapshot / event log | Memento |
| 1イベントに複数反応したい | stream / pub-sub | Observer |
| 状態ごとに振る舞いを変えたい | state ADT + transition | State |
| 固定手順の一部だけ差し替えたい | HOF skeleton / pipeline | Template Method |
| 固定データ構造に操作を追加したい | pattern matching / fold | Visitor |

## よくある組み合わせ

### HTTP API サーバー
- Adapter: 外部 request を domain input に変換する。
- Decorator: handler に auth / logging / error handling を重ねる。
- Facade: use-case API を提供する。
- Strategy: バリデーションや計算方法を差し替える。

### EC チェックアウト
- Strategy: 割引・送料計算。
- Abstract Factory: 決済プロバイダ一式の切り替え。
- State: 注文・決済・配送のライフサイクル。
- Observer: 注文完了後のメール・分析・CRM連携。
- Command: 注文作成・返金・キャンセルのキュー化。
- Facade: `placeOrder` で複雑な処理をまとめる。

### DSL / ルールエンジン
- Interpreter: ルールを AST と評価関数で表す。
- Visitor: 評価、表示、最適化など複数操作を追加する。
- Composite: AST が木構造の場合に fold で処理する。

### UI / フロントエンド
- State: 画面状態とイベントの遷移。
- Observer: ユーザーイベントや store の購読。
- Mediator: 複数コンポーネントの協調を reducer へ集約。
- Memento: undo/redo、time travel debugging。

## 過剰設計を避ける判断

次の条件に当てはまる場合、GoF 名を出すより普通の関数で済ませてください。

- バリエーションが1つしかない。
- 将来の拡張可能性だけを理由に抽象化している。
- 抽象化後の名前が、業務用語よりパターン名中心になっている。
- テストが難しくなる。
- データの流れや副作用の場所が見えにくくなる。

## 回答時の推奨構成

```markdown
## 推奨: <Pattern> を FP の <表現> として使う

### なぜこれか
<変化するもの・固定したいものを説明>

### 最小実装
<関数 / ADT / reducer など>

### 適用すべきユースケース
<具体条件>

### 具体事例
<現実的な業務例>

### 注意点
<使わない方がよいケース>
```
