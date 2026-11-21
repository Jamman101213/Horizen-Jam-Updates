# Horizen Jam - Download and OTA

**Note: this repo is where you can download Horizen Jam, and is where the Horizen Jam gets it's updates from. Horizen Jam is not open source!**

**Horizen Jam** is a custom Android 10–based firmware engineered specifically for the **Meta Quest 1 (`monterey`)**. Built on the official Quest 1 **v50** (`49845030443200410`) system architecture and infused with backported visual assets, shell layouts, and features from **Meta Quest 3 Horizon OS 2.10**, it unlocks modern capabilities, root customization, and account-free control on original Quest hardware.

## Base Architecture

* **Target Device:** Meta Quest 1 (`monterey` / Snapdragon 835)
* **Base Firmware:** Oculus / Meta Quest OS **v50** (`50.0.0.198.257.455910822` / Build `49845030443200410`)
* **Android Base:** Android 10 (`QQ3A.200805.001`, API Level 29)
* **Feature & UI Source:** Meta Quest 3 Horizon OS **2.10** (`v210`)

## Core Highlights

* **Horizon OS 2.10 Visual Backport:** Brings the streamlined Navigator system bar, status-bar quick controls, Theater viewing environment, and smooth locked-aspect window resizing onto Quest 1 v50.
* **Account-Free Offline Mode:** Optional first-time setup (`FirstTimeNux`) skip so the headset works out of the box without a Meta account or companion phone app.
* **Pre-Setup Experimental GApps:** Staged `NikGapps` Core installer with a live TWRP-style progress bar and automatic factory reset initialization.
* **Horizen Jam Settings & Root Suite:** Pre-patched Magisk root, system-wide accent color overlays, safe 72 Hz / 90 Hz OLED refresh switching, dormant v50 Direct Touch & 2D multitasking unlocks, and a clean VR bridge for hidden AOSP Android settings.
* **Horizen Files (Root VR File Manager):** Pre-granted global root access (`--mount-master`) with R/W partition remounting, built-in config/prop editing, SELinux `restorecon` preservation, and `FAT32`/`exFAT`/`NTFS` USB OTG auto-mounting.
