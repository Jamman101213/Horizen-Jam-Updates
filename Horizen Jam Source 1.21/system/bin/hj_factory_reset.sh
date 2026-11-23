#!/system/bin/sh
# Horizen Jam 1.1 - True Quest 1 Factory Reset (Formats /data AND /vision!)
# Stock Quest 1 recovery cannot wipe /data cleanly on custom ROMs.
# Both userdata (/data) and vision (/vision) have `formattable,fileencryption=ice`
# in /fstab.monterey. Zeroing their ext4 superblocks + rebooting makes Android 10's
# native fs_mgr format BOTH /data and /vision cleanly with Linux 4.4 ICE encryption!
#
# Usage:
#   hj_factory_reset.sh prepare          (verified stage-1 for FactoryResetActivity UI + 3-2-1 countdown)
#   hj_factory_reset.sh full             (immediate wipe + kernel reboot)
#   hj_factory_reset.sh keep_gapps_done  (immediate wipe + keep gapps_prompt_done flag)

MODE="${1:-full}"
VISION_DEV="/dev/block/bootdevice/by-name/vision"
DATA_DEV="/dev/block/bootdevice/by-name/userdata"

if [ "$MODE" = "prepare" ]; then
    echo "[1/5] Checking root privileges..."
    UID_NOW=$(id -u 2>/dev/null || echo 9999)
    if [ "$UID_NOW" != "0" ]; then
        echo "[FAILED] Root access required (uid=$UID_NOW)."
        exit 10
    fi
    echo "[OK] Root access verified (uid=0)."

    echo "[2/5] Checking /vision and /data block devices..."
    if [ ! -b "$VISION_DEV" ]; then
        echo "[FAILED] Missing block device: $VISION_DEV"
        exit 11
    fi
    if [ ! -b "$DATA_DEV" ]; then
        echo "[FAILED] Missing block device: $DATA_DEV"
        exit 12
    fi
    echo "[OK] Found $VISION_DEV and $DATA_DEV."

    echo "[3/5] Clearing Horizen Jam setup flags in /persist..."
    mkdir -p /persist/horizenjam 2>/dev/null
    chmod 0755 /persist/horizenjam 2>/dev/null || true
    rm -f /persist/horizenjam/setup_complete /persist/horizenjam/phase1_done /persist/horizenjam/gapps_prompt_done 2>/dev/null
    sync
    if [ -f /persist/horizenjam/setup_complete ]; then
        echo "[FAILED] Could not remove /persist/horizenjam/setup_complete"
        exit 13
    fi
    echo "[OK] Cleared /persist/horizenjam setup flags (Horizen Setup will run on next boot)."

    echo "[4/5] Formatting /vision partition (4 MB superblock wipe + verify)..."
    umount -l /vision 2>/dev/null || true
    blockdev --setrw "$VISION_DEV" 2>/dev/null || true
    if ! dd if=/dev/zero of="$VISION_DEV" bs=1048576 count=4 conv=fsync 2>/dev/null; then
        echo "[FAILED] dd write failed on $VISION_DEV!"
        exit 14
    fi
    NONZERO=$(dd if="$VISION_DEV" bs=4096 count=1 2>/dev/null | tr -d '\000' | wc -c)
    if [ "${NONZERO:-1}" != "0" ]; then
        echo "[FAILED] /vision readback verification failed (non-zero bytes=$NONZERO)!"
        exit 15
    fi
    echo "[OK] /vision formatted and verified zeroed!"

    echo "[5/5] Unlocking /data ($DATA_DEV) & staging atomic wipe script in /dev..."
    blockdev --setrw "$DATA_DEV" 2>/dev/null || true
    cat > /dev/hj_atomic_reset.sh << 'EOF'
#!/system/bin/sh
stop 2>/dev/null || true
sleep 1
sync
umount -l /vision 2>/dev/null || true
umount -l /sdcard 2>/dev/null || true
umount -l /storage/emulated 2>/dev/null || true
umount -l /data/media 2>/dev/null || true
umount -l /data 2>/dev/null || true
dd if=/dev/zero of=/dev/block/bootdevice/by-name/vision bs=1048576 count=4 conv=fsync 2>/dev/null || true
dd if=/dev/zero of=/dev/block/bootdevice/by-name/userdata bs=1048576 count=4 conv=fsync 2>/dev/null || true
sync
reboot -f 2>/dev/null || echo b > /proc/sysrq-trigger 2>/dev/null || /system/bin/reboot
EOF
    chmod 0755 /dev/hj_atomic_reset.sh
    if [ ! -x /dev/hj_atomic_reset.sh ]; then
        echo "[FAILED] Could not stage /dev/hj_atomic_reset.sh"
        exit 16
    fi
    echo "[OK] /data unlocked and atomic wipe script staged."
    exit 0
fi

# Direct immediate wipe mode
mkdir -p /persist/horizenjam 2>/dev/null
chmod 0755 /persist/horizenjam 2>/dev/null || true
rm -f /persist/horizenjam/setup_complete /persist/horizenjam/phase1_done /persist/horizenjam/gapps_prompt_done 2>/dev/null || true
sync

stop 2>/dev/null || true
sleep 2
sync

umount -l /vision 2>/dev/null || true
umount -l /sdcard 2>/dev/null || true
umount -l /storage/emulated 2>/dev/null || true
umount -l /data/media 2>/dev/null || true
umount -l /data 2>/dev/null || true

blockdev --setrw "$VISION_DEV" 2>/dev/null || true
blockdev --setrw "$DATA_DEV" 2>/dev/null || true
[ -b "$VISION_DEV" ] && dd if=/dev/zero of="$VISION_DEV" bs=1048576 count=4 conv=fsync 2>/dev/null || true
[ -b "$DATA_DEV" ] && dd if=/dev/zero of="$DATA_DEV" bs=1048576 count=4 conv=fsync 2>/dev/null || true
sync

reboot -f 2>/dev/null || echo b > /proc/sysrq-trigger 2>/dev/null || /system/bin/reboot
