---
description: Set up the rich statusline with context bar, git status, session stats, and Nerd Font icons
allowed-tools: ["Bash", "Read", "Write", "Edit", "AskUserQuestion"]
---

# Statusline Setup

Configure the Claude Code statusline to use the rich statusline provided by this plugin.

## Steps

### Step 1: Check Nerd Font Support

Use AskUserQuestion to check if the user's terminal supports Nerd Font icons.

First, use Bash to print test glyphs:

```bash
echo -e "Nerd Font test: \xef\x81\xa9 \xef\x83\xa7 \xef\x83\x87 \xef\x80\x97 \xee\x9c\xa5 \xef\x80\x95 \xef\x80\x87"
```

Then ask the user:

- Header: "Nerd Font Check"
- Question: "Do you see 7 distinct icons above, or boxes/question marks?"
- Options:
  - "I see icons" → proceed to Step 2
  - "I see boxes or question marks" → show install instructions, then ask to continue or abort

**If boxes**, show these instructions:

```
Your terminal font doesn't include Nerd Font glyphs. The statusline will work but icons will show as boxes.

To fix this, install a Nerd Font:
- https://www.nerdfonts.com/font-downloads
- Popular choices: JetBrainsMono Nerd Font, FiraCode Nerd Font, Hack Nerd Font

After installing, set it as your terminal font in your terminal emulator settings.
```

Then ask:
- "Continue setup anyway (icons will show as boxes)?"
- "Abort setup"

If abort, stop here.

### Step 2: Check Existing Configuration

Read both `.claude/settings.json` and `.claude/settings.local.json` in the current working directory. Check if either already has a `statusLine` key configured.

If a `statusLine` config already exists in either file, ask the user:

- Header: "Existing Statusline Found"
- Question: "A statusline is already configured in [filename]. What would you like to do?"
- Options:
  - "Overwrite with this plugin's statusline"
  - "Skip — keep current configuration"

If skip, stop here.

### Step 3: Choose Settings File

Ask the user which settings file to use:

- Header: "Settings File"
- Question: "Where should the statusline be configured?"
- Options:
  - "settings.json — shared with team (checked into repo)"
  - "settings.local.json — personal only (not checked in)"

### Step 4: Write Configuration

Read the chosen settings file (create it if it doesn't exist — use `{}` as starting content).

Add or update the `statusLine` key in the JSON:

```json
{
  "statusLine": {
    "type": "command",
    "command": "${CLAUDE_PLUGIN_ROOT}/scripts/statusline.sh"
  }
}
```

Use the Edit tool to add this key to the existing JSON. If the file doesn't exist yet, create it with Write tool containing just the statusLine config wrapped in `{}`.

IMPORTANT: Preserve all existing settings in the file — only add/update the `statusLine` key.

### Step 5: Confirm

Tell the user:

```
Statusline configured in [filename].

It will activate on your next Claude Code session. Features:
- Context window bar with color-coded zones (green → orange → red → critical)
- Model name and version
- Account email
- Git branch with working tree diff counts
- Session duration, API time, and lines changed
- Current project folder

To remove, delete the "statusLine" key from [filename].
```
