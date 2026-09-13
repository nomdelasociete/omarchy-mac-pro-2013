# Mac Pro 2013

The one Omarchy setup for the Late 2013 Mac Pro (MacPro6,1) — the cylinder.

Everyone else with this machine either:

```sh
omarchy plugin add https://github.com/nomdelasociete/omarchy-mac-pro-2013.git --enable
```

then **Apply Mac Pro profile** from the bar (sudo in a terminal) —

or they do the DRM / sleep / Wi-Fi / keymap ritual by hand. Don’t.

`omarchy plugin add` clones files only. It does **not** sudo, and it does **not** write `AQ_DRM_DEVICES`.

Apply is a **user** script: it writes your session files, then `sudo install`s helpers into **root-owned** `/usr/local/libexec/nomdelasociete-macpro/` and runs **that** copy with `env -i PATH=/usr/bin:/usr/sbin`. Root never executes the plugin checkout.

## What Apply does

- DRM: `/dev/dri/card2` (display) then `card1` (offload). Never PCI `by-path` (login loop). Never invent `d700-*` names.
- **Screen:** Omarchy screensaver 2.5 min + lock 5 min (compositor overlay). Validated: click → password → session back. Does **not** cut DisplayPort.
- **Sleep:** power-menu Sleep / `systemctl suspend` / Hibernate **masked**. amdgpu DC on DCE 6.0 wedges HPD (`dal_gpio_service_open`); only a reboot recovers. Fix is a kernel patch, not this plugin. Power the machine off.
- Never `amdgpu.dc=0` (no picture at boot).
- Never restart Hyprland/SDDM/`gpu_recover` for a black screen.
- BCM4360 Wi-Fi watchdog (reconnect, no BSSID lock).
- Login greeter keymap from `/etc/vconsole.conf`.
- RADV only. Software cursors.
- Bar: relaunch a window on the other FirePro.
- `d700 <app>` / Super+Alt+M (sharp vs 60 Hz on the current cable).

## Remove

Bar → **Remove profile**. Plugin can stay installed.

## Not this plugin

A USB Wi-Fi adapter or Ethernet will always beat the internal BCM4360. Apply does not pretend otherwise.
