# Ubuntu Concept on the Zenbook A16

Work in progress. Target: the Ubuntu Concept Snapdragon image
(`stonking-desktop-arm64+x1e`, people.canonical.com/~platform/images/ubuntu-concept/),
installed over the whole disk.

## Known from the Ubuntu Concept forum thread (Nov 2026)

- The installer crashes at partitioning without a network connection; have
  USB Ethernet or phone USB tethering ready.
- The disk-unlock prompt stays black; the passphrase can be typed blind.
- Wi-Fi needs A16 board data (`board-2.bin`); Wi-Fi 7 association fails,
  limiting to Wi-Fi 6 works.
- Speakers need the ADSP firmware, the A16 topology and UCM.

## Plan

1. Install, and record what works out of the box on the current image.
2. Bring over the A16 pieces Omarchy packages: ADSP/CDSP firmware and Wi-Fi
   board data from ASUS's BSP, the audio topology/UCM and speaker tuning,
   the early-unlock initramfs modules.
3. Port `patches/omarchy-7.3-78` to the Ubuntu Concept kernel (camera,
   `cluster_cl5`, power-off) and package it.
4. Install `system/` (fallback idle service, sleep hook, libcamera tuning).
