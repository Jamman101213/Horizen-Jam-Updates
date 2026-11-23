#!/system/bin/sh
# Horizen Jam 1.0 - USB-C OTG Auto-Mounter (FAT32 / exFAT / NTFS -> /sdcard/USB_Drive)

MOUNT_POINT="/sdcard/USB_Drive"
RAW_MOUNT="/mnt/horizenjam_usb"

mount_device() {
    DEV="$1"
    mkdir -p "$RAW_MOUNT" "$MOUNT_POINT" 2>/dev/null
    if mount | grep -q " $RAW_MOUNT "; then
        return 0
    fi
    # Try vfat (FAT32), exfat, ntfs in order
    mount -t vfat -o rw,uid=1023,gid=1023,umask=0002 "$DEV" "$RAW_MOUNT" 2>/dev/null || \
    mount -t exfat -o rw,uid=1023,gid=1023,umask=0002 "$DEV" "$RAW_MOUNT" 2>/dev/null || \
    mount -t ntfs -o rw,uid=1023,gid=1023,umask=0002 "$DEV" "$RAW_MOUNT" 2>/dev/null || \
    mount -o rw "$DEV" "$RAW_MOUNT" 2>/dev/null || return 1

    mount -o bind "$RAW_MOUNT" "$MOUNT_POINT" 2>/dev/null || true
    setprop persist.horizenjam.usb_mounted 1
    setprop persist.horizenjam.usb_device "$DEV"
    return 0
}

is_usb_block_device() {
    BASE=$(basename "$1" | sed 's/[0-9]*$//')
    LINK=$(readlink -f "/sys/block/$BASE" 2>/dev/null || true)
    echo "$LINK" | grep -qiE "usb|xhci|ssusb" && ! echo "$LINK" | grep -qi "ufshc"
}

scan_once() {
    for dev in /dev/block/sd[a-z][0-9] /dev/block/sd[a-z]; do
        if [ -b "$dev" ] && is_usb_block_device "$dev"; then
            mount_device "$dev" && break
        fi
    done
}

case "${1:-once}" in
    watch)
        while true; do
            scan_once
            sleep 4
        done
        ;;
    *)
        scan_once
        ;;
esac
