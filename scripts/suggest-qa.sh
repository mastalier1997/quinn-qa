#!/usr/bin/env bash
# suggest-qa.sh — PostToolUse hook. After a UI file is edited, remind Claude
# (via additionalContext) that a visual QA pass is available. Throttled to at
# most one nudge per session per 30 minutes so it never becomes spam.
#
# This script only reads the hook event from stdin and prints a JSON hint.
# It never touches your code or the network.
set -u

INPUT="$(cat)"

# Extract file_path and session_id; prefer jq, fall back to sed.
if command -v jq >/dev/null 2>&1; then
  FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
  SESSION="$(printf '%s' "$INPUT" | jq -r '.session_id // "default"' 2>/dev/null)"
else
  FILE="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  SESSION="$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
fi
[ -n "${FILE:-}" ] || exit 0

# Never nudge for Quinn's own report files.
case "$FILE" in
  *.quinn/*) exit 0 ;;
esac

# Only nudge for files that plausibly affect the UI.
# Adjust this list to taste.
case "$FILE" in
  *.tsx|*.jsx|*.vue|*.svelte|*.astro|*.html|*.css|*.scss|*.less) ;;
  *) exit 0 ;;
esac

# Throttle: one nudge per session per 30 minutes.
FLAG="${TMPDIR:-/tmp}/quinn-qa-nudge-${SESSION:-default}"
if [ -e "$FLAG" ] && [ -n "$(find "$FLAG" -mmin -30 2>/dev/null)" ]; then
  exit 0
fi
touch "$FLAG"

cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"A UI file was just edited. If this change affects visible behavior and the work is wrapping up, offer the user a visual QA pass (the /quinn-qa:visual-test skill runs Quinn, the browser-based QA tester). Suggest it once — do not launch it unprompted."}}
EOF
exit 0
