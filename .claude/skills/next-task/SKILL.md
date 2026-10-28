---
name: next-task
description: Implement the next unchecked task from PLAN.md, verify it, tick it off and commit
disable-model-invocation: true
---
Work on one task from PLAN.md. If a task ID is given ($ARGUMENTS, e.g. 2.6), do that task; otherwise take the first unchecked task.

1. Read PLAN.md: the task, its phase goal and the phase's "Done when" check. Follow the CLAUDE.md rules that apply.
2. If the task touches 2 or more files, show a short plan (files, steps, tests) and wait for my approval.
3. Implement the task. Write tests first for anything in lib/core/.
4. Run `dart format .`, `flutter analyze` and `flutter test`. Fix failures at the root cause; never skip or delete tests to make them pass.
5. Show evidence: test output, command output, or exact steps to try it in the web app.
6. Tick the task's checkbox in PLAN.md and add one line to the Progress log: date, task ID, short note.
7. Commit with `type(scope): summary`.
8. Stop and report in simple English: what changed, how to try it, and which task is next.
