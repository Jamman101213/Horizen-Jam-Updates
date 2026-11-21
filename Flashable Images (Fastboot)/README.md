# Horizen Jam 1.0 — Fastboot Images (Meta Quest 1 / `monterey`)

## Requirements
- **Meta Quest 1 (`monterey`)** with an **unlocked bootloader**
- Android `platform-tools` (`fastboot`) installed on your PC

> **WARNING:** **Never** run `fastboot -w` on Meta Quest 1. To factory reset cleanly after flashing, use the built-in **Settings → Jam Internals → Factory Reset** inside Horizen Jam.

## Files
- `boot.img` — Magisk v31.1 patched kernel/ramdisk (**safe 72 Hz default**, recommended for first boot)
- `boot_90hz.img` — Optional Magisk v31.1 patched kernel/ramdisk with **90 Hz OLED** display timings (can also be toggled inside Settings → Jam Internals)
- `system.img` — Horizen Jam 1.0 (`HJ-0001`, 2.50 GB raw ext4 — hosted on [GitHub Releases](https://github.com/Jamman101213/Horizen-Jam-Updates/releases) due to GitHub's 100 MB per-file repository limit)
- `flash_horizenjam.bat` / `flash_horizenjam.sh` — One-click fastboot flasher scripts

## How to Flash
1. Download `system.img` from the **1.0** release on the [Releases](https://github.com/Jamman101213/Horizen-Jam-Updates/releases) page and place it in this folder alongside `boot.img`.
2. Boot your Quest 1 into **Fastboot Mode** (power off, then hold **Power + Volume Down**).
3. Connect via USB and run:
   - **Windows:** Double-click `flash_horizenjam.bat`
   - **Linux / macOS:** `chmod +x flash_horizenjam.sh && ./flash_horizenjam.sh`

   Or flash manually:
   ```bash
   fastboot flash boot boot.img
   fastboot flash system system.img
   fastboot reboot
   ```
4. Once booted, future updates can be installed over-the-air via **Settings → System → Software Update** (or **Settings → Jam Internals → Check OTA**).
