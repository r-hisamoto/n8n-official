# AGENTS.md — AIエージェント運用指針（n8n-official）

## 目的
AI エージェント（例: Codex / ローカルCLI）が **最小差分・安全** にリポを整備するための「境界・権限・手順」を明文化する。

## 対象範囲（Scope）
- **対象**: ドキュメント（`docs/`）、CIワークフロー（`.github/workflows/`）、補助スクリプト（`scripts/`）
- **非対象**: `.lab/`（ローカル専用・公開禁止）、機微ワークフローJSONの公開コミット、シークレットの直接投入

## データ境界（Boundary）
- `.lab/**` は **公開不可・未追跡** を厳守（`pre-push` で検知、CI `guard-lab.yml` でブロック）
- シークレットは **GitHub Secrets / ENV** のみ使用（平文コミット禁止、ダミー値で例示）
- プライベートなバックアップは **ネストGit（`.lab/n8n-workflows`）** を任意で利用

## 変更権限と承認マトリクス
| 変更種別 | 例 | 承認 |
|---|---|---|
| docs軽微 | `docs/*.md` の追記・誤字修正 | **自己承認可**（直接main可） |
| CIの非破壊整備 | `paths-ignore` 追加、guardの強化 | **PR必須**（レビュー1名） |
| CIの挙動変更 | トリガー/権限変更、ジョブ削除 | **PR必須**（レビュー2名/オーナー承認） |
| スクリプト更新 | `scripts/*.sh` の追加/修正 | **PR推奨**（軽微は自己承認可） |

> オーナー/レビュアは CODEOWNERS で定義。

## コミット規約
- **Conventional Commits** 推奨（例: `docs:`, `ci:`, `chore:`）
- エージェント実行時は `Co-authored-by: <Agent Name> <agent@example>` を付与可
- 重要変更は **PR** と **説明（意図/影響/ロールバック）** を必ず記載

## セーフティ & ロールバック
- 事前: **ドライラン**／`git status`／差分の可視化 → **最小差分**で実施
- 失敗時:  
  1) `git revert <SHA>` で即時巻き戻し  
  2) ワークフロー誤作動は GitHub UI から **一時無効化**  
  3) `.lab/` 流出時は `git filter-repo` 等で **履歴から抹消** → Token/Secret **即時ローテーション**
- 監視: `guard-lab.yml` が `.lab` 追跡を検出したら **fail**、`OPS_LOG.md` に事後記録

## 運用ログ（OPS_LOG.md）
- **対象**: 運用系の判断・防御策導入・CI変更など（機能リリースはCHANGELOGへ）
- **記法**: 日付 / 要約 / SHA / リンク / 影響範囲 / ロールバック方法

## CI ポリシー
- すべての `on: push:` に `paths-ignore: ['.lab/**']` を付与（`scripts/apply_minimal_patches.sh` で冪等適用）
- `.github/workflows/guard-lab.yml` で `.lab` の追跡を **CIブロック**
- CodeQL/Dependabot等の**セキュリティスキャン**は破壊的でない限り歓迎

## ワークスペース/ツール
- **マルチルート** `.code-workspace` を固定運用（拡張のローカル履歴が安定）
- ローカル実行の原則: **計画（Plan）→実行（Apply）→検証（Verify）→記録（Log）**
- 外部通信は必要最小限。大規模操作は **明示の合意** が取れたときのみ

## 標準プロンプト（テンプレ）
> **役割**: n8n-official のドキュメント/CI/スクリプトを最小差分で整備するエージェント。  
> **必須**: 1) 実行前に計画を要約、2) `.lab/` は触らない、3) 影響/ロールバックを明記、4) 変更後に `OPS_LOG.md` へ記録。

## インシデント対応プレイブック（例）
- **.labが誤って追跡**:  
  `git rm -r --cached .lab && printf '\n.lab/\n' >> .git/info/exclude && git commit -m "chore: untrack .lab"`  
  → 影響確認 → `OPS_LOG.md` に記録
- **Secret露出**:  
  露出箇所を削除/改名 → 直後に **鍵ローテーション** → 影響範囲共有＆ログ化

## ロール & 連絡
- **Owner**: `<maintainer/team>`（連絡先: `<Slack/Email>`）  
- **Reviewers**: CI/セキュリティ `<reviewers>`、ドキュメント `<docs-owners>`  
- 相談ルール: 境界/権限に迷いがあれば **Ownerへ事前確認**

