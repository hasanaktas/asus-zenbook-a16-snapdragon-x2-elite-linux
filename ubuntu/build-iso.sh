#!/bin/sh
# Build an Ubuntu Concept live image for the Zenbook A16 (UX3607OA):
#   - cpuidle.off=1 on the kernel command line (after "---", so the installed
#     system keeps it too): the image's kernel still has cluster_cl5, which
#     freezes and resets the laptop every few minutes, see
#     docs/freeze-cluster-cl5.md
#   - the A16 Wi-Fi board data and ADSP/CDSP firmware from ASUS's BSP in the
#     base layer, so Wi-Fi works in the live session and the installer (which
#     crashes at partitioning without a network) and the installed system
#     gets them too
#
# Usage, in a privileged Ubuntu container with livefs-editor
# (pip install git+https://github.com/mwhudson/livefs-editor), xorriso and
# squashfs-tools, with TMPDIR on a real filesystem (overlayfs cannot stack on
# Docker's overlay root):
#
#   ./build-iso.sh stonking-desktop-arm64+x1e-20261113.iso BSP_DIR out.iso
#
# BSP_DIR is the unpacked 7z payload of ASUS's
# SOCPackage_forWebSite_Qualcomm_Z_V1.312.4500.0_50616.exe
# (sha256 e8f2389ac5d4dfd30a1a8481ec3c1e282f24baea2898414351d0b6eb1fa8a0b3),
# the same source Omarchy's asus-zenbook-a16-firmware package uses.
# livefs-edit calls `udevadm settle`; in a container a stub that exits 0 is enough.
set -eu
umask 022

src=$1
bsp=$2/QualcommBSP
out=$3
fw=new/minimal/usr/lib/firmware
dsp=qcom/glymur/ASUSTeK/UX3607OA

livefs-edit "$src" "$out" \
  --add-cmdline-arg cpuidle.off=1 \
  --edit-squashfs minimal \
  --cp "$bsp/WIFI_BT/qcwlancol8480/bdwlan_qcc2072_1p0_ncm820A.elf" "$fw/ath12k/QCC2072/hw1.0/board.bin" \
  --cp "$bsp/Subsystem/qcsubsys_ext_adsp8480/qcadsp8480.mbn" "$fw/$dsp/qcadsp8480.mbn" \
  --cp "$bsp/Subsystem/qcsubsys_ext_adsp8480/adsp_dtbs.elf" "$fw/$dsp/adsp_dtbs.elf" \
  --cp "$bsp/NPU/qcnspmcdm8480/qccdsp8480.mbn" "$fw/$dsp/qccdsp8480.mbn" \
  --cp "$bsp/NPU/qcnspmcdm8480/cdsp_dtbs.elf" "$fw/$dsp/cdsp_dtbs.elf"
