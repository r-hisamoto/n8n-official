# GitHub 操作ログ（Ops Log）

この文書は、GitHub 上での主要な手動オペレーションや、それに紐づくコミットを簡潔に記録するためのものです。CHANGELOG（機能変更の履歴）ではなく、運用上の判断・導入・保護措置などを追えるようにします。

— 記法 —
- 日時（ローカルタイム）: 要約 — コミット: `<short-sha>`（リンク）

— ログ —
- 2025-09-02 20:32 JST: 最小パッチ適用スクリプトの使い方を docs に追記 — コミット: a37bc556b
  https://github.com/r-hisamoto/n8n-official/commit/a37bc556b
- 2025-09-02 20:24 JST: CI の push に .lab/** を無視し、.editorconfig の最小ルールを補強 — コミット: cb1741ce1
  https://github.com/r-hisamoto/n8n-official/commit/cb1741ce1
- 2025-09-02 20:05 JST: .lab ガード用ワークフロー追加 と .gitattributes の LF 正規化 — コミット: 7dcd12530
  https://github.com/r-hisamoto/n8n-official/commit/7dcd12530
- 2025-09-02 19:08 JST: bootstrap スクリプトを実行可能（100755）へ修正 — コミット: 7d1cb3573
  https://github.com/r-hisamoto/n8n-official/commit/7d1cb3573
- 2025-09-02 19:07 JST: LOCAL_WORKFLOWS ガイドと bootstrap の追加 — コミット: 03825d013
  https://github.com/r-hisamoto/n8n-official/commit/03825d013

— 更新のヒント —
- 運用上の判断や保護措置（フック/CI/ルールの追加など）を行ったら、1 行で要約し、コミットリンクを添えます。
- リリースノート用途ではないため、機能改修やドキュメントの細かな修正は CHANGELOG 側に任せ、Ops Log は“運用まわりの決定と履歴”に絞ります。

