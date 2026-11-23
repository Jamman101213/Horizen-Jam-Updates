#!/system/bin/sh
# Horizen Jam 1.0 - Native Android 10 SAR NikGapps Core Installer
# Directly installs all 6 AppSet/Core/*.zip payloads from NikGapps-core-arm64-10-20260204-signed.zip
# into /system/product/ without fragile TWRP /sbin/sh or /etc/fstab dependencies!
# MUST be invoked via: su --mount-master -c "/system/bin/sh /system/bin/hj_flash_gapps.sh"

set -u
ZIPFILE="/system/etc/horizenjam/NikGapps-core-arm64-10-20260204-signed.zip"
[ -f "$ZIPFILE" ] || ZIPFILE="/data/horizenjam/NikGapps-core-arm64-10-20260204-signed.zip"
WORK="/data/local/tmp/hj_gapps_work"

emit_print() { echo "ui_print $1"; }
emit_prog()  { echo "set_progress $1"; }

if [ ! -f "$ZIPFILE" ]; then
    emit_print "! ERROR: Staged NikGapps ZIP not found at $ZIPFILE"
    exit 1
fi

emit_print "=============================================="
emit_print " Horizen Jam 1.0 - NikGapps Core Installer"
emit_print " Target: Quest 1 v50 (Android 10 SAR / API 29)"
emit_print "=============================================="
emit_prog 0.05

# 1. Unlock block device & remount / (System-as-Root) as read-write
emit_print "- Unlocking block device & remounting /system read-write..."
SLOT=$(getprop ro.boot.slot_suffix)
blockdev --setrw "/dev/block/bootdevice/by-name/system${SLOT}" 2>/dev/null || true
blockdev --setrw /dev/root 2>/dev/null || true
mount -o rw,remount / 2>/dev/null || mount -o rw,remount -t auto / 2>/dev/null

if ! (touch /system/.hj_rw_test 2>/dev/null && rm -f /system/.hj_rw_test 2>/dev/null); then
    emit_print "! ERROR: Failed to remount /system read-write (check su --mount-master)"
    exit 2
fi
emit_prog 0.12

# 2. Extract bundled NikGapps busybox + AppSet/Core/*.zip archives to writable /data/local/tmp
rm -rf "$WORK" 2>/dev/null
mkdir -p "$WORK/zips" "$WORK/unpacked" || exit 3

emit_print "- Extracting bundled NikGapps busybox & AppSet/Core archives..."
unzip -o "$ZIPFILE" "busybox" -d "$WORK" >/dev/null 2>&1 || true
BB="$WORK/busybox"
if [ -f "$BB" ]; then
    chmod 0755 "$BB"
    UNZIP_CMD="$BB unzip"
else
    UNZIP_CMD="unzip"
fi

PACKAGES="ExtraFiles GoogleServicesFramework GmsCore GooglePlayStore GoogleContactsSyncAdapter GoogleCalendarSyncAdapter"
for PKG in $PACKAGES; do
    $UNZIP_CMD -o "$ZIPFILE" "AppSet/Core/${PKG}.zip" -d "$WORK/zips" >/dev/null 2>&1 || true
done
if [ ! -f "$WORK/zips/AppSet/Core/GmsCore.zip" ]; then
    emit_print "! ERROR: Failed to unpack AppSet/Core/GmsCore.zip from $ZIPFILE"
    rm -rf "$WORK" 2>/dev/null
    exit 4
fi
emit_prog 0.25

# 3. Install each Core package directly into /system/product/
#    NikGapps inner entry naming: ___dir1___dir2/filename -> /system/product/dir1/dir2/filename
IDX=0
for PKG in $PACKAGES; do
    SUBZIP="$WORK/zips/AppSet/Core/${PKG}.zip"
    if [ ! -f "$SUBZIP" ]; then
        emit_print "- Skipping missing archive ${PKG}.zip"
        continue
    fi
    IDX=$((IDX + 1))
    emit_print "- Installing ${PKG} (${IDX}/6)..."
    PKG_DIR="$WORK/unpacked/${PKG}"
    mkdir -p "$PKG_DIR"
    $UNZIP_CMD -o "$SUBZIP" -d "$PKG_DIR" >/dev/null 2>&1 || {
        emit_print "! ERROR: Failed to unzip ${PKG}.zip"
        rm -rf "$WORK" 2>/dev/null
        exit 5
    }

    for entry in "$PKG_DIR"/___*; do
        [ -e "$entry" ] || continue
        BN=$(basename "$entry")
        # Convert leading ___ and internal ___ to /
        REL=$(echo "$BN" | sed 's/^___//; s/___/\//g')
        DEST="/system/product/${REL}"
        mkdir -p "$DEST" || {
            emit_print "! ERROR: Failed to create $DEST"
            exit 6
        }
        if [ -d "$entry" ]; then
            cp -af "$entry/." "$DEST/" || {
                emit_print "! ERROR: Failed copying files to $DEST (check free space)"
                exit 7
            }
            find "$DEST" -type d -exec chmod 0755 {} + 2>/dev/null || true
            find "$DEST" -type f -exec chmod 0644 {} + 2>/dev/null || true
            chown -R 0:0 "$DEST" 2>/dev/null || true
        fi
    done

    case "$IDX" in
        1) emit_prog 0.38 ;;
        2) emit_prog 0.50 ;;
        3) emit_prog 0.68 ;;
        4) emit_prog 0.78 ;;
        5) emit_prog 0.84 ;;
        6) emit_prog 0.88 ;;
    esac
done

# 4. Verify core Google APKs actually exist and are non-empty BEFORE deleting ZIP!
emit_print "- Verifying Google Play Services & Play Store payload..."
GMS_APK="/system/product/priv-app/PrebuiltGmsCore/PrebuiltGmsCore.apk"
PLAY_APK="/system/product/priv-app/Phonesky/Phonesky.apk"
GSF_APK="/system/product/priv-app/GoogleServicesFramework/GoogleServicesFramework.apk"

if [ ! -s "$GMS_APK" ] || [ ! -s "$PLAY_APK" ] || [ ! -s "$GSF_APK" ]; then
    emit_print "! ERROR: Verification failed! Core APKs missing after install."
    emit_print "  GMS=$(ls -lh "$GMS_APK" 2>&1)"
    emit_print "  PLAY=$(ls -lh "$PLAY_APK" 2>&1)"
    emit_print "  GSF=$(ls -lh "$GSF_APK" 2>&1)"
    rm -rf "$WORK" 2>/dev/null
    exit 8
fi

emit_prog 0.93

# 5. Restore Android 10 SELinux contexts cleanly
emit_print "- Restoring Android 10 SELinux contexts (restorecon -RF)..."
restorecon -RF /system/product/priv-app /system/product/app /system/product/etc /system/product/framework /system/product/lib /system/product/lib64 2>/dev/null || true
sync

# 6. Delete staged NikGapps ZIP from /system & /data, mark prompt done in /persist
rm -f /system/etc/horizenjam/NikGapps-core-arm64-10-20260204-signed.zip /data/horizenjam/NikGapps-core-arm64-10-20260204-signed.zip 2>/dev/null || true
mkdir -p /persist/horizenjam 2>/dev/null
echo "installed:$(date +%s)" > /persist/horizenjam/gapps_prompt_done
rm -rf "$WORK" 2>/dev/null
sync
mount -o ro,remount / 2>/dev/null || true

emit_prog 1.00
emit_print "- NikGapps Core verified & installed cleanly!"
emit_print "- Formatting /data and /vision in 3 seconds so Google Play Services initializes fresh..."
exit 0
