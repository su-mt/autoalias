# autoalias

Automatically create shell aliases based on your typos and corrections.

## How it works

When you mistype a command and then correct it, autoalias tracks the pattern. After a configurable threshold (default: 3 times), it either creates an alias automatically or asks for confirmation.

Example:
```bash
$ gt status
zsh: command not found: gt
$ git status
# After 3 repetitions of this pattern:
# Suggestion: create alias 'gt' -> 'git' (used 3 times)
# Create this alias? [y/n]:
```

## Installation

```bash
./autoalias.py install
```

This will:
- Create `~/.autoalias/` directory with configuration files
- Add hooks to your `.bashrc` or `.zshrc`
- Add autoalias to your PATH

Restart your terminal or run `source ~/.bashrc` (or `~/.zshrc`).

## Configuration

Edit `~/.autoalias/config.json`:

```json
{
  "enabled": true,
  "threshold": 3,
  "mode": "confirm",
  "notify": true
}
```

- `enabled`: Enable or disable autoalias
- `threshold`: Number of repetitions before creating alias
- `mode`: "confirm" (ask) or "auto" (create automatically)
- `notify`: Show notification when alias is created

## Commands

```bash
autoalias stats         # Show candidates for aliases
autoalias list          # Show created aliases
autoalias start         # Enable autoalias
autoalias stop          # Disable autoalias
autoalias reset         # Clear statistics
autoalias remove <name> # Remove an alias
autoalias ignore list   # Show ignored aliases/commands
autoalias ignore remove <item>  # Remove from ignore list
```

## How ignore works

When you decline to create an alias (answer 'n' in confirm mode), it's added to the ignore list. Statistics continue to accumulate, but the alias won't be suggested again unless you remove it from the ignore list.

## Requirements

- Python 3.6+
- bash or zsh shell

## Files

- `~/.autoalias/config.json` - Configuration
- `~/.autoalias/stats.json` - Tracked patterns
- `~/.autoalias/ignore.json` - Ignored aliases and commands
- `~/.autoalias/aliases.sh` - Created aliases
