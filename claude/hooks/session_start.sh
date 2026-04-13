#!/usr/bin/env bash
# Injects caveman + using-superpowers skills at session start for prompt caching
# Guard against double-execution when both global + project settings files are present
LOCK="/tmp/.claude_session_start_${PPID}"
if [ -f "$LOCK" ]; then exit 0; fi
touch "$LOCK"

CAVEMAN_PATH="$HOME/.claude/skills/caveman/SKILL.md"
SUPERPOWERS_PATH=$(find "$HOME/.claude/plugins/cache/claude-plugins-official/superpowers" \
  -name "SKILL.md" -path "*/using-superpowers/*" 2>/dev/null | sort -V | tail -1)

CAVEMAN=""
SUPERPOWERS=""

[ -f "$CAVEMAN_PATH" ] && CAVEMAN=$(cat "$CAVEMAN_PATH")
[ -n "$SUPERPOWERS_PATH" ] && SUPERPOWERS=$(cat "$SUPERPOWERS_PATH")

COMBINED="# Session Defaults

> NOTE: This content was injected by the SessionStart hook. The \`using-superpowers\` and \`caveman\` skills are already loaded — do NOT invoke them again via the Skill tool.

## Caveman Mode (full)

${CAVEMAN}

---

## Superpowers: Using Skills

${SUPERPOWERS}"

printf '%s' "$COMBINED" | jq -Rs '{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": .
  }
}'
