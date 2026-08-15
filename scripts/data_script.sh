#!/usr/bin/env bash
set -e

echo "[*] 1/7: Updating system repositories..."
sudo apt update && sudo apt upgrade -y

echo "[*] 2/7: Installing core build essentials, CLI utilities, and runtime environments..."
sudo apt install -y \
    tmux \
    htop \
    curl \
    wget \
    git \
    build-essential \
    zsh \
    ripgrep \
    fd-find \
    tree \
    jq \
    nodejs \
    npm \
    dconf-cli

echo "[*] 3/7: Installing Data Analysis & Pentest SQL / OSINT Stack..."
# Scientific Python & C++ development headers
sudo apt install -y \
    python3-pip \
    python3-venv \
    python3-dev \
    libopenblas-dev \
    liblapack-dev \
    gfortran

mkdir -p ~/.config/pip
cat << 'EOF' > ~/.config/pip/pip.conf
[global]
break-system-packages = true
EOF

# Data analysis libraries
pip3 install --user --upgrade \
    numpy \
    pandas \
    scipy \
    matplotlib \
    seaborn \
    jupyterlab \
    polars \
    scikit-learn

# SQL & Database clients
sudo apt install -y \
    sqlite3 \
    libsqlite3-dev \
    default-mysql-client \
    postgresql-client \
    sqlmap

pip3 install --user --upgrade \
    mycli \
    pgcli \
    litecli \
    sqlalchemy \
    psycopg2-binary

# OSINT CLI Tools
sudo apt install -y \
    whois \
    dnsutils \
    theharvester \
    amass \
    recon-ng

pip3 install --user --upgrade \
    sherlock-project \
    holehe \
    tinfoleak \
    shodan

# Gemini CLI & Google GenAI SDK
sudo npm install -g @google/gemini-cli
pip3 install --user --upgrade google-genai

# Discord (.deb)
DISCORD_DEB="/tmp/discord.deb"
wget -O "$DISCORD_DEB" "https://discord.com/api/download?platform=linux&format=deb"
sudo apt install -y "$DISCORD_DEB" || sudo apt --fix-broken install -y
rm -f "$DISCORD_DEB"

echo "[*] 4/7: Installing GNOME Shell, Tweaks, and macOS-style Themes..."
sudo apt install -y \
    gnome-tweaks \
    gnome-shell-extensions \
    gnome-shell-extension-dashtodock \
    pipx

# CLI extension installer tool
pipx install gnome-extensions-cli --force
export PATH="$HOME/.local/bin:$PATH"

# Install Blur-My-Shell and User Themes via gext
gnome-extensions-cli install blur-my-shell@aunetx 2>/dev/null || true
gnome-extensions-cli install user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true

# Enable installed extensions
gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
gnome-extensions enable blur-my-shell@aunetx 2>/dev/null || true

# Install WhiteSur (macOS Big Sur/Monterey GTK Theme & Icon Pack)
THEME_DIR="/tmp/whitesur-theme"
rm -rf "$THEME_DIR"
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$THEME_DIR"
"$THEME_DIR/install.sh" -c Dark -t all -N glassy -s 220
rm -rf "$THEME_DIR"

ICON_DIR="/tmp/whitesur-icons"
rm -rf "$ICON_DIR"
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$ICON_DIR"
"$ICON_DIR/install.sh" -a -b
rm -rf "$ICON_DIR"

echo "[*] 5/7: Configuring macOS-like GNOME desktop layout..."
# Set left-side traffic light window controls (Close, Minimize, Maximize)
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

# Set macOS WhiteSur Dark Theme and Icons
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-Dark' 2>/dev/null || true

# Configure Dash-to-Dock for floating macOS Dock aesthetic
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
gsettings set org.gnome.shell.extensions.dash-to-dock show-trash-icon true
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.75

# Set a dark minimalist macOS-inspired wallpaper
mkdir -p "$HOME/Pictures/Wallpapers"
WALLPAPER_PATH="$HOME/Pictures/Wallpapers/dark_monterey.jpg"
curl -sL -o "$WALLPAPER_PATH" "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=1920&q=80"

gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH" 2>/dev/null || true
gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH" 2>/dev/null || true
gsettings set org.gnome.desktop.background picture-options 'zoom' 2>/dev/null || true

echo "[*] 6/7: Configuring tmux profile..."
cat << 'EOF' > "$HOME/.tmux.conf"
set -g mouse on
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"

# Remap prefix to C-a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Pane splitting
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Alt + Arrow pane switching
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Minimal status bar
set -g status-position bottom
set -g status-style bg=colour235,fg=colour137
set -g status-left '#[fg=colour148,bg=colour237,bold] 󰌽 #S #[default] '
set -g status-right '#[fg=colour244]%Y-%m-%d │ #[fg=colour250]%H:%M '
set -g status-right-length 50
set -g status-left-length 20

setw -g window-status-current-style fg=colour81,bg=colour238,bold
setw -g window-status-current-format ' #I:#W#F '
setw -g window-status-style fg=colour245,bg=colour235
setw -g window-status-format ' #I:#W '
EOF

echo "[*] 7/7: Updating PATH in ~/.bashrc..."
if ! grep -q 'PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo "[*] Setup complete! Please log out and log back in (or reboot) to load GNOME extensions and theme caches."