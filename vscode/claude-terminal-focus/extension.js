const vscode = require("vscode");
const fs = require("fs");
const path = require("path");

// File that Hammerspoon writes to request terminal focus
const FOCUS_FILE = "/tmp/vscode-focus-terminal";

let watcher = null;

function handleFocusRequest() {
  try {
    if (!fs.existsSync(FOCUS_FILE)) return;
    const content = fs.readFileSync(FOCUS_FILE, "utf8").trim();
    fs.unlinkSync(FOCUS_FILE);
    if (!content) return;

    // Format: "name" to focus, or "name\napprove" to focus + send Enter
    const lines = content.split("\n");
    const name = lines[0];
    const approve = lines[1] === "approve";

    const terminal = findTerminal(name);
    if (!terminal) return;

    if (approve) {
      // Send Enter to approve without showing (no focus switch)
      terminal.sendText("", true);
    } else {
      terminal.show();
    }
  } catch {
    // File may have been deleted between check and read
  }
}

function findTerminal(name) {
  if (!name) return null;
  const target = name.trim();
  for (const terminal of vscode.window.terminals) {
    if (terminal.name.includes(target)) {
      return terminal;
    }
  }
  return null;
}

function activate(context) {
  // Register command (for manual/keybinding use)
  context.subscriptions.push(
    vscode.commands.registerCommand("claude.focusTerminalByTTY", async () => {
      const name = await vscode.window.showInputBox({
        prompt: "Terminal name or TTY ID to focus",
      });
      if (name) {
        const terminal = findTerminal(name);
        if (terminal) terminal.show();
      }
    })
  );

  // Watch the focus file for changes from Hammerspoon
  // fs.watch on the file itself fails if it doesn't exist yet,
  // so watch the directory and filter for our file
  const dir = path.dirname(FOCUS_FILE);
  const basename = path.basename(FOCUS_FILE);

  watcher = fs.watch(dir, (event, filename) => {
    if (filename === basename) {
      // Small delay to ensure file is fully written
      setTimeout(handleFocusRequest, 50);
    }
  });

  context.subscriptions.push({ dispose: () => watcher?.close() });

  // Also check on activation in case file was written before VS Code started
  handleFocusRequest();
}

function deactivate() {
  watcher?.close();
}

module.exports = { activate, deactivate };
