#!/system/bin/sh
# Horizen Jam 1.1 - Lightweight Hardware Button Macro Daemon
# - Vol Up + Vol Down chord: Instant screenshot to /sdcard/Pictures/HorizenJam/
# - Double-tap Vol Down (<500ms): Open Horizen ModHub anywhere!

PIDFILE="/data/horizenjam/macro_daemon.pid"

case "${1:-start}" in
    stop)
        if [ -f "$PIDFILE" ]; then
            kill "$(cat "$PIDFILE")" 2>/dev/null || true
            rm -f "$PIDFILE"
        fi
        exit 0
        ;;
    start)
        if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
            exit 0
        fi
        echo $$ > "$PIDFILE"
        VOL_UP=0
        VOL_DN=0
        LAST_DN_MS=0
        getevent -l 2>/dev/null | while read -r DEV TYPE CODE VAL; do
            if [ "$CODE" = "KEY_VOLUMEUP" ]; then
                [ "$VAL" = "DOWN" ] && VOL_UP=1 || VOL_UP=0
            elif [ "$CODE" = "KEY_VOLUMEDOWN" ]; then
                if [ "$VAL" = "DOWN" ]; then
                    VOL_DN=1
                    NOW_MS=$(date +%s 2>/dev/null || echo 0)
                    if [ "$VOL_UP" = "1" ]; then
                        mkdir -p /sdcard/Pictures/HorizenJam 2>/dev/null
                        TS=$(date +%Y%m%d_%H%M%S 2>/dev/null || echo shot)
                        screencap -p "/sdcard/Pictures/HorizenJam/macro_${TS}.png" >/dev/null 2>&1 &
                    elif [ "$((NOW_MS - LAST_DN_MS))" -le 1 ] && [ "$LAST_DN_MS" != "0" ]; then
                        am start -n com.horizenjam.files/.ModHubActivity >/dev/null 2>&1 &
                        LAST_DN_MS=0
                        continue
                    fi
                    LAST_DN_MS="$NOW_MS"
                else
                    VOL_DN=0
                fi
            fi
        done
        ;;
esac
