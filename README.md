# syna3602-fix

Workaround en userspace para el botón físico del touchpad
**SYNA3602:00 0911:5288** (Hantick, I2C HID) en notebooks VAIO
(probado en VAIO `VJFE51A0211H`, placa `N15WP6`, CachyOS / kernel 7.2.x).

## Problema

El hardware emite por el reporte HID táctil:

| Dedos | Evento kernel |
|---|---|
| 1 dedo | `BTN_LEFT (272)` |
| 2 dedos | `BTN_RIGHT (273)` |

Pero libinput considera el dispositivo un clickpad y **descarta** el
`BTN_RIGHT`:

```
SYNA3602:00 0911:5288: kernel bug: received BTN_RIGHT button event on a clickpad
```

(ver quirk `30-vendor-hantick.quirks` que filtra `BTN_RIGHT` con
`AttrEventCode=-BTN_RIGHT`). Resultado: el **clic derecho físico no
llega nunca al escritorio**.

Bug upstream (el arreglo real va en `hid-multitouch` del kernel):
https://bugzilla.kernel.org/show_bug.cgi?id=222005

## Solución

Un daemon en Python que reemite `BTN_RIGHT` / `BTN_MIDDLE` en un puntero
virtual `uinput` (`syna3602-fix`) que **no** es clickpad, así libinput lo
acepta. `BTN_LEFT` no se toca porque ya llega nativo (reemitirlo causaba
doble clic).

Mapeo final:

| Acción | Resultado |
|---|---|
| Físico 1 dedo | clic izquierdo (nativo) |
| Físico 2 dedos | clic derecho (virtual) |
| Toque 1 dedo / 2 dedos | izquierdo / derecho (tap-to-click de GNOME, sin cambios) |

## Instalación

En una línea (Fedora, Arch/CachyOS, Debian/Ubuntu):

```bash
curl -sSL https://raw.githubusercontent.com/AZIT0/syna3602-fix/master/install.sh | sudo bash
```

O clonando el repo:

```bash
git clone https://github.com/AZIT0/syna3602-fix.git
cd syna3602-fix
sudo bash install.sh
```

Verificar:

```bash
systemctl is-active syna3602-fix.service
sudo libinput list-devices | grep -A8 syna3602-fix
```

## Desinstalación

```bash
sudo bash uninstall.sh
```

## Licencia

MIT, ver `LICENSE`.
