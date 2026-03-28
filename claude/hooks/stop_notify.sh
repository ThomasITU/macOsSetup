#!/bin/bash
HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
source "$HOOK_DIR/parse_hook.sh"

SUBTITLE="$PROJECT"
[ -n "$BRANCH" ] && SUBTITLE="$PROJECT  ·  $BRANCH"

BODY="${PREVIEW:-Done}"

afplay "$HOOK_DIR/sounds/smile-ringtone.mp3" &
osascript -e "display notification \"$BODY\" with title \"✅ Claude Finished — $PROJECT\" subtitle \"$SUBTITLE  ·  $SESSION\""
