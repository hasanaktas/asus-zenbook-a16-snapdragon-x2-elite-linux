# Building the patched linux-omarchy

Built on an Apple Silicon Mac, natively on arm64, in an Arch Linux ARM
container. The kernel tree has files whose names differ only by case, so build
inside the container's own volume, not in a macOS bind mount.

```sh
IMG=ghcr.io/menci/archlinuxarm@sha256:3e1074c407fc1a57c2a2117af6920c96a7cc906fa6f1f2da8a4a7fd3aa2c2f4e
docker volume create a16kb-build
docker run -d --name a16kb -v a16kb-build:/build $IMG sleep infinity
docker exec a16kb sh -c '
  sed -i "/^\[options\]/a DisableSandbox" /etc/pacman.conf   # Landlock fails in Docker
  pacman-key --init && pacman-key --populate archlinuxarm
  pacman -Syu --noconfirm --needed base-devel git bc cpio gettext libelf openssl \
    pahole perl python rust rust-bindgen rust-src tar xxhash xz zlib zstd clang llvm dtc sudo
  useradd -m builder && echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder
  chown builder /build'
```

The recipes are `pkgbuilds/linux-omarchy-aarch64` and `pkgbuilds/linux-omarchy-dtbs`
from [omacom/omarchy-pkgs](https://github.com/omacom/omarchy-pkgs). Use the
patch directory that matches the recipe:

| linux-omarchy | omarchy-pkgs | dtbs pkgrel | Patches |
|---|---|---|---|
| 7.3-78 | before 7.3.6 | 63 | `patches/omarchy-7.3-78/` |
| 7.3.6-2 | `923ba2b` | 66 | `patches/omarchy-7.3.6-2/` |

If the container's network is slow, download the kernel tarball (and the
NVIDIA module source the recipe lists) elsewhere and copy them next to the
PKGBUILD. makepkg uses files that are already there.

1. Run `makepkg -o --skippgpcheck` in the kernel recipe. This unpacks the
   kernel and applies Omarchy's patches.
2. In `src/linux-<version>`, apply `000*.patch` from the matching patch
   directory in order (`patch -p1`).
3. Append `kernel/config-a16.fragment` to `.config`, then run
   `make olddefconfig`.
4. Give the build a distinct release, so it is obvious which kernel is running.
   For example, with release `2.4`:
   - `echo -2.4 > localversion.10-pkgrel`
   - `make -s kernelrelease > version`
   - set `pkgrel=2.4` in the PKGBUILD

   Keep any `.git` out of the tree, or the release gets a `+`.
5. Run `makepkg -e -f --skipchecksums --skippgpcheck`. The build takes 20-60
   minutes.
6. Install the new `linux-omarchy-headers` in the container, then build
   `linux-omarchy-dtbs` against it with `pkgrel` bumped (for example 66.1).
   The DTBs are compiled from the headers' device-tree sources. This is the
   only way the camera nodes and the `cluster_cl5` change reach the boot image.

To install on the laptop, take a snapper snapshot first. Then run `pacman -U`
on `linux-omarchy`, `linux-omarchy-headers` and `linux-omarchy-dtbs`. Limine's
UKI hook rebuilds the boot image.

An `omarchy update` that brings a newer `linux-omarchy` or
`linux-omarchy-dtbs` replaces this build. On 7.3.6-2 that also brings back the
GPU corruption from [gpu-corruption-7.3.6.md](gpu-corruption-7.3.6.md).
Rebuild on top of the new version instead.
