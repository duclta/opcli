# opcli Agent Operational Notes

Use this file when `opcli` behaves unexpectedly, when the request touches hooks or alerts, or when you need implementation-level detail before running mutating commands.

## Local State

`opcli` stores local state here:

- `~/.opcli/config.json`
  - stores `url`, `username`, base64-encoded `password`, optional `session`, optional `schedule`, optional `autoLogin`
- `~/.opcli/logs/`
  - stores logged commit hashes per repository so branch-based `opcli log` does not double-log commits
- `~/.opcli/alert.json`
  - stores whether alerting is enabled and which hour to check

## Important Current Constraints

- `opcli config setup` currently uses the hardcoded URL `https://devtak.cbidigital.com`.
- `opcli tasks view --web` uses macOS `open`.
- `opcli alert` is macOS-oriented:
  - try `terminal-notifier`
  - then try `osascript`
  - then fall back to a terminal bell
- branch-based `opcli log` expects the current branch name to contain `/op-<id>`.
- direct logging with `opcli tasks update <id> --log-time ...` does not require git context.
- the `autoLogin` flag is stored, but the current runtime does not actively refresh sessions in the background.

## Status Validation

The current code path calls `getAvailableStatuses(task.id)`, but the implementation fetches `/api/v3/statuses` and validates against the instance-wide status list.

Practical consequence:

- `opcli` checks that the status exists in the OpenProject instance
- it does not currently verify task-specific transition rules before sending the update

## Git Behavior

Branch pattern:

```text
<prefix>/op-<id>-<slug>
```

Task ID extraction logic:

- match `/op-(\d+)`
- works for `feature/op-123-foo`, `fix/op-123-foo`, and similar prefixes

Branch-based `opcli log` commit range logic:

- try `git merge-base main <branch>`
- then try `git merge-base master <branch>`
- otherwise use all commits reachable on the branch

## Hook Side Effects

`opcli hook install` changes:

- repo file `.git/hooks/post-commit`
- repo file `.git/hooks/post-checkout`
- user file `~/.bashrc`
- user file `~/.zshrc`

Markers used by the current code:

- post-commit marker: `# opcli-post-commit-hook`
- post-checkout block: `# opcli-post-checkout-hook-start` to `# opcli-post-checkout-hook-end`
- `gpush` block: `# opcli-gpush-start` to `# opcli-gpush-end`
- alert cron marker: `# opcli-alert-check`

Check those markers before assuming installation or removal succeeded.

## Troubleshooting Flow

### `opcli` command not found

Run:

```bash
command -v opcli
node --version
```

If missing, install:

```bash
npm i -g @huynhthuc/opcli
```

### No configuration found

Run:

```bash
opcli config setup
```

If you only need to inspect whether config exists, use `bash scripts/opcli-doctor.sh` instead of printing the config file directly.

### Authentication failed

Likely causes:

- stale session
- wrong username or password
- wrong environment

Action:

- rerun `opcli config setup`
- verify the stored URL if you suspect a different OpenProject environment

### Cannot extract task ID from branch

Verify the current branch name. The logging workflow only works when the branch contains `/op-<id>`.

If the user already knows the ticket ID, skip branch-based logging and use:

```bash
opcli tasks update <id> --log-time <hours>
```

### Hook install appears incomplete

Check:

- repo hook files for the upstream markers
- `~/.bashrc` and `~/.zshrc` for `gpush` markers
- whether the shell was reloaded after installation

### Alert did not fire

Check:

- `~/.opcli/alert.json`
- `crontab -l` for the `# opcli-alert-check` line
- whether local notifications are available on the machine

## Safe Execution Guidance

- Prefer read-only commands first when the request is underspecified.
- Avoid printing passwords or raw config contents.
- State clearly when a command will alter OpenProject data, repo hooks, shell startup files, or cron.
