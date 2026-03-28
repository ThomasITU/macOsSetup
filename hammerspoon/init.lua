-- Hammerspoon configuration
-- Managed by macSetup dotfiles

-----------------------------------------------------------
-- Cmd+Shift+A: Click "Allow once" on Claude notification
-----------------------------------------------------------
hs.hotkey.bind({"cmd", "shift"}, "A", function()
    local script = [[
        tell application "System Events"
            -- Find Claude notifications and click the first action button
            tell process "NotificationCenter"
                set alertGroups to groups of UI element 1 of scroll area 1 of group 1 of window "Notification Center"
                repeat with alertGroup in alertGroups
                    set alertActions to actions of alertGroup
                    repeat with act in alertActions
                        if name of act contains "Allow" then
                            perform act
                            return "allowed"
                        end if
                    end repeat
                    -- Also check buttons inside the notification
                    try
                        set alertButtons to buttons of alertGroup
                        repeat with btn in alertButtons
                            if name of btn contains "Allow" then
                                click btn
                                return "allowed"
                            end if
                        end repeat
                    end try
                end repeat
            end tell
        end tell
        return "no notification found"
    ]]

    hs.osascript.applescript(script)
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
