#!/system/bin/sh
# Horizen Jam 1.0 - Account-Free / No-Meta Full-Feature Offline Setup Skip
# Unlocks all normal Quest 1 features (Home, Dock, Quick Settings, Library, Hand Tracking,
# Double-Tap Passthrough, Multi-Window Productivity Mode, Direct Touch, MTP USB, Guardian,
# ADB/Dev Mode) and suppresses Meta login/account begging without requiring a Meta account.

LOG=/data/horizenjam/skip_nux.log
echo "[HorizenJam] Executing Full-Feature Offline NUX Skip..." > "$LOG"

# 1. Unlock ALL native Quest 1 v50 features & Local Account Offline Mode via oculussetting
/system/bin/oculuspreferences --set first_time_nux_backfill_complete 1 >/dev/null 2>&1 || true
/system/bin/oculussetting --set \
    first_time_nux_complete 1 \
    first_time_nux_pre_ota_complete 1 \
    first_time_nux_ota_state complete \
    first_time_nux_guardian_setup_complete 1 \
    first_time_nux_guardian_setup_entered 1 \
    first_time_nux_health_safety_complete 1 \
    first_time_nux_allow_guardian 1 \
    local_account_mode_enabled_v1 1 \
    hand_tracking_enabled 1 \
    hand_tracking_opt_in 1 \
    hand_tracking_opt_in_v20 1 \
    autotransition_hands_controllers 1 \
    passthrough_on_demand_enabled 1 \
    productivity_mode_enabled 1 \
    desk_mode 1 \
    mtp_dialog_enabled 1 \
    controller_laser_beam_effects 1 \
    wakeup_dialog_enabled 0 \
    telemetry_state off \
    crash_reports_enabled 0 \
    browser_crash_reports_enabled 0 \
    enterprise_auto_ota 0 \
    licensing_mode 0 >/dev/null 2>&1 || true

# Fire internal Oculus/Quest NUX bypass broadcasts & Android provisioning flags
am broadcast -a firsttimenux.ota.SKIP_NUX >/dev/null 2>&1 || true
am broadcast -a com.oculus.firsttimenux.SKIP_NUX >/dev/null 2>&1 || true
settings put global device_provisioned 1
settings put secure user_setup_complete 1

# 2. Automatically enable USB Debugging, Developer Mode & 2D Multitasking
#    (Direct Touch stays opt-in OFF so offline Guardian boundary ray clicks never glitch!)
settings put global adb_enabled 1
settings put global development_settings_enabled 1
setprop persist.ovr.developer_mode 1
setprop persist.ovr.skip_nux 1
setprop persist.ovr.offline_mode 1
setprop persist.horizenjam.nux_skipped 1
setprop persist.horizenjam.direct_touch 0
setprop persist.ovr.direct_touch_enabled 0
setprop debug.oculus.directTouch 0
setprop persist.ovr.multitasking_2d_in_vr 1
setprop debug.oculus.allow2DMultitasking 1
setprop sys.horizenjam.setup_complete 1
setprop sys.horizenjam.setup_active 0

# 3. Disable Meta sign-in / telemetry collector packages ONLY
#    (Keep com.oculus.updater & com.oculus.os.telemetry enabled - hosts block handles telemetry cleanly)
for NAG_PKG in \
    com.oculus.firsttimenux \
    com.oculus.statscollector \
    com.oculus.bugreportservice
do
    pm disable-user --user 0 "$NAG_PKG" >/dev/null 2>&1 || true
done
pm enable com.oculus.updater >/dev/null 2>&1 || true
pm enable com.oculus.os.telemetry >/dev/null 2>&1 || true

# 4. Suppress Account Required lockouts in VrShell & SystemUX
setprop persist.ovr.bypass_account_check 1
setprop debug.oculus.offlineUnlock 1

# 5. Mark setup complete & clean up any leftover staged NikGapps ZIP in /data
mkdir -p /persist/horizenjam 2>/dev/null
chmod 0755 /persist/horizenjam 2>/dev/null || true
echo "offline_full_features:$(date +%s)" > /persist/horizenjam/setup_complete
GAPPS_ZIP="/data/horizenjam/NikGapps-core-arm64-10-20260204-signed.zip"
if [ -f "$GAPPS_ZIP" ]; then
    rm -f "$GAPPS_ZIP"
    echo "[HorizenJam] Deleted leftover $GAPPS_ZIP" >> "$LOG"
fi
[ -f /persist/horizenjam/gapps_prompt_done ] || echo "skipped_via_nux:$(date +%s)" > /persist/horizenjam/gapps_prompt_done

# 6. Check Touch controller pairing; launch on-device pairing panel inside VrShell ONLY if unpaired
PAIRED_BT=$(dumpsys bluetooth_manager 2>/dev/null | grep -iE "Oculus Touch|Quest Controller" | wc -l)
if [ "${PAIRED_BT:-0}" -eq 0 ]; then
    echo "[HorizenJam] No controllers paired yet; opening on-device pairing panel in VrShell." >> "$LOG"
    am broadcast -a com.oculus.vrshell.intent.action.LAUNCH -p com.oculus.vrshell \
        -e intent_data "apk://com.horizenjam.presetup" \
        -e uri "com.horizenjam.presetup/.ControllerPairActivity" >/dev/null 2>&1 || true
fi

echo "[HorizenJam] Full-Feature Offline NUX Skip complete." >> "$LOG"
