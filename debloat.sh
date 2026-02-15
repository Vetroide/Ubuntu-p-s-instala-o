#!/usr/bin/env bash

# --- CONFIGURAÇÕES INICIAIS ---
set -e # Para o script se encontrar um erro

check_root_user() {
    if [ "$(id -u)" != 0 ]; then
        echo "Por favor, execute como root (use sudo)!"
        exit 1
    fi
}

msg() {
    echo -e "\e[32m[*] $1\e[0m"
}

# --- FUNÇÕES ---

disable_telemetry_and_apport() {
    msg "Desativando telemetria e popups de erro (Apport)..."
    ubuntu-report send no || true
    apt purge ubuntu-report apport apport-gtk -y
}

disable_terminal_ads() {
    msg "Limpando anúncios do terminal (Ubuntu Pro/MOTD)..."
    sed -i 's/ENABLED=1/ENABLED=0/g' /etc/default/motd-news 2>/dev/null || true
    if command -v pro &> /dev/null; then
        pro config set apt_news=false || true
    fi
}

remove_snaps() {
    msg "Removendo Snaps e bloqueando o snapd..."
    # Remove todos os pacotes snap instalados
    while [ "$(snap list 2>/dev/null | wc -l)" -gt 0 ]; do
        for snap in $(snap list | tail -n +2 | cut -d ' ' -f 1); do
            snap remove --purge "$snap" 2> /dev/null || true
        done
    done

    systemctl stop snapd || true
    systemctl disable snapd || true
    systemctl mask snapd || true
    apt purge snapd -y
    rm -rf /snap /var/lib/snapd /root/snap
    
    # Impede que o Ubuntu reinstale o snapd automaticamente
    cat <<-EOF | tee /etc/apt/preferences.d/nosnap.pref
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
}

setup_flatpak_and_gnome_software() {
    msg "Instalando Flatpak e GNOME Software..."
    apt install flatpak gnome-software gnome-software-plugin-flatpak -y
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

install_brave_deb() {
    msg "Instalando Brave Browser (Repositório oficial .deb)..."
    apt install curl -y
    curl -fsS https://dl.brave.com/install.sh | sh
}

remove_libreoffice() {
    msg "Removendo LibreOffice..."
    apt purge libreoffice* -y
}

update_and_cleanup() {
    msg "Atualizando o sistema e limpando restos..."
    apt update && apt upgrade -y
    apt autoremove -y
}

# --- EXECUÇÃO ---

main() {
    check_root_user
    
    disable_telemetry_and_apport
    disable_terminal_ads
    remove_snaps
    remove_libreoffice
    setup_flatpak_and_gnome_software
    install_brave_deb
    update_and_cleanup

    msg "Tudo pronto! O sistema foi limpo e o Brave instalado."
    echo "Recomenda-se reiniciar o computador para aplicar todas as mudanças."
}

main
