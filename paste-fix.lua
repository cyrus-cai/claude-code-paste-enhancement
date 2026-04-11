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

local CHAR_DELAY  = __CHAR_DELAY__          -- seconds between each character (0.001~0.005)
local LINE_DELAY  = CHAR_DELAY * 10         -- newline pause: auto-derived from CHAR_DELAY
local MAX_LINES   = __MAX_LINES__           -- above this = normal paste; 0 = unlimited
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

    -- Build a flat list of actions: each is either a character or a newline
    local actions = {}
    for i, line in ipairs(lines) do
        if i > 1 then
            table.insert(actions, { type = "newline" })
        end
        -- Break line into individual UTF-8 characters
        local pos = 1
        while pos <= #line do
            local byte = string.byte(line, pos)
            local charLen = 1
            if byte >= 0xF0 then charLen = 4
            elseif byte >= 0xE0 then charLen = 3
            elseif byte >= 0xC0 then charLen = 2
            end
            local char = line:sub(pos, pos + charLen - 1)
            table.insert(actions, { type = "char", value = char })
            pos = pos + charLen
        end
    end

    if #actions == 0 then return true end

    typing = true
    local idx = 0
    local nextDelay = CHAR_DELAY

    local function scheduleNext()
        pasteTimer = hs.timer.doAfter(nextDelay, function()
            idx = idx + 1
            if idx > #actions then
                pasteTimer = nil
                typing = false
                return
            end

            local action = actions[idx]
            if action.type == "newline" then
                hs.eventtap.keyStroke({"shift"}, "return")
                nextDelay = LINE_DELAY
            else
                hs.eventtap.keyStrokes(action.value)
                nextDelay = CHAR_DELAY
            end

            scheduleNext()
        end)
    end

    -- Fire the first action immediately
    idx = 1
    local action = actions[idx]
    if action.type == "newline" then
        hs.eventtap.keyStroke({"shift"}, "return")
        nextDelay = LINE_DELAY
    else
        hs.eventtap.keyStrokes(action.value)
        nextDelay = CHAR_DELAY
    end
    scheduleNext()

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
