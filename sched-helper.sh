#!/usr/bin/env bash
set -euo pipefail

DBUS_DEST="org.scx.Loader"
DBUS_PATH="/org/scx/Loader"

dbus_prop() {
    dbus-send --system --print-reply --dest="$DBUS_DEST" "$DBUS_PATH" \
        org.freedesktop.DBus.Properties.Get string:org.scx.Loader string:"$1" 2>/dev/null
}

case "${1:-status}" in
    current)
        out=$(dbus_prop CurrentScheduler)
        sched=$(echo "$out" | grep "string" | sed 's/.*string "\(.*\)"/\1/')
        [[ "$sched" == "unknown" ]] && sched="none"

        out=$(dbus_prop SchedulerMode)
        mode_id=$(echo "$out" | grep "uint32" | awk '{print $NF}')
        case "$mode_id" in
            0) mode="Auto" ;;
            1) mode="Gaming" ;;
            2) mode="PowerSave" ;;
            3) mode="LowLatency" ;;
            4) mode="Server" ;;
            *) mode="?" ;;
        esac

        echo "$sched|$mode|$mode_id"
        ;;
    list)
        out=$(dbus_prop SupportedSchedulers)
        echo "$out" | grep "string" | sed 's/.*string "\(.*\)"/\1/'
        ;;
    start)
        sched="${2:-scx_bpfland}"
        mode="${3:-0}"
        dbus-send --system --print-reply --dest="$DBUS_DEST" "$DBUS_PATH" \
            org.scx.Loader.StartScheduler string:"$sched" uint32:"$mode" >/dev/null 2>&1
        echo "$sched"
        ;;
    switch)
        sched="${2:-scx_bpfland}"
        mode="${3:-0}"
        dbus-send --system --print-reply --dest="$DBUS_DEST" "$DBUS_PATH" \
            org.scx.Loader.SwitchScheduler string:"$sched" uint32:"$mode" >/dev/null 2>&1
        echo "$sched"
        ;;
    switchmode)
        mode="${2:-0}"
        dbus-send --system --print-reply --dest="$DBUS_DEST" "$DBUS_PATH" \
            org.scx.Loader.SwitchScheduler string:"" uint32:"$mode" >/dev/null 2>&1
        echo "$mode"
        ;;
    stop)
        dbus-send --system --print-reply --dest="$DBUS_DEST" "$DBUS_PATH" \
            org.scx.Loader.StopScheduler >/dev/null 2>&1
        echo "stopped"
        ;;
    restore)
        dbus-send --system --print-reply --dest="$DBUS_DEST" "$DBUS_PATH" \
            org.scx.Loader.RestoreDefault >/dev/null 2>&1
        echo "restored"
        ;;
esac
