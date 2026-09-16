# Mac Pro 2013

![Mac Pro 2013](preview.png)

The Omarchy setup for the Late 2013 Mac Pro (MacPro6,1) — the cylinder, two FirePro D700s.

Installing the plugin only puts the cylinder on the bar. **Apply** is what actually configures the machine.

## Install

```bash
omarchy plugin add https://github.com/nomdelasociete/omarchy-mac-pro-2013.git --enable
```

Click the cylinder → **Apply · sudo in a terminal**. Type your password once.

First Apply installs package `nomdelasociete-macpro` if needed (AUR when the package exists, otherwise the GitHub Release). Pacman owns the root helper. The plugin checkout is never copied into a root path.

`omarchy plugin add` copies widget files only. It does not sudo, and it does not write `AQ_DRM_DEVICES`.

## What Apply does

- **GPUs** — puts the connected FirePro first (`/dev/dri/card2` then `card1` on a typical cylinder). Never PCI `by-path` names: those contain `:` and Hyprland login-loops.
- **Screen** — screensaver after 2.5 minutes, lock after 5. Overlay only. Click, type your password, session is back. Does not cut DisplayPort.
- **Sleep** — power-menu Suspend is hidden, Sleep key locks instead of sleeping, `systemctl suspend` / Hibernate are masked. The 2013 FirePro cannot wake DisplayPort; only a reboot recovers. Power the machine off.
- **Wi-Fi** — reconnects the Broadcom BCM4360 if the radio drops. No BSSID lock.
- **Login** — greeter keymap from `/etc/vconsole.conf`.
- **Apps** — RADV, software cursors. From the bar, relaunch a window on the other FirePro. `d700 <app>` runs something on the offload GPU.

## What it will not do

- `amdgpu.dc=0` (no picture at boot). The package ships a pacman hook that strips it before any UKI rebuild.
- Restart Hyprland, SDDM, or `gpu_recover` for a black screen
- Make the internal Wi-Fi as good as Ethernet or a USB adapter

## Remove

Bar → **Remove profile**. Plugin can stay installed.

```bash
omarchy plugin remove nomdelasociete.macpro
```

Suspend stays masked until you unmask it. Do not unmask on this hardware.

## Requirements

- Omarchy with its shell running
- Late 2013 Mac Pro, product `MacPro6,1`, two AMD FirePro D700s
- A real terminal for sudo (Apply does not use polkit)
- Package `nomdelasociete-macpro` (Apply installs it if missing). AUR when listed; until then the [v0.4.0 GitHub Release](https://github.com/nomdelasociete/omarchy-mac-pro-2013/releases/tag/v0.4.0).

MIT.

## Privilege

Apply writes your session files as you. The privileged helper is **package** `nomdelasociete-macpro`, files under `/usr/lib/nomdelasociete-macpro/`, owned by pacman.

```text
sudo env -i PATH=/usr/bin:/usr/sbin /usr/lib/nomdelasociete-macpro/apply
```

Apply refuses if that path is missing or not owned by the package. It never `sudo install`s from the plugin checkout.

The DisplayPort retrain hook is embedded in the packaged helper (here-doc). The `amdgpu.dc=0` strip runs from a packaged alpm hook.
