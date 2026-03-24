#!/usr/bin/env bash
set -euo pipefail

print_kv() {
  printf '%s: %s\n' "$1" "$2"
}

bool_from_marker() {
  local file="$1"
  local marker="$2"
  if [ -f "$file" ] && grep -Fq "$marker" "$file"; then
    printf 'yes'
  else
    printf 'no'
  fi
}

print_kv "cwd" "$(pwd)"

if command -v node >/dev/null 2>&1; then
  print_kv "node_path" "$(command -v node)"
  print_kv "node_version" "$(node --version)"
else
  print_kv "node_path" "missing"
fi

if command -v opcli >/dev/null 2>&1; then
  print_kv "opcli_path" "$(command -v opcli)"
  opcli_version="$(opcli --version 2>/dev/null || true)"
  if [ -n "$opcli_version" ]; then
    print_kv "opcli_version" "$opcli_version"
  else
    print_kv "opcli_version" "unknown"
  fi
else
  print_kv "opcli_path" "missing"
fi

config_path="$HOME/.opcli/config.json"
if [ -f "$config_path" ]; then
  print_kv "config_path" "$config_path"
  python3 - "$config_path" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text())
schedule = data.get("schedule") or {}
print(f"config_url: {data.get('url') or 'missing'}")
print(f"config_username: {data.get('username') or 'missing'}")
print(f"config_session_present: {'yes' if data.get('session') else 'no'}")
print(f"config_auto_login: {data.get('autoLogin')}")
if schedule:
    parts = []
    for key in ("startHour", "endHour", "lunchStart", "lunchEnd"):
        parts.append(f"{key}={schedule.get(key)}")
    print("config_schedule: " + ",".join(parts))
else:
    print("config_schedule: none")
PY
else
  print_kv "config_path" "missing"
fi

logs_dir="$HOME/.opcli/logs"
if [ -d "$logs_dir" ]; then
  log_count="$(find "$logs_dir" -type f | wc -l | tr -d ' ')"
  print_kv "logs_dir" "$logs_dir"
  print_kv "logs_files" "$log_count"
else
  print_kv "logs_dir" "missing"
fi

alert_path="$HOME/.opcli/alert.json"
if [ -f "$alert_path" ]; then
  print_kv "alert_path" "$alert_path"
  python3 - "$alert_path" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text())
print(f"alert_enabled: {data.get('enabled')}")
print(f"alert_hour: {data.get('hour')}")
PY
else
  print_kv "alert_path" "missing"
fi

if crontab -l >/dev/null 2>&1; then
  if crontab -l 2>/dev/null | grep -Fq "# opcli-alert-check"; then
    print_kv "alert_cron" "installed"
  else
    print_kv "alert_cron" "not-installed"
  fi
else
  print_kv "alert_cron" "no-crontab"
fi

if git rev-parse --show-toplevel >/dev/null 2>&1; then
  repo_root="$(git rev-parse --show-toplevel)"
  branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'unknown')"
  task_id="$(printf '%s\n' "$branch" | sed -n 's/.*\/op-\([0-9][0-9]*\).*/\1/p')"
  print_kv "git_repo_root" "$repo_root"
  print_kv "git_branch" "$branch"
  print_kv "git_task_id" "${task_id:-none}"

  post_commit="$repo_root/.git/hooks/post-commit"
  post_checkout="$repo_root/.git/hooks/post-checkout"
  print_kv "hook_post_commit" "$(bool_from_marker "$post_commit" "# opcli-post-commit-hook")"
  print_kv "hook_post_checkout" "$(bool_from_marker "$post_checkout" "# opcli-post-checkout-hook-start")"
else
  print_kv "git_repo_root" "not-a-git-repo"
fi

print_kv "zshrc_gpush" "$(bool_from_marker "$HOME/.zshrc" "# opcli-gpush-start")"
print_kv "bashrc_gpush" "$(bool_from_marker "$HOME/.bashrc" "# opcli-gpush-start")"
