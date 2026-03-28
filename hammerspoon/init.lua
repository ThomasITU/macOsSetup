-- Hammerspoon configuration
-- Managed by macSetup dotfiles

-- Enable CLI (hs command)
require("hs.ipc")

-----------------------------------------------------------
-- Cmd+Shift+A: Click "Allow once" on Claude notification
-----------------------------------------------------------

-- Recursively search AX tree for the "Allow once" button
local function findAndClickAllow(elem, depth)
    if depth > 8 then return false end

    local role = elem:attributeValue("AXRole") or ""
    local desc = elem:attributeValue("AXDescription") or ""

    -- The "Allow once" button has desc="Allow once" and supports AXPress
    if role == "AXButton" and desc:find("Allow") then
        elem:performAction("AXPress")
        return true
    end

    -- Also check for named actions on groups (macOS puts actions on the notification group)
    local actions = elem:actionNames()
    if actions then
        for _, action in ipairs(actions) do
            if action:find("Allow") then
                elem:performAction(action)
                return true
            end
        end
    end

    -- Recurse into children
    local children = elem:attributeValue("AXChildren")
    if children then
        for _, child in ipairs(children) do
            if findAndClickAllow(child, depth + 1) then
                return true
            end
        end
    end

    return false
end

hs.hotkey.bind({"cmd", "shift"}, "A", function()
    -- macOS 15: notifications are under com.apple.notificationcenterui
    local app = hs.application.find("com.apple.notificationcenterui")
    if not app then
        hs.alert.show("No NotificationCenter", 1)
        return
    end

    local axApp = hs.axuielement.applicationElement(app)
    local windows = axApp:attributeValue("AXWindows") or {}

    if #windows == 0 then
        hs.alert.show("No notifications visible", 1)
        return
    end

    for _, win in ipairs(windows) do
        if findAndClickAllow(win, 0) then
            hs.alert.show("Allowed", 1)
            return
        end
    end

    hs.alert.show("No Allow button found", 1)
end)

-----------------------------------------------------------
-- Auto-reload config on save
-----------------------------------------------------------
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
    for _, file in pairs(files) do
        if file:sub(-4) == ".lua" then
            hs.reload()
            return
        end
    end
end):start()

hs.alert.show("Hammerspoon loaded")
