#!/bin/bash
# Export current terminal configuration to this repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Exporting terminal configuration ==="
echo ""
echo "This will export your current terminal config to this repository."
echo "Files that will be overwritten:"
echo "  - .zshrc.full"
echo "  - .p10k.zsh"
echo "  - plugins.list"
echo "  - brew-packages.list"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Export cancelled."
    exit 0
fi
echo ""

# Export .zshrc (full version with personal settings)
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
    # Get list of custom plugins (exclude example and built-in ones)
    find ~/.oh-my-zsh/custom/plugins -maxdepth 1 -type d -not -name "plugins" -not -name "example" | \
        xargs -I {} basename {} > plugins.list.tmp

    # Remove empty lines
    grep -v '^$' plugins.list.tmp > plugins.list || touch plugins.list
    rm plugins.list.tmp

    echo "  Found $(wc -l < plugins.list | tr -d ' ') custom plugins"
else
    echo "  No custom plugins directory found"
    touch plugins.list
fi

# Export brew packages (only the ones we care about)
echo "✓ Exporting brew packages"
cat > brew-packages.list << 'EOF'
powerlevel10k
fzf
asdf
coreutils
tree
EOF

echo ""
echo "=== Export complete ==="
echo ""
echo "Files exported:"
echo "  - .zshrc.full (your complete config)"
echo "  - .p10k.zsh (powerlevel10k config)"
echo "  - plugins.list (custom plugins)"
echo "  - brew-packages.list (required packages)"
echo ""
echo "Next steps:"
echo "  1. Review the exported files"
echo "  2. Split .zshrc.full into .zshrc.base and .zshrc.personal if needed"
echo "  3. Commit and push changes"
