-- Hammerspoon configuration
-- Managed by macSetup dotfiles

-- Enable CLI (hs command)
require("hs.ipc")

-----------------------------------------------------------
-- Claude prompt approval system
--
-- Three ways to handle Claude permission prompts:
--   1. Desktop app:     click "Allow once" on macOS notification
--   2. Double-tap Ctrl: approve in background (no focus switch)
--   3. Click notification banner: navigate to the terminal
--
-- Supported terminals: Ghostty, Terminal, iTerm2, Alacritty,
--                      WezTerm, kitty, VS Code
-- Supports tmux inside any terminal.
-----------------------------------------------------------

local queueDir = os.getenv("HOME") .. "/.claude/.prompt_queue"
local tmuxBin = "/opt/homebrew/bin/tmux"
hs.fs.mkdir(queueDir)

-----------------------------------------------------------
-- Breadcrumb queue: FIFO directory of prompt files.
-- Each notification creates a timestamped file.
-- Double-tap Ctrl processes the oldest first.
-----------------------------------------------------------

local function parseBreadcrumbFile(path)
    local attrs = hs.fs.attributes(path)
    if not attrs then return nil end
    if os.time() - attrs.modification > 300 then
        os.remove(path)
        return nil
    end

    local f = io.open(path, "r")
    if not f then return nil end
    local info = { _path = path }
    for line in f:lines() do
        local k, v = line:match("^([%w_]+)=(.*)")
        if k and v and v ~= "" then info[k] = v end
    end
    f:close()
    return info
end

-- Read the oldest breadcrumb from the queue (FIFO)
local function readBreadcrumb()
    local files = {}
    for file in hs.fs.dir(queueDir) do
        if file ~= "." and file ~= ".." then
            table.insert(files, file)
        end
    end
    if #files == 0 then return {} end
    table.sort(files)
    return parseBreadcrumbFile(queueDir .. "/" .. files[1]) or {}
end

local function clearBreadcrumb(prompt)
    if prompt and prompt._path then
        os.remove(prompt._path)
    end
end

-- Clear all breadcrumbs (used when withdrawing all notifications)
local function clearAllBreadcrumbs()
    for file in hs.fs.dir(queueDir) do
        if file ~= "." and file ~= ".." then
            os.remove(queueDir .. "/" .. file)
        end
    end
end

-----------------------------------------------------------
-- Terminal registry
--
-- To add a new terminal:
--   1. Add an entry to terminalApps with name and TERM_PROGRAM values
--   2. That's it — tmux support is automatic
-----------------------------------------------------------

local terminalApps = {
    { name = "Ghostty",          termPrograms = { "ghostty" } },
    { name = "Terminal",         termPrograms = { "Apple_Terminal" } },
    { name = "iTerm2",           termPrograms = { "iTerm2", "iTerm.app" } },
    { name = "Alacritty",        termPrograms = { "alacritty" } },
    { name = "WezTerm",          termPrograms = { "WezTerm" } },
    { name = "kitty",            termPrograms = { "kitty" } },
    { name = "Code",             termPrograms = { "vscode" } },
    { name = "Code - Insiders",  termPrograms = { "vscode-insiders" } },
}

-- Build lookup: TERM_PROGRAM value → Hammerspoon app name
local termProgramToApp = {}
for _, entry in ipairs(terminalApps) do
    for _, tp in ipairs(entry.termPrograms) do
        termProgramToApp[tp] = entry.name
    end
end

local function isVSCode(termProgram)
    return termProgram == "vscode" or termProgram == "vscode-insiders"
end

-- Find the macOS app for a given prompt.
-- TERM_PROGRAM inside tmux is "tmux", so we fall back to
-- finding whichever terminal app is actually running.
local function findTerminalApp(prompt)
    if prompt.TERM_PROGRAM and prompt.TERM_PROGRAM ~= "tmux" then
        local appName = termProgramToApp[prompt.TERM_PROGRAM]
        if appName then
            local app = hs.application.find(appName)
            if app then return app end
        end
    end
    -- Fallback: find any running terminal (covers tmux in any host terminal)
    for _, entry in ipairs(terminalApps) do
        local app = hs.application.find(entry.name)
        if app then return app end
    end
    return nil
end

-----------------------------------------------------------
-- Navigation: activate terminal and focus the right pane
-----------------------------------------------------------

-- Request VS Code extension to focus a terminal by name
local vscodeFocusFile = "/tmp/vscode-focus-terminal"

local function focusVSCodeTerminal(name)
    local f = io.open(vscodeFocusFile, "w")
    if f then
        f:write(name)
        f:close()
    end
end

-- Short label for alert messages, e.g. "TradingBot · main · 014"
local function promptLabel(prompt)
    local parts = {}
    if prompt.PROJECT and prompt.PROJECT ~= "" then
        table.insert(parts, prompt.PROJECT)
    end
    if prompt.BRANCH and prompt.BRANCH ~= "" then
        table.insert(parts, prompt.BRANCH)
    end
    local tty = prompt.TTY_ID or ""
    if tty ~= "" then
        table.insert(parts, tty:gsub("^ttys", ""))
    end
    if #parts == 0 then return "terminal" end
    return table.concat(parts, " · ")
end

-- Navigate to the correct terminal/pane and activate it.
-- Used by notification click and navigateToTerminalPrompt().
local function navigateToPrompt(prompt)
    local termApp = findTerminalApp(prompt)
    if not termApp then return false end

    termApp:activate()

    if isVSCode(prompt.TERM_PROGRAM) then
        -- Extension's terminal.show() opens the panel automatically
        -- Use longer delay to ensure VS Code is activated (especially after notification click)
        hs.timer.doAfter(0.3, function()
            local target = prompt.VSCODE_TERM_TITLE or prompt.TTY_ID or ""
            if target ~= "" then
                focusVSCodeTerminal(target)
            end
        end)
    end

    if prompt.TMUX_PANE then
        hs.timer.doAfter(0.1, function()
            local winTarget = hs.execute(
                tmuxBin .. " display-message -p -t " .. prompt.TMUX_PANE
                .. " '#{session_name}:#{window_index}'", true)
            winTarget = winTarget and winTarget:gsub("%s+$", "") or ""
            if winTarget ~= "" then
                hs.execute(tmuxBin .. " select-window -t " .. winTarget, true)
            end
            hs.execute(tmuxBin .. " select-pane -t " .. prompt.TMUX_PANE, true)
        end)
    end

    return true
end

-- Approve a prompt without focus switch (used by notification button).
-- Similar to approveTerminalPrompt() but uses a specific prompt instead of queue.
local function approveFromPrompt(prompt)
    if prompt.TMUX_PANE then
        hs.execute(tmuxBin .. " send-keys -t " .. prompt.TMUX_PANE .. " Enter", true)
        hs.alert.show("Allowed · " .. promptLabel(prompt), 1)
        return true
    end

    if isVSCode(prompt.TERM_PROGRAM) then
        local target = prompt.VSCODE_TERM_TITLE or prompt.TTY_ID or ""
        if target ~= "" then
            local f = io.open(vscodeFocusFile, "w")
            if f then
                f:write(target .. "\napprove")
                f:close()
            end
            hs.alert.show("Allowed · " .. promptLabel(prompt), 1)
        end
        return true
    end

    -- Bare terminal: need to navigate to approve
    local termApp = findTerminalApp(prompt)
    if termApp and isSimpleYesNoPrompt(termApp) then
        hs.eventtap.keyStroke({}, "return", 0, termApp)
        hs.alert.show("Allowed · " .. promptLabel(prompt), 1)
        return true
    end

    return false
end

-----------------------------------------------------------
-- Approval: send Enter to accept a prompt without focus
-----------------------------------------------------------

-- Read AX content from the focused terminal window
local function readTerminalContent(app)
    local axApp = hs.axuielement.applicationElement(app)
    if not axApp then return "" end

    local windows = axApp:attributeValue("AXWindows") or {}
    if #windows == 0 then return "" end

    local focused = axApp:attributeValue("AXFocusedWindow") or windows[1]
    local val = focused:attributeValue("AXValue")
        or focused:attributeValue("AXDescription")
        or ""

    if val == "" then
        local function extractText(elem, depth)
            if depth > 5 then return "" end
            local t = elem:attributeValue("AXValue") or ""
            local children = elem:attributeValue("AXChildren") or {}
            for _, child in ipairs(children) do
                t = t .. extractText(child, depth + 1)
            end
            return t
        end
        val = extractText(focused, 0)
    end
    return val
end

-- Check if terminal shows a simple "1. Yes / 2. No" prompt (no checkboxes)
local function isSimpleYesNoPrompt(app)
    local val = readTerminalContent(app)
    if val == "" then return false end

    local hasYes = val:find("1%.%s*Yes") or val:find("1%.%s*yes")
    local hasNo = val:find("2%.%s*No") or val:find("2%.%s*no")
    local hasCheckbox = val:find("%[%s*%]") or val:find("%[x%]") or val:find("%[X%]")

    return hasYes and hasNo and not hasCheckbox
end

-- Withdraw the notification tied to a specific breadcrumb
local function withdrawNotificationForPrompt(prompt)
    if not prompt or not prompt._path then return end
    for i, entry in ipairs(_claudeNotifications) do
        if entry.breadcrumbPath == prompt._path then
            entry.notification:withdraw()
            table.remove(_claudeNotifications, i)
            return
        end
    end
end

-- Navigate to the terminal prompt on double-tap Ctrl.
-- (Approve functionality preserved in approveFromPrompt() for future use)
function approveTerminalPrompt()
    local prompt = readBreadcrumb()
    if not prompt.TERM_PROGRAM then return false end

    withdrawNotificationForPrompt(prompt)
    clearBreadcrumb(prompt)

    if navigateToPrompt(prompt) then
        hs.alert.show("Navigating to " .. promptLabel(prompt), 1)
        return true
    end
    return false
end

-----------------------------------------------------------
-- Desktop app: click "Allow once" on macOS notification
-----------------------------------------------------------

local function findAndClickAllow(elem, depth)
    if depth > 8 then return false end

    local role = elem:attributeValue("AXRole") or ""
    local desc = elem:attributeValue("AXDescription") or ""

    if role == "AXButton" and desc:find("Allow") then
        elem:performAction("AXPress")
        return true
    end

    local actions = elem:actionNames()
    if actions then
        for _, action in ipairs(actions) do
            if action:find("Allow") then
                elem:performAction(action)
                return true
            end
        end
    end

    local children = elem:attributeValue("AXChildren")
    if children then
        for _, child in ipairs(children) do
            if findAndClickAllow(child, depth + 1) then return true end
        end
    end
    return false
end

local function approveNotification()
    local app = hs.application.find("com.apple.notificationcenterui")
    if not app then return false end

    local axApp = hs.axuielement.applicationElement(app)
    local windows = axApp:attributeValue("AXWindows") or {}
    if #windows == 0 then return false end

    for _, win in ipairs(windows) do
        if findAndClickAllow(win, 0) then
            hs.alert.show("Allowed", 1)
            return true
        end
    end
    return false
end

-----------------------------------------------------------
-- Navigate to terminal (called from breadcrumb file)
-----------------------------------------------------------

function navigateToTerminalPrompt()
    local prompt = readBreadcrumb()
    if not prompt.TERM_PROGRAM then return false end

    if navigateToPrompt(prompt) then
        hs.alert.show("Navigating to " .. promptLabel(prompt), 1)
        return true
    end
    return false
end

-----------------------------------------------------------
-- Notification from terminal
--
-- Hook scripts drop files into ~/.claude/.notifications/
-- Hammerspoon watches that directory (no IPC overhead).
--
-- Uses hs.notify for reliable click callbacks.
--   Banner click → navigate to the terminal
--   "Allow" button → approve in background (no focus switch)
-- Stop notifications only have banner click (no approve).
-----------------------------------------------------------

_claudeNotifications = {}

-- Load Claude icon once
local claudeIcon = hs.image.imageFromPath("/Applications/Claude.app/Contents/Resources/electron.icns")

function showClaudeNotification(path)
    local f = io.open(path, "r")
    if not f then return end
    local info = {}
    for line in f:lines() do
        local k, v = line:match("^([%w_]+)=(.*)")
        if k and v then info[k] = v end
    end
    f:close()
    os.remove(path)

    local prompt = info

    -- Permission/waiting prompts start with lock or zzz emoji, stop with checkmark
    local isPermission = info.TITLE and not info.TITLE:find("✅")

    local n = hs.notify.new(function(notification)
        local atype = notification:activationType()

        -- Clean up notification reference
        local breadcrumb = nil
        for i, entry in ipairs(_claudeNotifications) do
            if entry.notification == notification then
                breadcrumb = entry.breadcrumbPath
                table.remove(_claudeNotifications, i)
                break
            end
        end

        if atype == hs.notify.activationTypes.actionButtonClicked and isPermission then
            approveFromPrompt(prompt)
            if breadcrumb and breadcrumb ~= "" then
                os.remove(breadcrumb)
            end
        else
            if navigateToPrompt(prompt) then
                hs.alert.show("Navigating to " .. promptLabel(prompt), 1)
            end
        end
    end, {
        title = info.TITLE or "Claude",
        subTitle = info.SUBTITLE or "",
        informativeText = info.MESSAGE or "",
        withdrawAfter = 0,
        hasActionButton = isPermission and true or false,
        actionButtonTitle = "Allow",
        alwaysPresent = true,
    })

    if claudeIcon then
        n:contentImage(claudeIcon)
    end

    table.insert(_claudeNotifications, {
        notification = n,
        breadcrumbPath = prompt._path or prompt.BREADCRUMB_PATH or "",
    })
    n:send()
end



-----------------------------------------------------------
-- Double-tap Ctrl hotkey
-----------------------------------------------------------

local lastCtrlTap = 0
local doubleTapThreshold = 0.75

ctrlTap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(event)
    local flags = event:getFlags()
    local keyCode = event:getKeyCode()

    if keyCode ~= 59 and keyCode ~= 62 then return false end
    if flags.ctrl then return false end

    local now = hs.timer.secondsSinceEpoch()
    if (now - lastCtrlTap) < doubleTapThreshold then
        lastCtrlTap = 0
        if not approveTerminalPrompt() then
            approveNotification()
        end
    else
        lastCtrlTap = now
    end

    return false
end):start()

-----------------------------------------------------------
-- Auto-reload config on save
-----------------------------------------------------------

local function reloadOnLua(files)
    for _, file in pairs(files) do
        if file:sub(-4) == ".lua" then
            hs.reload()
            return
        end
    end
end

hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadOnLua):start()

local initPath = os.getenv("HOME") .. "/.hammerspoon/init.lua"
local realPath = hs.fs.pathToAbsolute(initPath)
if realPath and realPath ~= initPath then
    local sourceDir = realPath:match("(.*/)")
    if sourceDir then
        hs.pathwatcher.new(sourceDir, reloadOnLua):start()
    end
end

hs.alert.show("Hammerspoon loaded")
