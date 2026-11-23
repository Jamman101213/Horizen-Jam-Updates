#!/system/bin/sh
# Horizen Jam 1.0 (Build HJ-0001) - Early Boot (post-fs-data) Provisioner & Guard
# Target: Meta Quest 1 v50 (monterey, Android 10 / API 29, System-as-Root)

LOG=/data/horizenjam/boot.log
mkdir -p /data/horizenjam /persist/horizenjam /data/adb/post-fs-data.d /data/adb/service.d 2>/dev/null
chmod 0770 /data/horizenjam 2>/dev/null
chmod 0755 /persist/horizenjam 2>/dev/null

echo "[HorizenJam] post-fs-data start $(date)" > "$LOG"

# 1. Boot-time guard: delete leftover staged NikGapps ZIP if prompt already finished or GMS present
GAPPS_ZIP="/data/horizenjam/NikGapps-core-arm64-10-20260204-signed.zip"
DONE_FLAG="/persist/horizenjam/gapps_prompt_done"
if [ -f "$GAPPS_ZIP" ]; then
    if [ -f "$DONE_FLAG" ] || [ -d /system/product/priv-app/PrebuiltGmsCore ] || [ -d /system/priv-app/PrebuiltGmsCore ]; then
        rm -f "$GAPPS_ZIP"
        echo "[HorizenJam] Guard cleaned up leftover staged NikGapps ZIP." >> "$LOG"
    fi
fi

# 2. Safe 90Hz boot watchdog: if a 90Hz switch was pending and never confirmed, revert to 72Hz
if [ -f /persist/horizenjam/hz_unconfirmed ]; then
    echo "[HorizenJam] Unconfirmed 90Hz state detected on boot; reverting to safe 72Hz." >> "$LOG"
    rm -f /persist/horizenjam/hz_unconfirmed
    setprop persist.horizenjam.refresh_rate 72
    setprop debug.oculus.refreshRate 72
fi

# 3. Default Horizen Jam build properties & Telemetry suppression
setprop ro.horizenjam.active 1
setprop persist.ovr.telemetry.disabled 1
if [ -z "$(getprop persist.horizenjam.build_code)" ]; then
    setprop persist.horizenjam.build_code "HJ-0003"
fi

# 4. Dormant Quest 1 v50 Feature Unlocks
#    Direct Touch is OPT-IN (default OFF) so offline Guardian boundary ray-clicks never freeze!
if [ "$(getprop persist.horizenjam.direct_touch)" = "1" ]; then
    setprop persist.ovr.direct_touch_enabled 1
    setprop debug.oculus.directTouch 1
else
    setprop persist.ovr.direct_touch_enabled 0
    setprop debug.oculus.directTouch 0
fi
if [ "$(getprop persist.horizenjam.multitasking_2d)" != "0" ]; then
    setprop persist.ovr.multitasking_2d_in_vr 1
    setprop debug.oculus.allow2DMultitasking 1
fi

# Mirror /persist/horizenjam setup flags to SystemProperties (untrusted_app cannot stat /persist under SELinux!)
if [ -f /persist/horizenjam/phase1_done ]; then
    setprop sys.horizenjam.phase1_done 1
else
    setprop sys.horizenjam.phase1_done 0
fi
if [ -f /persist/horizenjam/setup_complete ]; then
    setprop sys.horizenjam.setup_complete 1
    setprop sys.horizenjam.setup_active 0
else
    setprop sys.horizenjam.setup_complete 0
    setprop sys.horizenjam.setup_active 1
fi

# 5. Copy boot guard into Magisk post-fs-data.d so Magisk always runs it too
cp -f /system/etc/horizenjam/post-fs-data.sh /data/adb/post-fs-data.d/10_horizenjam_guard.sh 2>/dev/null
chmod 0755 /data/adb/post-fs-data.d/10_horizenjam_guard.sh 2>/dev/null
cp -f /system/etc/horizenjam/service.sh /data/adb/service.d/20_horizenjam_service.sh 2>/dev/null
chmod 0755 /data/adb/service.d/20_horizenjam_service.sh 2>/dev/null

echo "[HorizenJam] post-fs-data done" >> "$LOG"
