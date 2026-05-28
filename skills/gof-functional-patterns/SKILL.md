---
name: gof-functional-patterns
description: GoF/オブジェクト指向デザインパターンを関数型プログラミング（pure functions, higher-order functions, ADT, composition, immutability, effect boundaries）でシンプルに整理・設計・リファクタリングする。Strategy/Factory/Adapter/ObserverなどGoF全23パターンのFP置き換え、適用判断、具体事例を提示する必要があるときに使う。
---

# GoF Functional Patterns

GoF の全23デザインパターンを、関数型プログラミング（FP）の考え方でシンプルに説明・設計・リファクタリングするための Skill です。  
「クラス階層を作る」ことを目的にせず、**データ・関数・合成・不変性・明示的な副作用境界**で問題を小さく解くことを優先してください。

## この Skill を使う場面

ユーザーが次のような依頼をしたときに使います。

- GoF デザインパターンを関数型で説明してほしい
- OO のパターン実装を FP っぽく簡略化したい
- Strategy / Factory / Adapter / Observer などを、クラスなしで実装したい
- ある設計課題にどのパターンを当てるべきか判断したい
- パターンごとの適用ユースケースと具体事例を知りたい
- 既存コードの「過剰なパターン適用」を見直したい

## 基本方針

1. **パターン導入ありきにしない**  
   まず「普通の関数・データ構造・合成」で足りるか確認する。

2. **継承より合成を優先する**  
   Template Method / Factory Method / State など、継承で表現されがちなものは、関数引数・レコード・ADT・パターンマッチ・fold に置き換える。

3. **副作用を境界に寄せる**  
   I/O、DB、HTTP、ログ、キャッシュ、時刻、乱数などは、純粋関数の外側に閉じ込める。必要なら `Env` や「関数のレコード」を渡す。

4. **状態は明示的な値として扱う**  
   State / Memento / Command / Observer などは、ミュータブルオブジェクトではなく、状態値・イベント・コマンド・Reducer・Stream として扱う。

5. **「いつ使うか」「いつ使わないか」を必ず述べる**  
   各パターンについて、適用条件、非適用条件、具体的な業務例をセットで説明する。

## 回答フロー

ユーザーの依頼に対して、原則として次の順序で考えてください。

1. **問題の力点を特定する**  
   例: アルゴリズム差し替え、生成ロジック、外部API変換、状態遷移、イベント通知、木構造、横断的関心事など。

2. **GoF パターン名を対応づける**  
   必要なら複数候補を挙げ、最小のものを選ぶ。

3. **FP での最小形に落とす**  
   クラス図ではなく、関数、関数レコード、ADT、Reducer、fold、middleware、pipeline、memoization などで表現する。

4. **適用すべきユースケースを明確にする**  
   「何が変化するのか」「何を固定したいのか」「どの副作用を隔離したいのか」を説明する。

5. **具体事例を添える**  
   抽象論だけで終わらず、EC、決済、APIクライアント、通知、検索、ワークフロー、DSL、UI、ログなどの現実的な例を出す。

6. **必要なら短いコードスケッチを出す**  
   言語指定がなければ TypeScript 風の疑似コードを使う。関数型言語指定がある場合はその言語に寄せる。

## GoF → FP 早見表

詳細は [`references/pattern-catalog.md`](references/pattern-catalog.md) を読んでください。

| 分類 | GoF パターン | FP でのシンプルな見方 |
|---|---|---|
| 生成 | Abstract Factory | 関連する生成関数・操作関数をまとめたレコード / モジュール |
| 生成 | Builder | 不変な設定値を積み上げる pipeline / smart constructor |
| 生成 | Factory Method | コンストラクタ関数の引数化 / キーから関数を引く registry |
| 生成 | Prototype | 不変テンプレート値 + copy/update |
| 生成 | Singleton | module-level value / DI された共有依存 / memoized factory |
| 構造 | Adapter | 入出力変換関数 / wrapper / `map`・`contramap` |
| 構造 | Bridge | 関数レコードに対して書くプログラム / algebra と interpreter の分離 |
| 構造 | Composite | 再帰的 ADT + fold |
| 構造 | Decorator | 高階関数による function wrapping / middleware |
| 構造 | Facade | 複雑なサブシステムを束ねる薄い use-case 関数 |
| 構造 | Flyweight | 共有された不変値 / interning / memoization |
| 構造 | Proxy | lazy thunk / cache wrapper / auth wrapper / remote wrapper |
| 振る舞い | Chain of Responsibility | `Request -> Option<Response>` の関数列 / middleware chain |
| 振る舞い | Command | Command ADT + interpreter / thunk / event log |
| 振る舞い | Interpreter | AST ADT + evaluator / parser combinator |
| 振る舞い | Iterator | lazy sequence / generator / fold・map・filter |
| 振る舞い | Mediator | event loop / reducer / state machine |
| 振る舞い | Memento | immutable snapshot / persistent data structure / event sourcing |
| 振る舞い | Observer | stream / pub-sub / signal / event handler list |
| 振る舞い | State | state ADT + transition function |
| 振る舞い | Strategy | 関数を渡す / アルゴリズムを値として扱う |
| 振る舞い | Template Method | 高階関数に手順を注入する / pipeline skeleton |
| 振る舞い | Visitor | ADT の pattern matching / fold |

## 参照ファイル

- [`references/pattern-catalog.md`](references/pattern-catalog.md): GoF 全23パターンの FP 版、適用条件、非適用条件、具体事例。
- [`references/decision-guide.md`](references/decision-guide.md): 要件・症状から使うパターンを選ぶ判断ガイド。
- [`references/fp-recipes.md`](references/fp-recipes.md): パターンを簡略化する FP 実装レシピ。
- [`examples/ecommerce-checkout.md`](examples/ecommerce-checkout.md): EC チェックアウトを題材にした複数パターンの具体例。

## 回答テンプレート

単一パターンを説明するときは、次の形を基本にしてください。

````markdown
## <Pattern Name> を FP で見る

### 一言で
<クラスベースの意図を、関数型の最小形に言い換える>

### FP での置き換え
- <関数 / ADT / fold / reducer / middleware など>

### 適用すべきユースケース
- <いつ使うか>

### 使わない方がよいケース
- <過剰設計になる条件>

### 具体例
<現実的な事例>

### 最小コード例
```ts
// 必要な場合だけ
```
````

複数パターンの比較を求められた場合は、最初に「最小で済む候補」を示し、過剰なパターンを避ける判断も説明してください。
