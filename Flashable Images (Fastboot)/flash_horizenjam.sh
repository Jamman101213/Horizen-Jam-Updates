#!/usr/bin/env bash
# Horizen Jam 1.0 (Build HJ-0001) Fastboot Installer for Meta Quest 1 (monterey)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "============================================================"
echo "  Horizen Jam 1.0 (Build HJ-0001) - Meta Quest 1 (monterey)"
echo "  Base: v50 (49845030443200410) | Donor UI: Quest 3 v2.10"
echo "============================================================"

if [ ! -f "$SCRIPT_DIR/boot.img" ]; then
    echo "[ERROR] boot.img not found in $SCRIPT_DIR"
    exit 1
fi
if [ ! -f "$SCRIPT_DIR/system.img" ]; then
    echo "[ERROR] system.img not found in $SCRIPT_DIR"
    echo "Download system.img from the Horizen Jam GitHub Releases page and place it in this folder."
    exit 1
fi

echo "[1/3] Flashing Magisk v31.1 patched boot.img (Safe 72 Hz default) to active slot..."
fastboot flash boot "$SCRIPT_DIR/boot.img"

echo "[2/3] Flashing Horizen Jam 1.0 system.img to active slot..."
fastboot flash system "$SCRIPT_DIR/system.img"

echo "[3/3] Rebooting into Horizen Jam 1.0..."
fastboot reboot
echo "Done! Future updates can be installed directly via Settings > Software Update."
