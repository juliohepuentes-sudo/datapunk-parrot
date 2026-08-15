#!/usr/bin/env bash
set -e

echo "[*] 1/7: Installing core performance & hardware management tools..."
sudo apt update
sudo apt install -y \
    zram-tools \
    preload \
    irqbalance \
    systemd-timesyncd

echo "[*] 2/7: Locking CPU Governor to 'Performance' Mode..."
# Set CPU scaling governor across all available cores
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [ -f "$cpu" ] && echo "performance" | sudo tee "$cpu" > /dev/null
done

# Persist CPU performance governor across reboots
sudo bash -c 'cat << EOF > /etc/default/cpufrequtils
ENABLE="true"
GOVERNOR="performance"
MAX_SPEED="0"
MIN_SPEED="0"
EOF'
sudo systemctl enable --now cpufrequtils 2>/dev/null || true

echo "[*] 3/7: Configuring Kernel Memory & I/O Tuning (sysctl)..."
# Optimize RAM management, reduce swap write-penalties, and enable fast TCP BBR
sudo bash -c 'cat << "EOF" > /etc/sysctl.d/99-parrot-performance.conf
# Aggressively keep processes in RAM before swapping
vm.swappiness = 10

# Keep filesystem metadata/dentry cache in memory
vm.vfs_cache_pressure = 50

# Avoid massive disk write-stalls by flushing dirty buffers earlier
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10

# Fast network congestion control
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# Increase maximum file handles and watchers for IDEs / pentest scripts
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
EOF'
sudo sysctl --system

echo "[*] 4/7: Setting up fast ZRAM (Compressed RAM Swap)..."
# Compresses idle memory in RAM using zstd, preventing slow disk swap paging
sudo bash -c 'cat << "EOF" > /etc/default/zramswap
ALGO=zstd
PERCENT=50
PRIORITY=100
EOF'
sudo systemctl enable --now zramswap.service 2>/dev/null || true

echo "[*] 5/7: Disabling Unnecessary Background Daemons..."
# Disable services that consume background CPU cycles and RAM on idle
UNWANTED_SERVICES=(
    "cups.service"
    "cups-browsed.service"
    "ModemManager.service"
    "avahi-daemon.service"
    "tracker-miner-fs-3.service"
    "tracker-extract-3.service"
)

for service in "${UNWANTED_SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "$service"; then
        echo " -> Disabling $service"
        sudo systemctl stop "$service" 2>/dev/null || true
        sudo systemctl disable "$service" 2>/dev/null || true
    fi
done

# Cap systemd journal logs to 100MB to avoid disk bloat
sudo sed -i 's/^#SystemMaxUse=.*/SystemMaxUse=100M/' /etc/systemd/journald.conf 2>/dev/null || true
sudo systemctl restart systemd-journald

echo "[*] 6/7: Stripping GNOME Desktop Animation Latency..."
# Turn off UI animations for instant window opening and switching
gsettings set org.gnome.desktop.interface enable-animations false 2>/dev/null || true

# Turn off GNOME search indexing on background folders
gsettings set org.gnome.desktop.search-providers disable-external true 2>/dev/null || true

echo "[*] 7/7: Cleaning Package Cache & Temporary Build Artifacts..."
sudo apt autoremove --purge -y
sudo apt clean
sudo journalctl --vacuum-size=50M

echo "====================================================="
echo "[✔] Optimization complete!"
echo "Reboot your computer with 'sudo reboot' to apply all kernel and governor changes."
echo "====================================================="