#!/bin/bash
# Build an Ubuntu Concept live image for the Zenbook A16 (UX3607OA):
#   - cpuidle.off=1 on the kernel command line (after "---", so the installed
#     system keeps it too): the image's kernel still has cluster_cl5, which
#     freezes and resets the laptop every few minutes, see
#     docs/freeze-cluster-cl5.md
#   - the A16 Wi-Fi board data and ADSP/CDSP firmware from ASUS's BSP in the
#     base layer (casper/minimal.squashfs), so Wi-Fi works in the live
#     session and the installer (which crashes at partitioning without a
#     network), and the installed system gets them too
#
# Usage, as root on Linux (or a privileged container) with squashfs-tools and
# xorriso, about 15 GB free next to OUT:
#
#   ./build-iso.sh stonking-desktop-arm64+x1e-20261113.iso BSP_DIR out.iso
#
# BSP_DIR is the unpacked 7z payload of ASUS's
# SOCPackage_forWebSite_Qualcomm_Z_V1.312.4500.0_50616.exe
# (sha256 e8f2389ac5d4dfd30a1a8481ec3c1e282f24baea2898414351d0b6eb1fa8a0b3),
# the same source Omarchy's asus-zenbook-a16-firmware package uses.
#
# Do not use livefs-editor's --edit-squashfs for this: its repack of the
# layered base silently dropped all of /etc (no machine-id, passwd, shadow),
# and the live session hung in systemd-firstboot behind the splash screen.
set -euo pipefail
umask 022

src=$(realpath "$1")
bsp=$(realpath "$2")/QualcommBSP
out=$3
work=$(mktemp -d "$(dirname "$(realpath "$out")")/a16iso.XXXX")
trap 'umount "$work/iso" 2>/dev/null || true; rm -rf "$work"' EXIT

mkdir "$work/iso"
mount -o loop,ro "$src" "$work/iso"

# Base layer: unpack, add firmware, repack with the original settings.
unsquashfs -no-progress -d "$work/root" "$work/iso/casper/minimal.squashfs"
fw=$work/root/usr/lib/firmware
dsp=$fw/qcom/glymur/ASUSTeK/UX3607OA
install -D -m 644 "$bsp/WIFI_BT/qcwlancol8480/bdwlan_qcc2072_1p0_ncm820A.elf" "$fw/ath12k/QCC2072/hw1.0/board.bin"
install -D -m 644 -t "$dsp" \
  "$bsp/Subsystem/qcsubsys_ext_adsp8480/qcadsp8480.mbn" \
  "$bsp/Subsystem/qcsubsys_ext_adsp8480/adsp_dtbs.elf" \
  "$bsp/NPU/qcnspmcdm8480/qccdsp8480.mbn" \
  "$bsp/NPU/qcnspmcdm8480/cdsp_dtbs.elf"
mksquashfs "$work/root" "$work/minimal.squashfs" -comp xz -b 131072 -xattrs -noappend -no-progress
du -sx --block-size=1 "$work/root" | cut -f1 > "$work/minimal.size"

# Sanity check: same entries as the original, plus the firmware.
missing=$(comm -23 <(unsquashfs -lc "$work/iso/casper/minimal.squashfs" | sort) \
                   <(unsquashfs -lc "$work/minimal.squashfs" | sort) | wc -l)
[ "$missing" = 0 ] || { echo "rebuilt base layer lost $missing files" >&2; exit 1; }
rm -rf "$work/root"

sed 's/--- quiet splash/--- quiet splash cpuidle.off=1/' "$work/iso/boot/grub/grub.cfg" > "$work/grub.cfg"
grep -q 'cpuidle.off=1' "$work/grub.cfg"

(cd "$work/iso" && grep -v -e ' ./casper/minimal.squashfs$' -e ' ./casper/minimal.size$' \
   -e ' ./boot/grub/grub.cfg$' md5sum.txt) > "$work/md5sum.txt"
(cd "$work" && for f in minimal.squashfs minimal.size; do echo "$(md5sum < $f | cut -d' ' -f1)  ./casper/$f"; done
 echo "$(md5sum < grub.cfg | cut -d' ' -f1)  ./boot/grub/grub.cfg") >> "$work/md5sum.txt"

rm -f "$out"
xorriso -indev "$src" -outdev "$out" -boot_image any replay \
  -map "$work/minimal.squashfs" /casper/minimal.squashfs \
  -map "$work/minimal.size" /casper/minimal.size \
  -map "$work/grub.cfg" /boot/grub/grub.cfg \
  -map "$work/md5sum.txt" /md5sum.txt
