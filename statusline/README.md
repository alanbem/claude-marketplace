# Statusline Plugin for Claude Code

A rich, dark-themed statusline for Claude Code with context visualization, git status, session stats, and account info.

## Features

- Context window bar with color-coded zones (green → orange → red → critical)
- Model name and version
- Account email (read from Claude config)
- Git branch with working tree diff counts
- Session duration, API time, and lines changed
- Current project folder with relative path
- Nerd Font icons throughout
- Dimmed numbers for clean visual hierarchy

## Requirements

- A terminal font with [Nerd Font](https://www.nerdfonts.com/) glyphs (e.g., JetBrainsMono Nerd Font, FiraCode Nerd Font)
- `jq` installed for JSON parsing
- `bash` shell

## Setup

Run the setup command in Claude Code:

```
/statusline-setup
```

The command will:
1. Check if your terminal font supports Nerd Font icons
2. Let you choose between shared (`settings.json`) or personal (`settings.local.json`) configuration
3. Configure the statusline automatically

## Manual Setup

Add to your `.claude/settings.json` or `.claude/settings.local.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "${CLAUDE_PLUGIN_ROOT}/scripts/statusline.sh"
  }
}
```

## License

MIT
