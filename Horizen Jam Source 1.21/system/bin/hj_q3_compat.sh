#!/system/bin/sh
# Horizen Jam 1.0 - Quest 3 App Compatibility Layer & Working Magisk resetprop Spoofing
# Supports real runtime Quest 3 (eureka) model/device spoofing for Singularity & Quest 3 apps!

CFG="/data/horizenjam/q3_compat.json"
DEFAULT_CFG="/system/etc/horizenjam/q3_compat_default.json"
MAGISK_BIN="/sbin/magisk"
[ -x "$MAGISK_BIN" ] || MAGISK_BIN="$(which magisk 2>/dev/null || echo /sbin/magisk)"

mkdir -p /data/horizenjam 2>/dev/null
[ -f "$CFG" ] || cp -f "$DEFAULT_CFG" "$CFG" 2>/dev/null

case "${1:-apply}" in
    apply)
        # Preserve stock VrApi GoCompatibility layer so VrDriver always boots cleanly
        setprop debug.oculus.vrapilayers "GoCompatibility"
        setprop persist.horizenjam.q3_compat_active 1
        setprop persist.horizenjam.xr_fallback_passthrough "monochrome_insight"
        setprop persist.horizenjam.xr_fallback_depth "disabled_graceful"
        setprop persist.horizenjam.xr_fallback_facetracking "stub_neutral"
        echo "Quest 3 App Compatibility Layer applied."
        ;;
    spoof_on)
        setprop persist.horizenjam.spoof_q3 1
        "$MAGISK_BIN" resetprop ro.product.model "Quest 3" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.system.model "Quest 3" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.vendor.model "Quest 3" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.odm.model "Quest 3" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.device "eureka" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.system.device "eureka" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.vendor.device "eureka" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.name "eureka" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.build.product "eureka" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.manufacturer "Meta" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.brand "oculus" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.horizenjam.spoofed_model "Quest 3 (eureka)" 2>/dev/null || true
        # Restart Singularity so it picks up the spoofed Build.MODEL / Build.DEVICE immediately!
        am force-stop com.lumi.singularity 2>/dev/null || true
        echo "Quest 3 spoofing ENABLED (Quest 3 / eureka via Magisk resetprop)."
        ;;
    spoof_off)
        setprop persist.horizenjam.spoof_q3 0
        "$MAGISK_BIN" resetprop ro.product.model "Quest" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.system.model "Quest" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.vendor.model "Quest" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.odm.model "Quest" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.device "monterey" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.system.device "monterey" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.vendor.device "monterey" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.name "vr_monterey" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.build.product "monterey" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.product.manufacturer "Oculus" 2>/dev/null || true
        "$MAGISK_BIN" resetprop ro.horizenjam.spoofed_model "Quest 1 (monterey)" 2>/dev/null || true
        am force-stop com.lumi.singularity 2>/dev/null || true
        echo "Quest 3 spoofing DISABLED (restored Quest 1 / monterey)."
        ;;
    enable_pkg)
        PKG="$2"
        [ -n "$PKG" ] && setprop "persist.hj.q3.${PKG}" 1
        echo "Enabled Quest 3 compat profile for $PKG"
        ;;
    disable_pkg)
        PKG="$2"
        [ -n "$PKG" ] && setprop "persist.hj.q3.${PKG}" 0
        echo "Disabled Quest 3 compat profile for $PKG"
        ;;
esac
