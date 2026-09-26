#!/usr/bin/env bash
# Desinstalador de syna3602-fix. Correr con sudo: sudo bash uninstall.sh
set -e

if [[ $EUID -ne 0 ]]; then
    echo "Corre con sudo: sudo bash uninstall.sh"
    exit 1
fi

systemctl disable --now syna3602-fix.service || true
rm -f /etc/systemd/system/syna3602-fix.service /usr/local/bin/syna3602-fix.py
systemctl daemon-reload
echo "OK: syna3602-fix desinstalado."
