import QtQuick
import qs.Common
import qs.Services
import qs.Modules.Plugins

PluginSettings {
    id: settings

    sectionTitle: "Scheduler Picker"
    sectionSubtitle: "sched-ext CPU scheduler switcher"

    SectionLabel { text: "Current State" }

    StyledRect {
        width: parent.width
        height: stateColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: stateColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            Row {
                width: parent.width
                spacing: Theme.spacingM

                DankIcon {
                    name: "speed"
                    size: Theme.iconSize
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    StyledText {
                        text: {
                            var s = PluginService.getGlobalVar("dankSchedPicker", "currentSched", "none")
                            return s !== "none" ? s : "No scheduler running"
                        }
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: {
                            var m = PluginService.getGlobalVar("dankSchedPicker", "currentMode", "")
                            return m ? "Mode: " + m : ""
                        }
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        visible: text !== ""
                    }
                }
            }
        }
    }

    SectionLabel { text: "Configuration" }

    StyledRect {
        width: parent.width
        height: configColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: configColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            Row {
                width: parent.width
                spacing: Theme.spacingM

                Column {
                    width: (parent.width - Theme.spacingM) / 2
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "Poll Interval (seconds)"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    DankTextField {
                        id: pollIntervalField
                        width: parent.width
                        text: String(PluginService.getGlobalVar("dankSchedPicker", "pollInterval", 3000) / 1000)
                        placeholderText: "3"
                        validator: IntValidator { bottom: 1; top: 300 }
                        onTextChanged: {
                            var val = parseInt(text) || 3;
                            PluginService.setGlobalVar("dankSchedPicker", "pollInterval", val * 1000);
                        }
                    }

                    StyledText {
                        text: "How often to check scheduler state (1-300)"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }

                Column {
                    width: (parent.width - Theme.spacingM) / 2
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "List Refresh Interval (s)"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    DankTextField {
                        id: listIntervalField
                        width: parent.width
                        text: String(PluginService.getGlobalVar("dankSchedPicker", "listInterval", 15000) / 1000)
                        placeholderText: "15"
                        validator: IntValidator { bottom: 5; top: 600 }
                        onTextChanged: {
                            var val = parseInt(text) || 15;
                            PluginService.setGlobalVar("dankSchedPicker", "listInterval", val * 1000);
                        }
                    }

                    StyledText {
                        text: "How often to refresh scheduler list (5-600)"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }

            Row {
                spacing: Theme.spacingM

                Column {
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "Auto-refresh list"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    DankToggle {
                        id: autoRefreshToggle
                        checked: PluginService.getGlobalVar("dankSchedPicker", "autoRefresh", true)
                        onToggled: isChecked => {
                            PluginService.setGlobalVar("dankSchedPicker", "autoRefresh", isChecked);
                        }
                    }
                }

                Column {
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "Animate transitions"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    DankToggle {
                        id: animateToggle
                        checked: PluginService.getGlobalVar("dankSchedPicker", "animate", true)
                        onToggled: isChecked => {
                            PluginService.setGlobalVar("dankSchedPicker", "animate", isChecked);
                        }
                    }
                }
            }
        }
    }

    SectionLabel { text: "About Schedulers" }

    StyledRect {
        width: parent.width
        height: aboutColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surface

        Column {
            id: aboutColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingS

            StyledText {
                text: "sched-ext schedulers are BPF-based CPU scheduling plugins. Each has different characteristics:"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
            }

            StyledText {
                text: "• scx_bpfland — Interactive vruntime scheduler. Great all-rounder for desktop/gaming."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                wrapMode: Text.WordWrap
                width: parent.width
                leftPadding: Theme.spacingS
            }

            StyledText {
                text: "• scx_rusty — Feature-rich, highly tunable. Good for gaming and audio production."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                wrapMode: Text.WordWrap
                width: parent.width
                leftPadding: Theme.spacingS
            }

            StyledText {
                text: "• scx_lavd — Latest-gen CPU optimizer. Great for gaming and power saving."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                wrapMode: Text.WordWrap
                width: parent.width
                leftPadding: Theme.spacingS
            }

            StyledText {
                text: "• Mode reference: Auto=balanced default, Gaming=low-latency, PowerSave=energy-efficient, LowLatency=maximum responsiveness"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }
    }
}
