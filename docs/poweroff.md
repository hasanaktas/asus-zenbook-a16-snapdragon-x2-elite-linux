# Power off reboots instead

## Symptom

Shutting down restarts the laptop. The journal of the previous boot ends with
"System is powering down" and the next boot starts one second later.

## Cause (as far as known)

arm64 Linux powers off through UEFI `ResetSystem(EfiResetShutdown)` whenever
EFI runtime services are enabled. The Dell Inspiron 14 3420 (SC8180XP) has the
same fault; linux-omarchy patch 2912 skips the EFI power-off handler there so
PSCI `SYSTEM_OFF` is used. EFI variables on this laptop go through
`qcom.tz.uefisecapp`, not runtime services, so skipping it does not affect them.

## Patch

`patches/omarchy-7.3-78/0003-...` adds `asus,zenbook-a16-ux3607oa` to that
exception.

## Status: unconfirmed

After installing it, one shutdown was again followed by a boot one second
later. Whether PSCI `SYSTEM_OFF` also reboots on this firmware is not settled
yet. Workaround: when the ASUS logo appears after a shutdown, hold the power
button for 10 seconds (Linux has not mounted the disk at that point).
