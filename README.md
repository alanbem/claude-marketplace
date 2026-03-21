# Personal Claude Code Plugins

A collection of personal plugins for [Claude Code](https://claude.ai/code).

## Plugins

| Plugin | Description |
|--------|-------------|
| [statusline](./statusline) | Rich statusline with context bar, git file/line stats, ahead/behind, worktree detection, CLI auth indicators, and session stats |

## Installation

### Add Marketplace

Add this marketplace to your `.claude/settings.json` or `.claude/settings.local.json`:

```json
{
  "extraKnownMarketplaces": {
    "alanbem": {
      "source": {
        "source": "github",
        "repo": "alanbem/claude-plugins"
      }
    }
  }
}
```

### Install Plugins

Once the marketplace is registered, install plugins via Claude Code:

```
/plugin install statusline@alanbem
```

Or browse available plugins:

```
/plugin > Discover
```

## License

See each plugin's LICENSE file.
