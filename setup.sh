#!/bin/bash
set -e

trap 'echo "ERROR on line $LINENO. Press Enter to exit."; read' ERR

# 1. Enable 32-bit support and add the Driver Repository

sudo dpkg --add-architecture i386

sudo add-apt-repository ppa:kisak/kisak-mesa -y

sudo apt update


# 2. Upgrade the system to use the new drivers

sudo apt full-upgrade -y


# 3. Vulkan support

sudo apt install -y libgl1-mesa-dri:i386 mesa-vulkan-drivers mesa-vulkan-drivers:i386 libvulkan1 libvulkan1:i386 vulkan-tools

# 4. Audio stack

sudo apt install -y pipewire-audio-client-libraries libspa-0.2-jack wireplumber

amixer -D hw:Generic_1 sset "Auto-Mute Mode" Disabled

sudo alsactl store


# 5. Bloat removal

sudo apt remove -y --purge gnome-maps gnome-games libreoffice* bluetooth bluez brave-browser || true 
sudo apt autoremove -y || true
sudo apt clean || true

rm -rf ~/.config/BraveSoftware ~/.local/share/BraveSoftware ~/.cache/BraveSoftware || true
rm -rf ~/.config/brave ~/.local/share/brave ~/.cache/brave || true


# 6. Download Brave Origin

sudo apt install curl -y

sudo curl -fsSLo /usr/share/keyrings/brave-browser-nightly-archive-keyring.gpg https://brave-browser-apt-nightly.s3.brave.com/brave-browser-nightly-archive-keyring.gpg

sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-nightly.sources https://brave-browser-apt-nightly.s3.brave.com/brave-browser.sources

sudo apt update

sudo apt install brave-origin-nightly -y


# 7.Steam

sudo apt install -y steam


# 8. Faugus Launcher

sudo add-apt-repository -y ppa:faugus/faugus-launcher

sudo apt update

sudo apt install -y faugus-launcher


# 9. Ensure x11 (For Redshift and CopyQ to work)

sudo sed -i -E 's/^# ?WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf

# 10. Flatpak Setup and Applications

sudo apt install -y flatpak

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install flathub dev.vencord.Vesktop -y

flatpak install flathub eu.betterbird.Betterbird -y

flatpak install flathub com.github.hluk.copyq -y

# 11. Kernel Optimizations

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

# 12. Enable custom volume keys

gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up "['Page_Up']"


gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down "['Page_Down']"


gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute "['End']"


# 13.Redshift

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

echo "Setup complete! Please restart your computer to apply all changes."
