# opcli

`opcli` is a Node.js CLI for working with OpenProject from the terminal. It talks directly to the target OpenProject instance, stores local state under `~/.opcli`, and supports task management, time logging, git-linked workflows, notifications, reminders, stats, and local automation.

## Principles

- No middleware server.
- No telemetry or data collection in this repo.
- Direct access to OpenProject pages and API endpoints.

## Requirements

- Node.js `>=18`
- Access to the target OpenProject instance
- A shell environment with git available for git-aware commands
- macOS is the best-supported environment for `tasks view --web`, `alert`, and some shell automation

## Installation

Install from npm:

```bash
npm i -g @huynhthuc/opcli
```

Install from source:

```bash
git clone https://github.com/huynhthuchct/opcli.git
cd opcli
npm install
npm run build
npm link
```

Useful checks:

```bash
opcli --help
opcli tasks --help
opcli --version
```

## Quick Start

1. Configure credentials:

```bash
opcli config setup
```

2. Optional: configure your work schedule so `opcli stats` can calculate expected daily hours:

```bash
opcli config schedule
```

3. List your tasks:

```bash
opcli tasks list
```

4. Update a task:

```bash
opcli tasks update 54379 -s "In progress"
```

5. Log time directly by ticket ID:

```bash
opcli tasks update 54379 --log-time 1.5 --log-comment "Implemented API fix"
```

## Configuration And Local State

### `opcli config setup`

Run:

```bash
opcli config setup
```

Behavior:

- The current implementation uses a hardcoded OpenProject URL: `https://devtak.cbidigital.com`
- Prompts for username and password
- Logs in and stores the returned OpenProject session cookie
- Prompts for an `autoLogin` preference and stores it in config
- Saves configuration to `~/.opcli/config.json`

Example stored file shape:

```json
{
  "url": "https://devtak.cbidigital.com",
  "username": "user@example.com",
  "password": "YmFzZTY0LWVuY29kZWQtcGFzc3dvcmQ=",
  "session": "session-cookie-value",
  "autoLogin": true
}
```

Notes:

- The password is base64-encoded, not encrypted.
- The current code stores the `autoLogin` preference, but does not run a background refresh loop by itself.

### `opcli config schedule`

Run:

```bash
opcli config schedule
```

Prompts for:

- `startHour`
- `endHour`
- `lunchStart`
- `lunchEnd`

Example:

```bash
opcli config schedule
# Start hour (0-23): 8
# End hour (0-23): 17
# Lunch start (HH:MM): 12:00
# Lunch end (HH:MM): 13:30
```

Behavior:

- Validates that `startHour < endHour`
- Stores the schedule in `~/.opcli/config.json`
- Uses the stored schedule in `opcli stats`
- Computes expected daily hours as `endHour - startHour - lunchDuration`

### Files And Side Effects

`opcli` can write to:

- `~/.opcli/config.json`: credentials, session, schedule, and `autoLogin`
- `~/.opcli/logs/*.json`: logged commit hashes per repository for `opcli log`
- `~/.opcli/alert.json`: alert configuration
- `.git/hooks/post-commit`: when `opcli hook install` is used
- `.git/hooks/post-checkout`: when `opcli hook install` is used
- `~/.bashrc` and `~/.zshrc`: when `opcli hook install` adds the `gpush` function
- Your user crontab: when `opcli alert on` is used

## Command Overview

Top-level command groups:

- `config`
- `tasks`
- `log`
- `hook`
- `notifications`
- `reminder`
- `stats`
- `alert`

## Tasks Commands

### `opcli tasks list [search]`

List work packages, assigned to you by default.

```bash
opcli tasks list
opcli tasks list "keyword"
opcli tasks list -s "In progress"
opcli tasks list -a me
opcli tasks list -a all
opcli tasks list -a "username"
opcli tasks list -a 123
opcli tasks list --wp-version "Sprint 26"
opcli tasks list --wp-version 1899 -a me -s "In progress"
```

Options:

- `-s, --status <status>`: client-side substring filter on the returned status label
- `-a, --assignee <user>`: assignee name, numeric user ID, `me`, or `all`
- `--wp-version <version>`: OpenProject version name or numeric ID

Behavior:

- Default assignee is `me`
- If you pass a non-numeric assignee other than `me` or `all`, `opcli` searches users first
- If a version name matches exactly or partially, `opcli` resolves it to an ID
- If multiple users or versions match, the command prints candidates and exits so you can rerun with an ID such as `--wp-version 1899`
- Results are sorted by `updatedAt desc`
- The list output is capped by the underlying API page size of `100`

### `opcli tasks versions [search]`

List available OpenProject versions and sprints.

```bash
opcli tasks versions
opcli tasks versions "Sprint"
opcli tasks versions 1899
```

Behavior:

- Returns versions from OpenProject and prints a simple `ID | Name` table
- Optional `search` filters case-insensitively by version name
- Numeric `search` terms also match by version ID text

### `opcli tasks search`

Interactive search with live filtering.

```bash
opcli tasks search
opcli tasks search -a all
opcli tasks search -a me
```

Options:

- `-a, --assignee <user>`: same assignee rules as `tasks list`

Interactive actions after selecting a task:

- `View detail`
- `Update`
- `Comment`
- `Create branch`
- `Exit`

Filtering fields:

- subject
- task ID
- status
- priority
- assignee

### `opcli tasks view <id>`

Show work package details.

```bash
opcli tasks view 54379
opcli tasks view 54379 --activities
opcli tasks view 54379 --relations
opcli tasks view 54379 --activities --relations
opcli tasks view 54379 --web
```

Options:

- `--activities`: include activity history and comments
- `--relations`: include related work packages
- `--web`: open the task page in a browser

Behavior:

- `--web` uses the macOS `open` command
- When the work package belongs to a version or sprint, the detail output includes a `Version` line
- Descriptions and comments are rendered from HTML/Markdown into terminal-friendly text
- Activity output includes timestamp, actor, change details, and formatted comments when available

### `opcli tasks create`

Create a new work package.

```bash
opcli tasks create --name "Task name" --description "Description" --assignee me --project "AI Agents"
opcli tasks create --name "Task name" -a me -p 248
opcli tasks create --name "Task name" -a "username" -p "Conative PaaS"
opcli tasks create
```

Options:

- `-n, --name <name>`: task subject
- `-d, --description <text>`: task description
- `-a, --assignee <user>`: assignee name, numeric user ID, or `me`
- `-p, --project <project>`: project name or numeric ID

Behavior:

- If `--name` is omitted, `opcli` prompts for it
- If `--description` is omitted, `opcli` prompts for it
- If `--project` is omitted and only one project is available, `opcli` auto-selects it
- If multiple projects exist, `opcli` prompts you to choose one
- If you pass a non-numeric assignee name and multiple users match, `opcli` exits and asks you to rerun with a user ID

### `opcli tasks update <id>`

Update task fields, log time, or both.

```bash
opcli tasks update 54379
opcli tasks update 54379 -s "In progress"
opcli tasks update 54379 -a me
opcli tasks update 54379 -a "username"
opcli tasks update 54379 --start 2026-03-12 --due 2026-03-15
opcli tasks update 54379 --description "New description"
opcli tasks update 54379 --log-time 4
opcli tasks update 54379 --log-time 4 --log-date 2026-03-12 --log-comment "Worked on ETL fixes"
opcli tasks update 54379 -s "Developed" --log-time 1 --log-comment "Completed implementation"
opcli tasks update 54379 -s "In progress" --start 2026-03-12 --due 2026-03-15 --log-time 2
```

Options:

- `-s, --status <status>`: status name
- `-a, --assignee <user>`: assignee name, numeric user ID, or `me`
- `--start <date>`: start date in `YYYY-MM-DD`
- `--due <date>`: due date in `YYYY-MM-DD`
- `--description <text>`: replace description text
- `--log-time <hours>`: log time in hours
- `--log-date <date>`: log date in `YYYY-MM-DD`, defaults to today
- `--log-comment <text>`: comment for the time entry

Behavior:

- If you pass update flags, `opcli` applies them directly
- If you pass no flags at all, `opcli` enters interactive mode and lets you pick which fields to update
- Status validation currently checks the instance status list from `/api/v3/statuses`
- Assignee lookup supports `me`, numeric IDs, or a name search
- Time logging can be combined with field updates in the same command

Interactive mode can update:

- status
- assignee
- start date
- due date
- description
- logged time

### `opcli tasks comment <id> <message>`

Add a comment to a work package.

```bash
opcli tasks comment 54379 "Picked this up in the current sprint."
```

### `opcli tasks create-branch <id> <slug>`

Create and check out a git branch linked to a task.

```bash
opcli tasks create-branch 54379 fix-ad-clicks
opcli tasks create-branch 54379 fix-ad-clicks -p fix
```

Options:

- `-p, --prefix <prefix>`: branch prefix, default `feature`

Branch format:

```text
<prefix>/op-<id>-<sanitized-slug>
```

Examples:

```text
feature/op-54379-fix-ad-clicks
fix/op-54379-fix-ad-clicks
```

Behavior:

- The slug is lowercased and sanitized to alphanumeric, underscore, and hyphen characters
- Runs `git checkout -b <branch>`
- Suppresses the post-checkout hook prompt while creating the branch from `opcli`
- After branch creation, prompts whether to update the task to `In progress`

### `opcli tasks projects`

List available OpenProject projects.

```bash
opcli tasks projects
```

Output is a simple table of project IDs and names.

## Time Logging

### Direct Time Logging By Ticket ID

Use this when you already know the work package ID.

```bash
opcli tasks update 54379 --log-time 1
opcli tasks update 54379 --log-time 2 --log-date 2026-03-12
opcli tasks update 54379 --log-time 1 --log-comment "Worked on ETL fixes"
opcli tasks update 54379 -s "Developed" --log-time 1 --log-comment "Completed implementation"
```

This path does not require a git repository.

### `opcli log`

Use branch-aware time logging based on commits in the current branch.

```bash
opcli log
opcli log --hours 2
```

Options:

- `--hours <hours>`: skip auto/manual hour selection and set hours directly

Behavior:

- Requires a git repository
- Extracts the task ID from the current branch name using the pattern `/op-<id>`
- Reads unlogged commits from the current branch
- Uses `git merge-base main <branch>` first, then `master`, then falls back to all commits reachable on the branch
- Stores logged commit hashes in `~/.opcli/logs/<repo-hash>.json`
- Still asks for final confirmation before creating the time entry

Interactive mode:

1. Show unlogged commits
2. Ask whether to calculate hours automatically or manually
3. Show the final hours/date summary
4. Ask for confirmation
5. Log time and persist commit hashes as logged

## Hooks And Git Automation

### `opcli hook install`

Install repo hooks and a helper shell function.

```bash
opcli hook install
```

What it installs:

- `.git/hooks/post-commit`
- `.git/hooks/post-checkout`
- `gpush` function in `~/.bashrc`
- `gpush` function in `~/.zshrc`

Installed behavior:

- `post-commit`
  - If the latest commit subject contains `done:` (case-insensitive), run `opcli tasks update <id> --status "Developed"`
  - Prompt for hours and optionally log time for the latest commit
- `post-checkout`
  - When a new branch is created and its name contains `/op-<id>`, prompt to update the task to `In progress`
- `gpush`
  - Runs `git push "$@"`
  - If push succeeds and the branch contains `/op-<id>`, offer to update the task to `Developed` and set due date to today
  - Skips the update prompt if the latest commit subject contains `WIP`

After installation:

```bash
source ~/.zshrc
# or
source ~/.bashrc
```

### `opcli hook uninstall`

Remove the installed hook sections and `gpush` shell function.

```bash
opcli hook uninstall
```

Behavior:

- Removes only the `opcli`-marked sections when possible
- Preserves unrelated hook content if the hook file contains other logic

## Notifications

### `opcli notifications list`

List recent notifications.

```bash
opcli notifications list
opcli notifications list -n 10
opcli notifications list -a
```

Options:

- `-u, --unread`: unread only, effectively the default behavior
- `-a, --all`: include read notifications
- `-n, --count <count>`: number of rows to show, default `20`

Output includes:

- read/unread marker
- timestamp
- reason
- related work package ID when available
- resource title
- actor

### `opcli notifications read [id]`

Mark one or all notifications as read.

```bash
opcli notifications read 12345
opcli notifications read --all
```

## Reminder

### `opcli reminder`

Show open tasks grouped by urgency.

```bash
opcli reminder
opcli reminder -d 7
```

Options:

- `-d, --days <days>`: include tasks due within `N` days, default `3`

Categories:

- `Due today`
- `Due soon`
- `New`
- `Overdue`
- `Other`

Behavior:

- Closed and rejected tasks are excluded
- Due dates are compared against today
- New tasks without due dates are moved into the `New` section

## Stats

### `opcli stats`

Show time logging statistics for the current user.

```bash
opcli stats
opcli stats -m 2
opcli stats -m 1 -y 2025
```

Options:

- `-m, --month <month>`: month `1-12`, default current month
- `-y, --year <year>`: default current year

Behavior:

- Uses your configured schedule, or defaults to `08:00-17:00` with lunch `12:00-13:30`
- Prints one line per day
- Skips weekends from expected-hour calculations
- Shows expected total hours, logged total, average logged hours, work days, logged days, and missing days
- Colors hours as:
  - red: `<= 4h`
  - yellow: `< 7h`
  - green: `>= 7h`

### Team Stats

```bash
opcli stats --team
opcli stats --team -w
opcli stats --team -w 10
opcli stats --team -m 2 -y 2026
```

Additional options:

- `-t, --team`: switch to team mode
- `-w, --week [weekNumber]`
  - no value: weekly summary by member
  - with a number: detailed view for that week

Modes:

- `--team`: per-member monthly detail
- `--team -w`: weekly summary table
- `--team -w <n>`: specific-week daily table

## Alerts

### `opcli alert on`

Enable a weekday reminder to check logged hours.

```bash
opcli alert on
opcli alert on -h 18
```

Options:

- `-h, --hour <hour>`: hour of day, default `17`

Behavior:

- Saves `~/.opcli/alert.json`
- Installs a weekday cron entry with the marker `# opcli-alert-check`
- Runs `opcli alert check` at the chosen hour

### `opcli alert off`

Disable alerts and remove the cron entry.

```bash
opcli alert off
```

### `opcli alert status`

Show whether alerts are enabled.

```bash
opcli alert status
```

### `opcli alert check`

Check today's logged hours and send a local notification.

```bash
opcli alert check
```

Current thresholds:

- `>= 8h`: success message
- `> 4h and < 8h`: keep-going message
- `< 4h`: warning
- `0h`: reminder to log time

Notification delivery order:

1. `terminal-notifier`
2. `osascript`
3. terminal bell fallback

## Branch Naming Convention

Git-aware commands expect branch names like:

```text
feature/op-54379-fix-ad-clicks
fix/op-54379-fix-ad-clicks
chore/op-54379-update-docs
```

Task ID extraction rule:

- Match `/op-(\d+)`

Commands that depend on this pattern:

- `opcli log`
- `opcli hook install` automation
- `gpush`
- `opcli tasks create-branch`

## Common Statuses

The current README history in this repo references these statuses from the target OpenProject instance:

- `New`
- `In specification`
- `Specified`
- `Confirmed`
- `To be scheduled`
- `Scheduled`
- `In progress`
- `Developed`
- `In testing`
- `Tested`
- `Test failed`
- `Closed`
- `On hold`
- `Rejected`
- `Staging`
- `Production`
- `Fixed`

Treat these as instance-specific examples, not a guaranteed universal list.

## Troubleshooting

### `No configuration found`

Run:

```bash
opcli config setup
```

### Authentication failed

Likely causes:

- expired or invalid session
- wrong username or password
- wrong server environment

Fix:

```bash
opcli config setup
```

### `Cannot extract task ID from branch`

Your branch name does not include `/op-<id>`.

Either:

- rename the branch to the expected pattern, or
- log time directly by ticket ID with `opcli tasks update <id> --log-time ...`

### `tasks view --web` does not open a browser

The current implementation uses macOS `open`. On non-macOS systems, use the printed task URL manually or adapt the command locally.

### Hook or `gpush` changes do not take effect

Reload your shell:

```bash
source ~/.zshrc
# or
source ~/.bashrc
```

### Alert did not fire

Check:

- `~/.opcli/alert.json`
- `crontab -l`
- notification support on your machine

## Development

Install dependencies:

```bash
npm install
```

Useful scripts:

```bash
npm run build
npm test
npm run dev
```

Project entry points:

- `src/index.ts`
- `src/commands/*.ts`
- `src/api/openproject.ts`
- `src/config/store.ts`
- `bin/opcli.js`
