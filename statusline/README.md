# Statusline Plugin for Claude Code

A rich, dark-themed statusline for Claude Code with context visualization, git status, session stats, CLI auth indicators, and Nerd Font icons.

## What It Shows

The statusline is a single line split into sections by `│` separators. Each section has a Nerd Font icon in Anthropic's brand color (warm tan/sienna).

### Version & Model

Shows the Claude Code version and the active model name (e.g., `Opus`, `Sonnet`). The context qualifier like "(1M context)" is stripped for brevity.

### Account

Your Claude account email, read from `~/.claude/.claude.json`. The `@` symbol is dimmed to visually separate the username from the domain.

### Context Window

A 20-dot progress bar showing how much of the context window is used. Each dot represents 5% of the window.

**Color zones** are percentage-based, so they work correctly at any context window size:
- **Green** (0–30%) — comfortable headroom
- **Orange** (30–40%) — approaching limits
- **Red** (40–80%) — high usage
- **Critical (bright red)** (80–100%) — near capacity

Unfilled dots use a very faint version of their zone's color, so you can see where each zone starts before you reach it. The percentage number matches the color of the last filled dot.

Token counts are shown as `used/total` with numbers dimmed and unit suffixes (`k`, `M`) at normal brightness for visual hierarchy.

### Session Stats

Three metrics separated by `·` dots:
- **Duration** — total session wall time
- **API time** — time spent waiting on API calls
- **Lines changed** — total lines added (green `✚`) and removed (red `−`) across the session

Durations use progressive formatting: `<1m` → `5m` → `1h30m` → `1d2h15m`. Numbers are dimmed, unit letters are normal brightness.

### Git

**Double branch icon** — two branch glyphs side by side indicate worktree awareness:
- **Both bright orange** — you're in a git worktree
- **First bright, second dimmed** — normal repo (the dimmed second icon subtly hints at worktree capability)
- **Both dimmed gray** — not inside a git repository

Worktree detection works two ways: via Claude Code's native worktree field, and as a fallback by checking `git rev-parse --git-dir` for a `/worktrees/<name>` path.

**Ahead/behind remote** — shown after the branch name as arrows:
- `↑2` (dim green) — commits ahead of remote
- `↓1` (dim red) — commits behind remote
- Zeros shown in dimmed white when there's nothing to push/pull

**File stats** — changes at the file level compared to HEAD:
- `+1` (dim green) — new files added
- `~3` (dim orange) — files modified
- `−0` (dim red) — files deleted
- `?2` (dimmed white) — untracked files (not yet tracked by git)

**Line stats** — insertions and deletions compared to HEAD:
- `+142` (dim green) — lines added
- `−37` (dim red) — lines removed

### CLI Auth Status

Shows authentication state for command-line tools. Each tool has a Nerd Font CLI icon and a label with three possible states:

| State | Color | Meaning |
|-------|-------|---------|
| **Dimmed gray** | `rgb(60,60,60)` | CLI tool is not installed |
| **Dim red** | `rgb(120,70,70)` | Installed but not authenticated |
| **Dim green** | `rgb(70,100,70)` | Installed and authenticated |

Currently tracked tools:
- **aws** — checks `aws configure list` for a configured access key
- **gh** — runs `gh auth status` to validate the GitHub token
- **acli** — runs `acli jira auth status` (Atlassian CLI)
- **gws** — checks `gws auth status` JSON output for `"token_valid": true` (Google Workspace CLI)

### Project Folder

Shows the project directory name followed by the relative path from the project root to your current working directory. If you're at the project root, it just shows `project-name/`. If you're deeper, the subdirectory path is dimmed — e.g., `my-project/`**`src/components`** — so the project name stands out and the nested path is secondary context.

## Requirements

- A terminal font with [Nerd Font](https://www.nerdfonts.com/) glyphs (e.g., JetBrainsMono Nerd Font, FiraCode Nerd Font)
- `jq` for JSON parsing
- `bash` shell (compatible with macOS bash 3.2 — uses `\x` byte sequences instead of `\u` escapes)

## Setup

Run the setup command in Claude Code:

```
/statusline:setup
```

The command will:
1. Check if your terminal font supports Nerd Font icons
2. Detect any existing statusline configuration
3. Let you choose between shared (`settings.json`) or personal (`settings.local.json`) configuration
4. Configure the statusline automatically

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
