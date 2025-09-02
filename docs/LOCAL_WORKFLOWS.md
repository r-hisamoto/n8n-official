# ローカル専用 n8n ワークフロー管理ガイド

このリポジトリでは、n8n のワークフロー JSON は公開リポジトリに含めず、各開発者のローカル環境にのみ保持します。これにより、機微な処理内容や周辺情報を公開せずに VS Code 等で快適に編集できます。

---

## 目的と方針

- 公開リポジトリ（例: `r-hisamoto/n8n-official`）とは分離し、ワークフロー JSON は「ローカル専用フォルダ」で管理する。
- 誤 push を防ぐため、Git の追跡対象から確実に外す（`.git/info/exclude` を使用）。
- 必要に応じて、ローカル専用フォルダ配下を「個人のプライベートリポ」で別途バックアップ（任意）。
- 将来的にチーム/CI で必要になれば、サブモジュール or CI 追加チェックアウト方式へ段階移行できるようにする。

---

## ディレクトリ構成

- 正本（canonical）: `.lab/n8n-workflows/`
  - n8n 側との入出力は本フォルダ配下を正とします。
  - 公開リポには含めません（追跡外）。
- 検証用・一時作業: `.lab/test-workflows/`
  - 検証中の草案や作業中データはこちらに配置します。
  - 正式化が決まったら `.lab/n8n-workflows/` へ昇格移動します。

---

## 初期セットアップ（各開発者のローカル）

1) 作業フォルダの作成

```bash
mkdir -p .lab/n8n-workflows .lab/test-workflows
```

2) 誤 push 防止（Git 追跡から外す）

- `.git/info/exclude` は「このローカルだけで有効な .gitignore 相当」です。リポジトリには含まれません。

```bash
printf '\n.lab/\n' >> .git/info/exclude
```

設定検証（任意）: `git check-ignore -v .lab/` を実行し、除外が有効か・どの設定由来かを確認できます。

メモ: `.gitignore` に `.lab/` を書くと、設定自体が公開されます。それで問題なければ `.gitignore` でも構いませんが、本方針では「ローカル専用」を徹底するため `.git/info/exclude` を推奨します。

3) VS Code 推奨設定（任意）

```jsonc
// .vscode/settings.json （コミットしたくない場合は除外してください）
{
  "files.trimTrailingWhitespace": true,
  "editor.insertSpaces": true,
  "editor.tabSize": 2,
  "[json]": { "editor.formatOnSave": true }
}
```

補足: `.vscode/` を公開したくない場合は `.git/info/exclude` に `.vscode/` を追加するか、VS Code のユーザー設定（グローバル設定）に入れてください。

4) スニペット（任意）

```json
// .vscode/snippets/n8n.code-snippets
{
  "n8n workflow (Manual -> HTTP)": {
    "prefix": "n8nwf",
    "body": [
      "{",
      "  \"name\": \"$1\",",
      "  \"nodes\": [",
      "    {",
      "      \"parameters\": {},",
      "      \"id\": \"ManualTrigger1\",",
      "      \"name\": \"Manual Trigger\",",
      "      \"type\": \"n8n-nodes-base.manualTrigger\",",
      "      \"typeVersion\": 1,",
      "      \"position\": [240, 300]",
      "    },",
      "    {",
      "      \"parameters\": { \"url\": \"${2:https://example.com}\", \"method\": \"GET\" },",
      "      \"id\": \"HttpRequest1\",",
      "      \"name\": \"HTTP Request\",",
      "      \"type\": \"n8n-nodes-base.httpRequest\",",
      "      \"typeVersion\": 3,",
      "      \"position\": [620, 300]",
      "    }",
      "  ],",
      "  \"connections\": {",
      "    \"Manual Trigger\": {",
      "      \"main\": [[{ \"node\": \"HTTP Request\", \"type\": \"main\", \"index\": 0 }]]",
      "    }",
      "  }",
      "}"
    ],
    "description": "Quick n8n workflow JSON skeleton"
  }
}
```

---

## 使い方

- 編集: 正式運用するものは `.lab/n8n-workflows/*.json` を編集します。
- 検証中は `.lab/test-workflows/*.json` を利用し、確定後に `n8n-workflows` へ移動します。
- n8n への取り込み: n8n UI で「Import from File / Clipboard」を使って JSON を取り込みます。
- n8n からのエクスポート: n8n UI から JSON をエクスポートし、`.lab/n8n-workflows/` に保存します。
- 命名規則（推奨）: `n8n_workflows_<用途や特徴>.json` のように検索しやすい名前を付与します。

---

## 誤 push 防止と注意点

- `.lab/` は `.git/info/exclude` により追跡対象外です。誤って `git add` しても追加されません。
- フォルダ名を変更したり、`.lab/` の外へファイルを移動すると保護の対象外になります。
- 公開リポの GitHub Actions ログ等に内容が出ないよう、CI で `.lab/` を参照しない構成を維持します。

pre-push フック（任意・最終防波堤）:

```bash
# .git/hooks/pre-push
#!/usr/bin/env bash
if [[ -n "$(git ls-files .lab 2>/dev/null)" ]]; then
  echo "❌ '.lab' に追跡済みファイルがあります。push を中止しました。"
  exit 1
fi
# 有効化
chmod +x .git/hooks/pre-push
```

CI 参照禁止の明確化（例）:

```yaml
on:
  push:
    paths-ignore:
      - '.lab/**'
```

---

## バックアップと複数端末（任意: ネスト Git）

ローカル専用を保ちつつ履歴やバックアップを確保したい場合、`.lab/n8n-workflows`（必要なら `.lab/test-workflows` も）を独立 Git リポにできます。

```bash
cd .lab/n8n-workflows
git init
git remote add origin git@github.com:<your-account>/<private-repo>.git  # プライベートで作成
git add .
git commit -m "init local workflows"
git branch -M main
git push -u origin main
```

- 上位（公開）リポからは `.lab/` が無視されるため、露出はありません。
- 他端末でも同様に `.git/info/exclude` を設定後、このプライベートリポを clone/pull すれば同期できます。

---

## 将来の拡張（チーム/CIで利用する場合）

1) サブモジュール方式（王道・再現性重視）

```bash
git submodule add -b main git@github.com:<org>/<private-repo>.git private-workflows
git commit -m "Add private workflows submodule"
```

```yaml
# .github/workflows/build.yml（例）
name: Build
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
          token: ${{ secrets.PAT_WITH_REPO_SCOPE }}
      - run: ls -la private-workflows && echo "…ここでビルド…"
```

2) CI 時だけ追加チェックアウト（露出最小化）

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: actions/checkout@v4
    with:
      repository: <org>/<private-repo>
      token: ${{ secrets.PAT_WITH_REPO_SCOPE }}
      path: private-workflows
```

いずれも PAT（最小権限）または Deploy Key の用意が必要です。

---

## よくある質問 / トラブルシュート

- 誤って `.lab/` をコミットしそうになった
  - 対応: `git rm -r --cached .lab` を実行し、`.git/info/exclude` へ `.lab/` を追加してください。

- 新しい端末で環境を再現したい
  - 手順: リポ clone → `.lab/workflows` を作成 → `.git/info/exclude` に `.lab/` を追加 → 必要ならネスト Git を pull。

- 機微なシークレットの扱いは？
  - n8n の認証情報は n8n のクレデンシャルストアで管理し、JSON には直接含めないのが原則です。必要に応じてダミー値を使います。

---

## このドキュメントの意図

本方針は「いまはローカルで気軽に編集したい」を最優先しつつ、将来のチーム/CI 利用へも自然に移行できるように設計しています。迷ったら `.lab/workflows` に置く、公開に出したくなったらサブモジュール等へ昇格、という二段構えで運用してください。

---

## セットアップ自動化（付録）

初期セットアップをまとめて行うスクリプトを用意しています（不要な処理は編集してから実行）。

```bash
# リポジトリのルートで実行
bash scripts/bootstrap_local_workflows.sh

# ネスト Git のリモートも同時指定する場合
NESTED_REMOTE_URL="git@github.com:<you>/private-n8n-workflows.git" \
  bash scripts/bootstrap_local_workflows.sh
```

---

## 運用メンテ（最小パッチ適用）

公開リポ側の CI やエディタ差分を安定させるための“最小差分パッチ”適用用スクリプトがあります。

```bash
# 既存のワークフローに paths-ignore を追加（on: push かつ未設定のみ）
# 既存の .editorconfig に最小ルールを不足分だけ追記
# ※ 本スクリプトは変更を行いますが、コミットは自動では行いません
bash scripts/apply_minimal_patches.sh

# 変更を確認してからコミット（必要に応じて）
git add .github/workflows/*.y*ml .editorconfig 2>/dev/null || true
git commit -m "ci: ignore .lab/** on push; append minimal .editorconfig defaults"
git push

# （任意）マルチルート .code-workspace の作成
CREATE_WORKSPACE=1 WORKSPACE_PATH="../n8n-multi-root.code-workspace" \
  bash scripts/apply_minimal_patches.sh
```

スクリプトの役割:

- ワークフローの `on: push:` に `paths-ignore: ['.lab/**']` を未設定ファイルにのみ追記
- `.editorconfig` に不足している最小ルール（改行/末尾改行/トリム、JSON の 2 スペース）を重複なしで追記
- （任意）マルチルート用 `.code-workspace` を生成

いずれも既存設定を尊重し、上書きや大きな変更は行いません。
