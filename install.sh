#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing autoalias...${NC}"

# Determine home directory
if [ -z "$HOME" ]; then
    echo -e "${RED}Error: HOME environment variable not set${NC}"
    exit 1
fi

# Create autoalias directory
AUTOALIAS_DIR="$HOME/.autoalias"
echo "Creating directory: $AUTOALIAS_DIR"
mkdir -p "$AUTOALIAS_DIR"

# Get script directory (where autoalias.py is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Initialize config.json
CONFIG_FILE="$AUTOALIAS_DIR/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating config.json..."
    cat > "$CONFIG_FILE" << 'EOF'
{
  "enabled": true,
  "threshold": 3,
  "mode": "confirm",
  "notify": true
}
EOF
fi

# Initialize stats.json
STATS_FILE="$AUTOALIAS_DIR/stats.json"
if [ ! -f "$STATS_FILE" ]; then
    echo "Creating stats.json..."
    echo '{}' > "$STATS_FILE"
fi

# Initialize ignore.json
IGNORE_FILE="$AUTOALIAS_DIR/ignore.json"
if [ ! -f "$IGNORE_FILE" ]; then
    echo "Creating ignore.json..."
    cat > "$IGNORE_FILE" << 'EOF'
{
  "ignore_aliases": [],
  "ignore_commands": []
}
EOF
fi

# Initialize aliases.sh
ALIASES_FILE="$AUTOALIAS_DIR/aliases.sh"
if [ ! -f "$ALIASES_FILE" ]; then
    echo "Creating aliases.sh..."
    touch "$ALIASES_FILE"
fi

# Copy hooks
echo "Copying hooks..."
cp "$SCRIPT_DIR/hooks/bash_hook.sh" "$AUTOALIAS_DIR/"
cp "$SCRIPT_DIR/hooks/zsh_hook.sh" "$AUTOALIAS_DIR/"

# Detect shell
DETECTED_SHELL=$(basename "$SHELL")
echo -e "Detected shell: ${YELLOW}$DETECTED_SHELL${NC}"

# Determine RC file
RC_FILE=""
HOOK_FILE=""

case "$DETECTED_SHELL" in
    zsh)
        RC_FILE="$HOME/.zshrc"
        HOOK_FILE="$AUTOALIAS_DIR/zsh_hook.sh"
        ;;
    bash)
        RC_FILE="$HOME/.bashrc"
        HOOK_FILE="$AUTOALIAS_DIR/bash_hook.sh"
        ;;
    *)
        echo -e "${YELLOW}Warning: Unsupported shell '$DETECTED_SHELL'${NC}"
        echo "Supported shells: bash, zsh"
        echo "You'll need to manually source the hooks"
        exit 0
        ;;
esac

# Check if RC file exists
if [ ! -f "$RC_FILE" ]; then
    echo "Creating $RC_FILE..."
    touch "$RC_FILE"
fi

AUTOALIAS_PATH="$SCRIPT_DIR"

if ! grep -Fq "$AUTOALIAS_PATH" "$RC_FILE"; then
    {
        echo ""
        echo "# autoalias PATH"
        echo "export PATH=\"\$PATH:$AUTOALIAS_PATH\""
    } >> "$RC_FILE"
    echo -e "${GREEN}✓${NC} Added autoalias to PATH"
else
    echo -e "${YELLOW}✓${NC} autoalias already in PATH"
fi

# Add hook source
HOOK_LINE="source $HOOK_FILE"
if ! grep -Fq "$HOOK_LINE" "$RC_FILE"; then
    echo "" >> "$RC_FILE"
    echo "# autoalias hook" >> "$RC_FILE"
    echo "$HOOK_LINE" >> "$RC_FILE"
    echo -e "${GREEN}✓${NC} Added autoalias hook to $RC_FILE"
else
    echo -e "${YELLOW}✓${NC} autoalias hook already in $RC_FILE"
fi

# Make autoalias.py executable
chmod +x "$SCRIPT_DIR/autoalias.py"

# Make symlink
ln -s autoalias.py autoalias

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "To start using autoalias:"
echo "  1. Restart your terminal or run: source $RC_FILE"
echo "  2. Use autoalias stats to see statistics"
echo "  3. Use autoalias list to see created aliases"
echo "  4. Use autoalias stop to disable temporarily"
echo ""
echo "Configuration:"
echo "  - Config: $CONFIG_FILE"
echo -e "  - Edit threshold, mode confirm/auto, and other settings "




