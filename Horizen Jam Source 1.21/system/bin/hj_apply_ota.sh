#!/system/bin/sh
# Horizen Jam 1.0 - Built-In GitHub Releases OTA Flasher
# Called by patched OSUpdater.apk (com.oculus.updater) after downloading a release ZIP
# from https://github.com/Jamman101213/Horizen-Jam-Updates/releases
#
# Supported ZIP formats (zip filename does not matter):
#   1) Full A/B Image ZIP: contains boot.img and/or system.img (or system.img.gz)
#      -> streams directly to the INACTIVE A/B slot and marks it active via bootctl!
#   2) System Patch / Overlay ZIP: contains system/ directory and/or update.sh
#      -> unlocks current /system RW via blockdev --setrw, extracts files, restorecon -RF!
#   3) Standard Android A/B OTA ZIP: contains payload.bin + payload_properties.txt
#      -> feeds directly to update_engine_client!

set -u
ZIPFILE="$1"
TARGET_VER="${2:-}"
WORK="/data/local/tmp/hj_ota_work"

if [ -z "$ZIPFILE" ] || [ ! -f "$ZIPFILE" ]; then
    echo "ERROR: OTA zip not found: $ZIPFILE"
    exit 1
fi

rm -rf "$WORK" 2>/dev/null
mkdir -p "$WORK"

LIST=$(unzip -l "$ZIPFILE" 2>/dev/null)
if [ -z "$LIST" ]; then
    echo "ERROR: Invalid ZIP archive: $ZIPFILE"
    exit 2
fi

CUR_SLOT=$(getprop ro.boot.slot_suffix)
if [ "$CUR_SLOT" = "_a" ]; then
    OTHER_SLOT="_b"
    OTHER_NUM=1
else
    OTHER_SLOT="_a"
    OTHER_NUM=0
fi

# Case 1: Full A/B Image ZIP (boot.img / system.img / system.img.gz)
if echo "$LIST" | grep -qE "(^|[[:space:]])(boot\.img|system\.img|system\.img\.gz)$"; then
    echo "OTA: Detected Horizen Jam A/B image package (target slot: $OTHER_SLOT)"
    if echo "$LIST" | grep -qE "(^|[[:space:]])boot\.img$"; then
        BOOT_DEV="/dev/block/bootdevice/by-name/boot${OTHER_SLOT}"
        blockdev --setrw "$BOOT_DEV" 2>/dev/null || true
        unzip -p "$ZIPFILE" boot.img | dd of="$BOOT_DEV" bs=1048576 conv=fsync || exit 3
        echo "OTA: Flashed boot.img to $BOOT_DEV"
    fi
    if echo "$LIST" | grep -qE "(^|[[:space:]])system\.img\.gz$"; then
        SYS_DEV="/dev/block/bootdevice/by-name/system${OTHER_SLOT}"
        blockdev --setrw "$SYS_DEV" 2>/dev/null || true
        unzip -p "$ZIPFILE" system.img.gz | gzip -dc | dd of="$SYS_DEV" bs=1048576 conv=fsync || exit 4
        echo "OTA: Flashed system.img.gz to $SYS_DEV"
    elif echo "$LIST" | grep -qE "(^|[[:space:]])system\.img$"; then
        SYS_DEV="/dev/block/bootdevice/by-name/system${OTHER_SLOT}"
        blockdev --setrw "$SYS_DEV" 2>/dev/null || true
        unzip -p "$ZIPFILE" system.img | dd of="$SYS_DEV" bs=1048576 conv=fsync || exit 4
        echo "OTA: Flashed system.img to $SYS_DEV"
    fi
    if echo "$LIST" | grep -qE "(^|[[:space:]])update\.sh$"; then
        unzip -p "$ZIPFILE" update.sh > "$WORK/update.sh"
        chmod 0755 "$WORK/update.sh"
        /system/bin/sh "$WORK/update.sh" "$OTHER_SLOT" "$TARGET_VER" || exit 5
    fi
    # Switch active A/B slot
    if [ -x /system/bin/bootctl ]; then
        /system/bin/bootctl set-active-boot-slot "$OTHER_NUM" || exit 6
    elif [ -x /vendor/bin/bootctl ]; then
        /vendor/bin/bootctl set-active-boot-slot "$OTHER_NUM" || exit 6
    fi
    sync
    rm -rf "$WORK" "$ZIPFILE" 2>/dev/null
    [ -n "$TARGET_VER" ] && setprop persist.horizenjam.ota_pending_version "$TARGET_VER"
    echo "OTA_SUCCESS_SLOT_SWITCHED:$OTHER_SLOT"
    exit 0
fi

# Case 2: System Overlay / Patch ZIP (system/ directory or update.sh)
if echo "$LIST" | grep -qE "(^|[[:space:]])(system/|update\.sh)"; then
    echo "OTA: Detected Horizen Jam live /system patch package"
    blockdev --setrw "/dev/block/bootdevice/by-name/system${CUR_SLOT}" 2>/dev/null || true
    mount -o rw,remount / || exit 7
    unzip -o "$ZIPFILE" -d "$WORK" >/dev/null || exit 8
    if [ -d "$WORK/system" ]; then
        cp -af "$WORK/system/." /system/ || exit 9
        chown -R 0:0 /system/etc/horizenjam /system/vendor/overlay 2>/dev/null || true
        chmod 0755 /system/bin/hj_*.sh /system/etc/horizenjam/*.sh 2>/dev/null || true
        restorecon -RF /system/priv-app /system/app /system/framework /system/vendor/overlay /system/etc /system/bin 2>/dev/null || true
    fi
    if [ -f "$WORK/update.sh" ]; then
        chmod 0755 "$WORK/update.sh"
        /system/bin/sh "$WORK/update.sh" "$CUR_SLOT" "$TARGET_VER" || exit 10
    fi
    if [ -n "$TARGET_VER" ]; then
        sed -i "s/^ro\.horizenjam\.version=.*/ro.horizenjam.version=${TARGET_VER}/" /system/build.prop 2>/dev/null || true
        sed -i "s/^ro\.build\.display\.id=.*/ro.build.display.id=Horizen Jam ${TARGET_VER}/" /system/build.prop 2>/dev/null || true
        chmod 0600 /system/build.prop
        restorecon /system/build.prop 2>/dev/null || true
    fi
    sync
    mount -o ro,remount / 2>/dev/null || true
    rm -rf "$WORK" "$ZIPFILE" 2>/dev/null
    echo "OTA_SUCCESS_LIVE_PATCH"
    exit 0
fi

# Case 3: Standard Android A/B payload.bin + payload_properties.txt ZIP
if echo "$LIST" | grep -q "payload\.bin"; then
    echo "OTA: Detected Android A/B payload.bin package"
    unzip -p "$ZIPFILE" payload_properties.txt > "$WORK/payload_properties.txt" 2>/dev/null || true
    HEADERS=$(tr '\n' ' ' < "$WORK/payload_properties.txt" | sed 's/[[:space:]]*$//')
    if [ -x /system/bin/update_engine_client ] && [ -n "$HEADERS" ]; then
        /system/bin/update_engine_client --update --follow --payload="file://${ZIPFILE}" --headers="$HEADERS" || exit 11
        rm -rf "$WORK" "$ZIPFILE" 2>/dev/null
        echo "OTA_SUCCESS_UPDATE_ENGINE"
        exit 0
    fi
fi

echo "ERROR: Unrecognized OTA ZIP structure (expected boot.img/system.img, system/, update.sh, or payload.bin)"
rm -rf "$WORK" 2>/dev/null
exit 12
