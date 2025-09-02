#!/usr/bin/env bash
set -euo pipefail

# === options ===
# Set to a private repo URL to enable nested Git for backups/sync
# Example: export NESTED_REMOTE_URL="git@github.com:<you>/private-n8n-workflows.git"
NESTED_REMOTE_URL="${NESTED_REMOTE_URL:-}"

# === go ===
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"

mkdir -p .lab/n8n-workflows .lab/test-workflows .vscode .vscode/snippets .git/hooks scripts

# 1) Prevent accidental push (local-only ignore)
if ! grep -qxF ".lab/" .git/info/exclude 2>/dev/null; then
  printf "\n.lab/\n" >> .git/info/exclude
fi

# 2) VS Code recommended settings
cat > .vscode/settings.json <<'JSON'
{
  "files.trimTrailingWhitespace": true,
  "editor.insertSpaces": true,
  "editor.tabSize": 2,
  "[json]": { "editor.formatOnSave": true }
}
JSON

# 3) Snippets
cat > .vscode/snippets/n8n.code-snippets <<'JSON'
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
JSON

# 4) pre-push hook (abort if .lab has tracked files)
cat > .git/hooks/pre-push <<'HOOK'
#!/usr/bin/env bash
if [[ -n "$(git ls-files .lab 2>/dev/null)" ]]; then
  echo "❌ '.lab' に追跡ファイルがあります。push を中止しました。"
  exit 1
fi
HOOK
chmod +x .git/hooks/pre-push

# 5) Sample (for testing)
cat > .lab/test-workflows/sample_manual_http.json <<'JSON'
{
  "name": "sample_manual_http",
  "nodes": [
    { "parameters": {}, "id": "ManualTrigger1", "name": "Manual Trigger",
      "type": "n8n-nodes-base.manualTrigger", "typeVersion": 1, "position": [240, 300] },
    { "parameters": { "url": "https://example.com", "method": "GET" },
      "id": "HttpRequest1", "name": "HTTP Request",
      "type": "n8n-nodes-base.httpRequest", "typeVersion": 3, "position": [620, 300] }
  ],
  "connections": {
    "Manual Trigger": { "main": [[{ "node": "HTTP Request", "type": "main", "index": 0 }]] }
  }
}
JSON

# 6) Optional nested Git for backups
if [[ -n "$NESTED_REMOTE_URL" ]]; then
  (
    cd .lab/n8n-workflows
    if [[ ! -d .git ]]; then
      git init -b main
      git add .
      git commit -m "init local workflows"
      git remote add origin "$NESTED_REMOTE_URL"
      git push -u origin main || true
    fi
  )
fi

echo "✅ setup done."
echo "   - .lab/ を除外済み。確認:  git check-ignore -v .lab/"

