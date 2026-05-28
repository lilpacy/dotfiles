# gof-functional-patterns

GoF の全23デザインパターンを、関数型プログラミングの観点でシンプルに説明・設計・リファクタリングするための Claude Code Skill です。

## 構成

```text
gof-functional-patterns/
├── SKILL.md
├── README.md
├── references/
│   ├── pattern-catalog.md
│   ├── decision-guide.md
│   └── fp-recipes.md
└── examples/
    └── ecommerce-checkout.md
```

## インストール例

Personal skill として使う場合:

```bash
mkdir -p ~/.claude/skills
cp -r gof-functional-patterns ~/.claude/skills/
```

Project skill として共有する場合:

```bash
mkdir -p .claude/skills
cp -r gof-functional-patterns .claude/skills/
```

## 使い方の例

- 「Strategy パターンを関数型で実装して」
- 「GoF の全パターンを FP で整理して」
- 「このクラスベースの Factory を関数型にリファクタリングして」
- 「Observer と Mediator を FP でどう使い分ける？」
- 「EC チェックアウトに適用すべき GoF パターンを FP で提案して」
