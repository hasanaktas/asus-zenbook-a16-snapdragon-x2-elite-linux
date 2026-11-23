# Lid-close suspend

Omarchy turns suspend off on the A16 (`/etc/systemd/sleep.conf.d/omarchy-sleep-disabled.conf`):
deep sleep resets the SoC on wake and an overnight s2idle once hung.

## What works

With s2idle and the hook in `system/system-sleep/a16-sleep`:

- before sleep: remove the Wi-Fi card's PCIe root port (`0004:00:00.0`),
  unbind the card reader's xHCI controller (`a400000.usb`), and let the CPUs
  use their idle states;
- after wake: on a kernel that still has `cluster_cl5`, disable the CPU idle
  states again; rebind the card reader; rescan PCI.

Sleep config: `MemorySleepMode=s2idle` in `/etc/systemd/sleep.conf.d/`, and
Omarchy's `omarchy-sleep-disabled.conf` renamed away.

Three suspends of a few seconds to 20 minutes all woke cleanly with Wi-Fi back.

## What does not

`/sys/kernel/debug/qcom_stats`: `apss` counts up, but `cxsd`, `aosd` and
`ddr` stay at 0, so the SoC never collapses CX. `qcom-pcie 1bf0000.pcie:
Timeout waiting for L2 entry` is logged on every suspend, with or without the
Wi-Fi port removed. Measured drain is roughly 1.5-2 W asleep against ~10 W
awake. FixItFoundry carries PCIe suspend patches (0012, 0048, 0049) aimed at
this; they are not in this tree yet.
