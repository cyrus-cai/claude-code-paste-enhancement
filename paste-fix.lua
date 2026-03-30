-- =============================================================
-- Claude Code Paste Enhancement: Bypass terminal bracketed paste detection
-- https://github.com/anthropics/claude-code/issues/23134
--
-- In terminal apps: Cmd+V auto-converts paste to keystrokes (no fold)
-- Cmd+Shift+V: force type-paste in any app
-- =============================================================
local TERMINAL_APPS = {
    ["com.mitchellh.ghostty"] = true,
    ["com.googlecode.iterm2"] = true,
    ["com.apple.Terminal"] = true,
    ["dev.warp.Warp-Stable"] = true,
    ["com.todesktop.230313mzl4w4u92"] = true,  -- Cursor
    -- Add your terminal's bundle ID here
}

local function typeClipboard()
    local text = hs.pasteboard.getContents()
    if not text or #text == 0 then return end
    -- Replace newlines with spaces to avoid triggering submit in Claude Code
    -- and prevent keyStrokes from producing "aa" on newline chars
    text = text:gsub("\r\n", " "):gsub("\n", " "):gsub("\r", " ")
    hs.eventtap.keyStrokes(text)
end

-- Cmd+Shift+V: force type-paste in any app
hs.hotkey.bind({"cmd", "shift"}, "V", typeClipboard)

-- Cmd+V in terminal apps: intercept and type instead of paste
terminalPasteWatcher = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    local flags = event:getFlags()
    local keyCode = event:getKeyCode()
    -- Cmd+V = keyCode 9, only cmd flag
    if keyCode == 9 and flags.cmd and not flags.shift and not flags.alt and not flags.ctrl then
        local app = hs.application.frontmostApplication()
        if app and TERMINAL_APPS[app:bundleID()] then
            typeClipboard()
            return true  -- suppress original Cmd+V
        end
    end
    return false
end)
terminalPasteWatcher:start()
