# Claude Code Paste Enhancement

![macOS](https://img.shields.io/badge/macOS-only-blue?logo=apple)

Bypass Claude Code's `[Pasted text +N lines]` folding on macOS. Works with any terminal.

## The Problem

Claude Code collapses multi-line paste into `[Pasted text +N lines]`. This breaks voice-to-text workflows ([Typeless](https://typeless.so/), etc.) where you need to review transcription before submitting.

**Before** — paste a paragraph, get this:

```
> [Pasted text #1 +3 lines]
```

**After** — same paste, fully visible and editable:

```
> The Adolescence of Technology
  Confronting and Overcoming the Risks of Powerful AI
  January 2026
  There is a scene in the movie version of Carl Sagan's book Contact
  where the main character, an astronomer who has detected the first
  radio signal from an alien civilization, is being considered for the
  role of humanity's representative to meet the aliens. The international
  panel interviewing her asks, "If you could ask [the aliens] just one
  question, what would it be?" Her reply is: "How did you do it? How did
  you evolve, how did you survive this technological adolescence without
  destroying yourself?"
```

```
Normal paste:  Clipboard → bracketed paste → Claude Code folds it
Enhanced:      Clipboard → simulated keystrokes → no fold
```

Related: [anthropics/claude-code#23134](https://github.com/anthropics/claude-code/issues/23134)

## Install

Paste this prompt into Claude Code:

```
Install Hammerspoon via brew if not installed, grant it Accessibility permission,
then fetch paste-fix.lua from https://github.com/cyrus-cai/claude-code-paste-enhancement.

Before writing the config, use the AskUserQuestion tool to ask the user for TWO settings:

1. TICK_INTERVAL (default: 0.025)
   Ask: "How many seconds between each line when type-pasting? (default: 0.025)
   - This controls the delay between typing each line of pasted text.
   - Lower = faster paste, but if lines get dropped or newlines disappear, increase it.
   - Higher = slower but more reliable.
   - Tested range: 0.025 (fast) ~ 0.1 (conservative). Start with 0.025 if unsure."

2. MAX_LINES (default: 50)
   Ask: "Max lines to type-paste? Above this, falls back to normal paste. (default: 50)
   - Enter a number (e.g. 50), or 0 for unlimited (always type-paste, never fold).
   - Large values may cause a noticeable delay while pasting."

Replace __TICK_INTERVAL__ and __MAX_LINES__ in paste-fix.lua with the user's answers.
Then append the result to ~/.hammerspoon/init.lua (don't overwrite existing config).
Detect my terminal's bundle ID and add it to TERMINAL_APPS.
Reload Hammerspoon config and confirm the reload was successful.
```

## Keybindings

**Cmd+V** / **Cmd+Shift+V** in terminal apps → type-paste (no fold)

## Credits

Inspired by [claude-code-type-from-clipboard](https://github.com/Looking4OffSwitch/claude-code-type-from-clipboard).

## License

MIT
