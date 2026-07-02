---
name: visual-test
description: >-
  Autonomous visual QA with auto-repair. Launches the app in a real browser
  via the Quinn (qa-tester) subagent, finds functional and visual bugs, fixes
  them in the source, and re-tests until everything passes or the fix budget
  is spent. Use when the user asks to visually test the app, QA a flow, test
  the UI in a browser, or verify recent UI changes actually work.
argument-hint: "[url] [flow to test, e.g. 'the signup flow']"
---

# /visual-test — explore → test → fix → re-test

You are orchestrating an autonomous QA run with auto-repair. Quinn (the
`qa-tester` subagent) does the black-box testing in a real browser; you do the
diagnosis and code fixes. Quinn never reads source code; you never test
through the browser yourself — keep the roles separate.

**Defaults (adjustable by the user):** max fix rounds: **3**. Max flows per
run: **6**. If `$ARGUMENTS` contains a URL, use it; if it names a flow, test
only that flow; otherwise Quinn explores the main user journeys.

## Step 0 — Arm the finish notification

Run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh" --arm
```

This makes sure the user gets a desktop notification when the run ends, even
if the run stops unexpectedly.

## Step 1 — Get the app running

1. If a URL was given, verify it responds (e.g. `curl -sf -o /dev/null <url>`).
2. Otherwise, look for an already-running dev server on common ports
   (3000, 5173, 8080, 4200, 8000) and use the first that responds.
3. Otherwise, find the project's dev/start script (`package.json` scripts or
   equivalent), start it as a background task, and wait until the URL responds
   (poll up to ~60s).
4. If the app cannot be started or reached, stop here and tell the user what
   failed — do not send Quinn to a dead URL.

## Step 2 — Dispatch Quinn

Launch the `qa-tester` subagent with a clear brief:

- the exact URL to test,
- the specific flow(s) to test, or "explore the main user journeys" if none,
- the flow budget (default 6 flows, 30 actions per flow),
- whether destructive actions are allowed (default: **no**; only pass
  allowance the user explicitly gave),
- where to save the report: `.quinn/report-<date>-<time>.md`.

## Step 3 — Triage

Read Quinn's report from its final message.

- **Verdict PASS** → go to Step 5.
- **Verdict FAIL** → go to Step 4.
- **Setup failure** (browser missing and `browser_install` failed, URL dead
  mid-run) → fix the environment issue if you can, otherwise report and stop.

## Step 4 — Auto-repair loop (max 3 rounds)

For each round:

1. Pick the unfixed bugs, most severe first. For each, locate the root cause
   in the source (now *you* read the code — Quinn's repro steps, console
   errors, and failed requests tell you where to look).
2. Apply the **minimal** fix. Do not refactor, restyle, or "improve" anything
   the bug report doesn't require.
3. Make sure the running app picked up the change (hot reload usually
   suffices; restart the dev server if not).
4. Re-dispatch Quinn to re-test **only the flows that failed**, plus a quick
   sanity pass of one previously-passing flow to catch regressions.
5. Track a fix ledger in your head: bug → attempted fix → re-test result.

**Hard stop conditions** — stop the loop immediately and report when any of
these happens, rather than thrashing:

- All flows pass (success).
- 3 fix rounds are used up.
- The same bug survives 2 different fix attempts (mark it "needs human").
- A fix introduces a regression you can't resolve within the same round.
- The bug is not in this codebase (e.g. an external API is down).

## Step 5 — Report and notify

1. Summarize for the user: verdict, flows tested, bugs found → fixed →
   remaining, files you changed, and where the reports live (`.quinn/`).
   Suggest adding `.quinn/` to `.gitignore` if it isn't ignored.
2. Send the finish notification (this also disarms the Stop-hook fallback):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh" --done "Quinn QA: <one-line verdict, e.g. '4/4 flows passing (2 bugs fixed)'>"
```

Do **not** commit anything as part of this skill — leave the fixes in the
working tree for the user to review, and say exactly which files you touched.
