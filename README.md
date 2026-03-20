# Personal Claude Code Plugins

A collection of personal plugins for [Claude Code](https://claude.ai/code).

## Plugins

| Plugin | Description |
|--------|-------------|
| [statusline](./statusline) | Rich statusline with context bar, git status, session stats, and account info |

## Installation

### Add Marketplace

Add this marketplace to your `.claude/settings.json` or `.claude/settings.local.json`:

```json
{
  "extraKnownMarketplaces": {
    "alanbem": {
      "source": {
        "source": "github",
        "repo": "alanbem/claude-marketplace"
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
