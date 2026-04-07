#!/bin/bash
HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
source "$HOOK_DIR/parse_hook.sh"

TTY_ID="${SHELL_TTY##*/}"
TTY_SHORT="${TTY_ID#ttys}"  # e.g. "014" from "ttys014"

# Title: emoji + project + branch (truncated) + tty short id
# e.g. "🔐 TradingBot · main · 014"
TITLE_PARTS="$PROJECT"
[ -n "$BRANCH" ] && TITLE_PARTS="$PROJECT · ${BRANCH:0:20}"
[ -n "$TTY_SHORT" ] && TITLE_PARTS="$TITLE_PARTS · $TTY_SHORT"

case "$NTYPE" in
  permission_prompt) TITLE="🔐 $TITLE_PARTS" ;;
  idle_prompt)       TITLE="💤 $TITLE_PARTS" ;;
  *)                 TITLE="⚠️ $TITLE_PARTS" ;;
esac

# Subtitle: the permission message (most important line)
SUBTITLE="$MESSAGE"

# Body: preview of what Claude is doing (max context)
BODY="$PREVIEW"

# Write breadcrumb to FIFO queue so multiple prompts are handled in order
QUEUE_DIR=~/.claude/.prompt_queue
mkdir -p "$QUEUE_DIR"
BREADCRUMB="$QUEUE_DIR/$(date +%s%N)-$$"
cat > "$BREADCRUMB" <<EOF
DIR=$DIR
PROJECT=$PROJECT
BRANCH=${BRANCH:-}
TERM_PROGRAM=${TERM_PROGRAM:-}
TMUX_PANE=${TMUX_PANE:-}
SHELL_TTY=${SHELL_TTY:-}
TTY_ID=${TTY_ID:-}
EOF

# VS Code: rename terminal tab so user can visually identify the right one
if [[ "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "vscode-insiders" ]]; then
  VSCODE_TITLE="Claude · $PROJECT [$TTY_ID]"
  if [ -n "$SHELL_TTY" ] && [ -w "$SHELL_TTY" ]; then
    printf '\033]0;%s\007' "$VSCODE_TITLE" > "$SHELL_TTY"
  fi
  echo "VSCODE_TERM_TITLE=$VSCODE_TITLE" >> "$BREADCRUMB"
fi

(afplay -v 1 /System/Library/Sounds/Ping.aiff &) 2>/dev/null

HS="/opt/homebrew/bin/hs"

if [ -n "$TERM_PROGRAM" ]; then
  NOTIFY_FILE=$(mktemp /tmp/claude-notify.XXXXXX)
  cat > "$NOTIFY_FILE" <<NOTIFYEOF
TITLE=$TITLE
SUBTITLE=$SUBTITLE
MESSAGE=$BODY
PROJECT=$PROJECT
BRANCH=${BRANCH:-}
TERM_PROGRAM=${TERM_PROGRAM:-}
TMUX_PANE=${TMUX_PANE:-}
SHELL_TTY=${SHELL_TTY:-}
VSCODE_TERM_TITLE=${VSCODE_TITLE:-}
TTY_ID=${TTY_ID:-}
BREADCRUMB_PATH=$BREADCRUMB
NOTIFYEOF
  $HS -c "showClaudeNotification('$NOTIFY_FILE')" &
else
  osascript -e "display notification \"$BODY\" with title \"$TITLE\" subtitle \"$SUBTITLE\""
fi
