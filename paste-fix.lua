-- =============================================================
-- Claude Code Paste Enhancement: Bypass terminal bracketed paste detection
-- https://github.com/anthropics/claude-code/issues/23134
--
-- In terminal apps: Cmd+V types clipboard line-by-line (preserving newlines)
-- Cmd+Shift+V: force type-paste in any app
-- Large pastes (>MAX_LINES) fall through to normal paste (Claude Code folds)
-- =============================================================
local TERMINAL_APPS = {
    ["com.mitchellh.ghostty"] = true,
    ["com.googlecode.iterm2"] = true,
    ["com.apple.Terminal"] = true,
    ["dev.warp.Warp-Stable"] = true,
    ["com.todesktop.230313mzl4w4u92"] = true,  -- Cursor
    ["com.jetbrains.intellij"] = true,         -- IntelliJ IDEA
    -- Add your terminal's bundle ID here
}

local TICK_INTERVAL = __TICK_INTERVAL__  -- seconds between lines
local MAX_LINES = __MAX_LINES__          -- above this = normal paste; 0 = unlimited
local typing = false
local pasteTimer = nil

local function typeClipboard()
    if typing then return true end
    local text = hs.pasteboard.getContents()
    if not text or #text == 0 then return end

    text = text:gsub("\r\n", "\n"):gsub("\r", "\n")

    local lines = {}
    for line in text:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
    end
    if lines[#lines] == "" then table.remove(lines) end

    -- Large pastes: let terminal handle it normally (0 = unlimited)
    if MAX_LINES > 0 and #lines > MAX_LINES then
        return false
    end

    typing = true
    local idx = 0

    pasteTimer = hs.timer.doEvery(TICK_INTERVAL, function()
        idx = idx + 1
        if idx > #lines then
            if pasteTimer then
                pasteTimer:stop()
                pasteTimer = nil
            end
            typing = false
            return
        end

        if idx > 1 then
            hs.eventtap.keyStroke({"shift"}, "return")
        end

        local line = lines[idx]
        if #line > 0 then
            hs.eventtap.keyStrokes(line)
        end
    end)
    return true
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
            local intercepted = typeClipboard()
            if intercepted == false then
                return false  -- large paste, let terminal handle it
            end
            return true  -- suppress original Cmd+V
        end
    end
    return false
end)
terminalPasteWatcher:start()
