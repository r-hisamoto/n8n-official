#!/usr/bin/env bash
set -euo pipefail

# Move to repo root (works from any subdir)
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# ========= 1) Add paths-ignore to workflows =========
shopt -s nullglob
WF_FILES=(.github/workflows/*.yml .github/workflows/*.yaml)
PATCHED=()

for f in "${WF_FILES[@]}"; do
  # Only if it has top-level on: and push:, and no paths-ignore yet
  if grep -qE '^[[:space:]]*on:[[:space:]]*$' "$f" \
     && grep -qE '^[[:space:]]*push:[[:space:]]*$' "$f" \
     && ! grep -qE '^[[:space:]]*paths-ignore:' "$f"; then

    # Insert right after a line that is exactly "push:" (2-space indent assumed)
    awk '
      BEGIN{added=0}
      { print }
      /^[[:space:]]*push:[[:space:]]*$/ && !added {
        print "    paths-ignore:"
        print "      - '\''.lab/**'\''"
        added=1
      }
    ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"

    PATCHED+=("$f")
  fi
done

# ========= 2) Append minimal .editorconfig rules (dedup-safe) =========
if [ -f .editorconfig ]; then
  NEED_APPEND=0
  grep -q 'end_of_line' .editorconfig || NEED_APPEND=1
  grep -q 'insert_final_newline' .editorconfig || NEED_APPEND=1
  grep -q 'trim_trailing_whitespace' .editorconfig || NEED_APPEND=1
  grep -q 'indent_style' .editorconfig || NEED_APPEND=1
  grep -q 'indent_size' .editorconfig || NEED_APPEND=1

  if [ "$NEED_APPEND" -eq 1 ]; then
    cat >> .editorconfig <<'EOC'
# --- minimal defaults (appended) ---
[*]
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.json]
indent_style = space
indent_size = 2
EOC
  fi
fi

# ========= 3) Optional: create multi-root .code-workspace =========
# CREATE_WORKSPACE=1 to enable; WORKSPACE_PATH overrides save path
if [ "${CREATE_WORKSPACE:-0}" = "1" ]; then
  TARGET="${WORKSPACE_PATH:-../n8n-multi-root.code-workspace}"
  cat > "$TARGET" <<'JSON'
{
  "folders": [
    { "path": "n8n-official" },
    { "path": "workflows - n8n" }
  ],
  "settings": {}
}
JSON
  echo "[created] $TARGET"
fi

# ========= 4) Show status summary =========
echo "---- git status (preview) ----"
git status --porcelain
echo "---- patched workflows ----"
printf '%s\n' "${PATCHED[@]:-}"

echo "Done (no commit performed)."

