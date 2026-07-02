# Changelog

## 0.1.0 — 2026-07-02

Initial release.

- `qa-tester` subagent ("Quinn"): black-box browser testing via bundled
  Playwright MCP, structured bug reports with repro steps and severity.
- `/quinn-qa:visual-test` skill: explore → test → fix → re-test loop with
  auto-repair (max 3 fix rounds) and explicit stop conditions.
- Hooks: throttled QA nudge after UI file edits; desktop notification when a
  run finishes (with Stop-hook fallback if a run ends unexpectedly).
- Self-hosting marketplace (`.claude-plugin/marketplace.json`).
