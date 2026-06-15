import QtQuick
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "dankSchedPicker"

    StyledText {
        text: "Current State"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    StyledRect {
        width: parent.width
        height: stateContent.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: stateContent
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            Row {
                spacing: Theme.spacingM

                DankIcon {
                    name: "speed"
                    size: Theme.iconSize
                    color: Theme.primary
                }

                Column {
                    spacing: 2

                    StyledText {
                        text: PluginService.getGlobalVar("dankSchedPicker", "currentSched", "none") || "none"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: "Mode: " + (PluginService.getGlobalVar("dankSchedPicker", "currentMode", "Auto") || "Auto")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }
            }
        }
    }

    SliderSetting {
        settingKey: "pollInterval"
        label: "Poll Interval"
        description: "How often to check scheduler state (seconds)"
        defaultValue: 3
        minimum: 1
        maximum: 300
        unit: "s"
    }

    SliderSetting {
        settingKey: "listInterval"
        label: "List Refresh"
        description: "How often to refresh the scheduler list (seconds)"
        defaultValue: 15
        minimum: 5
        maximum: 600
        unit: "s"
    }

    ToggleSetting {
        settingKey: "autoRefresh"
        label: "Auto-refresh list"
        description: "Automatically refresh the available scheduler list"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "animate"
        label: "Animate transitions"
        description: "Smooth color transitions in the popout"
        defaultValue: true
    }
}
