---
name: japanese-test-conventions
description: Use when writing or editing tests. Tests should be ordered by near-normal, normal, then abnormal cases where applicable, and test names must be Japanese behavior descriptions from a reviewer/user perspective.
---

# Japanese Test Conventions

## Order

- For each function or behavior, write tests in this order where the categories exist:
  1. 準正常系
  2. 正常系
  3. 異常系
- Do not invent a category when it does not naturally exist.

## Test Names

- Write test names in Japanese.
- Prefix each test name with the category.
- Describe user-visible behavior or reviewer-understandable results.
- Avoid implementation terms, internal data flow, and helper names in test names.

```ts
it("準正常系: <条件> のとき <期待する振る舞い>", () => {});
it("正常系: <条件> のとき <期待する振る舞い>", () => {});
it("異常系: <条件> のとき <期待する振る舞い>", () => {});
```

## Examples

NG: `正常系: preset と project 候補をマージした rank source を返す`
OK: `正常系: 既存ラベルは preset と一緒に候補へ表示される`

NG: `正常系: row 群から自由入力ランク候補を軸ごとに収集できる`
OK: `正常系: 一覧で使われている自由入力ラベルを軸ごとに再利用できる`

NG: `正常系: server 候補と client 行データ候補をマージできる`
OK: `正常系: 同じ画面で追加したラベルも重複なく候補へ残る`

NG: `正常系: ランク値と null をセル値へ相互変換できる`
OK: `正常系: 入力したラベルは trim され、空入力は未設定として扱われる`
