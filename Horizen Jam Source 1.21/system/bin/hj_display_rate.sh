#!/system/bin/sh
# Horizen Jam 1.1 - Quest 1 Samsung Lightman OLED 72Hz / 90Hz Display & Boot Flasher
# Default: Safe 72Hz. Supports live chunked 0-100% progress reporting when adding/removing 90Hz!

CMD="${1:-status}"

flash_boot_with_progress() {
    IMG="$1"
    TARGET_IS_90="$2"
    SLOT=$(getprop ro.boot.slot_suffix)
    DEV="/dev/block/bootdevice/by-name/boot${SLOT}"

    echo "PROGRESS 2"
    if [ ! -f "$IMG" ]; then
        echo "[FAILED] Boot image not found: $IMG"
        exit 2
    fi
    if [ ! -b "$DEV" ]; then
        echo "[FAILED] Boot block device not found: $DEV"
        exit 3
    fi

    SIZE_BYTES=$(wc -c < "$IMG" 2>/dev/null | tr -dc '0-9')
    if [ -z "$SIZE_BYTES" ] || [ "$SIZE_BYTES" -lt 1048576 ]; then
        echo "[FAILED] Invalid boot image size: $SIZE_BYTES"
        exit 4
    fi

    MB_TOTAL=$(( (SIZE_BYTES + 1048575) / 1048576 ))
    echo "[INFO] Flashing $(basename "$IMG") ($MB_TOTAL MB) to boot${SLOT}..."
    blockdev --setrw "$DEV" 2>/dev/null || true

    IDX=0
    while [ "$IDX" -lt "$MB_TOTAL" ]; do
        # CRITICAL: conv=notrunc is required on Android toybox dd when seek>0 on raw block devices
        # (without conv=notrunc, toybox calls ftruncate() on boot_a/boot_b -> EINVAL at block 1 / 7%!)
        if ! dd if="$IMG" of="$DEV" bs=1048576 count=1 skip="$IDX" seek="$IDX" conv=notrunc 2>/dev/null; then
            echo "[FAILED] Write error at block $IDX / $MB_TOTAL"
            exit 5
        fi
        IDX=$((IDX + 1))
        PCT=$(( (IDX * 94) / MB_TOTAL + 4 ))
        [ "$PCT" -gt 98 ] && PCT=98
        echo "PROGRESS $PCT"
    done

    sync
    # Verify Android boot header magic ("ANDROID!") readback from block device
    MAGIC=$(dd if="$DEV" bs=8 count=1 2>/dev/null)
    if [ "$MAGIC" != "ANDROID!" ]; then
        echo "[FAILED] Boot header verification failed on $DEV (got: $MAGIC)!"
        exit 6
    fi
    if [ "$TARGET_IS_90" = "1" ]; then
        setprop persist.horizenjam.boot_90hz_installed 1
        setprop persist.horizenjam.refresh_rate 90
        setprop debug.oculus.refreshRate 90
        setprop debug.oculus.forceRefreshRate 90
        echo "[OK] 90 Hz OLED boot image flashed to boot${SLOT}!"
    else
        setprop persist.horizenjam.boot_90hz_installed 0
        setprop persist.horizenjam.refresh_rate 72
        setprop debug.oculus.refreshRate 72
        setprop debug.oculus.forceRefreshRate 72
        echo "[OK] Safe 72 Hz OLED boot image restored to boot${SLOT}!"
    fi
    echo "PROGRESS 100"
    exit 0
}

case "$CMD" in
    72)
        rm -f /persist/horizenjam/hz_unconfirmed
        setprop persist.horizenjam.refresh_rate 72
        setprop debug.oculus.refreshRate 72
        setprop debug.oculus.forceRefreshRate 72
        echo "72" > /sys/class/graphics/fb0/dynamic_fps 2>/dev/null || true
        echo "Display refresh rate set to safe 72 Hz."
        ;;
    90_test)
        mkdir -p /persist/horizenjam 2>/dev/null
        echo "pending" > /persist/horizenjam/hz_unconfirmed
        setprop persist.horizenjam.refresh_rate 90
        setprop debug.oculus.refreshRate 90
        setprop debug.oculus.forceRefreshRate 90
        echo "90" > /sys/class/graphics/fb0/dynamic_fps 2>/dev/null || true
        echo "Display switched to 90 Hz."
        ;;
    90_confirm)
        rm -f /persist/horizenjam/hz_unconfirmed
        setprop persist.horizenjam.refresh_rate 90
        echo "90 Hz display mode confirmed."
        ;;
    flash_90hz_progress)
        flash_boot_with_progress "/system/etc/horizenjam/boot_90hz.img" "1"
        ;;
    flash_72hz_progress)
        flash_boot_with_progress "/system/etc/horizenjam/boot_72hz.img" "0"
        ;;
    flash_90hz_boot)
        flash_boot_with_progress "/system/etc/horizenjam/boot_90hz.img" "1"
        ;;
    flash_72hz_boot)
        flash_boot_with_progress "/system/etc/horizenjam/boot_72hz.img" "0"
        ;;
    status|*)
        RATE=$(getprop persist.horizenjam.refresh_rate)
        echo "${RATE:-72}"
        ;;
esac
