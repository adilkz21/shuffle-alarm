---
name: next-task
description: Implement the next unchecked task of the current PLAN.md stage, verify it, tick it off and commit
disable-model-invocation: true
---
Work on one task from PLAN.md. If a task ID is given ($ARGUMENTS, e.g. 2.3), do that task; otherwise take the first unchecked task of the current stage. If every task of the current stage is ticked, don't start the next stage: remind me of the stage's "Ready when" check and its test with people. When I share the test results, write them into docs/DECISIONS.md as findings, mark the stage done, and plan the next stage in detail (show that plan and wait for my approval).

1. Read PLAN.md: the task, and its stage's question, "Ready when" check and test with people, so the task serves them. Read the findings in docs/DECISIONS.md that apply. Follow the CLAUDE.md rules that apply.
2. If the task touches 2 or more files, show a short plan (files, steps, tests) and wait for my approval.
3. Implement the task. Write tests first for anything in lib/core/.
4. Run `dart format .`, `flutter analyze` and `flutter test`. Fix failures at the root cause; never skip or delete tests to make them pass.
5. Show evidence: test output, command output, or exact steps to try it in the web app.
6. Tick the task's checkbox in PLAN.md and add one line to the Progress log: date, task ID, short note.
7. Commit with `type(scope): summary`.
8. Stop and report in simple English: what changed, how to try it, and which task is next. After the stage's last task, say instead that the stage is ready for its "Ready when" check and its test with people.
