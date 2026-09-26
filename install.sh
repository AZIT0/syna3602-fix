#!/usr/bin/env bash
# Instalador de syna3602-fix. Correr con sudo: sudo bash install.sh
set -e

if [[ $EUID -ne 0 ]]; then
    echo "Corre con sudo: sudo bash install.sh"
    exit 1
fi

# Dependencia (nombre de paquete en Arch/CachyOS, Fedora, Debian/Ubuntu)
if ! python3 -c "import evdev" 2>/dev/null; then
    echo "Instalando python-evdev..."
    if command -v pacman >/dev/null; then
        pacman -S --needed --noconfirm python-evdev
    elif command -v dnf >/dev/null; then
        dnf install -y python3-evdev
    elif command -v apt-get >/dev/null; then
        apt-get update && apt-get install -y python3-evdev
    else
        echo "No se pudo instalar python-evdev solo. Instalalo a mano y reintenta."
        exit 1
    fi
fi

cp syna3602-fix.py /usr/local/bin/syna3602-fix.py
chmod 644 /usr/local/bin/syna3602-fix.py
cp syna3602-fix.service /etc/systemd/system/syna3602-fix.service
chmod 644 /etc/systemd/system/syna3602-fix.service

systemctl daemon-reload
systemctl enable --now syna3602-fix.service
sleep 2
systemctl is-active syna3602-fix.service
echo "OK: fisico 1 dedo = izquierdo, fisico 2 dedos = derecho."
