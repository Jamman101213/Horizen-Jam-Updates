# Horizen Jam - Download and OTA

**Note: This repo is where you can download Horizen Jam and where it gets its OTA updates from. Horizen Jam is not open source!**

Download: https://github.com/Jamman101213/Horizen-Jam-Updates/releases/tag/Fastboot-Installer 
**Step 1. Unzip the file and run 'adb reboot bootloader' with your device connected.**
**Step 2. Run the flash bat/sh file.**

**Horizen Jam** is a custom Android 10–based firmware engineered specifically for the **Meta Quest 1 (`monterey`)**. Built on the official Quest 1 **v50** (`49845030443200410`) system architecture and infused with backported visual assets, shell layouts, and features from **Meta Quest 3 Horizon OS 2.10**, it unlocks modern capabilities, root customization, built-in OTA updates, and account-free control on original Quest hardware.

## Base Architecture

* **Target Device:** Meta Quest 1 (`monterey` / Snapdragon 835)
* **Base Firmware:** Oculus / Meta Quest OS **v50** (`50.0.0.198.257.455910822` / Build `49845030443200410`)
* **Android Base:** Android 10 (`QQ3A.200805.001`, API Level 29)
* **Feature & UI Source:** Meta Quest 3 Horizon OS **2.10** (`v210`)
* **Default Refresh Rate:** **90 Hz OLED** (`boot.img` pre-patched with Magisk v31.1)

## Core Highlights

* **Horizon OS 2.10 Visual Backport:** Brings the streamlined Navigator system bar, status-bar quick controls, Theater viewing environment, and smooth resizable 2D multitasking windows onto Quest 1 v50.
* **Native Settings → Jam Internals:** Integrated directly into the regular Quest Settings menu — includes live accent color themes, Snapdragon 835 performance profiles, 72 Hz / 90 Hz switching, Quest 3 / Singularity device spoofing, Direct Touch, Guardian/proximity controls, Wireless ADB, and a safe built-in Factory Reset (`/data` + `/vision`).
* **Built-In GitHub OTA Updates:** Uses the headset's native **Settings → System → Software Update** screen to fetch and install future Horizen Jam updates directly from this repository's Releases.
* **Account-Free Offline Mode & First-Boot Setup:** Optional first-time setup skip plus staged **NikGapps Core** installer with automatic clean initialization.
* **Meta Telemetry Blocking:** Blocks Oculus/Meta logging, crash reporting, and telemetry endpoints while preserving Login, Store, and GitHub OTA access.
* **Horizen Files (Root VR File Manager):** Pre-granted global root access (`--mount-master`) with R/W partition remounting, built-in config/prop editing, and USB OTG support.

---

## How to Install (Fastboot — First-Time Setup)

### Requirements
* A **Meta Quest 1 (`monterey`)** with an **unlocked bootloader** (on v50 firmware)
* A USB cable connected to your PC
* Android **`platform-tools`** (`fastboot` / `adb`) installed and added to your PATH

> **WARNING:** **NEVER run `fastboot -w`** on a Meta Quest 1 — it can break `/data` and `/vision` encryption. If you need a factory reset after installing, use **Settings → Jam Internals → Factory Reset** inside Horizen Jam instead.

### Installation Steps
1. **Download `Fastboot Installer.zip`** from the [Flashable Images](./Flashable%20Images) folder (or the [Releases](https://github.com/Jamman101213/Horizen-Jam-Updates/releases) page) and **extract** all files into a folder on your PC.
2. **Boot your Quest 1 into Fastboot Mode** using either method:
   * **Hardware buttons:** Power off the Quest 1 completely, then hold **Power + Volume Down** until the fastboot / USB Update Mode screen appears.
   * **Via ADB (if booted & USB debugging is on):**
     ```bash
     adb reboot bootloader
     ```
3. **Connect your Quest 1 via USB** and flash Horizen Jam:
   * **Windows:** Double-click **`flash_horizenjam.bat`**
   * **Linux / macOS:** Open a terminal in the extracted folder and run:
     ```bash
     chmod +x flash_horizenjam.sh && ./flash_horizenjam.sh
     ```
   * **Or flash manually:**
     ```bash
     fastboot flash boot boot.img
     fastboot flash system system.img
     fastboot reboot
     ```
4. **Wait for first boot:** Your Quest 1 will reboot automatically into **Horizen Jam 1.0** (the first boot may take 1–2 minutes while caches initialize). Follow the on-screen **Horizen Setup** to optionally install NikGapps Core or jump straight into Home.

---

## How to Update (Over-the-Air / OTA)

Once Horizen Jam **1.0** is installed, you do **not** need a PC for future updates:

1. Connect your Quest 1 to **Wi-Fi**.
2. Open **Settings → System → Software Update** (or **Settings → Jam Internals → Check OTA**).
3. Select **Check for Updates** — Horizen Jam will automatically detect any newer release from this repository, download it, apply the update, and prompt you to restart.
