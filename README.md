# Linux on the ASUS Zenbook A16 (UX3607OA, Snapdragon X2 Elite)

Kernel patches, system configuration and notes for running Linux on the
**Snapdragon X2 Elite** Zenbook A16, model **UX3607OA** (Glymur SoC). The AMD
Zenbook A16 models are different machines and nothing here applies to them.

The kernel patches are distribution-independent. They were built and tested
on Omarchy's `linux-omarchy` 7.3-78; [`ubuntu/`](ubuntu/) tracks the move to
Ubuntu Concept.

## Status on linux-omarchy 7.3-78 + these patches

| Area | State | Notes |
|---|---|---|
| Random freeze, then reset every few minutes | **Fixed** | [docs/freeze-cluster-cl5.md](docs/freeze-cluster-cl5.md) |
| Cameras (OV02C10 RGB, HM1092 IR) | **Works** | [docs/camera.md](docs/camera.md) |
| Lid-close suspend (s2idle) | Works, shallow | [docs/sleep.md](docs/sleep.md) |
| Power off reboots instead | Patch applied, unconfirmed | [docs/poweroff.md](docs/poweroff.md) |
| Wi-Fi, Bluetooth, keyboard, touchpad, display, speakers | Works | Stock linux-omarchy |

## Layout

```
patches/omarchy-7.3-78/      applies on linux-omarchy 7.3-78
  0001-camera-stack-...      the camera series as one diff
  0002-...cluster_cl5...     freeze fix
  0003-...Power-off...       power-off fix
  upstream-camera/           the individual camera patches, original authors
kernel/config-a16.fragment   options the camera patches need
system/                      systemd unit, sleep hook, libcamera tuning
docs/                        findings, and how the kernel was built
ubuntu/                      Ubuntu Concept bring-up
```

## Before installing a patched kernel

The patches change the device tree. Keep a bootable fallback (Omarchy's
Limine snapshots, or the distribution's previous kernel).

## Credits

- Camera, EC, Wi-Fi and most A16 bring-up: Jesse Casco,
  [FixItFoundry/zenbook-a16-linux](https://github.com/FixItFoundry/zenbook-a16-linux),
  and the Qualcomm engineers credited in each patch.
- `cluster_cl5` mitigation: Jens Glathe (hamoa), suggested by Marc Zyngier;
  reported on the A16 by a Gentoo user in the Ubuntu Concept forum thread.
- Power-off approach: the Inspiron 14 3420 patch in omacom/omarchy-pkgs
  (Matt Durr, Birk Skyum).
- Omarchy's A16 support: omacom/omarchy, omacom/omarchy-pkgs.

Patches keep the license of the files they modify (GPL-2.0 for the kernel).
