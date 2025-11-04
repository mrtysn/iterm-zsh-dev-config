#!/bin/bash
# Import and setup terminal configuration from this repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== iTerm ZSH Dev Config Import ==="
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}✗ This script is designed for macOS${NC}"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Install Homebrew
echo "=== Step 1: Homebrew ==="
if command_exists brew; then
    echo -e "${GREEN}✓ Homebrew already installed${NC}"
else
    echo -e "${YELLOW}→ Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    echo -e "${GREEN}✓ Homebrew installed${NC}"
fi
echo ""

# 2. Install brew packages
echo "=== Step 2: Brew Packages ==="
if [ -f brew-packages.list ]; then
    while IFS= read -r package; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" =~ ^# ]] && continue

        if brew list "$package" &>/dev/null; then
            echo -e "${GREEN}✓ $package already installed${NC}"
        else
            echo -e "${YELLOW}→ Installing $package...${NC}"
            brew install "$package"
            echo -e "${GREEN}✓ $package installed${NC}"
        fi
    done < brew-packages.list
else
    echo -e "${RED}✗ brew-packages.list not found${NC}"
fi
echo ""

# 3. Install Oh-My-Zsh
echo "=== Step 3: Oh-My-Zsh ==="
if [ -d ~/.oh-my-zsh ]; then
    echo -e "${GREEN}✓ Oh-My-Zsh already installed${NC}"
else
    echo -e "${YELLOW}→ Installing Oh-My-Zsh...${NC}"
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo -e "${GREEN}✓ Oh-My-Zsh installed${NC}"
fi
echo ""

# 4. Install custom plugins
echo "=== Step 4: Custom Plugins ==="
mkdir -p ~/.oh-my-zsh/custom/plugins

# Plugin repository mapping
declare -A PLUGIN_REPOS=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["fast-syntax-highlighting"]="https://github.com/zdharma-continuum/fast-syntax-highlighting"
    ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab"
    ["alias-tips"]="https://github.com/djui/alias-tips"
    ["git-it-on"]="https://github.com/peterhurford/git-it-on.zsh"
    ["catimg"]="https://github.com/posva/catimg"
    ["hitchhiker"]="https://github.com/Mumbleskates/hitchhiker"
    ["auto-notify"]="https://github.com/MichaelAquilina/zsh-auto-notify"
    ["autoswitch_virtualenv"]="https://github.com/MichaelAquilina/zsh-autoswitch-virtualenv"
    ["iterm-tab-color"]="https://github.com/bernardop/iterm-tab-color"
    ["cd-ls"]="https://github.com/zshzoo/cd-ls"
    ["autoupdate"]="https://github.com/TamCore/autoupdate-oh-my-zsh-plugins"
    ["ls"]="https://github.com/zpm-zsh/ls"
)

if [ -f plugins.list ]; then
    while IFS= read -r plugin; do
        # Skip empty lines
        [[ -z "$plugin" ]] && continue

        plugin_dir=~/.oh-my-zsh/custom/plugins/$plugin

        if [ -d "$plugin_dir" ]; then
            echo -e "${GREEN}✓ $plugin already installed${NC}"
        else
            if [ -n "${PLUGIN_REPOS[$plugin]}" ]; then
                echo -e "${YELLOW}→ Installing $plugin...${NC}"
                git clone "${PLUGIN_REPOS[$plugin]}" "$plugin_dir"
                echo -e "${GREEN}✓ $plugin installed${NC}"
            else
                echo -e "${RED}✗ Unknown plugin: $plugin (no repo mapping)${NC}"
            fi
        fi
    done < plugins.list
else
    echo -e "${RED}✗ plugins.list not found${NC}"
fi
echo ""

# 5. Setup Homebrew command-not-found
echo "=== Step 5: Homebrew command-not-found ==="
if brew tap | grep -q "homebrew/command-not-found"; then
    echo -e "${GREEN}✓ homebrew/command-not-found already tapped${NC}"
else
    echo -e "${YELLOW}→ Tapping homebrew/command-not-found...${NC}"
    brew tap homebrew/command-not-found
    echo -e "${GREEN}✓ homebrew/command-not-found tapped${NC}"
fi
echo ""

# 6. Setup FZF
echo "=== Step 6: FZF Integration ==="
FZF_INSTALL_PATH="$(brew --prefix)/opt/fzf/install"
if [ -f ~/.fzf.zsh ]; then
    echo -e "${GREEN}✓ FZF already configured${NC}"
else
    if [ -f "$FZF_INSTALL_PATH" ]; then
        echo -e "${YELLOW}→ Setting up FZF integration...${NC}"
        "$FZF_INSTALL_PATH" --key-bindings --completion --no-update-rc --no-bash --no-fish
        echo -e "${GREEN}✓ FZF configured${NC}"
    else
        echo -e "${RED}✗ FZF install script not found${NC}"
    fi
fi
echo ""

# 7. Backup and copy configuration files
echo "=== Step 7: Configuration Files ==="

# Check if any configs will be overwritten
WILL_OVERWRITE=false
[ -f ~/.zshrc ] && WILL_OVERWRITE=true
[ -f ~/.zshrc.base ] && WILL_OVERWRITE=true
[ -f ~/.p10k.zsh ] && WILL_OVERWRITE=true

if [ "$WILL_OVERWRITE" = true ]; then
    echo ""
    echo "WARNING: The following files will be backed up and overwritten:"
    [ -f ~/.zshrc ] && echo "  - ~/.zshrc"
    [ -f ~/.zshrc.base ] && echo "  - ~/.zshrc.base"
    [ -f ~/.p10k.zsh ] && echo "  - ~/.p10k.zsh"
    echo ""
    echo "A backup will be created at ~/.zsh-config-backup-TIMESTAMP/"
    echo ""
    read -p "Continue? (y/N) " -r
    REPLY=${REPLY:-N}  # Default to N if empty
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Import cancelled.${NC}"
        exit 0
    fi
    echo ""
fi

# Backup existing configs
BACKUP_DIR=~/.zsh-config-backup-$(date +%Y%m%d-%H%M%S)
if [ -f ~/.zshrc ] || [ -f ~/.zshrc.base ] || [ -f ~/.p10k.zsh ]; then
    echo -e "${YELLOW}→ Backing up existing configs to $BACKUP_DIR${NC}"
    mkdir -p "$BACKUP_DIR"
    [ -f ~/.zshrc ] && cp ~/.zshrc "$BACKUP_DIR/.zshrc"
    [ -f ~/.zshrc.base ] && cp ~/.zshrc.base "$BACKUP_DIR/.zshrc.base"
    [ -f ~/.zshrc.personal ] && cp ~/.zshrc.personal "$BACKUP_DIR/.zshrc.personal"
    [ -f ~/.p10k.zsh ] && cp ~/.p10k.zsh "$BACKUP_DIR/.p10k.zsh"
    echo -e "${GREEN}✓ Existing configs backed up${NC}"
fi

# Determine which config files to use
if [ -f .zshrc.base ] && [ -f .zshrc.personal ]; then
    # Split config mode
    echo -e "${YELLOW}→ Copying .zshrc.base and .zshrc.personal${NC}"
    cp .zshrc.base ~/.zshrc.base

    # Only copy personal if it doesn't exist (user might have their own)
    if [ ! -f ~/.zshrc.personal ]; then
        cp .zshrc.personal ~/.zshrc.personal
        echo -e "${GREEN}✓ Created ~/.zshrc.personal from template${NC}"
    else
        echo -e "${YELLOW}! Skipping ~/.zshrc.personal (already exists)${NC}"
    fi

    # Create main .zshrc that sources both
    cat > ~/.zshrc << 'EOF'
# Source base configuration
[ -f ~/.zshrc.base ] && source ~/.zshrc.base

# Source personal configuration
[ -f ~/.zshrc.personal ] && source ~/.zshrc.personal
EOF
    echo -e "${GREEN}✓ Created ~/.zshrc (sources base + personal)${NC}"

elif [ -f .zshrc.full ]; then
    # Full config mode
    echo -e "${YELLOW}→ Copying .zshrc.full${NC}"
    cp .zshrc.full ~/.zshrc
    echo -e "${GREEN}✓ Copied .zshrc${NC}"

elif [ -f .zshrc ]; then
    # Legacy single file mode
    echo -e "${YELLOW}→ Copying .zshrc${NC}"
    cp .zshrc ~/.zshrc
    echo -e "${GREEN}✓ Copied .zshrc${NC}"
else
    echo -e "${RED}✗ No .zshrc config found in repo${NC}"
fi

# Copy .p10k.zsh
if [ -f .p10k.zsh ]; then
    echo -e "${YELLOW}→ Copying .p10k.zsh${NC}"
    cp .p10k.zsh ~/.p10k.zsh
    echo -e "${GREEN}✓ Copied .p10k.zsh${NC}"
else
    echo -e "${RED}✗ .p10k.zsh not found in repo${NC}"
fi
echo ""

# 8. Set zsh as default shell
echo "=== Step 8: Default Shell ==="
if [ "$SHELL" = "/bin/zsh" ]; then
    echo -e "${GREEN}✓ zsh is already the default shell${NC}"
else
    echo -e "${YELLOW}→ Setting zsh as default shell...${NC}"
    chsh -s /bin/zsh
    echo -e "${GREEN}✓ zsh set as default shell${NC}"
fi
echo ""

echo "=== Import Complete ==="
echo ""
echo -e "${GREEN}✓ All setup steps completed${NC}"
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
