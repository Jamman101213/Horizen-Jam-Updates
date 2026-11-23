#!/system/bin/sh
# Horizen Jam 1.0 - Safe Eject USB-C OTG Storage
sync
umount -l /sdcard/USB_Drive 2>/dev/null || true
umount -l /mnt/horizenjam_usb 2>/dev/null || true
setprop persist.horizenjam.usb_mounted 0
setprop persist.horizenjam.usb_device ""
echo "USB Drive safely ejected."
