# chezmoi 移行判断: 見送り

## 結論

| 項目 | 内容 |
|---|---|
| 判断 | chezmoi への移行は行わない（見送り） |
| 判断日 | 2026-07-21 |
| 対象計画 | [chezmoi-migration-plan.md](./chezmoi-migration-plan.md) |
| 現行運用 | `link.sh` による symlink 方式を継続 |

## 理由

### 1. chezmoi の利点が現在の運用条件に当てはまらない

chezmoi が本当に効くのは次の条件だが、現状はいずれも該当しない。

| 条件 | 現状 |
|---|---|
| 複数マシンで同じ dotfiles を使い、差分を template で吸収したい | Mac 1台で完結している |
| secrets（API キー等）を 1Password / age 経由で埋め込みたい | secrets は repo 外で管理済み |
| 新マシンの bootstrap を `chezmoi init --apply` 一発にしたい | 頻度が低く `link.sh` で十分 |

### 2. symlink 方式の「即時反映」を失う

symlink 方式は実体ファイルを直接編集すると即 repo に反映される。chezmoi は「source state から home へコピー」が基本のため、`chezmoi edit` 経由か `chezmoi diff` での差分回収という運用規律が必要になる。`~/.claude/settings.json` や `nvim/` を日常的に編集する運用では摩擦が増えるだけ。

### 3. 移行計画の実質的な成果物が chezmoi を必要としない

[移行計画](./chezmoi-migration-plan.md) は Phase 2 でほぼ全て「既存 symlink を維持」しており、chezmoi が実質担うのは `~/.codex/hooks.json` の jq merge のみ。これは `link.sh`（または分離した merge script）に小さな shell script を足せば済み、そのために source state・apply 運用・trust 管理を導入するのはコストと釣り合わない。

また `skills/` の公開 repo 化（submodule 化）は chezmoi と独立に実施できるため、移行の根拠にならない。

## 再検討の条件

次のいずれかが発生したら移行を再検討する。その際は既存計画の「Codex 関連だけ段階移行」の骨格をそのまま使える。

| 条件 | 内容 |
|---|---|
| マシンの追加 | 2台目以降の Mac / Linux 環境で同じ dotfiles を使う必要が出た |
| secrets 配布 | API キー等を repo 経由で安全に配りたくなった |

## 代替アクション

| アクション | chezmoi なしでの実現方法 |
|---|---|
| `~/.codex/hooks.json` の merge | `link.sh` から呼ぶ merge script（jq）を追加する |
| `skills/` の公開 repo 化 | git submodule として独立に実施する |
