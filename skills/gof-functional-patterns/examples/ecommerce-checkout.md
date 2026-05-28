# 具体例: EC チェックアウトを FP + GoF で設計する

EC チェックアウトは、GoF パターンを FP で簡略化する例として分かりやすい題材です。

## 要件

- カートから注文を作る。
- 会員ランクやクーポンで割引計算を変える。
- 決済プロバイダを Stripe / PayPal で切り替える。
- 注文状態を `draft` → `paid` → `shipped` → `completed` に遷移させる。
- 注文完了後にメール、分析、CRM 連携を行う。
- 失敗した決済や返金はリトライ可能な command として扱う。

---

## Strategy: 割引計算を関数として渡す

```ts
type DiscountStrategy = (cart: Cart) => Money;

const couponDiscount = (coupon: Coupon): DiscountStrategy => cart =>
  coupon.valid ? money(coupon.amount) : money(0);

const rankDiscount: DiscountStrategy = cart =>
  cart.customer.rank === "gold" ? money(1000) : money(0);

const calculateTotal = (discount: DiscountStrategy) => (cart: Cart) =>
  cart.itemsTotal.minus(discount(cart));
```

### 適用すべきユースケース
割引アルゴリズムがキャンペーン、会員ランク、クーポン、地域などで変わる場合。

---

## Abstract Factory: 決済プロバイダ一式を切り替える

```ts
type PaymentModule = {
  charge: (input: ChargeInput) => Promise<ChargeResult>;
  refund: (paymentId: PaymentId) => Promise<RefundResult>;
  parseWebhook: (raw: unknown) => PaymentEvent;
};

const checkout = (payment: PaymentModule) => async (order: Order) => {
  const result = await payment.charge(toChargeInput(order));
  return markPaid(order, result.paymentId);
};
```

### 適用すべきユースケース
決済ごとに charge / refund / webhook / signature verification など関連機能がまとまって変わる場合。

---

## State: 注文ライフサイクルを transition 関数で表す

```ts
type OrderState =
  | { type: "draft" }
  | { type: "paid"; paymentId: PaymentId }
  | { type: "shipped"; trackingNo: string }
  | { type: "completed" }
  | { type: "cancelled"; reason: string };

type OrderEvent =
  | { type: "PaymentSucceeded"; paymentId: PaymentId }
  | { type: "Shipped"; trackingNo: string }
  | { type: "Delivered" }
  | { type: "Cancelled"; reason: string };

const transition = (state: OrderState, event: OrderEvent): OrderState => {
  if (state.type === "draft" && event.type === "PaymentSucceeded") {
    return { type: "paid", paymentId: event.paymentId };
  }
  if (state.type === "paid" && event.type === "Shipped") {
    return { type: "shipped", trackingNo: event.trackingNo };
  }
  if (state.type === "shipped" && event.type === "Delivered") {
    return { type: "completed" };
  }
  if (event.type === "Cancelled") {
    return { type: "cancelled", reason: event.reason };
  }
  return state;
};
```

### 適用すべきユースケース
注文、決済、配送、返品など、不正遷移を防ぎたいライフサイクルがある場合。

---

## Observer: 注文完了イベントを複数 handler に流す

```ts
type DomainEvent =
  | { type: "OrderPlaced"; orderId: OrderId; email: string };

type Handler = (event: DomainEvent) => Promise<void>;

const orderPlacedHandlers: Handler[] = [
  sendOrderMail,
  trackAnalytics,
  syncCrm,
];

const publish = async (event: DomainEvent) => {
  for (const handler of orderPlacedHandlers) {
    await handler(event);
  }
};
```

### 適用すべきユースケース
1つのドメインイベントに対して、メール、分析、外部連携など複数の独立した反応が必要な場合。

---

## Command: 返金や再試行を command として保存する

```ts
type PaymentCommand =
  | { type: "Charge"; orderId: OrderId; amount: Money }
  | { type: "Refund"; paymentId: PaymentId; reason: string };

const runPaymentCommand = (payment: PaymentModule) => async (cmd: PaymentCommand) => {
  switch (cmd.type) {
    case "Charge":
      return payment.charge({ orderId: cmd.orderId, amount: cmd.amount });
    case "Refund":
      return payment.refund(cmd.paymentId);
  }
};
```

### 適用すべきユースケース
失敗時にリトライしたい、監査ログに残したい、非同期ワーカーで実行したい操作がある場合。

---

## Facade: チェックアウト全体を1つの use-case 関数にする

```ts
type CheckoutEnv = {
  payment: PaymentModule;
  orderRepo: OrderRepo;
  publish: (event: DomainEvent) => Promise<void>;
};

const placeOrder = (env: CheckoutEnv, discount: DiscountStrategy) => async (cart: Cart) => {
  const total = calculateTotal(discount)(cart);
  const draft = createDraftOrder(cart, total);
  const paid = await checkout(env.payment)(draft);
  await env.orderRepo.save(paid);
  await env.publish({ type: "OrderPlaced", orderId: paid.id, email: cart.customer.email });
  return paid;
};
```

### 適用すべきユースケース
画面や API handler からは `placeOrder` だけを呼び、内部の在庫、決済、保存、通知の詳細を隠したい場合。

---

## この例で使わなかったパターン

- Builder: 検索クエリや注文作成入力が複雑になったら使う。
- Adapter: 決済 webhook payload を内部 event に変換するときに使う。
- Proxy / Decorator: 決済呼び出しに retry / cache / logging / auth を重ねるときに使う。
- Memento: カート編集の undo/redo が必要なときに使う。
- Interpreter / Visitor: クーポン条件を DSL 化するなら使う。
