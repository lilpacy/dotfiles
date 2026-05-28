# GoF 全23パターンの FP 簡略化カタログ

このカタログでは、各 GoF パターンを次の観点で整理します。

- **元の意図**: オブジェクト指向におけるパターンの狙い。
- **FP での最小形**: クラス階層を避け、関数・データ・合成で表すとどうなるか。
- **適用すべきユースケース**: どういう状況で使うべきか。
- **使わない方がよいケース**: 過剰設計になりやすい条件。
- **具体例**: 実務での適用イメージ。
- **最小コードスケッチ**: 言語未指定時の TypeScript 風疑似コード。

---

## 1. Abstract Factory

### 元の意図
関連するオブジェクト群を、具象クラスを指定せずに生成する。

### FP での最小形
**関連する生成関数・操作関数をまとめたレコード**として扱う。  
「Factory クラス」ではなく、環境や実装ごとの関数セットを注入する。

```ts
type PaymentModule = {
  createCharge: (input: ChargeInput) => Promise<Charge>;
  refund: (id: ChargeId) => Promise<Refund>;
  parseWebhook: (raw: unknown) => PaymentEvent;
};
```

### 適用すべきユースケース
- 複数の関連する処理を、実装ごとにまとめて差し替えたい。
- 1つの関数だけでなく、生成・検証・変換・実行などの「ファミリー」をセットで扱いたい。
- 本番・テスト・モック・外部サービス別実装などを切り替えたい。

### 使わない方がよいケース
- 差し替える処理が1つだけなら Strategy、単なる関数引数で十分。
- バリエーションが存在しないなら、抽象化しない方がよい。

### 具体例
EC サイトで決済プロバイダを Stripe / PayPal / GMO で切り替える。  
それぞれ `createCharge`、`refund`、`parseWebhook`、`verifySignature` を持つため、単一関数ではなく「決済モジュール」として注入する。

```ts
const stripePayment: PaymentModule = { createCharge, refund, parseWebhook };
const paypalPayment: PaymentModule = { createCharge, refund, parseWebhook };

const checkout = (payment: PaymentModule) => async (cart: Cart) => {
  const charge = await payment.createCharge(toChargeInput(cart));
  return charge;
};
```

---

## 2. Builder

### 元の意図
複雑なオブジェクトを段階的に組み立てる。

### FP での最小形
**不変な設定値を copy/update で積み上げる pipeline**、または **smart constructor** として扱う。  
副作用のある mutable builder ではなく、各ステップが新しい値を返す。

```ts
type Query = { filters: Filter[]; sort?: Sort; limit?: number };

const emptyQuery: Query = { filters: [] };
const where = (filter: Filter) => (q: Query): Query => ({ ...q, filters: [...q.filters, filter] });
const sortBy = (sort: Sort) => (q: Query): Query => ({ ...q, sort });
const limit = (n: number) => (q: Query): Query => ({ ...q, limit: n });
```

### 適用すべきユースケース
- オブジェクト・設定・クエリに多数の任意項目がある。
- 構築途中の状態を表現したい。
- 最後にまとめてバリデーションまたはコンパイルしたい。

### 使わない方がよいケース
- 必須フィールドが少ない単純なデータなら、通常のレコード生成で十分。
- builder が mutable な隠れ状態を持つと、FP の利点が失われる。

### 具体例
検索画面の条件を、キーワード・カテゴリ・価格帯・並び順・ページング条件として段階的に追加し、最後に Elasticsearch DSL に変換する。

```ts
const query = pipe(
  emptyQuery,
  where({ field: "category", op: "=", value: "book" }),
  where({ field: "price", op: "<", value: 3000 }),
  sortBy({ field: "createdAt", dir: "desc" }),
  limit(20)
);
```

---

## 3. Factory Method

### 元の意図
生成する具象クラスの決定をサブクラスに任せる。

### FP での最小形
**生成関数を引数で渡す**、または **キーから生成関数を引く registry** にする。

```ts
type Renderer = (message: Message) => RenderedMessage;

type Channel = "email" | "sms" | "slack";
const renderers: Record<Channel, Renderer> = {
  email: renderEmail,
  sms: renderSms,
  slack: renderSlack,
};
```

### 適用すべきユースケース
- 実行時の種類に応じて生成処理を変えたい。
- 呼び出し側に具象型・詳細な構築手順を知られたくない。
- プラグイン的に生成処理を登録したい。

### 使わない方がよいケース
- `if` が1〜2個で済み、今後の拡張もない。
- 生成以外の振る舞い差し替えなら Strategy の方が自然。

### 具体例
通知サービスで、通知チャネルに応じて送信ペイロードを生成する。  
Email は件名とHTML、SMS は短文、Slack は Block Kit 形式が必要。

```ts
const render = (channel: Channel, message: Message) =>
  renderers[channel](message);
```

---

## 4. Prototype

### 元の意図
既存オブジェクトを複製して新しいオブジェクトを作る。

### FP での最小形
**不変テンプレート値 + copy/update**。  
clone メソッドではなく、基準となるデータに差分をマージする。

```ts
const defaultCampaign: Campaign = {
  title: "Untitled",
  budget: 100000,
  channels: ["email"],
  status: "draft",
};

const newCampaign = { ...defaultCampaign, title: "Spring Sale" };
```

### 適用すべきユースケース
- 同じ初期値を持つデータを大量に作る。
- テンプレートから少数の項目だけを変更したい。
- 設定、キャンペーン、ドキュメント、UIコンポーネントなどの初期値を共有したい。

### 使わない方がよいケース
- 深い mutable object を clone すると、参照共有バグが起きる。
- テンプレートが頻繁に変わり、差分が不明瞭になる。

### 具体例
マーケティングツールで、既存キャンペーンテンプレートを複製し、タイトル・配信日時・対象セグメントだけ差し替えて新しいキャンペーンを作る。

```ts
const campaignFromTemplate = (overrides: Partial<Campaign>): Campaign => ({
  ...defaultCampaign,
  ...overrides,
});
```

---

## 5. Singleton

### 元の意図
あるクラスのインスタンスを1つだけにし、グローバルアクセスを提供する。

### FP での最小形
**module-level value**、**依存性注入された共有値**、または **memoized factory** として扱う。  
グローバル mutable state ではなく、必要な依存を明示的に渡す。

```ts
type Env = {
  config: Config;
  logger: Logger;
  now: () => Date;
};

const makeApp = (env: Env) => ({
  placeOrder: placeOrder(env),
});
```

### 適用すべきユースケース
- 設定、ロガー、DB接続プールなど、アプリケーション内で共有したい依存がある。
- 初期化コストが高く、1回だけ作りたい。
- テストでは差し替え可能にしたい。

### 使わない方がよいケース
- 変更可能なグローバル状態を隠す目的で使う。
- テスト順序に依存する状態を持つ。
- 単なる便利アクセスとして乱用する。

### 具体例
DB 接続プールをプロセス起動時に作成し、各 use-case 関数に `Env` として渡す。  
テストでは in-memory DB に差し替える。

```ts
const makeEnv = memoize((): Env => ({
  config: loadConfig(),
  logger: consoleLogger,
  now: () => new Date(),
}));
```

---

## 6. Adapter

### 元の意図
互換性のないインターフェースを、期待されるインターフェースに変換する。

### FP での最小形
**入力・出力の変換関数**、または **wrapper function**。  
外部の形を内部のドメイン型へ変換する境界として置く。

```ts
const adaptStripeWebhook = (raw: StripeWebhook): PaymentEvent => ({
  type: raw.event_type === "charge.succeeded" ? "PaymentSucceeded" : "Unknown",
  paymentId: raw.data.object.id,
});
```

### 適用すべきユースケース
- 外部API、レガシーシステム、ライブラリの型や形式が内部設計と合わない。
- 外部仕様の変更を内部に波及させたくない。
- 単位変換、命名変換、構造変換、エラー変換が必要。

### 使わない方がよいケース
- 呼び出し側・呼び出され側の両方を自由に変更できる。
- 変換というより新しい振る舞い追加なら Decorator や Strategy を検討する。

### 具体例
外部決済サービスの webhook payload を、自社の `PaymentEvent` に変換してからドメイン処理に渡す。

```ts
const handleWebhook = (raw: StripeWebhook) =>
  pipe(raw, adaptStripeWebhook, handlePaymentEvent);
```

---

## 7. Bridge

### 元の意図
抽象部分と実装部分を分離し、それぞれ独立に変化できるようにする。

### FP での最小形
**algebra と interpreter の分離**。  
ビジネスロジックは「関数レコード」に対して書き、実装は別途注入する。

```ts
type ReportRenderer = {
  title: (text: string) => Doc;
  table: (rows: Row[]) => Doc;
  concat: (docs: Doc[]) => Doc;
};

const salesReport = (R: ReportRenderer, rows: Row[]) =>
  R.concat([R.title("Sales"), R.table(rows)]);
```

### 適用すべきユースケース
- ビジネス上の抽象と出力・保存・通信などの実装が別々に増える。
- PDF / HTML / CSV などの出力先を差し替えたい。
- ロジックを実装詳細から切り離してテストしたい。

### 使わない方がよいケース
- 実装が1つしかなく、今後も増える見込みがない。
- 単純な Adapter で足りる。

### 具体例
売上レポートの構成ロジックは同じだが、出力形式を PDF / HTML / Markdown に切り替える。  
レポート生成は renderer の関数だけを使い、具体的な描画は interpreter 側に置く。

```ts
const html = salesReport(htmlRenderer, rows);
const pdf = salesReport(pdfRenderer, rows);
```

---

## 8. Composite

### 元の意図
個々のオブジェクトと複合オブジェクトを同一視し、木構造を扱う。

### FP での最小形
**再帰的 ADT + fold**。  
Leaf / Branch をデータとして表し、処理は fold で一箇所に集約する。

```ts
type Menu =
  | { type: "item"; name: string; price: number }
  | { type: "group"; name: string; children: Menu[] };

const totalPrice = (menu: Menu): number =>
  menu.type === "item"
    ? menu.price
    : menu.children.reduce((sum, child) => sum + totalPrice(child), 0);
```

### 適用すべきユースケース
- 木構造、階層構造、ネストした構成を扱う。
- 葉と枝に共通の処理を適用したい。
- メニュー、組織図、カテゴリ、ファイルツリー、AST など。

### 使わない方がよいケース
- データが本質的にフラット。
- 木に対する処理がほとんどなく、階層化が不要。

### 具体例
EC のカテゴリツリーで、親カテゴリ配下の商品数、表示可否、価格集計、パンくずリストを計算する。

```ts
const visibleItems = (node: Menu): string[] =>
  node.type === "item"
    ? [node.name]
    : node.children.flatMap(visibleItems);
```

---

## 9. Decorator

### 元の意図
オブジェクトに動的に責務を追加する。

### FP での最小形
**高階関数による function wrapping**、または **middleware composition**。  
元の関数を受け取り、追加処理を持つ新しい関数を返す。

```ts
type Handler = (req: Request) => Promise<Response>;

type Middleware = (next: Handler) => Handler;

const withLogging: Middleware = next => async req => {
  console.log(req.path);
  return next(req);
};
```

### 適用すべきユースケース
- ログ、認証、キャッシュ、リトライ、計測、トランザクションなどの横断的関心事を追加したい。
- 複数の追加処理を順序付きで合成したい。
- 元のビジネスロジックを変更したくない。

### 使わない方がよいケース
- wrapper の順序に隠れた依存があり、理解が難しくなる。
- 追加処理がビジネスロジックの中核なら、関数本体に明示的に書く方がよい。

### 具体例
HTTP handler に認証、ログ、エラー処理、キャッシュを重ねる。

```ts
const handler = composeMiddleware(
  withErrorHandling,
  withLogging,
  withAuth,
  withCache
)(getProductHandler);
```

---

## 10. Facade

### 元の意図
複雑なサブシステムに対して、単純な窓口を提供する。

### FP での最小形
**薄い use-case 関数**または **小さなモジュール API**。  
内部では複数の関数・サービスを呼び出すが、呼び出し側には1つの意味ある操作として見せる。

```ts
const placeOrder = (env: Env) => async (input: PlaceOrderInput) => {
  const cart = await env.cartRepo.get(input.cartId);
  const order = createOrder(cart, input.address);
  await env.payment.charge(order.payment);
  await env.orderRepo.save(order);
  await env.mail.sendOrderConfirmation(order);
  return order;
};
```

### 適用すべきユースケース
- 呼び出し側が複数サブシステムの詳細を知る必要がない。
- 業務上の「1ユースケース」を API として提供したい。
- 複雑な初期化や順序制御を隠したい。

### 使わない方がよいケース
- Facade が大きくなりすぎて、何でも知っている神モジュールになる。
- 必要な制御まで隠してしまい、利用者が困る。

### 具体例
`placeOrder` という単一関数で、在庫確認、注文作成、決済、保存、メール送信を束ねる。  
画面側は checkout の詳細な順序を知らなくてよい。

---

## 11. Flyweight

### 元の意図
大量の類似オブジェクトで共有可能な状態を共有し、メモリ使用量を削減する。

### FP での最小形
**共有された不変値**、**interning**、**memoization**、**正規化データ**。  
共有対象は immutable にする。

```ts
const intern = <T>(keyOf: (x: T) => string) => {
  const cache = new Map<string, T>();
  return (value: T): T => {
    const key = keyOf(value);
    const found = cache.get(key);
    if (found) return found;
    cache.set(key, value);
    return value;
  };
};
```

### 適用すべきユースケース
- 同じ値が大量に登場する。
- 共有しても安全な immutable データである。
- メモリや生成コストがボトルネックになっている。

### 使わない方がよいケース
- オブジェクトが mutable。
- メモリ削減効果が小さいのにキャッシュ管理が複雑になる。

### 具体例
コンパイラや検索エンジンで、大量のトークンや AST ノードが同じ識別子文字列を持つ。  
識別子を interning して、同一文字列を共有する。

```ts
const internSymbol = intern((s: string) => s);
const token = { kind: "identifier", text: internSymbol("userId") };
```

---

## 12. Proxy

### 元の意図
対象オブジェクトへのアクセスを代理し、遅延、制御、キャッシュ、リモート呼び出しなどを行う。

### FP での最小形
**関数 wrapper**、**lazy thunk**、**cache wrapper**、**auth wrapper**。  
本物の処理と同じ型の関数を返す。

```ts
type GetUser = (id: UserId) => Promise<User>;

const withCache = (getUser: GetUser): GetUser => {
  const cache = new Map<UserId, User>();
  return async id => {
    const cached = cache.get(id);
    if (cached) return cached;
    const user = await getUser(id);
    cache.set(id, user);
    return user;
  };
};
```

### 適用すべきユースケース
- 高コストな処理を遅延・キャッシュしたい。
- アクセス制御、認可、レート制限を挟みたい。
- リモート API をローカル関数のように扱いたい。

### 使わない方がよいケース
- リモート呼び出しを完全にローカルと同じに見せると、遅延・失敗・再試行の扱いが隠れる。
- キャッシュの無効化が重要なのに設計していない。

### 具体例
ユーザー情報 API への呼び出しをキャッシュし、同一リクエスト内で重複取得を避ける。

```ts
const getUser = withCache(remoteGetUser);
```

---

## 13. Chain of Responsibility

### 元の意図
複数の処理者を連鎖させ、リクエストを処理できるものに渡す。

### FP での最小形
**`Request -> Option<Response>` の関数リスト**、または **middleware chain**。  
最初に成功した handler を使う、または順番に変換する。

```ts
type Handler = (req: Request) => Response | undefined;

const handle = (handlers: Handler[]) => (req: Request) =>
  handlers.map(h => h(req)).find(Boolean);
```

### 適用すべきユースケース
- 処理者の順序や組み合わせを動的に変えたい。
- どの処理者が担当するかを呼び出し側が知らなくてよい。
- バリデーション、ルーティング、認可、問い合わせ分類など。

### 使わない方がよいケース
- 担当が明確で、直接呼び出せば済む。
- chain が長くなり、なぜ処理されたか追跡しづらい。

### 具体例
カスタマーサポートの問い合わせを、請求、配送、返品、技術サポートの順に分類し、最初に該当した handler が対応する。

```ts
const routeTicket = handle([
  billingHandler,
  shippingHandler,
  returnHandler,
  techSupportHandler,
]);
```

---

## 14. Command

### 元の意図
リクエストをオブジェクトとしてカプセル化し、キュー、ログ、取り消し、再実行を可能にする。

### FP での最小形
**Command ADT + interpreter**、または **実行を遅延する thunk**。  
命令をデータとして保存し、別の場所で解釈する。

```ts
type OrderCommand =
  | { type: "CreateOrder"; cartId: CartId }
  | { type: "CancelOrder"; orderId: OrderId }
  | { type: "RefundOrder"; orderId: OrderId };

const interpret = (env: Env) => async (cmd: OrderCommand) => {
  switch (cmd.type) {
    case "CreateOrder": return createOrder(env, cmd.cartId);
    case "CancelOrder": return cancelOrder(env, cmd.orderId);
    case "RefundOrder": return refundOrder(env, cmd.orderId);
  }
};
```

### 適用すべきユースケース
- 操作をキューに入れたい。
- 操作履歴を保存したい。
- リトライ、監査、undo/redo、バッチ処理、権限チェックをしたい。

### 使わない方がよいケース
- ただ即時に関数を呼べばよいだけ。
- コマンドデータが実行コンテキストに強く依存しすぎる。

### 具体例
注文作成、キャンセル、返金などを command として保存し、ワーカーが順次実行する。  
失敗時は同じ command をリトライできる。

---

## 15. Interpreter

### 元の意図
文法をクラスで表現し、その文法に従う文を解釈する。

### FP での最小形
**AST ADT + evaluator**、または **parser combinator**。  
構文をデータとして表し、評価関数を分離する。

```ts
type Expr =
  | { type: "lit"; value: number }
  | { type: "add"; left: Expr; right: Expr }
  | { type: "mul"; left: Expr; right: Expr };

const evalExpr = (expr: Expr): number => {
  switch (expr.type) {
    case "lit": return expr.value;
    case "add": return evalExpr(expr.left) + evalExpr(expr.right);
    case "mul": return evalExpr(expr.left) * evalExpr(expr.right);
  }
};
```

### 適用すべきユースケース
- 小さな DSL を作りたい。
- ルール、計算式、検索条件、ポリシーなどをデータとして扱いたい。
- 評価、表示、最適化など複数の処理をしたい。

### 使わない方がよいケース
- 文法が大規模で、本格的な parser / compiler が必要。
- 単なる設定ファイルで十分。

### 具体例
価格計算ルールを DSL として表し、キャンペーンごとに「10%割引」「500円引き」「条件付き送料無料」などを評価する。

```ts
type PricingRule =
  | { type: "percentOff"; rate: number }
  | { type: "fixedOff"; amount: number }
  | { type: "when"; condition: Condition; rule: PricingRule };
```

---

## 16. Iterator

### 元の意図
集合の内部構造を隠して、要素に順番にアクセスする。

### FP での最小形
**lazy sequence**、**generator**、**fold / map / filter**。  
外部から `next()` を呼ぶより、変換 pipeline として扱う。

```ts
function* lines(file: File): Generator<string> {
  // ファイルから1行ずつ読む想定
}

const activeUsers = pipe(
  lines(csvFile),
  map(parseUser),
  filter(user => user.active)
);
```

### 適用すべきユースケース
- 大量データを一度にメモリへ載せたくない。
- コレクションの表現を隠して順次処理したい。
- ストリーム、CSV、ログ、ページング API を扱う。

### 使わない方がよいケース
- 小さな配列を単純に処理するだけなら、通常の `map` / `filter` で十分。
- iterator の mutable な位置状態がバグの原因になる。

### 具体例
巨大な CSV を1行ずつ読み、parse → validate → transform → write の pipeline で処理する。

---

## 17. Mediator

### 元の意図
複数オブジェクト間の複雑な相互作用を、仲介者に集約する。

### FP での最小形
**event loop**、**reducer**、**state machine**。  
各 component が互いを直接呼ばず、event と state transition で協調する。

```ts
type CheckoutEvent =
  | { type: "CartValidated" }
  | { type: "PaymentSucceeded" }
  | { type: "InventoryReserved" }
  | { type: "CheckoutFailed"; reason: string };

const reduceCheckout = (state: CheckoutState, event: CheckoutEvent): CheckoutState => {
  // state と event から次状態を返す
  return nextState;
};
```

### 適用すべきユースケース
- 多数のコンポーネントが互いに呼び合い、依存関係が絡まっている。
- UI、ワークフロー、チャット、チェックアウトなど、イベント駆動の調整が必要。
- ルールを一箇所に集めて見通しを良くしたい。

### 使わない方がよいケース
- Mediator が全知全能の神オブジェクトになる。
- 単純な関数合成で順序が表せる。

### 具体例
チェックアウトで、カート検証、在庫確保、決済、注文確定、メール送信が互いに直接呼び合わないように、イベントと reducer で進行状態を管理する。

---

## 18. Memento

### 元の意図
オブジェクトの内部状態を保存し、後で復元できるようにする。

### FP での最小形
**immutable snapshot**、**persistent data structure**、**event log**。  
状態を値として保存する。

```ts
type EditorState = { text: string; cursor: number };

type History = {
  past: EditorState[];
  present: EditorState;
  future: EditorState[];
};

const undo = (h: History): History => {
  const previous = h.past.at(-1);
  if (!previous) return h;
  return {
    past: h.past.slice(0, -1),
    present: previous,
    future: [h.present, ...h.future],
  };
};
```

### 適用すべきユースケース
- undo/redo を実現したい。
- 過去状態を保存して比較・監査したい。
- 状態を直接破壊せず、履歴として扱いたい。

### 使わない方がよいケース
- snapshot が巨大で、保存コストが高すぎる。差分や event sourcing を検討する。
- 機密情報を履歴に残してはいけない。

### 具体例
フォームエディタで、ユーザーの入力状態を毎ステップ保存し、undo/redo を実現する。  
テキスト、選択中フィールド、バリデーション状態を snapshot として持つ。

---

## 19. Observer

### 元の意図
あるオブジェクトの状態変化を、依存する複数オブジェクトへ通知する。

### FP での最小形
**stream**、**pub-sub**、**signal**、**event handler list**。  
イベントを値として流し、購読側は純粋関数または effect handler として扱う。

```ts
type EventHandler<E> = (event: E) => Promise<void>;

const publish = async <E>(handlers: EventHandler<E>[], event: E) => {
  for (const h of handlers) await h(event);
};
```

### 適用すべきユースケース
- 1つのイベントに複数の反応が必要。
- 発行側と購読側を疎結合にしたい。
- ドメインイベント、UIイベント、ログ、通知、分析など。

### 使わない方がよいケース
- 通知順序に重要な意味があるのに明示されていない。
- イベントの発生元と結果が追跡できなくなる。
- 同期処理として順序制御すべきワークフローを、安易にイベント化する。

### 具体例
`OrderPlaced` イベントが発生したら、メール送信、在庫更新、分析ログ、CRM連携をそれぞれの handler が処理する。

```ts
await publish(orderPlacedHandlers, { type: "OrderPlaced", orderId });
```

---

## 20. State

### 元の意図
オブジェクトの状態に応じて振る舞いを変え、状態遷移をオブジェクトとして表す。

### FP での最小形
**state ADT + transition function**。  
状態とイベントを受け取り、次状態と必要な effect を返す。

```ts
type SubscriptionState =
  | { type: "trial"; endsAt: Date }
  | { type: "active"; plan: Plan }
  | { type: "pastDue"; retryCount: number }
  | { type: "cancelled" };

type SubscriptionEvent =
  | { type: "PaymentSucceeded" }
  | { type: "PaymentFailed" }
  | { type: "CancelRequested" };

const transition = (
  state: SubscriptionState,
  event: SubscriptionEvent
): SubscriptionState => {
  // 不正遷移もここで制御する
  return nextState;
};
```

### 適用すべきユースケース
- ライフサイクルやワークフローに明確な状態遷移がある。
- 不正な状態や不正遷移を防ぎたい。
- 注文、配送、チケット、サブスクリプション、申請フローなど。

### 使わない方がよいケース
- 状態が2つ程度で、単純な boolean で十分。
- 遷移表や ADT を作るほど複雑ではない。

### 具体例
サブスクリプションが trial → active → pastDue → cancelled と遷移する。  
支払い成功・失敗・解約要求に応じて、許可された遷移だけを transition 関数で定義する。

---

## 21. Strategy

### 元の意図
アルゴリズムのファミリーを定義し、実行時に差し替えられるようにする。

### FP での最小形
**関数を渡す**。  
Strategy object ではなく、同じ型を持つ関数を値として扱う。

```ts
type DiscountStrategy = (cart: Cart) => Money;

const checkout = (discount: DiscountStrategy) => (cart: Cart) => {
  const discountAmount = discount(cart);
  return calculateTotal(cart, discountAmount);
};
```

### 適用すべきユースケース
- 計算方法、ソート、検証、価格決定、推薦ロジックなどを差し替えたい。
- 同じ入力・出力型で複数のアルゴリズムがある。
- テストで簡単な strategy に置き換えたい。

### 使わない方がよいケース
- アルゴリズムが1つしかない。
- 分岐が単純で、関数化するとかえって読みにくい。

### 具体例
EC の割引計算で、通常割引、会員ランク割引、クーポン割引、期間限定セール割引を差し替える。

```ts
const memberDiscount: DiscountStrategy = cart =>
  cart.customer.rank === "gold" ? money(1000) : money(0);

const total = checkout(memberDiscount)(cart);
```

---

## 22. Template Method

### 元の意図
処理の骨格を親クラスで定義し、一部の手順をサブクラスで差し替える。

### FP での最小形
**高階関数に可変ステップを注入する**、または **pipeline skeleton**。  
固定したい流れを関数として書き、変わる部分を callback として渡す。

```ts
type EtlSteps<A, B> = {
  extract: () => Promise<A[]>;
  transform: (a: A) => B;
  load: (items: B[]) => Promise<void>;
};

const runEtl = <A, B>(steps: EtlSteps<A, B>) => async () => {
  const rows = await steps.extract();
  const transformed = rows.map(steps.transform);
  await steps.load(transformed);
};
```

### 適用すべきユースケース
- 処理の大枠は固定で、一部のステップだけが変わる。
- サブクラスではなく、関数注入で差し替えたい。
- ETL、ファイル取込、バッチ処理、テストセットアップなど。

### 使わない方がよいケース
- skeleton が複雑になり、callback の意味が分かりづらい。
- 手順の順序自体も頻繁に変わるなら、pipeline の組み立てを外に出す。

### 具体例
CSV / API / DB からデータを取得する ETL で、extract と load は異なるが、validate → transform → save の流れは同じ。

```ts
const importUsers = runEtl({
  extract: readUserCsv,
  transform: normalizeUser,
  load: saveUsers,
});
```

---

## 23. Visitor

### 元の意図
オブジェクト構造の要素に対して、新しい操作を追加しやすくする。

### FP での最小形
**ADT の pattern matching**、または **fold**。  
データのバリアントを明示し、処理側で分岐する。

```ts
type Expr =
  | { type: "num"; value: number }
  | { type: "add"; left: Expr; right: Expr }
  | { type: "neg"; expr: Expr };

const render = (expr: Expr): string => {
  switch (expr.type) {
    case "num": return String(expr.value);
    case "add": return `(${render(expr.left)} + ${render(expr.right)})`;
    case "neg": return `-${render(expr.expr)}`;
  }
};
```

### 適用すべきユースケース
- データ構造の種類は比較的固定で、操作を追加したい。
- AST、ドメインイベント、式、UIツリーなどに対して、評価・描画・検証・最適化を追加したい。
- クラスごとの `accept(visitor)` を避けたい。

### 使わない方がよいケース
- 新しいデータバリアントを頻繁に追加する。既存の pattern matching を多数更新する必要がある。
- 単純なデータで分岐が少ない。

### 具体例
数式 AST に対して、評価、文字列化、定数畳み込み、変数抽出などの操作を追加する。  
クラス階層ではなく ADT と関数で実装する。

```ts
const evaluate = (expr: Expr): number => {
  switch (expr.type) {
    case "num": return expr.value;
    case "add": return evaluate(expr.left) + evaluate(expr.right);
    case "neg": return -evaluate(expr.expr);
  }
};
```
