#!/system/bin/sh
# Horizen Jam 1.0 - Delete staged NikGapps ZIP from /system & /data after setup
REASON="${1:-done}"
GAPPS_SYS="/system/etc/horizenjam/NikGapps-core-arm64-10-20260204-signed.zip"
GAPPS_DATA="/data/horizenjam/NikGapps-core-arm64-10-20260204-signed.zip"

mkdir -p /persist/horizenjam 2>/dev/null
echo "${REASON}:$(date +%s)" > /persist/horizenjam/gapps_prompt_done 2>/dev/null || true

rm -f "$GAPPS_DATA" 2>/dev/null || true

if [ -f "$GAPPS_SYS" ]; then
    SLOT=$(getprop ro.boot.slot_suffix)
    blockdev --setrw "/dev/block/bootdevice/by-name/system${SLOT}" 2>/dev/null || true
    mount -o rw,remount / 2>/dev/null || true
    rm -f "$GAPPS_SYS" 2>/dev/null || true
    sync
    mount -o ro,remount / 2>/dev/null || true
fi
echo "Cleaned staged NikGapps ZIP ($REASON)."
