# Running BricsCAD on ub-cosmic

ub-cosmic bakes in the **runtime libraries BricsCAD needs** so it has the best chance of running.
The application itself is **proprietary and license-gated**, so it is *not* bundled — you install it
yourself (below). [Fedora is an officially supported BricsCAD platform](https://help.bricsys.com/en-us/document/bricscad/installation-and-licensing/bricscad-system-requirements?version=V26&id=165079150963)
(glibc ≥ 2.35, x86-64), and ub-cosmic's Bazzite/Fedora base satisfies that.

## What's baked in (build.sh)

BricsCAD **V26 is Qt 6.8-based** (older versions were GTK), so the image ships:

- **Qt 6:** `qt6-qtbase`, `qt6-qtbase-gui`, `qt6-qtsvg`, `qt6-qtwayland`
- **Qt xcb platform plugin deps:** `xcb-util`, `xcb-util-image`, `xcb-util-keysyms`,
  `xcb-util-renderutil`, `xcb-util-wm`, `xcb-util-cursor`, `libxkbcommon`, `libxkbcommon-x11`,
  `libX11-xcb` (these are what cause the infamous *"could not load the Qt platform plugin xcb"* error
  when missing)
- **X11 libs:** `libSM`, `libICE`, `libXi`, `libXtst`, `libXrandr`, `libXmu`, `libXScrnSaver`
- **3D / OpenGL:** `mesa-libGLU` (plus the base image's `mesa-libGL` / DRI drivers)
- **Fonts / misc:** `fontconfig`, `freetype`, `libdeflate`, `hicolor-icon-theme`
- **Licensing/network:** `openssl-libs` (the base's `libcurl-minimal` already provides `libcurl.so`)
- **Legacy GTK2 compat:** `gtk2`, `libpng12` — belt-and-suspenders for the RPM's older `Requires`

## Installing BricsCAD

1. Download the **Fedora/openSUSE `.rpm`** from the [Bricsys download page](https://www.bricsys.com/en-intl/download)
   (choose Linux → Fedora, OpenSUSE).
2. Layer it onto the image (ub-cosmic is an atomic/bootc system, so use package layering — not a
   plain `dnf install` into the running system):
   ```bash
   rpm-ostree install ~/Downloads/BricsCAD-V26*.x86_64.rpm
   systemctl reboot
   ```
   The baked dependencies above should let this resolve cleanly. If the RPM insists on the full
   `libcurl` (the base ships `libcurl-minimal`), add `--allowerasing`:
   `rpm-ostree install --allowerasing ~/Downloads/BricsCAD-V26*.x86_64.rpm`.
3. Launch BricsCAD from the app grid and activate your license (needs network).

> **Updates note:** a layered package persists across ub-cosmic's image updates, but you update
> BricsCAD itself by layering a newer RPM. If a future base change ever conflicts with the layer,
> `rpm-ostree uninstall` it, update, then re-layer.

## GPU / graphics caveats (from Bricsys)

BricsCAD's own requirements state **3D hardware acceleration is NOT supported on Intel graphics
chipsets or on laptops with dual graphics adapters**. For ub-cosmic that means:

- **NVIDIA machines** → install/boot the **`ub-cosmic-nvidia`** image (ub-cosmic auto-rebases to it on
  first boot). 3D accel supported. ✅
- **AMD machines** → the base `ub-cosmic` image (Mesa). 3D accel supported. ✅
- **Intel-only machines** → base image; BricsCAD 3D runs **without** hardware acceleration (slower).
  This is a BricsCAD limitation, not an ub-cosmic one.

## Wayland note

COSMIC and GNOME are Wayland. Qt 6 runs on Wayland (`qt6-qtwayland`) or through XWayland (the `xcb`
libs above). If you hit rendering or input glitches, force X11/XWayland:

```bash
QT_QPA_PLATFORM=xcb bricscad
```

## Minimum specs (Bricsys)

8 GB RAM minimum (16 GB recommended), 3 GB disk, Intel Core i5 / AMD Ryzen 5 or better, x86-64.
