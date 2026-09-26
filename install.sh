#!/usr/bin/env bash
# Instalador de syna3602-fix (Arch/CachyOS, Fedora, Debian/Ubuntu).
# Uso local:  sudo bash install.sh
# Una linea:  curl -sSL https://raw.githubusercontent.com/AZIT0/syna3602-fix/master/install.sh | sudo bash
set -e

RAW_BASE="https://raw.githubusercontent.com/AZIT0/syna3602-fix/master"

if [[ $EUID -ne 0 ]]; then
    echo "Corre con sudo."
    exit 1
fi

if ! python3 -c "import evdev" 2>/dev/null; then
    echo "Instalando python-evdev..."
    if command -v pacman >/dev/null; then
        pacman -S --needed --noconfirm python-evdev
    elif command -v dnf >/dev/null; then
        dnf install -y python3-evdev
    elif command -v apt-get >/dev/null; then
        apt-get update && apt-get install -y python3-evdev
    else
        echo "Instalalo a mano y reintenta."
        exit 1
    fi
fi

cd "$(dirname "$0")"
for f in syna3602-fix.py syna3602-fix.service; do
    [[ -f $f ]] || curl -sSL -o "$f" "$RAW_BASE/$f"
done

cp syna3602-fix.py /usr/local/bin/syna3602-fix.py
chmod 644 /usr/local/bin/syna3602-fix.py
cp syna3602-fix.service /etc/systemd/system/syna3602-fix.service
chmod 644 /etc/systemd/system/syna3602-fix.service
command -v restorecon >/dev/null && restorecon /usr/local/bin/syna3602-fix.py || true

systemctl daemon-reload
systemctl enable --now syna3602-fix.service
sleep 2
systemctl is-active syna3602-fix.service
echo "OK: fisico 1 dedo = izquierdo, fisico 2 dedos = derecho."
