#!/bin/bash
# Export current terminal configuration to this repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Exporting terminal configuration ==="
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
read -p "Continue? (y/N) " -r
REPLY=${REPLY:-N}  # Default to N if empty
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Export cancelled."
    exit 0
fi
echo ""

# Clean up existing .zshrc.* files before export
echo "✓ Cleaning up old config files"
rm -f .zshrc.full .zshrc.base .zshrc.personal
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

# Split .zshrc into base and personal if it has the markers
echo "✓ Analyzing .zshrc structure"
if grep -q "# PERSONAL CONFIGURATION" .zshrc.full 2>/dev/null || grep -q "# =============================================================================.*PERSONAL" .zshrc.full 2>/dev/null; then
    echo "  Detected personal configuration section, splitting..."

    # Extract base config (everything before PERSONAL CONFIGURATION section)
    sed -n '1,/# =============================================================================/{/# =============================================================================.*PERSONAL/!p;}' .zshrc.full > .zshrc.base.tmp

    # Extract personal config (everything from PERSONAL CONFIGURATION section onwards)
    sed -n '/# =============================================================================.*PERSONAL/,$p' .zshrc.full > .zshrc.personal.tmp

    # Only overwrite if we got valid content
    if [ -s .zshrc.base.tmp ] && [ -s .zshrc.personal.tmp ]; then
        mv .zshrc.base.tmp .zshrc.base
        mv .zshrc.personal.tmp .zshrc.personal
        echo "  Split into .zshrc.base and .zshrc.personal"
    else
        rm -f .zshrc.base.tmp .zshrc.personal.tmp
        echo "  Could not split automatically, keeping .zshrc.full only"
    fi
else
    echo "  No personal section markers found, keeping as .zshrc.full"
fi

echo ""
echo "=== Export complete ==="
echo ""
echo "Files exported:"
# Check if split files were ACTUALLY created from this export run
if [ -f .zshrc.base ] && [ -f .zshrc.personal ] && grep -q "# =============================================================================.*PERSONAL" .zshrc.full 2>/dev/null; then
    echo "  - $SCRIPT_DIR/.zshrc.base (generic config)"
    echo "  - $SCRIPT_DIR/.zshrc.personal (your customizations)"
    echo "  - $SCRIPT_DIR/.zshrc.full (complete backup)"
else
    echo "  - $SCRIPT_DIR/.zshrc.full (your complete config)"
fi
echo "  - $SCRIPT_DIR/.p10k.zsh (powerlevel10k config)"
echo "  - $SCRIPT_DIR/plugins.list (custom plugins)"
echo "  - $SCRIPT_DIR/brew-packages.list (required packages)"
echo ""
echo "Next steps:"
echo "  1. Review the exported files: git diff"
echo "  2. Commit and push changes: git add . && git commit && git push"
