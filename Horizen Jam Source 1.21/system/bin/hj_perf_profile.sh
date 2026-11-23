#!/system/bin/sh
# Horizen Jam 1.0 - Snapdragon 835 / Adreno 540 Performance Preset Engine
# Presets: battery | balanced | max

PRESET="${1:-balanced}"
setprop persist.horizenjam.perf_preset "$PRESET"

case "$PRESET" in
    battery)
        setprop debug.oculus.cpuLevel 1
        setprop debug.oculus.gpuLevel 1
        setprop debug.oculus.foveation.level 3
        setprop debug.oculus.textureWidth 1216
        setprop debug.oculus.textureHeight 1344
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            [ -w "$cpu" ] && echo "powersave" > "$cpu" 2>/dev/null
        done
        ;;
    max)
        setprop debug.oculus.cpuLevel 4
        setprop debug.oculus.gpuLevel 4
        setprop debug.oculus.foveation.level 1
        setprop debug.oculus.textureWidth 1600
        setprop debug.oculus.textureHeight 1760
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            [ -w "$cpu" ] && echo "performance" > "$cpu" 2>/dev/null
        done
        [ -w /sys/class/kgsl/kgsl-3d0/devfreq/governor ] && echo "performance" > /sys/class/kgsl/kgsl-3d0/devfreq/governor 2>/dev/null
        ;;
    balanced|*)
        setprop debug.oculus.cpuLevel 2
        setprop debug.oculus.gpuLevel 2
        setprop debug.oculus.foveation.level 2
        setprop debug.oculus.textureWidth 1440
        setprop debug.oculus.textureHeight 1600
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            [ -w "$cpu" ] && echo "interactive" > "$cpu" 2>/dev/null
        done
        [ -w /sys/class/kgsl/kgsl-3d0/devfreq/governor ] && echo "msm-adreno-tz" > /sys/class/kgsl/kgsl-3d0/devfreq/governor 2>/dev/null
        ;;
esac
echo "Applied Snapdragon 835 / Adreno 540 preset: $PRESET"
