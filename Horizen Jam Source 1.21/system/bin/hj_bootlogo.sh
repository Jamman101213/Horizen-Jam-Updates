#!/system/bin/sh
# Horizen Jam 1.2 (Build HJ-0003) - Custom Boot Logo Installer + Soft Reboot
# Usage:
#   hj_bootlogo.sh apply /path/to/216x144.png
#   hj_bootlogo.sh restore

set -u
CMD="${1:-}"
SRC="${2:-}"
BACKUP="/system/etc/horizenjam/default_meta_logo.png"

SLOT=$(getprop ro.boot.slot_suffix)
blockdev --setrw "/dev/block/bootdevice/by-name/system${SLOT}" 2>/dev/null || true
mount -o rw,remount / || exit 2

case "$CMD" in
    apply)
        if [ -z "$SRC" ] || [ ! -s "$SRC" ]; then
            echo "ERROR: Boot logo PNG not found: $SRC"
            mount -o ro,remount / 2>/dev/null || true
            exit 3
        fi
        if [ ! -f "$BACKUP" ] && [ -f /system/etc/meta_logo.png ]; then
            cp -f /system/etc/meta_logo.png "$BACKUP"
            chown 0:0 "$BACKUP"
            chmod 0644 "$BACKUP"
            restorecon -F "$BACKUP" 2>/dev/null || true
        fi
        cp -f "$SRC" /system/etc/meta_logo.png || exit 4
        cp -f "$SRC" /system/etc/meta_logo-L.png || exit 4
        cp -f "$SRC" /system/etc/meta_logo-R.png || exit 4
        ;;
    restore)
        if [ ! -s "$BACKUP" ]; then
            echo "ERROR: Default Jam Jar backup not found."
            mount -o ro,remount / 2>/dev/null || true
            exit 5
        fi
        cp -f "$BACKUP" /system/etc/meta_logo.png || exit 6
        cp -f "$BACKUP" /system/etc/meta_logo-L.png || exit 6
        cp -f "$BACKUP" /system/etc/meta_logo-R.png || exit 6
        ;;
    *)
        mount -o ro,remount / 2>/dev/null || true
        exit 1
        ;;
esac

chown 0:0 /system/etc/meta_logo.png /system/etc/meta_logo-L.png /system/etc/meta_logo-R.png
chmod 0644 /system/etc/meta_logo.png /system/etc/meta_logo-L.png /system/etc/meta_logo-R.png
restorecon -F /system/etc/meta_logo.png /system/etc/meta_logo-L.png /system/etc/meta_logo-R.png 2>/dev/null || true
sync
mount -o ro,remount / 2>/dev/null || true

# Clean soft reboot (restarts zygote / Android framework & VrShell!)
setprop ctl.restart zygote 2>/dev/null || (stop && start)
exit 0
