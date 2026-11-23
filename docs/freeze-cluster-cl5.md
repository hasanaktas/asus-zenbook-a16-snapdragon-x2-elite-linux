# Freeze, then reset: the `cluster_cl5` idle state

## Symptom

On stock linux-omarchy 7.3-78 the laptop froze and reset every 2-3 minutes in
normal use. Journals end abruptly; no panic is logged.

## Cause

Glymur's device tree gives each CPU cluster power domain a domain idle state,
`cluster_cl5` (PSCI suspend param `0x01000054`). On X1 (hamoa) the same state
"triggers DC ZVA misbehaviour that resets X1 SoCs" and linux-omarchy drops it
there (patch 2151, Jens Glathe), but not on Glymur. A Gentoo user on the A16
reported the same random resets from it.

## Evidence

Disabling every CPU idle state at runtime stopped the resets (half an hour
without one, where it had reset every 2-3 minutes):

```sh
echo 1 | sudo tee /sys/devices/system/cpu/cpu*/cpuidle/state*/disable
```

## Fix

`patches/omarchy-7.3-78/0002-...` removes `domain-idle-states = <&cluster_cl5>`
from `cluster0_pd`..`cluster2_pd` in `glymur.dtsi` and keeps the per-CPU
retention state (`cpu_c4`, "ret"), so idle power is not given up the way the
runtime workaround gives it up.

## Fallback for a kernel without the fix

`system/systemd/a16-no-cluster-idle.service` disables all CPU idle states at
boot, but only when the running device tree still has
`/sys/firmware/devicetree/base/psci/power-domain-cpu-cluster0/domain-idle-states`.
On a patched kernel it does nothing, so it can stay installed and catches a
distribution kernel update that lacks the fix.
