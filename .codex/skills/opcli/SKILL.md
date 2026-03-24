---
name: opcli
description: Use the opcli OpenProject CLI from this repository to inspect work packages, update status or assignee, create tasks and git branches, log time by ticket or branch activity, manage notifications, reminders, stats, and alerts, install local workflow hooks, or troubleshoot opcli setup. Trigger when the user mentions opcli, OpenProject CLI workflows, work package IDs or statuses, time logging, branch names like feature/op-123-slug, or terminal-based OpenProject automation.
---

# opcli

Use this skill when an agent needs repo-local guidance for operating `opcli`. Prefer direct CLI execution for concrete requests, verify setup before mutating state, and load the reference files only when exact syntax or troubleshooting detail is needed.

## Quick Start

1. Run `bash scripts/opcli-doctor.sh` when setup, repo state, or shell automation is uncertain.
2. Install `opcli` with `npm i -g @huynhthuc/opcli` or build this repository if the command is missing.
3. Run `opcli config setup` if `~/.opcli/config.json` is missing or auth looks stale.
4. Use `opcli tasks versions [search]` when the user needs to browse versions or sprints before filtering tasks.
5. Prefer `opcli tasks update <id> --log-time ...` when the user already gave a work package ID.
6. Use `opcli log` only when the user wants branch-aware logging from git commits.
7. Read [`references/commands.md`](references/commands.md) for command syntax and [`references/operational-notes.md`](references/operational-notes.md) for side effects and implementation caveats.

## Prefer Non-Interactive Execution

Prefer fully specified commands when the user already supplied the values.

Use a TTY for interactive commands such as:

- `opcli config setup`
- `opcli config schedule`
- `opcli tasks create` without all flags
- `opcli tasks update <id>` without flags
- `opcli tasks search`
- `opcli log` without `--hours`

## Verify Environment

Run `bash scripts/opcli-doctor.sh` first when the machine or repository state is unclear. It reports:

- `node` and `opcli` availability
- presence of `~/.opcli/config.json` without printing secrets
- stored schedule and alert settings
- whether the current directory is a git repository
- current branch and extracted task ID
- whether repo hooks and `gpush` shell blocks are installed

## Decide Whether The Request Is Read-Only Or Mutating

Treat these as read-only by default:

- `tasks list`
- `tasks versions`
- `tasks search`
- `tasks view`
- `tasks projects`
- `notifications list`
- `reminder`
- `stats`
- `alert status`

Treat these as mutating:

- `tasks create`
- `tasks update`
- `tasks comment`
- `tasks create-branch`
- `log`
- `notifications read`
- `hook install`
- `hook uninstall`
- `alert on`
- `alert off`

Inspect current state first if intent is ambiguous, then ask a short clarifying question before mutating anything important.

## Map Intent To Command Family

Use `tasks` for work package discovery, version and sprint lookup, creation, updates, comments, project lookup, and git branch creation.

Use `tasks versions [search]` when the user explicitly asks to list versions, releases, or sprints.

Use `tasks update <id> --log-time ...` for direct ticket-based logging.

Use `log` only for branch-aware logging from commit history on the current branch.

Use `hook` for repo hooks and the `gpush` helper.

Use `notifications`, `reminder`, `stats`, and `alert` for inbox, planning, reporting, and daily reminder workflows.

## Handle Git-Aware Flows Carefully

Verify git context before:

- `opcli tasks create-branch`
- `opcli log`
- `opcli hook install`
- relying on `gpush`

Expect branch names in this format:

```text
<prefix>/op-<id>-<slug>
```

Remember:

- `opcli log` extracts the task ID from the branch name
- `opcli log` compares the branch against `main`, then `master`, then falls back to all commits on the branch
- `opcli tasks create-branch` sanitizes the slug and then runs `git checkout -b`
- `opcli hook install` modifies repo hooks and user shell startup files

## Account For Implementation Caveats

Remember these current behaviors from the repository code:

- `opcli config setup` always targets `https://devtak.cbidigital.com`
- the stored password is base64-encoded, not encrypted
- `tasks view` prints a `Version` line when the work package has `_links.version.title`
- `tasks view --web` uses macOS `open`
- `alert` prefers `terminal-notifier`, then `osascript`, then a terminal bell
- status validation currently uses the instance-wide `/api/v3/statuses` list rather than per-task transition rules
- the `autoLogin` flag is stored in config but not actively refreshed by the CLI runtime

## Resources

- Read [`references/commands.md`](references/commands.md) for command inventory and common examples.
- Read [`references/operational-notes.md`](references/operational-notes.md) when diagnosing auth, git, hooks, alerts, or local state.
- Run `bash scripts/opcli-doctor.sh` before acting in an unfamiliar environment.
