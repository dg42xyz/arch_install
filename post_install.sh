# Update system
pacman -Syu

# Install yay
mkdir /tmp/aur && cd /tmp/aur
git clone https://aur.archlinux.org/yay.git
cd yay
cat PKGBUILD
makepkg -si

# Install generic packages
pacman -S bash-completion lsof pacman-contrib htop

# Install compression tools
pacman -S zip unzip unrar

# Install network tools
pacman -S rsync traceroute bind-tools speedtest-cli openssh openvpn macchanger

# Install services
pacman -S networkmanager xdg-user-dirs

# Enable NetworkManager and disable dhcpcd at boot
systemctl enable NetworkManager
systemctl disable dhcpcd

# Create default directories
xdg-user-dirs-update

# Install File system tools
pacman -S dosfstools ntfs-3g exfat-utils

# Install sound utilities
pacman -S alsa-utils alsa-plugins pulseaudio pulseaudio-alsa

# Install xorg
pacman -S xorg-server xorg-xinit

# Install xorg default fonts
pacman -S font-bh-ttf font-bitstream-speedo gsfonts sdl_ttf ttf-bitstream-vera ttf-dejavu ttf-liberation xorg-fonts-type1

# Install video driver
lspci | grep -e VGA -e 3D
pacman -Ssq xf86-video
pacman -S xf86-video-intel

# Install printer config
pacman -S system-config-printer

# Install desktop environment
pacman -S cinnamon gnome-terminal

# Install default display manager
pacman -S lightdm-gtk-greeter

# Install display manager and settings from AUR
yay -S lightdm-slick-greeter
yay -S lightdm-settings

# Edit /etc/lightdm/lightdm.conf, uncomment and change to
greeter-session=lightdm-slick-greeter

# Restart lightdm service
systemctl restart lightdm.service

# Enable lightdm greeter
systemctl enable lightdm

# Install themes
pacman -S arc-icon-theme arc-gtk-theme papirus-icon-theme

# Install dev tools
pacman -S code terraform packer aws-cli python-pip nodejs npm ruby-irb ansible

# Install other apps
pacman -S chromium firefox transmission-gtk virtualbox rhythmbox gedit gedit-plugins pidgin pidgin-otr vlc gnome-screenshot keepassxc youtube-dl ffmpeg kleopatra libreoffice-fresh gparted gimp

# Install other apps from AUR
yay -S pix
yay -S chef-workstation
yay -S slack-desktop
yay -S postman-bin
yay -S pacman-cleanup-hook
yay -S powershell
yay -S zoom
yay -S pidgin-sipe
yay -S caffeine-ng
