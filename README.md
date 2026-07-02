# Quinn QA — autonomous visual testing for Claude Code

Claude launches your app in a real browser, clicks through it like a user,
spots bugs, **fixes them, and re-tests until it works**. The tester (Quinn)
and the fixer (Claude) are deliberately separate: Quinn can't read your source
code, and Claude doesn't test through the browser — so the testing stays
honest and the fixes stay verified.

## What's inside

| Component | File | What it does |
|---|---|---|
| MCP server | `.mcp.json` | Bundles Playwright MCP (`@playwright/mcp`) so Claude can drive a real browser via the accessibility tree — no vision model, deterministic. |
| Subagent | `agents/qa-tester.md` | "Quinn", a black-box QA tester. Browser tools + `Write` (reports only) by design, so it can't cheat by reading source — it tests behavior like a real user. |
| Skill | `skills/visual-test/SKILL.md` | `/quinn-qa:visual-test` — orchestrates the explore → test → fix → re-test loop with hard stop conditions. |
| Hooks | `hooks/hooks.json` | Suggests a QA pass after UI edits; desktop notification when a run finishes. |
| Scripts | `scripts/` | `notify.sh` (cross-platform alert + run marker), `suggest-qa.sh` (throttled post-edit nudge). |

## Install

From this repo's built-in marketplace:

```
/plugin marketplace add mastalier1997/quinn-qa
/plugin install quinn-qa@quinn-qa
```

Or for local development, clone and load it as a skills-directory plugin:

```bash
git clone https://github.com/mastalier1997/quinn-qa ~/.claude/skills/quinn-qa
# restart Claude Code, or run /reload-plugins in an existing session
```

The Playwright browser installs on first use (Quinn calls `browser_install`
if it's missing). To pre-install manually:

```bash
npx playwright install chromium
```

## Usage

```
/quinn-qa:visual-test
/quinn-qa:visual-test http://localhost:5173 the signup flow
```

Or just ask: *"test the checkout flow"* — Claude routes to the `qa-tester`
subagent on its own.

What a run looks like:

1. Claude finds (or starts) your dev server.
2. Quinn explores the app in a headless browser and tests the main user
   journeys — happy paths and realistic mistakes — reading the accessibility
   tree, console, and network log.
3. Bugs come back as a structured report (`.quinn/report-*.md`) with repro
   steps, severity, and evidence.
4. **Auto-repair:** Claude locates the root cause in your source, applies a
   minimal fix, and sends Quinn back to re-test the failed flows (plus a
   regression check) — up to 3 fix rounds.
5. You get a summary, the changed files left uncommitted for review, and a
   desktop notification.

## Design choices worth knowing

- **DOM, not pixels.** Playwright MCP reads the accessibility tree, which is
  faster and far less hallucination-prone than screenshot-based clicking.
- **Black-box by tool restriction.** Quinn's `tools:` list grants only the
  bundled browser server and `Write` (for reports). No code reading. This
  forces honest testing.
- **Screenshots are rationed.** Snapshots are the default; screenshots only
  when a visual defect is plausible (max 4 per run), because image tokens are
  expensive.
- **Explicit stop conditions.** Hard budgets everywhere: flows per run,
  actions per flow, fix rounds, and a "same bug survived 2 different fixes →
  needs a human" rule so Claude never thrashes.
- **No surprise commits.** Fixes land in your working tree only; you review
  and commit.

## Security note

Plugin hooks run shell scripts with your credentials. Review `scripts/`
before installing. The scripts here only send desktop notifications and print
a throttled reminder; they don't touch your code or the network. Quinn is
instructed never to perform destructive-looking actions (payments, deletions,
emails) unless you explicitly allow them for a safe test environment.

## Tune it

- **Default budgets** (fix rounds, flows, actions): edit
  `skills/visual-test/SKILL.md`.
- **Browser tools**: Quinn's grant is the server-level pattern
  `mcp__plugin_quinn-qa_playwright` in `agents/qa-tester.md`. To restrict
  further, replace it with explicit tool names, e.g.
  `mcp__plugin_quinn-qa_playwright__browser_navigate`. (Plugin MCP tools are
  namespaced `mcp__plugin_<plugin>_<server>__<tool>` — plain
  `mcp__playwright__*` will not match.)
- **Headed browser**: remove `--headless` from `.mcp.json` to watch Quinn
  click through your app.
- **Nudge triggers**: adjust the file-extension list and the 30-minute
  throttle in `scripts/suggest-qa.sh`.
- Add `.quinn/` to your project's `.gitignore` to keep reports out of git.

## License

MIT — see [LICENSE](LICENSE).
