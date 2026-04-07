#!/bin/bash
HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
source "$HOOK_DIR/parse_hook.sh"

TTY_ID="${SHELL_TTY##*/}"
TTY_SHORT="${TTY_ID#ttys}"

TITLE_PARTS="$PROJECT"
[ -n "$BRANCH" ] && TITLE_PARTS="$PROJECT · ${BRANCH:0:20}"
[ -n "$TTY_SHORT" ] && TITLE_PARTS="$TITLE_PARTS · $TTY_SHORT"
TITLE="✅ $TITLE_PARTS"

# Stop hooks have last_assistant_message as PREVIEW
SUBTITLE="${PREVIEW:-Done}"
BODY=""

(afplay -v 0.8 "$HOOK_DIR/sounds/smile-ringtone.mp3" &) 2>/dev/null

HS="/opt/homebrew/bin/hs"

if [ -n "$TERM_PROGRAM" ]; then
  if [[ "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "vscode-insiders" ]]; then
    VSCODE_TITLE="Claude · $PROJECT [$TTY_ID]"
  fi
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
TTY_ID=${TTY_ID:-}
VSCODE_TERM_TITLE=${VSCODE_TITLE:-}
NOTIFYEOF
  $HS -c "showClaudeNotification('$NOTIFY_FILE')" &
else
  SUBTITLE_ESCAPED="${SUBTITLE//\"/\\\"}"
  osascript -e "display notification \"\" with title \"$TITLE\" subtitle \"${SUBTITLE_ESCAPED}\""
fi
