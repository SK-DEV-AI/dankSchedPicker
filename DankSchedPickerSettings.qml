import QtQuick
import QtQuick.Controls
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

    StyledText {
        text: "Configuration"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    StyledRect {
        width: parent.width
        height: configContent.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: configContent
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            Row {
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
                        width: parent.width
                        text: String(PluginService.getGlobalVar("dankSchedPicker", "pollInterval", 3000) / 1000)
                        placeholderText: "3"
                        validator: IntValidator { bottom: 1; top: 300 }
                        onTextChanged: {
                            var val = parseInt(text) || 3
                            PluginService.setGlobalVar("dankSchedPicker", "pollInterval", val * 1000)
                        }
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
                        width: parent.width
                        text: String(PluginService.getGlobalVar("dankSchedPicker", "listInterval", 15000) / 1000)
                        placeholderText: "15"
                        validator: IntValidator { bottom: 5; top: 600 }
                        onTextChanged: {
                            var val = parseInt(text) || 15
                            PluginService.setGlobalVar("dankSchedPicker", "listInterval", val * 1000)
                        }
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
                        checked: PluginService.getGlobalVar("dankSchedPicker", "autoRefresh", true)
                        onToggled: val => PluginService.setGlobalVar("dankSchedPicker", "autoRefresh", val)
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
                        checked: PluginService.getGlobalVar("dankSchedPicker", "animate", true)
                        onToggled: val => PluginService.setGlobalVar("dankSchedPicker", "animate", val)
                    }
                }
            }

            Row {
                spacing: Theme.spacingM
                visible: PluginService.getGlobalVar("dankSchedPicker", "currentSched", "none") !== "none"

                DankButton {
                    text: "Refresh"
                    iconName: "refresh"
                    onClicked: {
                        Qt.callLater(function() {
                            PluginService.setGlobalVar("dankSchedPicker", "_refresh", Date.now())
                        })
                    }
                }
            }
        }
    }
}
