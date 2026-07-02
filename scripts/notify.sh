#!/usr/bin/env bash
# notify.sh — cross-platform desktop notification + QA-run marker.
#
# Usage:
#   notify.sh "message"              send a notification now
#   notify.sh --arm                  mark a QA run as in progress (cwd-scoped)
#   notify.sh --done "message"       notify now and disarm the marker
#   notify.sh --fire-if-armed [msg]  notify only if armed, then disarm
#                                    (used by the Stop hook as a fallback)
#
# This script only sends notifications. It never touches your code or the
# network.
set -u

TITLE="Quinn QA"
MARKER="${TMPDIR:-/tmp}/quinn-qa-armed-$(pwd | cksum | cut -d' ' -f1)"

send() {
  msg="$1"
  if command -v osascript >/dev/null 2>&1; then
    # macOS
    osascript -e "display notification \"${msg//\"/\\\"}\" with title \"$TITLE\"" >/dev/null 2>&1
  elif command -v notify-send >/dev/null 2>&1; then
    # Linux desktop
    notify-send "$TITLE" "$msg" >/dev/null 2>&1
  elif command -v powershell.exe >/dev/null 2>&1; then
    # Windows (WSL / Git Bash): toast is noisy to script, use a message box-free fallback
    powershell.exe -NoProfile -Command "[console]::beep(880,200)" >/dev/null 2>&1
    printf '%s: %s\n' "$TITLE" "$msg"
  else
    # Headless fallback: terminal bell + text
    printf '\a%s: %s\n' "$TITLE" "$msg"
  fi
}

case "${1:-}" in
  --arm)
    touch "$MARKER"
    ;;
  --done)
    rm -f "$MARKER"
    send "${2:-Visual QA run finished.}"
    ;;
  --fire-if-armed)
    if [ -e "$MARKER" ]; then
      rm -f "$MARKER"
      send "${2:-Visual QA run finished.}"
    fi
    ;;
  "")
    send "Visual QA run finished."
    ;;
  *)
    send "$1"
    ;;
esac

exit 0
