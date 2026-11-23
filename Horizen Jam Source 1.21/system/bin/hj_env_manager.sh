#!/system/bin/sh
# Horizen Jam 1.1 - Custom Home Environment & World Swapper
# Installs any custom environment APKs placed in /sdcard/HorizenJam/Environments/
# and cycles active Quest Home environment via oculussetting!

CUSTOM_DIR="/sdcard/HorizenJam/Environments"
mkdir -p "$CUSTOM_DIR" 2>/dev/null

# Auto-install any newly dropped custom environment APKs
for apk in "$CUSTOM_DIR"/*.apk; do
    [ -f "$apk" ] || continue
    MARKER="${apk}.installed"
    if [ ! -f "$MARKER" ]; then
        pm install -r -g "$apk" >/dev/null 2>&1 && touch "$MARKER"
    fi
done

ENVS=$(pm list packages 2>/dev/null | grep -E "package:com\.oculus\.environment\.prod\." | sed 's/^package://' | sort)
[ -z "$ENVS" ] && exit 0

CUR=$(getprop persist.horizenjam.home_env_pkg)
NEXT=""
FOUND=0
FIRST=""
for e in $ENVS; do
    [ -z "$FIRST" ] && FIRST="$e"
    if [ "$FOUND" = "1" ]; then
        NEXT="$e"
        break
    fi
    [ "$e" = "$CUR" ] && FOUND=1
done
[ -z "$NEXT" ] && NEXT="$FIRST"

SHORT=$(echo "$NEXT" | sed 's/^com\.oculus\.environment\.prod\.//')
setprop persist.horizenjam.home_env_pkg "$NEXT"
setprop persist.horizenjam.home_env "$SHORT"
/system/bin/oculussetting --set environment_selected "$NEXT" >/dev/null 2>&1 || true
am broadcast -a com.oculus.vrshell.intent.action.LAUNCH -p com.oculus.vrshell -e intent_data "systemux://settings/virtual_environment" >/dev/null 2>&1 || true
echo "Switched Home Environment to: $SHORT ($NEXT)"
