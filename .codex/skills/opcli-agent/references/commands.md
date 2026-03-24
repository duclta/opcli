# opcli Agent Command Reference

Use this file when you need exact syntax, examples, or a quick reminder of which command family matches the request.

## Install And Setup

```bash
npm i -g @huynhthuc/opcli
opcli config setup
opcli config schedule
```

Notes:

- Node.js `>=18` is required.
- `config setup` currently logs into the hardcoded OpenProject URL `https://devtak.cbidigital.com`.
- `config setup` stores credentials, session, and an `autoLogin` preference in `~/.opcli/config.json`.
- `config schedule` stores expected workday hours used by `opcli stats`.

## Tasks

### List And Search

```bash
opcli tasks list
opcli tasks list "keyword"
opcli tasks list -s "In progress"
opcli tasks list -a me
opcli tasks list -a all
opcli tasks list -a "username"
opcli tasks list --wp-version "Sprint 26"
opcli tasks list --wp-version 1899 -a me -s "In progress"
opcli tasks search
opcli tasks search -a all
opcli tasks projects
```

Notes:

- `tasks list` defaults to assignee `me`.
- `-a/--assignee` accepts `me`, `all`, a numeric ID, or a user search string.
- `--wp-version` accepts a version name or numeric ID.
- If multiple versions match, the current CLI prints matching IDs and you should rerun with `--wp-version <id>`.
- Use `tasks search` only when the interactive live-filter flow is appropriate.

### View

```bash
opcli tasks view <id>
opcli tasks view <id> --web
opcli tasks view <id> --activities
opcli tasks view <id> --relations
opcli tasks view <id> --activities --relations
```

### Create

```bash
opcli tasks create --name "Task name" --description "Description" --assignee me --project "AI Agents"
opcli tasks create --name "Task name" -a me -p 248
opcli tasks create --name "Task name" -a "username" -p "Conative PaaS"
opcli tasks create
```

Behavior:

- If `--project` is omitted and only one project exists, `opcli` auto-selects it.
- If multiple projects exist, `opcli` prompts interactively.
- If `--assignee` resolves to multiple matches, `opcli` exits and asks for a numeric user ID.

### Update

```bash
opcli tasks update <id>
opcli tasks update <id> -s "In progress"
opcli tasks update <id> -a me
opcli tasks update <id> -a "username"
opcli tasks update <id> --start 2026-03-12 --due 2026-03-15
opcli tasks update <id> --description "New description"
opcli tasks update <id> --log-time 4 --log-date 2026-03-12 --log-comment "Worked on ETL fixes"
opcli tasks update <id> -s "Developed" --log-time 1 --log-comment "Completed implementation"
```

Behavior:

- If no flags are passed, `opcli` enters an interactive field picker.
- Status matching is case-insensitive, but validation currently uses the instance-wide `/api/v3/statuses` list.
- Assignee may be `me`, a numeric user ID, or a search string.

### Comment

```bash
opcli tasks comment <id> "Comment text"
```

### Create Branch

```bash
opcli tasks create-branch <id> <slug>
opcli tasks create-branch <id> <slug> -p fix
```

Resulting branch format:

```text
feature/op-<id>-<slug>
fix/op-<id>-<slug>
```

Behavior:

- `opcli` sanitizes the slug.
- After checkout, it prompts whether to update the task to `In progress`.

## Time Logging

### Direct Logging By Ticket ID

```bash
opcli tasks update <id> --log-time 1
opcli tasks update <id> --log-time 2 --log-date 2026-03-12
opcli tasks update <id> --log-time 1 --log-comment "Worked on ETL fixes"
opcli tasks update <id> -s "Developed" --log-time 1 --log-comment "Completed implementation"
```

Use this path when the user already knows the work package ID. It does not require git context.

### Branch-Based Logging

```bash
opcli log
opcli log --hours 2
```

Behavior:

- Reads the current branch and extracts the task ID from `/op-<id>`.
- Shows commits that have not yet been marked as logged.
- Without `--hours`, prompts for auto or manual hour calculation.
- Persists logged commit hashes under `~/.opcli/logs/`.

## Hooks And Automation

```bash
opcli hook install
opcli hook uninstall
```

Installed automation:

- post-commit hook
  - if the latest commit subject contains `done:`, update the task to `Developed`
  - optionally prompt to log time for the latest commit
- post-checkout hook
  - when a new `/op-<id>` branch is created, prompt to update the task to `In progress`
- `gpush` shell function in `~/.bashrc` and `~/.zshrc`
  - after a successful push, offer to update the task to `Developed` and set due date to today
  - skip the update prompt when the latest commit subject contains `WIP`

## Notifications

```bash
opcli notifications list
opcli notifications list -n 10
opcli notifications list -a
opcli notifications read <id>
opcli notifications read --all
```

## Reminder

```bash
opcli reminder
opcli reminder -d 7
```

Open tasks are grouped into:

- due today
- due soon
- new
- overdue
- other

## Stats

```bash
opcli stats
opcli stats -m 2
opcli stats -m 1 -y 2025
opcli stats --team
opcli stats --team -w
opcli stats --team -w 10
opcli stats --team -m 2 -y 2026
```

Behavior:

- Personal stats use the configured work schedule if available.
- Team stats support monthly detail, weekly summary, and specific-week detail.

## Alerts

```bash
opcli alert on
opcli alert on -h 18
opcli alert off
opcli alert status
opcli alert check
```

Behavior:

- `alert on` installs a weekday cron job.
- `alert check` sends a local notification based on today's logged hours.
