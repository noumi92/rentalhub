# .ai/development — Agent briefs for Rentalhub

Agent briefs adapted for this repo from
[msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents)
(upstream commit `8ae6164602c95ca78828b148b9052460ee426885`, MIT licence).
Adapted 2026-11-14. Only the briefs that fit this project were taken; the
rest of that repo (paid media, sales, marketing, game dev, healthcare, GIS…)
is irrelevant to Rentalhub and was left out.

## What these are

Each file is a **brief for a subagent** — an identity, a mission, critical
rules, a workflow, and a deliverable template — rewritten for Rentalhub.
They are prompts, not code: nothing here runs on its own. Use a brief as
the assignment when spawning a subagent for that kind of work, or paste the
relevant section into the subagent's task.

They are NOT installed into any tool (Claude Code / Cursor / Codex). Muse
does not load `.claude/agents/` files; these live here so any agent working
on this repo can pick them up.

## The briefs

| File | Adapted from | Use for |
| --- | --- | --- |
| `accessibility-auditor.md` | testing / Accessibility Auditor | UI/UX audits: labels, contrast, overflow, tap targets, semantics, 360px + large text scale |
| `test-automation-engineer.md` | testing / Test Automation Engineer | Writing and stabilising `flutter test` suites; killing flakes and hangs |
| `test-results-analyzer.md` | testing / Test Results Analyzer | Reading a test/CI run and giving a verified go/no-go; never bucket a failure as "known" without checking its error |
| `appsec-engineer.md` | security / Application Security Engineer | Security audits: Firestore rules, admin permission enforcement, secrets, auth flows |
| `ui-designer.md` | design / UI Designer | Design-system work and visual fixes under the rulebook (§4.5 tokens, themes, Urdu RTL) |
| `ui-finish-gate-reviewer.md` | design / UI Finish-Gate Reviewer | Pre-ship PASS/HOLD gate per screen, with a written design contract and forbidden-defaults list |
| `persona-walkthrough.md` | design / Persona Walkthrough Specialist | Walk a flow as a customer / owner / admin persona; five-second test, trust and anxiety tracking |

## Rules that are baked into every brief

These are Rentalhub facts the upstream files do not know. Every brief in
this folder already contains them; a new brief added here must too.

- Repo: `noumi92/rentalhub`, branch `master`. Flutter 3.44.2 / Dart 3.12.2.
  Android app (`pk.rentalhub.rentalhub`) + Flutter web admin panel.
  Firebase (Auth, Firestore, Functions TypeScript v2, FCM) + cPanel PHP
  storage + WhatsApp Business Cloud API via Functions.
- The rulebook (`.ai/doc12_comprehensive_rulebook.md`) is binding.
  Views ≤ 250 lines. NEVER run `dart format`. No hardcoded Urdu anywhere,
  including comments — all user strings through AppLocalizations with EN+UR
  `.arb` parity. Every `IconButton` needs a `tooltip:`.
- Design: Inter + Noto Nastaliq Urdu, rulebook §4.5 6-step type scale,
  Light theme default, login only keeps the curved hero, other screens use a
  minimal ~56dp app bar, tab bar flush at minimum height, no floating pill.
  Cards have no dark border — different backgrounds with shadow + elevation.
  Two forced-light keeps: QR pass + signature pad. Labels use short smart
  wording, never overflow at 360px, never bold per §4.5, and must stay
  readable in light AND dark themes.
- Clean Architecture (feature-driven), Cubit / get_it / go_router,
  offline-first with Firestore persistence + sync queue; server timestamps
  win for status. Real Firestore data, never mocks in the app. Never claim
  NADRA verification — only a blacklist check in Rentalhub's own database.
  Maps are key-free (flutter_map + OpenStreetMap); never invent a key or
  shop coordinates.
- Testing lessons (see `~/AGENTS.md`): full suite with
  `flutter test --concurrency 1`; `/tmp` is a 512 MB tmpfs — clean
  `/tmp/flutter_tools.*` after a killed run; wrap ALL widget-test teardown
  in `tester.runAsync()` (awaiting a stream/cubit close directly under the
  fake clock hangs forever); never serialize async work with a stored
  Future chain across zones; re-check the ERROR of every "known" failure
  by name — never trust the bucket.
- Pushes only on the user's explicit instruction. Enumerate the push list
  from a real diff against the REMOTE tree (per-file SHA comparison), never
  from a local grep. Verify by commit SHA + head check + small sample +
  the CI run. The GitHub connector rate-limits on rapid sequential reads.
- Security: live Firestore rules are wide open until 2026-12-01; the repo
  rules fragment is admin-section only and not deployable alone. The
  12-permission admin matrix exists in code but is NOT enforced on every
  action (audit finding F-C1). The CNIC back-QR number lives only in the
  restricted `customer_qr_codes/{customerId}` document, super_admin-only,
  never on the main customer document. No secrets in client code, chat,
  or committed files.
- Never claim workspace code is deployed or live. CI (GitHub Actions) is
  the final proof; a local green run is not.

## Adding a new brief

1. Copy only the upstream file(s) that fit this project.
2. Translate its generic/web parts to Flutter + Firebase equivalents
   (e.g. Playwright → `flutter test` / `testWidgets`, SQL injection →
   Firestore rules, axe-core → the `ui_accessibility_test.dart` E3 scan).
3. Delete anything that does not apply; do not keep it "for completeness".
4. Add the "Rentalhub context" block above (copy it from any brief here).
5. Record the upstream file, URL, and commit at the top of the new file.
