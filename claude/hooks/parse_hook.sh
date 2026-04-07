#!/bin/bash
# Shared JSON parser for Claude hook scripts.
# Reads hook JSON from stdin, exports shell variables.
#
# Exports: DIR, SESSION, PROJECT, BRANCH, MESSAGE, NTYPE, PREVIEW

INPUT=$(cat)

eval "$(echo "$INPUT" | node -e "
const d = JSON.parse(require('fs').readFileSync(0, 'utf8'));
const path = require('path');
const cwd = d.cwd || process.cwd();
const transcript = d.transcript_path || '';

// Derive project name from transcript path: ~/.claude/projects/<encoded-path>/session.jsonl
let project = path.basename(cwd);
if (transcript) {
  const parts = transcript.split('/');
  const idx = parts.indexOf('projects');
  if (idx >= 0 && idx + 1 < parts.length) {
    const segments = parts[idx + 1].split('-').filter(Boolean);
    project = segments[segments.length - 1] || project;
  }
}

// Shell-safe output using JSON.stringify (handles quotes and special chars)
const vars = {
  DIR: cwd,
  SESSION: (d.session_id || 'unknown').slice(0, 8),
  PROJECT: project,
  MESSAGE: d.message || 'Needs your attention',
  NTYPE: d.notification_type || 'unknown',
  PREVIEW: (d.last_assistant_message || '').slice(0, 200),
};

for (const [k, v] of Object.entries(vars)) {
  console.log(k + '=' + JSON.stringify(v));
}
")"

BRANCH=$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
