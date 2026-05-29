#!/bin/bash
set -e

trap 'echo "ERROR on line $LINENO. Press Enter to exit."; read' ERR

# 1. Update the system

sudo apt update && sudo apt full-upgrade -y

# 2. Debloat

(
set +e

sudo apt remove -y --purge 'libreoffice*' 'remmina*' 'cups*' 'evolution*' 'whoopsie*' 'bluez*' bluetooth blueman brave-browser

sudo rm -f /etc/apt/sources.list.d/brave-browser*.list
sudo rm -f /usr/share/keyrings/brave-browser*.gpg
sudo rm -rf ~/.config/BraveSoftware ~/.local/share/BraveSoftware ~/.cache/BraveSoftware
sudo rm -rf ~/.config/brave ~/.local/share/brave ~/.cache/brave


sudo systemctl disable --now snapd
sudo apt remove -y --purge snapd
sudo rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd

sudo tee /etc/apt/preferences.d/no-snapd.pref << 'EOF'
Package: snapd
Pin: release a=*
Pin-Priority: -1
EOF

sudo apt autoremove -y --purge

)

# 3. Enable 32-bit support and add the Driver Repository

sudo dpkg --add-architecture i386

sudo add-apt-repository ppa:kisak/kisak-mesa -y

# 4. Upgrade the system again to use the new drivers

sudo apt update && sudo apt full-upgrade -y

# 5. Vulkan support

sudo apt install -y libgl1-mesa-dri:i386 mesa-vulkan-drivers mesa-vulkan-drivers:i386 libvulkan1 libvulkan1:i386 vulkan-tools

# 6. Audio stack

sudo apt install -y pipewire-alsa pipewire-jack libspa-0.2-jack wireplumber

amixer -D hw:Generic_1 sset "Auto-Mute Mode" Disabled 2>/dev/null || echo "WARN: amixer device not found, skipping."

sudo alsactl store

# 7. Download Brave Origin

sudo apt install curl -y

sudo curl -fsSLo /usr/share/keyrings/brave-browser-nightly-archive-keyring.gpg https://brave-browser-apt-nightly.s3.brave.com/brave-browser-nightly-archive-keyring.gpg

sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-nightly.sources https://brave-browser-apt-nightly.s3.brave.com/brave-browser.sources

sudo apt update

sudo apt install brave-origin-nightly -y

# 8.Steam

sudo apt install -y steam

# 9. Faugus Launcher

sudo add-apt-repository -y ppa:faugus/faugus-launcher

sudo apt update

sudo apt install -y faugus-launcher


# 10. Ensure x11 // For Redshift and CopyQ to work

sudo sed -i -E 's/^#[ ]?WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
if ! sudo grep -q "^WaylandEnable=false" /etc/gdm3/custom.conf; then
     sudo sed -i '/^\[daemon\]/a WaylandEnable=false' /etc/gdm3/custom.conf
fi

# 11. Flatpak Setup and Applications

sudo apt install -y flatpak

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install flathub dev.vencord.Vesktop -y

flatpak install flathub io.github.hkdb.Aerion -y

flatpak install flathub com.github.hluk.copyq -y

# 12. Kernel Optimizations

if ! sudo grep -q "^vm.swappiness=" /etc/sysctl.conf; then
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
else
    sudo sed -i 's/^vm.swappiness=.*/vm.swappiness=10/' /etc/sysctl.conf
fi

if ! sudo grep -q "^kernel.sysrq=" /etc/sysctl.conf; then
    echo 'kernel.sysrq=1' | sudo tee -a /etc/sysctl.conf
else
    sudo sed -i 's/^kernel.sysrq=.*/kernel.sysrq=1/' /etc/sysctl.conf
fi

sudo sysctl -p

# 13. Enable custom volume keys

gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up "['Page_Up']"

gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down "['Page_Down']"

gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute "['End']"

# 14.Redshift // Screens are confirmed as accurately listed

sudo apt install -y redshift redshift-gtk

CONFIG_DIR="$HOME/.config/redshift"

CONFIG_FILE_DIR="$CONFIG_DIR/redshift.conf"

CONFIG_FILE_ROOT="$HOME/.config/redshift.conf"

mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_FILE_DIR" << 'EOF'

[redshift]

temp-day=4900

temp-night=4900

transition=0

adjustment-method=randr

location-provider=manual


[manual]

lat=0.0

lon=0.0


[randr]

screen=HDMI-A-0

screen=HDMI-A-1-1

EOF


cp -f "$CONFIG_FILE_DIR" "$CONFIG_FILE_ROOT"

chmod 644 "$CONFIG_FILE_DIR" "$CONFIG_FILE_ROOT"

# 15.  Auto-start config

mkdir -p "$HOME/.config/autostart"

create_autostart_entry() {
local app_name="$1"
local app_command="$2"

local file_name
file_name=$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
local target_file="$HOME/.config/autostart/${file_name}.desktop"

cat <<EOF > "$target_file"
[Desktop Entry]
Type=Application
Name=$app_name
Exec=$app_command
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

echo "✓ Configured $app_name for startup."
}

create_autostart_entry "Aerion" "flatpak run io.github.hkdb.Aerion"
create_autostart_entry "Vesktop" "flatpak run dev.vencord.Vesktop"
create_autostart_entry "CopyQ" "flatpak run com.github.hluk.copyq"
create_autostart_entry "Steam" "steam"
create_autostart_entry "Redshift" "redshift-gtk"


echo "Setup complete! Please restart your computer to apply all changes."
