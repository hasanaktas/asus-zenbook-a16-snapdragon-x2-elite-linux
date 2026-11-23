# Building the patched linux-omarchy

Built on an Apple Silicon Mac in an Arch Linux ARM container (native arm64).
The kernel tree has files that differ only by case, so build inside the
container's own volume, not a macOS bind mount.

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

Recipes: `pkgbuilds/linux-omarchy-aarch64` and `pkgbuilds/linux-omarchy-dtbs`
from [omacom/omarchy-pkgs](https://github.com/omacom/omarchy-pkgs) at pkgrel
78 / 63.

1. `makepkg -o --skippgpcheck` in the kernel recipe: downloads 7.3 and applies
   Omarchy's patches.
2. In `src/linux-7.3`, apply `patches/omarchy-7.3-78/000{1,2,3}-*.patch`.
3. Append `kernel/config-a16.fragment` to `.config`, `make olddefconfig`.
4. Set a distinct release so it is obvious which kernel runs:
   `echo -78.1 > localversion.10-pkgrel`, `make -s kernelrelease > version`,
   and `pkgrel=78.1` in the PKGBUILD. Keep any `.git` out of the tree, or
   the release gets a `+`.
5. `makepkg -e -f --skipchecksums --skippgpcheck` (about 30-60 min).
6. Install the new `linux-omarchy-headers` in the container, then build
   `linux-omarchy-dtbs` against it (`pkgrel=63.1`): the DTBs are compiled
   from the headers' device-tree sources, so the camera nodes and the
   `cluster_cl5` change only reach the boot image this way.

Install on the laptop with `pacman -U` of `linux-omarchy`,
`linux-omarchy-headers` and `linux-omarchy-dtbs`; Limine's UKI hook rebuilds
the boot image. Take a snapper snapshot first. An `omarchy update` that brings
a newer `linux-omarchy` replaces this kernel; rebuild on top of it.
