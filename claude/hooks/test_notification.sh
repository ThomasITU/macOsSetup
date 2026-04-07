#!/bin/bash
# Test notification hook from any terminal/pane.
# Usage: ./test_notification.sh [permission_prompt|idle_prompt]

NTYPE="${1:-permission_prompt}"
DIR="$(pwd)"
PROJECT="$(basename "$DIR")"
SESSION="test1234"
MESSAGE="Test $NTYPE from $(tty 2>/dev/null || echo 'unknown')"

HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"

# Fire the notification hook (writes breadcrumb + sends notification)
echo '{"cwd":"'"$DIR"'","session_id":"'"$SESSION"'","message":"'"$MESSAGE"'","notification_type":"'"$NTYPE"'"}' \
  | "$HOOK_DIR/notification_notify.sh"

echo ""
echo "Notification sent: $NTYPE"
echo "  Terminal: ${TERM_PROGRAM:-unknown}"
echo "  TTY: $(tty 2>/dev/null || echo 'N/A')"
echo "  TMUX_PANE: ${TMUX_PANE:-N/A}"
echo ""
echo "Waiting for approval..."
echo ""
echo "  1. Yes"
echo "  2. No"
echo ""

# Wait for input — double-tap Ctrl sends Enter via tmux, or user types manually
read -r answer </dev/tty

if [ "$answer" = "1" ] || [ "$answer" = "" ]; then
  echo "✅ Approved!"
else
  echo "❌ Denied."
fi
