#!/usr/bin/env python3
"""
autoalias - Automatic alias creation based on command history
"""

import json
import os
import sys
import argparse
import subprocess
from pathlib import Path
from typing import Dict, List, Optional


# Constants
AUTOALIAS_DIR = Path.home() / ".autoalias"
CONFIG_FILE = AUTOALIAS_DIR / "config.json"
STATS_FILE = AUTOALIAS_DIR / "stats.json"
IGNORE_FILE = AUTOALIAS_DIR / "ignore.json"
ALIASES_FILE = AUTOALIAS_DIR / "aliases.sh"


# Default configurations
DEFAULT_CONFIG = {
    "enabled": True,
    "threshold": 3,
    "mode": "confirm",
    "notify": True
}

DEFAULT_STATS = {}

DEFAULT_IGNORE = {
    "ignore_aliases": [],
    "ignore_commands": []
}


class ConfigManager:
    """Manages configuration files"""
    
    @staticmethod
    def load_json(filepath: Path, default: dict) -> dict:
        """Load JSON file or return default if not exists"""
        if not filepath.exists():
            return default.copy()
        try:
            with open(filepath, 'r') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError) as e:
            print(f"Error reading {filepath}: {e}", file=sys.stderr)
            return default.copy()
    
    @staticmethod
    def save_json(filepath: Path, data: dict):
        """Save data to JSON file"""
        filepath.parent.mkdir(parents=True, exist_ok=True)
        try:
            with open(filepath, 'w') as f:
                json.dump(data, f, indent=2)
        except IOError as e:
            print(f"Error writing {filepath}: {e}", file=sys.stderr)
    
    @staticmethod
    def get_config() -> dict:
        """Get current config"""
        return ConfigManager.load_json(CONFIG_FILE, DEFAULT_CONFIG)
    
    @staticmethod
    def save_config(config: dict):
        """Save config"""
        ConfigManager.save_json(CONFIG_FILE, config)
    
    @staticmethod
    def get_stats() -> dict:
        """Get statistics"""
        return ConfigManager.load_json(STATS_FILE, DEFAULT_STATS)
    
    @staticmethod
    def save_stats(stats: dict):
        """Save statistics"""
        ConfigManager.save_json(STATS_FILE, stats)
    
    @staticmethod
    def get_ignore() -> dict:
        """Get ignore list"""
        return ConfigManager.load_json(IGNORE_FILE, DEFAULT_IGNORE)
    
    @staticmethod
    def save_ignore(ignore: dict):
        """Save ignore list"""
        ConfigManager.save_json(IGNORE_FILE, ignore)


class AliasManager:
    """Manages alias creation and statistics"""
    
    @staticmethod
    def record_error(wrong_cmd: str):
        """Record a command not found error"""
        # Store last error in a temporary way (will be handled by shell hook)
        pass
    
    @staticmethod
    def record_correction(wrong_cmd: str, correct_cmd: str):
        """Record a correction and update statistics"""
        config = ConfigManager.get_config()
        
        if not config.get("enabled", True):
            return
        
        stats = ConfigManager.get_stats()
        
        # Update stats (always, even if ignored)
        if wrong_cmd not in stats:
            stats[wrong_cmd] = {}
        
        if correct_cmd not in stats[wrong_cmd]:
            stats[wrong_cmd][correct_cmd] = 0
        
        stats[wrong_cmd][correct_cmd] += 1
        ConfigManager.save_stats(stats)
        
        # Check if threshold reached
        count = stats[wrong_cmd][correct_cmd]
        threshold = config.get("threshold", 3)
        
        if count >= threshold:
            # Check ignore list before creating alias
            ignore = ConfigManager.get_ignore()
            if wrong_cmd in ignore.get("ignore_aliases", []):
                return
            if correct_cmd in ignore.get("ignore_commands", []):
                return
            
            AliasManager.handle_alias_creation(wrong_cmd, correct_cmd, count)
    
    @staticmethod
    def handle_alias_creation(alias: str, command: str, count: int):
        """Handle alias creation when threshold is reached"""
        config = ConfigManager.get_config()
        mode = config.get("mode", "confirm")
        
        if mode == "confirm":
            # Ask user for confirmation using /dev/tty
            try:
                print(f"\n⚠ Suggestion: create alias '{alias}' → '{command}' (used {count} times)")
                with open('/dev/tty', 'r') as tty:
                    sys.stdout.write("Create this alias? [y/n]: ")
                    sys.stdout.flush()
                    response = tty.readline().strip()
                
                if response.lower() != 'y':
                    # Add to ignore list
                    ignore = ConfigManager.get_ignore()
                    if alias not in ignore["ignore_aliases"]:
                        ignore["ignore_aliases"].append(alias)
                        ConfigManager.save_ignore(ignore)
                    print(f"Alias '{alias}' added to ignore list")
                    return
            except (IOError, OSError):
                # If can't read from tty, default to auto mode
                pass
        
        # Create alias
        AliasManager.create_alias(alias, command)
        
        # Notify if enabled
        if config.get("notify", True):
            print(f"✓ Added alias: {alias} → {command}")
    
    @staticmethod
    def create_alias(alias: str, command: str):
        """Create an alias in aliases.sh"""
        alias_line = f"alias {alias}='{command}'\n"
        
        # Check if alias already exists
        if ALIASES_FILE.exists():
            with open(ALIASES_FILE, 'r') as f:
                if alias_line in f.read():
                    return
        
        # Append alias
        with open(ALIASES_FILE, 'a') as f:
            f.write(alias_line)
        
        # Source the file in current shell (will be handled by shell hook)
    
    @staticmethod
    def get_aliases() -> List[tuple]:
        """Get list of created aliases"""
        if not ALIASES_FILE.exists():
            return []
        
        aliases = []
        with open(ALIASES_FILE, 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith('alias '):
                    # Parse: alias gt='git'
                    parts = line[6:].split('=', 1)
                    if len(parts) == 2:
                        alias_name = parts[0].strip()
                        command = parts[1].strip().strip("'\"")
                        aliases.append((alias_name, command))
        return aliases
    
    @staticmethod
    def remove_alias(alias: str) -> bool:
        """Remove an alias from aliases.sh"""
        if not ALIASES_FILE.exists():
            return False
        
        with open(ALIASES_FILE, 'r') as f:
            lines = f.readlines()
        
        new_lines = [line for line in lines if not line.strip().startswith(f'alias {alias}=')]
        
        if len(new_lines) == len(lines):
            return False
        
        with open(ALIASES_FILE, 'w') as f:
            f.writelines(new_lines)
        
        return True


# CLI Commands

def cmd_install(args):
    """Install autoalias"""
    script_dir = Path(__file__).parent
    install_script = script_dir / "install.sh"
    
    if not install_script.exists():
        print(f"Error: install.sh not found in {script_dir}", file=sys.stderr)
        sys.exit(1)
    
    subprocess.run(["bash", str(install_script)])


def cmd_start(args):
    """Enable autoalias"""
    config = ConfigManager.get_config()
    config["enabled"] = True
    ConfigManager.save_config(config)
    print("✓ autoalias enabled")


def cmd_stop(args):
    """Disable autoalias"""
    config = ConfigManager.get_config()
    config["enabled"] = False
    ConfigManager.save_config(config)
    print("✓ autoalias disabled")


def cmd_stats(args):
    """Show statistics (candidates for aliases)"""
    stats = ConfigManager.get_stats()
    
    if not stats:
        print("No statistics yet")
        return
    
    print("Current candidates:")
    print("-" * 50)
    for wrong_cmd, corrections in sorted(stats.items()):
        for correct_cmd, count in sorted(corrections.items(), key=lambda x: x[1], reverse=True):
            print(f"  {wrong_cmd} → {correct_cmd}: {count} times")


def cmd_list(args):
    """Show created aliases"""
    aliases = AliasManager.get_aliases()
    
    if not aliases:
        print("No aliases created yet")
        return
    
    print("Created aliases:")
    print("-" * 50)
    for alias, command in aliases:
        print(f"  {alias} → {command}")


def cmd_ignore(args):
    """Manage ignore list"""
    if args.ignore_cmd == "list":
        ignore = ConfigManager.get_ignore()
        print("Ignored aliases:")
        for alias in ignore.get("ignore_aliases", []):
            print(f"  {alias}")
        print("\nIgnored commands:")
        for cmd in ignore.get("ignore_commands", []):
            print(f"  {cmd}")
    
    elif args.ignore_cmd == "remove":
        if not args.item:
            print("Error: specify item to remove", file=sys.stderr)
            sys.exit(1)
        
        ignore = ConfigManager.get_ignore()
        removed = False
        
        if args.item in ignore["ignore_aliases"]:
            ignore["ignore_aliases"].remove(args.item)
            removed = True
        
        if args.item in ignore["ignore_commands"]:
            ignore["ignore_commands"].remove(args.item)
            removed = True
        
        if removed:
            ConfigManager.save_ignore(ignore)
            print(f"✓ Removed '{args.item}' from ignore list")
        else:
            print(f"'{args.item}' not found in ignore list")


def cmd_reset(args):
    """Reset statistics"""
    ConfigManager.save_stats({})
    print("✓ Statistics reset")


def cmd_remove(args):
    """Remove an alias"""
    if AliasManager.remove_alias(args.alias):
        print(f"✓ Removed alias: {args.alias}")
    else:
        print(f"Alias '{args.alias}' not found")


def cmd_record(args):
    """Record a correction (called by shell hook)"""
    AliasManager.record_correction(args.wrong, args.correct)


def main():
    parser = argparse.ArgumentParser(description="autoalias - Automatic alias creation")
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # install
    subparsers.add_parser('install', help='Install autoalias')
    
    # start/stop
    subparsers.add_parser('start', help='Enable autoalias')
    subparsers.add_parser('stop', help='Disable autoalias')
    
    # stats/list
    subparsers.add_parser('stats', help='Show statistics (candidates)')
    subparsers.add_parser('list', help='Show created aliases')
    
    # ignore
    ignore_parser = subparsers.add_parser('ignore', help='Manage ignore list')
    ignore_parser.add_argument('ignore_cmd', choices=['list', 'remove'], help='Ignore command')
    ignore_parser.add_argument('item', nargs='?', help='Item to remove')
    
    # reset
    subparsers.add_parser('reset', help='Reset statistics')
    
    # remove
    remove_parser = subparsers.add_parser('remove', help='Remove an alias')
    remove_parser.add_argument('alias', help='Alias to remove')
    
    # record (internal, called by shell hook)
    record_parser = subparsers.add_parser('record', help=argparse.SUPPRESS)
    record_parser.add_argument('wrong', help='Wrong command')
    record_parser.add_argument('correct', help='Correct command')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    # Dispatch commands
    commands = {
        'install': cmd_install,
        'start': cmd_start,
        'stop': cmd_stop,
        'stats': cmd_stats,
        'list': cmd_list,
        'ignore': cmd_ignore,
        'reset': cmd_reset,
        'remove': cmd_remove,
        'record': cmd_record,
    }
    
    commands[args.command](args)


if __name__ == '__main__':
    main()