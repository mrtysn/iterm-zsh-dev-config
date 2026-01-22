#!/bin/zsh
# Import and setup terminal configuration from this repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== iTerm ZSH Dev Config Import ==="
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print "${RED}✗ This script is designed for macOS${NC}"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to ask yes/no with default
# Usage: ask_yes_no "prompt" [default: y/n]
ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local reply

    if [[ "$default" == "y" ]]; then
        read "reply?${prompt} [Y/n] "
        reply=${reply:-Y}
    else
        read "reply?${prompt} [y/N] "
        reply=${reply:-N}
    fi

    [[ "$reply" =~ ^[Yy]$ ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Step 1: Homebrew (required - other steps depend on it)
# ═══════════════════════════════════════════════════════════════════════════════
echo "=== Step 1: Homebrew ==="
if command_exists brew; then
    print "${GREEN}✓ Homebrew already installed${NC}"
else
    print "${YELLOW}→ Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    print "${GREEN}✓ Homebrew installed${NC}"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# Step 2: Brew Packages (optional)
# ═══════════════════════════════════════════════════════════════════════════════
echo "=== Step 2: Brew Packages ==="
if [ -f brew-packages.list ]; then
    print "${BLUE}Packages: $(tr '\n' ' ' < brew-packages.list)${NC}"
    if ask_yes_no "Install brew packages?"; then
        while IFS= read -r package; do
            # Skip empty lines and comments
            [[ -z "$package" || "$package" =~ ^# ]] && continue

            if brew list "$package" &>/dev/null; then
                print "${GREEN}✓ $package already installed${NC}"
            else
                print "${YELLOW}→ Installing $package...${NC}"
                if brew install "$package"; then
                    print "${GREEN}✓ $package installed${NC}"
                else
                    print "${RED}✗ $package failed to install${NC}"
                fi
            fi
        done < brew-packages.list
    else
        print "${YELLOW}! Skipped brew packages${NC}"
    fi
else
    print "${RED}✗ brew-packages.list not found${NC}"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# Step 3: Oh-My-Zsh (optional)
# ═══════════════════════════════════════════════════════════════════════════════
echo "=== Step 3: Oh-My-Zsh ==="
if [ -d ~/.oh-my-zsh ]; then
    print "${GREEN}✓ Oh-My-Zsh already installed${NC}"
else
    if ask_yes_no "Install Oh-My-Zsh?"; then
        print "${YELLOW}→ Installing Oh-My-Zsh...${NC}"
        if sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
            if [ -d ~/.oh-my-zsh ]; then
                print "${GREEN}✓ Oh-My-Zsh installed${NC}"
            else
                print "${RED}✗ Oh-My-Zsh installation failed (directory not created)${NC}"
            fi
        else
            print "${RED}✗ Oh-My-Zsh installation script failed${NC}"
        fi
    else
        print "${YELLOW}! Skipped Oh-My-Zsh${NC}"
    fi
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# Step 4: Custom Plugins (optional)
# ═══════════════════════════════════════════════════════════════════════════════
echo "=== Step 4: Custom Plugins ==="
if [ ! -d ~/.oh-my-zsh ]; then
    print "${YELLOW}! Oh-My-Zsh not installed, skipping plugins${NC}"
elif [ ! -f plugins.list ]; then
    print "${RED}✗ plugins.list not found${NC}"
else
    print "${BLUE}Plugins: $(tr '\n' ' ' < plugins.list)${NC}"
    if ask_yes_no "Install custom plugins?"; then
        mkdir -p ~/.oh-my-zsh/custom/plugins

        # Plugin repository mapping
        declare -A PLUGIN_REPOS=(
            ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
            ["fast-syntax-highlighting"]="https://github.com/zdharma-continuum/fast-syntax-highlighting"
            ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab"
            ["alias-tips"]="https://github.com/djui/alias-tips"
            ["git-it-on"]="https://github.com/peterhurford/git-it-on.zsh"
            ["catimg"]="https://github.com/posva/catimg"
            ["auto-notify"]="https://github.com/MichaelAquilina/zsh-auto-notify"
            ["autoswitch_virtualenv"]="https://github.com/MichaelAquilina/zsh-autoswitch-virtualenv"
            ["cd-ls"]="https://github.com/zshzoo/cd-ls"
            ["autoupdate"]="https://github.com/TamCore/autoupdate-oh-my-zsh-plugins"
            ["ls"]="https://github.com/zpm-zsh/ls"
        )

        while IFS= read -r plugin; do
            # Skip empty lines
            [[ -z "$plugin" ]] && continue

            plugin_dir=~/.oh-my-zsh/custom/plugins/$plugin

            if [ -d "$plugin_dir" ]; then
                print "${GREEN}✓ $plugin already installed${NC}"
            else
                if [ -n "${PLUGIN_REPOS[$plugin]}" ]; then
                    repo_url="${PLUGIN_REPOS[$plugin]}"

                    # Validate repository exists before cloning
                    http_status=$(curl -s -o /dev/null -w "%{http_code}" "$repo_url" 2>/dev/null || echo "000")
                    if [ "$http_status" = "200" ]; then
                        print "${YELLOW}→ Installing $plugin...${NC}"
                        if git clone --quiet "$repo_url" "$plugin_dir" 2>/dev/null; then
                            print "${GREEN}✓ $plugin installed${NC}"
                        else
                            print "${RED}✗ $plugin failed to clone${NC}"
                        fi
                    else
                        print "${RED}✗ $plugin repository unavailable (HTTP $http_status): $repo_url${NC}"
                    fi
                else
                    print "${RED}✗ Unknown plugin: $plugin (no repo mapping)${NC}"
                fi
            fi
        done < plugins.list
    else
        print "${YELLOW}! Skipped custom plugins${NC}"
    fi
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# Step 5: Homebrew command-not-found (informational only)
# ═══════════════════════════════════════════════════════════════════════════════
echo "=== Step 5: Homebrew command-not-found ==="
print "${GREEN}✓ command-not-found is now built into Homebrew (no tap required)${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# Step 6: FZF Integration (optional)
# ═══════════════════════════════════════════════════════════════════════════════
echo "=== Step 6: FZF Integration ==="
if [ -f ~/.fzf.zsh ]; then
    print "${GREEN}✓ FZF already configured${NC}"
else
    FZF_INSTALL_PATH="$(brew --prefix 2>/dev/null)/opt/fzf/install"
    if [ -f "$FZF_INSTALL_PATH" ]; then
        if ask_yes_no "Setup FZF shell integration?"; then
            print "${YELLOW}→ Setting up FZF integration...${NC}"
            if "$FZF_INSTALL_PATH" --key-bindings --completion --no-update-rc --no-bash --no-fish; then
                print "${GREEN}✓ FZF configured${NC}"
            else
                print "${RED}✗ FZF configuration failed${NC}"
            fi
        else
            print "${YELLOW}! Skipped FZF integration${NC}"
        fi
    else
        print "${YELLOW}! FZF not installed (install with: brew install fzf)${NC}"
    fi
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# Step 7: Configuration Files (optional)
# ═══════════════════════════════════════════════════════════════════════════════
echo "=== Step 7: Configuration Files ==="

# Check what config files exist in repo
HAS_CONFIG=false
[ -f .zshrc.base ] && [ -f .zshrc.personal ] && HAS_CONFIG=true
[ -f .zshrc.full ] && HAS_CONFIG=true
[ -f .zshrc ] && HAS_CONFIG=true

if [ "$HAS_CONFIG" = false ]; then
    print "${RED}✗ No .zshrc config found in repo${NC}"
else
    # Show what will be copied
    print "${BLUE}Available configs:${NC}"
    [ -f .zshrc.full ] && echo "  - .zshrc.full"
    [ -f .zshrc.base ] && echo "  - .zshrc.base"
    [ -f .p10k.zsh ] && echo "  - .p10k.zsh"

    if ask_yes_no "Copy configuration files? (existing files will be backed up)"; then
        # Backup existing configs
        BACKUP_DIR=""
        if [ -f ~/.zshrc ] || [ -f ~/.zshrc.base ] || [ -f ~/.p10k.zsh ]; then
            BACKUP_DIR=~/.zsh-config-backup-$(date +%Y%m%d-%H%M%S)
            print "${YELLOW}→ Backing up existing configs to $BACKUP_DIR${NC}"
            mkdir -p "$BACKUP_DIR"
            [ -f ~/.zshrc ] && cp ~/.zshrc "$BACKUP_DIR/.zshrc"
            [ -f ~/.zshrc.base ] && cp ~/.zshrc.base "$BACKUP_DIR/.zshrc.base"
            [ -f ~/.zshrc.personal ] && cp ~/.zshrc.personal "$BACKUP_DIR/.zshrc.personal"
            [ -f ~/.p10k.zsh ] && cp ~/.p10k.zsh "$BACKUP_DIR/.p10k.zsh"
            print "${GREEN}✓ Existing configs backed up${NC}"
        fi

        # Determine which config files to use
        if [ -f .zshrc.base ] && [ -f .zshrc.personal ]; then
            # Split config mode
            print "${YELLOW}→ Copying .zshrc.base and .zshrc.personal${NC}"
            cp .zshrc.base ~/.zshrc.base

            # Only copy personal if it doesn't exist (user might have their own)
            if [ ! -f ~/.zshrc.personal ]; then
                cp .zshrc.personal ~/.zshrc.personal
                print "${GREEN}✓ Created ~/.zshrc.personal from template${NC}"
            else
                print "${YELLOW}! Skipping ~/.zshrc.personal (already exists)${NC}"
            fi

            # Create main .zshrc that sources both
            cat > ~/.zshrc << 'EOF'
# Source base configuration
[ -f ~/.zshrc.base ] && source ~/.zshrc.base

# Source personal configuration
[ -f ~/.zshrc.personal ] && source ~/.zshrc.personal
EOF
            print "${GREEN}✓ Created ~/.zshrc (sources base + personal)${NC}"

        elif [ -f .zshrc.full ]; then
            # Full config mode
            print "${YELLOW}→ Copying .zshrc.full${NC}"
            cp .zshrc.full ~/.zshrc
            print "${GREEN}✓ Copied .zshrc${NC}"

        elif [ -f .zshrc ]; then
            # Legacy single file mode
            print "${YELLOW}→ Copying .zshrc${NC}"
            cp .zshrc ~/.zshrc
            print "${GREEN}✓ Copied .zshrc${NC}"
        fi

        # Copy .p10k.zsh
        if [ -f .p10k.zsh ]; then
            print "${YELLOW}→ Copying .p10k.zsh${NC}"
            cp .p10k.zsh ~/.p10k.zsh
            print "${GREEN}✓ Copied .p10k.zsh${NC}"
        fi
    else
        print "${YELLOW}! Skipped configuration files${NC}"
    fi
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# Step 8: Default Shell (optional)
# ═══════════════════════════════════════════════════════════════════════════════
echo "=== Step 8: Default Shell ==="
if [ "$SHELL" = "/bin/zsh" ]; then
    print "${GREEN}✓ zsh is already the default shell${NC}"
else
    if ask_yes_no "Set zsh as default shell? (requires password)"; then
        print "${YELLOW}→ Setting zsh as default shell...${NC}"
        if chsh -s /bin/zsh; then
            print "${GREEN}✓ zsh set as default shell${NC}"
        else
            print "${RED}✗ Failed to set default shell (you can run 'chsh -s /bin/zsh' manually)${NC}"
        fi
    else
        print "${YELLOW}! Skipped setting default shell${NC}"
    fi
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# Complete
# ═══════════════════════════════════════════════════════════════════════════════
echo "=== Import Complete ==="
echo ""
print "${GREEN}✓ Setup finished${NC}"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Powerlevel10k config wizard will run on first start (if not configured)"
echo "  3. Customize ~/.zshrc.personal with your own aliases and settings"
echo ""
if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
    echo "Your old configs are backed up at: $BACKUP_DIR"
    echo ""
fi
