#!/bin/zsh
# Export current terminal configuration to this repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
cd "$SCRIPT_DIR"

HOSTNAME=$(hostname -s)
USERNAME=$(whoami)
DATE=$(date +"%Y-%m-%d %H:%M")

echo "=== Exporting terminal configuration ==="
echo ""
echo "Computer: $HOSTNAME"
echo "User: $USERNAME"
echo ""
echo "This will export your ~/.zshrc and ~/.p10k.zsh to this repository."
echo ""
echo "Files in this repo that will be overwritten:"
echo "  - $SCRIPT_DIR/.zshrc.full"
echo "  - $SCRIPT_DIR/.p10k.zsh"
echo "  - $SCRIPT_DIR/plugins.list"
echo "  - $SCRIPT_DIR/brew-packages.list"
echo ""
echo "Your actual ~/.zshrc and ~/.p10k.zsh will NOT be modified."
echo ""
read "REPLY?Continue? (y/N) "
REPLY=${REPLY:-N}
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Export cancelled."
    exit 0
fi
echo ""

# Clean up old split files (no longer used)
echo "✓ Cleaning up old config files"
rm -f .zshrc.full .zshrc.base .zshrc.personal
echo ""

# Export .zshrc
if [ -f ~/.zshrc ]; then
    echo "✓ Exporting ~/.zshrc"
    cp ~/.zshrc .zshrc.full
else
    echo "✗ ~/.zshrc not found"
    exit 1
fi

# Export .p10k.zsh
if [ -f ~/.p10k.zsh ]; then
    echo "✓ Exporting ~/.p10k.zsh"
    cp ~/.p10k.zsh .p10k.zsh
else
    echo "✗ ~/.p10k.zsh not found"
    exit 1
fi

# Export custom plugin list
echo "✓ Scanning custom plugins"
if [ -d ~/.oh-my-zsh/custom/plugins ]; then
    find ~/.oh-my-zsh/custom/plugins -maxdepth 1 -type d -not -name "plugins" -not -name "example" | \
        xargs -I {} basename {} > plugins.list.tmp

    grep -v '^$' plugins.list.tmp > plugins.list || touch plugins.list
    rm plugins.list.tmp

    echo "  Found $(wc -l < plugins.list | tr -d ' ') custom plugins"
else
    echo "  No custom plugins directory found"
    touch plugins.list
fi

# Write brew package dependencies (static list, not scanned from system)
# These are packages required by the zsh config:
#   powerlevel10k - prompt theme (sourced in zshrc)
#   fzf           - fuzzy finder (fzf --zsh integration + fzf-tab plugin)
#   asdf          - version manager (paths, commands, plugin)
#   coreutils     - GNU utilities (gnubin in PATH)
#   tree          - directory tree (used by ls plugin)
echo "✓ Writing brew package dependencies"
cat > brew-packages.list << 'EOF'
powerlevel10k
fzf
asdf
coreutils
tree
EOF

# Log export to EXPORTS.md
echo "✓ Logging export"
if [ ! -f EXPORTS.md ]; then
    cat > EXPORTS.md << 'EOF'
# Export History

| Date | Computer | User |
|------|----------|------|
EOF
fi

echo "| $DATE | $HOSTNAME | $USERNAME |" >> EXPORTS.md

echo ""
echo "=== Export complete ==="
echo ""
echo "Files exported:"
echo "  - $SCRIPT_DIR/.zshrc.full"
echo "  - $SCRIPT_DIR/.p10k.zsh"
echo "  - $SCRIPT_DIR/plugins.list"
echo "  - $SCRIPT_DIR/brew-packages.list"
echo "  - $SCRIPT_DIR/EXPORTS.md (updated)"
echo ""
echo "Next steps:"
echo "  1. Review the exported files: git diff"
echo "  2. Commit and push changes: git add . && git commit && git push"
