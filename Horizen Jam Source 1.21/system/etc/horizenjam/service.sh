#!/system/bin/sh
# Horizen Jam 1.0 (Build HJ-0001) - Late Boot Service
# Auto-grants Magisk v31.1 root, enables Horizon OS v2.10 RROs, applies user presets,
# launches Pre-Setup GApps prompt before FirstTimeNux, and starts USB OTG monitor.

LOG=/data/horizenjam/service.log
echo "[HorizenJam] service.sh start" > "$LOG"

# Wait for PackageManager & boot completion
TRIES=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ $TRIES -lt 60 ]; do
    sleep 1
    TRIES=$((TRIES + 1))
done
sleep 2

# ---------------------------------------------------------------------------
# 0. Once-Per-Wipe Preload Install (all 5 apps visible in App Library ->
#    Android / Sideloaded Apps, NOT hidden by FLAG_SYSTEM, and Singularity
#    remains freely uninstallable!)
# ---------------------------------------------------------------------------
mkdir -p /data/horizenjam /persist/horizenjam /data/adb/service.d 2>/dev/null
chmod 0770 /data/horizenjam 2>/dev/null
chmod 0755 /persist/horizenjam 2>/dev/null

PRELOAD_DIR="/system/etc/horizenjam/preloads"
PRELOAD_SENTINEL="/data/horizenjam/.preloads_v7_done"
if [ -d "$PRELOAD_DIR" ] && [ ! -f "$PRELOAD_SENTINEL" ]; then
    # Remove legacy standalone HorizenJamSettings (now integrated natively inside Meta Settings -> Jam Internals)
    pm uninstall com.horizenjam.settings >/dev/null 2>&1 || true
    for apk in \
        "$PRELOAD_DIR/HorizenPreSetup.apk" \
        "$PRELOAD_DIR/HorizenFiles.apk" \
        "$PRELOAD_DIR/Singularity.apk" \
        "$PRELOAD_DIR/Magisk.apk"
    do
        if [ -f "$apk" ]; then
            pm install -r -g "$apk" >> "$LOG" 2>&1 || true
            echo "[HorizenJam] Preloaded $(basename "$apk")" >> "$LOG"
        fi
    done
    touch "$PRELOAD_SENTINEL" 2>/dev/null || true
fi

# Register service.sh in Magisk service.d as backup boot runner
cp -f /system/etc/horizenjam/service.sh /data/adb/service.d/20_horizenjam_service.sh 2>/dev/null || true
chmod 0755 /data/adb/service.d/20_horizenjam_service.sh 2>/dev/null || true

# ---------------------------------------------------------------------------
# 1. Auto-grant silent Magisk v31.1 root (policy=2, logging=0, notification=0)
#    Targets: Horizen Jam Settings, Horizen Files, PreSetup, Singularity, Magisk, ADB Shell (2000)
# ---------------------------------------------------------------------------
MAGISK_BIN="/sbin/magisk"
[ -x "$MAGISK_BIN" ] || MAGISK_BIN="$(which magisk 2>/dev/null || echo magisk)"

grant_uid_root() {
    UID_VAL="$1"
    LABEL="$2"
    if [ -n "$UID_VAL" ]; then
        if [ -x "$MAGISK_BIN" ] || command -v magisk >/dev/null 2>&1; then
            "$MAGISK_BIN" --sqlite "REPLACE INTO policies (uid, policy, until, logging, notification) VALUES ($UID_VAL, 2, 0, 0, 0);" 2>/dev/null || true
            echo "[HorizenJam] Auto-granted Magisk root via magisk --sqlite to $LABEL (uid=$UID_VAL)" >> "$LOG"
        fi
    fi
}

grant_magisk_root() {
    PKG="$1"
    UID_VAL=$(awk -v p="$PKG" '$1 == p {print $2; exit}' /data/system/packages.list 2>/dev/null)
    if [ -z "$UID_VAL" ]; then
        UID_VAL=$(cmd package list packages -U 2>/dev/null | grep "package:${PKG} " | sed 's/.*uid://' | tr -dc '0-9')
    fi
    grant_uid_root "$UID_VAL" "$PKG"
}

# Ensure Magisk root access allows Apps & ADB (root_access=3)
"$MAGISK_BIN" --sqlite "REPLACE INTO settings (key, value) VALUES ('root_access', 3);" 2>/dev/null || true
grant_uid_root "2000" "com.android.shell"

for ROOT_PKG in \
    com.oculus.systemux \
    com.oculus.updater \
    com.horizenjam.files \
    com.horizenjam.presetup \
    com.lumi.singularity \
    com.topjohnwu.magisk
do
    grant_magisk_root "$ROOT_PKG"
done

# Pick up NikGapps ZIP if pushed to /sdcard/ for staging into /data/horizenjam/
if [ -f /sdcard/NikGapps-core-arm64-10-20260204-signed.zip ] && [ ! -f /persist/horizenjam/gapps_prompt_done ]; then
    mkdir -p /data/horizenjam 2>/dev/null
    mv -f /sdcard/NikGapps-core-arm64-10-20260204-signed.zip /data/horizenjam/NikGapps-core-arm64-10-20260204-signed.zip 2>/dev/null || true
    chmod 0644 /data/horizenjam/NikGapps-core-arm64-10-20260204-signed.zip 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 2. Disable Meta Telemetry collector/bugreport ONLY.
#    Keep com.oculus.os.telemetry ENABLED (hosts + telemetry_state=off already block all uploads)
#    so system daemons stop spamming TelemetryService binder retries every 500ms!
for BLK_PKG in \
    com.oculus.statscollector \
    com.oculus.bugreportservice
do
    pm disable-user --user 0 "$BLK_PKG" >/dev/null 2>&1 || true
done
for KEEP_PKG in \
    com.oculus.os.telemetry \
    com.oculus.updater \
    com.oculus.nux.ota \
    com.oculus.firsttimenux \
    com.oculus.accountscenterpwa
do
    pm enable "$KEEP_PKG" >/dev/null 2>&1 || true
done

# ---------------------------------------------------------------------------
# 3. Enable Horizon OS v2.10 Backport RROs & Saved System-Wide Accent Color
# ---------------------------------------------------------------------------
for BASE_RRO in \
    com.horizenjam.overlay.systemux \
    com.horizenjam.overlay.framework \
    com.horizenjam.overlay.settings
do
    cmd overlay enable --user 0 "$BASE_RRO" >/dev/null 2>&1 || true
done

ACCENT=$(getprop persist.horizenjam.accent)
[ -z "$ACCENT" ] && ACCENT="cobalt"
cmd overlay enable-exclusive --user 0 "com.horizenjam.accent.${ACCENT}" >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------
# 4. Re-apply Saved Snapdragon 835 Performance Preset, Guardian, Prox, Wireless ADB
# ---------------------------------------------------------------------------
PRESET=$(getprop persist.horizenjam.perf_preset)
[ -z "$PRESET" ] && PRESET="balanced"
/system/bin/sh /system/bin/hj_perf_profile.sh "$PRESET" >/dev/null 2>&1 || true

if [ "$(getprop persist.horizenjam.guardian_disabled)" = "1" ]; then
    setprop debug.oculus.guardian_pause 1
fi

if [ "$(getprop persist.horizenjam.prox_disabled)" = "1" ]; then
    am broadcast -a com.oculus.vrpowermanager.prox_close >/dev/null 2>&1 || true
    am broadcast -a com.oculus.vrpowermanager.automation_disable >/dev/null 2>&1 || true
fi

if [ "$(getprop persist.horizenjam.wireless_adb)" = "1" ]; then
    setprop service.adb.tcp.port 5555
    stop adbd && start adbd
fi

# Unlock hardware OLED backlight node for instant zero-lag Quick Settings brightness slider!
chmod 0666 /sys/class/leds/lcd-backlight/brightness 2>/dev/null || true
SAVED_BRI=$(getprop persist.horizenjam.brightness)
if [ -n "$SAVED_BRI" ] && [ "$SAVED_BRI" -ge 12 ] 2>/dev/null && [ "$SAVED_BRI" -le 255 ] 2>/dev/null; then
    echo "$SAVED_BRI" > /sys/class/leds/lcd-backlight/brightness 2>/dev/null || true
    settings put system screen_brightness "$SAVED_BRI" >/dev/null 2>&1 || true
fi

# Apply Quest 3 App Compatibility Layer overrides
/system/bin/sh /system/bin/hj_q3_compat.sh apply >/dev/null 2>&1 || true

# Start USB-C OTG auto-mount daemon in background
/system/bin/sh /system/bin/hj_usb_otg.sh watch >/dev/null 2>&1 &

# Start Hardware Button Macros daemon if user enabled it
if [ "$(getprop persist.horizenjam.macros_enabled)" = "1" ]; then
    /system/bin/sh /system/bin/hj_macro_daemon.sh start >/dev/null 2>&1 &
fi

# ---------------------------------------------------------------------------
# 5. First-Boot Custom Horizen Jam Setup Kiosk Auto-Launch & Watchdog
# ---------------------------------------------------------------------------
GAPPS_SYS="/system/etc/horizenjam/NikGapps-core-arm64-10-20260204-signed.zip"
GAPPS_DATA="/data/horizenjam/NikGapps-core-arm64-10-20260204-signed.zip"
DONE_FLAG="/persist/horizenjam/gapps_prompt_done"
SETUP_FLAG="/persist/horizenjam/setup_complete"
GMS_PRESENT=$(pm list packages com.google.android.gms 2>/dev/null | grep -c "com.google.android.gms")

# Keep ADB, Developer Settings, Resizable Windows, Passthrough & Telemetry Block active
# Direct Touch stays OFF unless user explicitly opts in (prevents offline Guardian click glitches!)
settings put global adb_enabled 1 >/dev/null 2>&1 || true
settings put global development_settings_enabled 1 >/dev/null 2>&1 || true
if [ "$(getprop persist.horizenjam.direct_touch)" = "1" ]; then
    setprop persist.ovr.direct_touch_enabled 1
    setprop debug.oculus.directTouch 1
else
    setprop persist.ovr.direct_touch_enabled 0
    setprop debug.oculus.directTouch 0
fi
setprop persist.ovr.multitasking_2d_in_vr 1
setprop debug.oculus.allow2DMultitasking 1
/system/bin/oculussetting --set \
    first_time_nux_require_ota 0 \
    hand_tracking_enabled 1 \
    hand_tracking_opt_in 1 \
    hand_tracking_opt_in_v20 1 \
    autotransition_hands_controllers 1 \
    passthrough_on_demand_enabled 1 \
    productivity_mode_enabled 1 \
    desk_mode 1 \
    intrusion_detection_enabled 1 \
    mtp_dialog_enabled 1 \
    controller_laser_beam_effects 1 \
    telemetry_state off \
    crash_reports_enabled 0 \
    browser_crash_reports_enabled 0 >/dev/null 2>&1 || true

# Re-apply Quest 3 / Singularity spoof if user enabled it in Jam Internals
if [ "$(getprop persist.horizenjam.spoof_q3)" = "1" ]; then
    /system/bin/sh /system/bin/hj_q3_compat.sh spoof_on >/dev/null 2>&1 || true
fi

# Auto-delete staged NikGapps ZIP from /system & /data once flashed or skipped
if [ -f "$DONE_FLAG" ] || [ "$GMS_PRESENT" != "0" ]; then
    if [ -f "$GAPPS_SYS" ] || [ -f "$GAPPS_DATA" ]; then
        /system/bin/sh /system/bin/hj_cleanup_gapps.sh guard_cleanup >> "$LOG" 2>&1 || true
    fi
fi

# First boot after flash / factory reset: Kiosk Setup Mode!
# 1. CRITICAL: Always mark first_time_nux_backfill_complete=1 in PreferencesService so
#    VrShell (ShellApp) NEVER stalls on "BlockingLaunch: Awaiting System Settings back-fill"
#    with a black screen after factory reset!
/system/bin/oculuspreferences --set first_time_nux_backfill_complete 1 >/dev/null 2>&1 || true

# Mirror /persist/horizenjam flags into SystemProperties so HorizenPreSetup can read them
# instantaneously with zero SELinux denials on /persist!
if [ -f /persist/horizenjam/phase1_done ]; then
    setprop sys.horizenjam.phase1_done 1
else
    setprop sys.horizenjam.phase1_done 0
fi

# 2. If setup_complete flag is missing, lock VR dock & window control bar via
#    sys.horizenjam.setup_active=1 and launch HorizenPreSetup cleanly without ever leaving
#    an empty black VrDesktop panel!
if [ ! -f "$SETUP_FLAG" ]; then
    echo "[HorizenJam] Setup pending (phase1=$(getprop sys.horizenjam.phase1_done)) - starting Kiosk Setup Mode..." >> "$LOG"
    setprop sys.horizenjam.setup_complete 0
    setprop sys.horizenjam.setup_active 1
    /system/bin/oculuspreferences --set first_time_nux_backfill_complete 1 >/dev/null 2>&1 || true
    /system/bin/oculussetting --set \
        first_time_nux_complete 1 \
        first_time_nux_require_ota 0 \
        first_time_nux_pre_ota_complete 1 \
        first_time_nux_ota_state complete \
        first_time_nux_guardian_setup_complete 1 \
        first_time_nux_health_safety_complete 1 >/dev/null 2>&1 || true
    settings put global device_provisioned 1 >/dev/null 2>&1 || true
    settings put secure user_setup_complete 1 >/dev/null 2>&1 || true

    # Helper: find any existing VrDesktop 2D panel display (mDisplayId > 0, size >= 800x500)
    find_vr2d_display() {
        dumpsys window displays 2>/dev/null | awk '
            /Display: mDisplayId=/ { sub(/.*mDisplayId=/, ""); id=$1+0 }
            /init=/ {
                if (id > 0) {
                    match($0, /init=[0-9]+x[0-9]+/)
                    if (RSTART > 0) {
                        s = substr($0, RSTART+5, RLENGTH-5)
                        split(s, wh, "x")
                        if (wh[1]+0 >= 800 && wh[2]+0 >= 500) { print id; exit }
                    }
                }
            }'
    }

    # Helper: launch PreSetupActivity cleanly, rescuing any empty black VrDesktop display!
    launch_presetup_safe() {
        # Dismiss USB MTP prompt if plugged into PC so it cannot block Vr2dDisplayResolver
        if dumpsys activity activities 2>/dev/null | grep -q "com.oculus.os.vrusb/.MtpAlertActivity"; then
            am force-stop com.oculus.os.vrusb >/dev/null 2>&1 || true
            sleep 1
        fi
        VR2D_ID=$(find_vr2d_display)
        if [ -n "$VR2D_ID" ]; then
            # Rescue directly onto the existing VrDesktop display (prevents empty black window!)
            am start --display "$VR2D_ID" -n com.horizenjam.presetup/.PreSetupActivity >/dev/null 2>&1 || true
        else
            am start -n com.horizenjam.presetup/.PreSetupActivity >/dev/null 2>&1 || true
        fi
    }

    W=0
    while { ! pidof com.oculus.vrshell >/dev/null 2>&1 || ! pidof com.oculus.shellenv >/dev/null 2>&1; } && [ $W -lt 30 ]; do
        sleep 1
        W=$((W + 1))
    done

    # Self-healing kiosk watchdog:
    # - Never fires am start while headset display is OFF/asleep (prevents dead black panels!)
    # - Automatically launches once headset wakes, and rescues any empty VrDesktop display via --display!
    (
        sleep 3
        while [ ! -f "$SETUP_FLAG" ]; do
            setprop sys.horizenjam.setup_active 1
            [ -f /persist/horizenjam/phase1_done ] && setprop sys.horizenjam.phase1_done 1
            # Only launch/rescue when the headset is Awake (display ON) AND no modal Guardian dialog (384x750) is open!
            if dumpsys power 2>/dev/null | grep -q "mWakefulness=Awake"; then
                if dumpsys window displays 2>/dev/null | grep -q "init=384x750"; then
                    sleep 3
                    continue
                fi
                if ! pidof com.horizenjam.presetup >/dev/null 2>&1 || \
                   ! dumpsys activity activities 2>/dev/null | grep -q "com.horizenjam.presetup/.PreSetupActivity"; then
                    launch_presetup_safe
                    sleep 4
                    continue
                fi
            fi
            sleep 3
        done
        setprop sys.horizenjam.setup_complete 1
        setprop sys.horizenjam.setup_active 0
        echo "[HorizenJam] Setup completed - VR dock & control bar unlocked, watchdog exited." >> "$LOG"
    ) &
    echo "[HorizenJam] Armed self-healing Kiosk Setup watchdog (dock & control bar hidden)." >> "$LOG"
else
    setprop sys.horizenjam.setup_complete 1
    setprop sys.horizenjam.setup_active 0
fi

echo "[HorizenJam] service.sh complete" >> "$LOG"
