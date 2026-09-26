#!/usr/bin/env python3
"""syna3602-fix: workaround en userspace para el boton fisico del touchpad
SYNA3602:00 0911:5288 (Hantick, I2C HID) en notebooks VAIO (ej. VJFE51A0211H).

Problema: el hardware emite BTN_LEFT con 1 dedo y BTN_RIGHT con 2 dedos,
pero libinput descarta el BTN_RIGHT por tratarse de un clickpad
("kernel bug: received BTN_RIGHT button event on a clickpad", ver
30-vendor-hantick.quirks que filtra BTN_RIGHT). Resultado: el clic
derecho fisico nunca llega al escritorio.

Fix: reemite BTN_RIGHT (y BTN_MIDDLE si aparece) en un puntero virtual
uinput que NO es clickpad, asi libinput lo acepta. BTN_LEFT no se toca
porque ya llega nativo.

Mapeo final:
  fisico 1 dedo = clic izquierdo (nativo)
  fisico 2 dedos = clic derecho (virtual)
  toque 1/2 dedos = izquierdo/derecho (tap-to-click de GNOME, sin cambios)

Bug upstream: https://bugzilla.kernel.org/show_bug.cgi?id=222005
El arreglo real debe ir en el driver hid-multitouch del kernel.
"""
import glob
import select
import time

import evdev
from evdev import UInput, ecodes

DEVICE_SUBSTRING = "SYNA3602"
VIRTUAL_NAME = "syna3602-fix"


def find_sources():
    """Todos los nodos /dev/input/event* del touchpad (la enumeracion cambia
    entre boots/suspensiones: event7, event8, event9...)."""
    sources = []
    for path in sorted(glob.glob("/dev/input/event*")):
        try:
            device = evdev.InputDevice(path)
        except Exception:
            continue
        if DEVICE_SUBSTRING in device.name:
            sources.append(device)
    return sources


def main():
    while True:
        sources = find_sources()
        if not sources:
            time.sleep(5)
            continue
        capabilities = {
            ecodes.EV_KEY: [ecodes.BTN_RIGHT, ecodes.BTN_MIDDLE],
            ecodes.EV_REL: [ecodes.REL_X, ecodes.REL_Y],
        }
        try:
            virtual = UInput(capabilities, name=VIRTUAL_NAME)
        except Exception:
            time.sleep(5)
            continue
        try:
            while True:
                readable, _, _ = select.select(
                    [s.fd for s in sources], [], [], 1.0
                )
                by_fd = {s.fd: s for s in sources}
                for fd in readable:
                    for event in by_fd[fd].read():
                        if event.type != ecodes.EV_KEY:
                            continue
                        if event.code in (ecodes.BTN_RIGHT, ecodes.BTN_MIDDLE):
                            virtual.write(ecodes.EV_KEY, event.code, event.value)
                            virtual.syn()
                        # BTN_LEFT: no tocar, ya llega nativo al escritorio.
        except Exception:
            try:
                virtual.close()
            except Exception:
                pass
            time.sleep(2)


if __name__ == "__main__":
    main()
