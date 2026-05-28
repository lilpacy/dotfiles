# GoF を FP で簡略化する実装レシピ

## 1. Strategy は「関数を渡す」

```ts
type Strategy<A, B> = (a: A) => B;
const useStrategy = <A, B>(strategy: Strategy<A, B>, input: A): B => strategy(input);
```

使う場面: アルゴリズム、計算、検証、ソート、変換を差し替える。

## 2. Factory は「関数を返す / registry から引く」

```ts
type Maker<A> = () => A;
const registry: Record<string, Maker<Service>> = {
  local: makeLocalService,
  remote: makeRemoteService,
};
```

使う場面: 種類や設定に応じて生成処理を選ぶ。

## 3. Abstract Factory / Bridge は「関数レコード」

```ts
type Algebra<F> = {
  op1: (x: string) => F;
  op2: (a: F, b: F) => F;
};
```

使う場面: 複数操作をセットで切り替える、抽象ロジックと実装を分離する。

## 4. Adapter は「境界の変換関数」

```ts
const toDomain = (external: ExternalUser): User => ({
  id: external.user_id,
  name: external.display_name,
});
```

使う場面: 外部 API、DB row、legacy payload、UI input を domain 型に変換する。

## 5. Decorator / Proxy は「同じ型の関数を返す wrapper」

```ts
const withRetry = <A, B>(f: (a: A) => Promise<B>) => async (a: A): Promise<B> => {
  try {
    return await f(a);
  } catch (_) {
    return await f(a);
  }
};
```

使う場面: ログ、認証、キャッシュ、リトライ、遅延、計測。

## 6. Composite / Interpreter / Visitor は「ADT + fold」

```ts
type Tree<A> =
  | { type: "leaf"; value: A }
  | { type: "node"; children: Tree<A>[] };

const foldTree = <A, B>(
  onLeaf: (a: A) => B,
  onNode: (children: B[]) => B,
  tree: Tree<A>
): B =>
  tree.type === "leaf"
    ? onLeaf(tree.value)
    : onNode(tree.children.map(child => foldTree(onLeaf, onNode, child)));
```

使う場面: 木構造、AST、式、メニュー、カテゴリ、UIツリー。

## 7. State / Mediator は「Reducer」

```ts
type Reducer<S, E> = (state: S, event: E) => S;
```

副作用が必要なら、次状態と effect command を一緒に返す。

```ts
type Step<S, E, C> = (state: S, event: E) => { state: S; commands: C[] };
```

使う場面: ワークフロー、画面状態、注文状態、申請状態、チャット状態。

## 8. Command は「データ + interpreter」

```ts
type Command =
  | { type: "SendEmail"; to: string; body: string }
  | { type: "Charge"; amount: number };

const runCommand = (env: Env) => async (cmd: Command) => {
  switch (cmd.type) {
    case "SendEmail": return env.mail.send(cmd.to, cmd.body);
    case "Charge": return env.payment.charge(cmd.amount);
  }
};
```

使う場面: キュー、監査ログ、リトライ、undo/redo、event sourcing。

## 9. Observer は「イベントを流す」

```ts
type Handler<E> = (event: E) => Promise<void>;
const publish = <E>(handlers: Handler<E>[]) => (event: E) =>
  Promise.all(handlers.map(h => h(event)));
```

使う場面: ドメインイベント、UIイベント、通知、ログ、分析。

## 10. Memento は「状態履歴を値として持つ」

```ts
type History<S> = { past: S[]; present: S; future: S[] };
```

使う場面: undo/redo、time travel、監査、差分比較。

## 11. Facade は「use-case 関数」

```ts
const registerUser = (env: Env) => async (input: RegisterUserInput) => {
  const user = createUser(input);
  await env.userRepo.save(user);
  await env.mail.sendWelcome(user.email);
  return user;
};
```

使う場面: 複数サブシステムを業務上の1操作としてまとめる。

## 12. Singleton は「グローバルではなく Env」

```ts
type Env = { logger: Logger; db: Db; config: Config };
const main = async () => {
  const env = await makeEnv();
  await runApp(env);
};
```

使う場面: config、logger、DB pool などを共有しつつ、テストでは差し替える。
