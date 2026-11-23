# Cameras

The A16 has an OV02C10 RGB camera (CCI1, address 0x36) and an HM1092 mono
near-infrared camera for Windows Hello (CCI0, 0x24) with a PMH0101 IR emitter.
Stock linux-omarchy 7.3-78 has no CAMSS/CCI nodes for Glymur and no sensor
nodes for the A16, so no `/dev/video*` appears.

## What the patch carries

`patches/omarchy-7.3-78/0001-camera-stack-...` is FixItFoundry's stable camera
series (individual patches in `upstream-camera/`) rebased onto linux-omarchy
7.3-78:

- glymur CAMSS + CSIPHY, CCI and MCLK nodes (Qualcomm, posted upstream);
- the standalone Qualcomm MIPI CSI2 PHY driver and CCI changes, taken from
  the camera part of FixItFoundry's 0028 snapshot;
- PMH0104 camera LDOs, PM8010 over I2C, the HM1092 driver;
- the A16 RGB/IR wiring, MCLK4 at 6 mA (removes banding while the DMICs run),
  the ganged PMH0101 IR emitter.

Rebasing notes: 0026's `cci_resume_runtime()` hunk was dropped because
linux-omarchy's own CCI patches already reset the controller there; 0103 and
0108 applied with fuzz and the resulting A16 DTB was checked to contain both
sensors, the PM8010 and the privacy LED.

Kernel config: `kernel/config-a16.fragment`.

## Userspace

libcamera's simple pipeline handler with the black-level files in
`system/libcamera/` (install to `/etc/libcamera/ipa/simple/`). PipeWire lists
`ov02c10` and `hm1092` as libcamera sources; pick `ov02c10` in applications.
The 16 raw "Qualcomm Camera Subsystem" V4L2 nodes are pipeline internals.

## Tested

A 640x480 RGB frame was captured through PipeWire on the patched kernel. The
IR camera enumerates; its capture is untested.
