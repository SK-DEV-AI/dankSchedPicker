#!/usr/bin/env bash
set -euo pipefail

DBUS_DEST="org.scx.Loader"
DBUS_PATH="/org/scx/Loader"

dbus_prop() {
    dbus-send --system --print-reply --dest="$DBUS_DEST" "$DBUS_PATH" \
        org.freedesktop.DBus.Properties.Get string:org.scx.Loader string:"$1" 2>/dev/null
}

scxctl_cmd() {
    if command -v scxctl &>/dev/null; then
        scxctl "$@" 2>/dev/null
    fi
}

case "${1:-status}" in
    current)
        out=$(dbus_prop CurrentScheduler)
        sched=$(echo "$out" | grep "string" | sed 's/.*string "\(.*\)"/\1/')
        [[ "$sched" == "unknown" || -z "$sched" ]] && sched="none"

        out=$(dbus_prop SchedulerMode)
        mode_id=$(echo "$out" | grep "uint32" | awk '{print $NF}')
        case "${mode_id:-255}" in
            0) mode="Auto" ;;
            1) mode="Gaming" ;;
            2) mode="PowerSave" ;;
            3) mode="LowLatency" ;;
            4) mode="Server" ;;
            *) mode="?" ;;
        esac

        echo "$sched|$mode|${mode_id:-0}"
        ;;
    list)
        out=$(dbus_prop SupportedSchedulers)
        if [ -z "$out" ]; then
            scxctl_cmd list 2>/dev/null | grep "^scx_" || true
        else
            echo "$out" | grep "string" | sed 's/.*string "\(.*\)"/\1/'
        fi
        ;;
    start)
        sched="${2:-scx_bpfland}"
        mode="${3:-0}"
        if dbus-send --system --print-reply --dest="$DBUS_DEST" "$DBUS_PATH" \
            org.scx.Loader.StartScheduler string:"$sched" uint32:"$mode" >/dev/null 2>&1; then
            echo "$sched"
        else
            scxctl_cmd switch "$sched" "$mode" && echo "$sched" || { echo "FAILED"; exit 1; }
        fi
        ;;
    switch)
        sched="${2:-scx_bpfland}"
        mode="${3:-0}"
        if dbus-send --system --print-reply --dest="$DBUS_DEST" "$DBUS_PATH" \
            org.scx.Loader.SwitchScheduler string:"$sched" uint32:"$mode" >/dev/null 2>&1; then
            echo "$sched"
        else
            scxctl_cmd switch "$sched" "$mode" && echo "$sched" || { echo "FAILED"; exit 1; }
        fi
        ;;
    switchmode)
        mode="${2:-0}"
        sched=$(dbus_prop CurrentScheduler | grep "string" | sed 's/.*string "\(.*\)"/\1/')
        dbus-send --system --print-reply --dest="$DBUS_DEST" "$DBUS_PATH" \
            org.scx.Loader.SwitchScheduler string:"$sched" uint32:"$mode" >/dev/null 2>&1
        echo "$mode"
        ;;
    stop)
        if dbus-send --system --print-reply --dest="$DBUS_DEST" "$DBUS_PATH" \
            org.scx.Loader.StopScheduler >/dev/null 2>&1; then
            echo "stopped"
        else
            scxctl_cmd stop && echo "stopped" || { echo "FAILED"; exit 1; }
        fi
        ;;
    restore)
        dbus-send --system --print-reply --dest="$DBUS_DEST" "$DBUS_PATH" \
            org.scx.Loader.RestoreDefault >/dev/null 2>&1
        echo "restored"
        ;;
esac
