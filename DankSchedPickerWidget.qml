import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root
    layerNamespacePlugin: "sched-picker"

    property string currentSched: "none"
    property string currentMode: "Auto"
    property int currentModeId: 0
    property bool isRunning: false
    property var schedList: []
    property var _pendingList: []
    property bool isLoading: false

    readonly property string schedHelper: {
        var url = Qt.resolvedUrl("./sched-helper.sh")
        return url.toString().replace("file://", "")
    }

    readonly property var modeNames: ["Auto", "Gaming", "PowerSave", "LowLatency", "Server"]

    readonly property var schedDescriptions: ({
        "scx_beerland": [ "Cache locality", "Prioritizes keeping tasks on the same CPU for cache warmth. Good for cache-heavy workloads, servers, and surprisingly well in some games." ],
        "scx_bpfland": [ "Interactive vruntime", "L2/L3 cache-aware scheduler for great interactivity under load. Good for gaming, desktop, audio production, power saving, and servers." ],
        "scx_cake": [ "CAKE algorithm gaming", "Experimental 4-tier BPF scheduler adapting network CAKE's DRR++ for CPU. Designed for modern AMD/Intel gaming hardware." ],
        "scx_cosmos": [ "Lightweight general", "Preserves task-to-CPU locality when not saturated. Adapts to both desktop and server workloads with low overhead." ],
        "scx_flash": [ "EDF fairness", "Earliest-deadline-first policy with fairness and predictability. Good for gaming, latency-sensitive audio, multimedia, and servers." ],
        "scx_flow": [ "Budget-based auto-tune", "Priority lanes with wakeup budget. Auto-tunes between balanced/latency/throughput. Best for desktop multitasking, gaming w/ background apps, and dev work." ],
        "scx_lavd": [ "AMD/Intel optimized", "Latest-gen CPU optimizer with core compaction (idle cores sleep longer, active cores run faster). Great for gaming, audio, desktop, and power saving." ],
        "scx_pandemonium": [ "Behavioral + NUMA", "EWMA-driven 3-tier classification with topology-aware placement. Self-calibrates from 2C laptops to 32C+ servers. Good for gaming, desktop, ZFS/storage." ],
        "scx_p2dq": [ "LLC load balance", "Pick-two load balancing between LLCs. Keeps high cache locality with work conservation. Good for servers, desktops, and gaming with tuning." ],
        "scx_tickless": [ "Server/HPC tickless", "Routes scheduling through primary CPUs so others run tickless. Designed for cloud computing, virtualization, and HPC server workloads." ],
        "scx_rustland": [ "Userspace (bpfland-like)", "Userspace scheduler sharing similarities with bpfland. Good for low-latency gaming, video conferencing, streaming, and general desktop." ],
        "scx_rusty": [ "Feature-rich tunable", "Highly tunable scheduler with wide feature set. Good for gaming, latency-sensitive workloads, desktop, audio production, and power saving." ]
    })

    function readSetting(key, defaultVal) {
        var v = PluginService.getGlobalVar("dankSchedPicker", key, defaultVal)
        return v !== undefined ? v : defaultVal
    }

    function readPollInterval() {
        return Math.max(1000, Math.min(300000, readSetting("pollInterval", 3000)))
    }

    function readListInterval() {
        return Math.max(5000, Math.min(600000, readSetting("listInterval", 15000)))
    }

    function readAnimate() {
        return readSetting("animate", true)
    }

    function readAutoRefresh() {
        return readSetting("autoRefresh", true)
    }

    Timer {
        id: pollTimer
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            interval = root.readPollInterval()
            getProcess.command = ["sh", "-c", root.schedHelper + " current"]
            getProcess.running = true
        }
    }

    Timer {
        id: listTimer
        interval: 15000
        repeat: true
        running: root.readAutoRefresh()
        onTriggered: {
            interval = root.readListInterval()
            root.refreshList()
        }
    }

    Component.onCompleted: {
        Qt.callLater(root.refreshList)
    }

    Process {
        id: getProcess
        running: false
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split("|")
                if (parts.length >= 3) {
                    root.currentSched = parts[0]
                    root.currentMode = parts[1]
                    root.currentModeId = parseInt(parts[2])
                    root.isRunning = root.currentSched !== "none"

                    PluginService.setGlobalVar("dankSchedPicker", "currentSched", root.currentSched)
                    PluginService.setGlobalVar("dankSchedPicker", "currentMode", root.currentMode)
                }
            }
        }
    }

    Process {
        id: listProcess
        running: false
        stdout: SplitParser {
            onRead: data => {
                if (data.trim())
                    root._pendingList.push(data.trim())
            }
        }
        onExited: (code, status) => {
            root.schedList = root._pendingList
            root._pendingList = []
            root.isLoading = false
        }
    }

    Process {
        id: switchProcess
        running: false
        onStarted: {
            root.isLoading = true
        }
        onExited: (code, status) => {
            root.isLoading = false
            if (code === 0) {
                getProcess.command = ["sh", "-c", root.schedHelper + " current"]
                getProcess.running = true
                Qt.callLater(root.refreshList)
            } else {
                if (typeof ToastService !== "undefined")
                    ToastService.showError("Scheduler", "Switch failed (exit " + code + ")")
            }
        }
    }

    function refreshList() {
        if (root.isLoading)
            return
        root._pendingList = []
        listProcess.command = ["sh", "-c", root.schedHelper + " list"]
        listProcess.running = true
    }

    function switchScheduler(name, mode) {
        if (root.isLoading)
            return
        var cmd = root.isRunning
            ? root.schedHelper + " switch " + name + " " + mode
            : root.schedHelper + " start " + name + " " + mode
        switchProcess.command = ["sh", "-c", cmd]
        switchProcess.running = true
    }

    function switchMode(modeId) {
        if (!root.isRunning || root.isLoading)
            return
        switchProcess.command = ["sh", "-c", root.schedHelper + " switchmode " + modeId]
        switchProcess.running = true
    }

    function stopSched() {
        if (root.isLoading)
            return
        switchProcess.command = ["sh", "-c", root.schedHelper + " stop"]
        switchProcess.running = true
    }

    horizontalBarPill: Component {
        MouseArea {
            id: pillMouse
            implicitWidth: contentRow.implicitWidth + 6
            implicitHeight: contentRow.implicitHeight + 4
            acceptedButtons: Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                if (root.isRunning)
                    root.stopSched()
            }

            Row {
                id: contentRow
                spacing: 2

                DankIcon {
                    name: "bolt"
                    size: Theme.iconSize - 4
                    color: root.isRunning ? Theme.primary : Theme.surfaceVariantText
                }

                StyledText {
                    text: root.isRunning ? root.currentSched.replace("scx_", "") : "none"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: root.isRunning ? Theme.surfaceText : Theme.surfaceVariantText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    text: root.isRunning ? "[" + root.currentMode + "]" : ""
                    font.pixelSize: Theme.fontSizeSmall - 1
                    font.weight: Font.Light
                    color: Theme.primary
                    visible: root.isRunning
                }
            }
        }
    }

    verticalBarPill: Component {
        MouseArea {
            implicitWidth: contentColumn.implicitWidth + 2
            implicitHeight: contentColumn.implicitHeight + 2
            acceptedButtons: Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton && root.isRunning)
                    root.stopSched()
            }

            Column {
                id: contentColumn
                spacing: 2
                anchors.centerIn: parent

                DankIcon {
                    name: "bolt"
                    size: Theme.iconSize - 6
                    color: root.isRunning ? Theme.primary : Theme.surfaceVariantText
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    text: root.isRunning ? root.currentSched.replace("scx_", "") : ""
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: root.isRunning ? Theme.surfaceText : Theme.surfaceVariantText
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.isRunning
                }

                StyledText {
                    text: root.currentMode
                    font.pixelSize: Theme.fontSizeSmall - 2
                    font.weight: Font.Light
                    color: Theme.primary
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.isRunning
                }
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: "CPU Scheduler"
            detailsText: root.isRunning
                ? root.currentSched + " [" + root.currentMode + "]"
                : "No scheduler running"
            showCloseButton: true

            property string hoverTip: ""

            Item {
                width: parent.width
                implicitHeight: contentColumn.implicitHeight + Theme.spacingL

                Column {
                    id: contentColumn
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: "Mode:"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                        visible: root.isRunning
                        leftPadding: Theme.spacingS
                    }

                    Flow {
                        spacing: Theme.spacingXS
                        visible: root.isRunning
                        leftPadding: Theme.spacingS
                        width: parent.width - Theme.spacingL

                        Repeater {
                            model: root.modeNames
                            delegate: StyledRect {
                                id: modeBtn
                                required property int index
                                required property string modelData

                                width: modeLabel.implicitWidth + 16
                                height: 28
                                radius: Theme.cornerRadius
                                color: root.currentModeId === index
                                    ? Theme.primary
                                    : (modeMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)

                                StyledText {
                                    id: modeLabel
                                    text: parent.modelData
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: root.currentModeId === index ? Font.Bold : Font.Normal
                                    color: root.currentModeId === index ? Theme.onPrimary : Theme.surfaceText
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: modeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.currentModeId !== index)
                                            root.switchMode(index)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width - Theme.spacingL
                        height: 1
                        color: Theme.outlineVariant
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.isRunning
                    }

                    StyledText {
                        text: "Schedulers:"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                        leftPadding: Theme.spacingS
                    }

                    Item {
                        width: parent.width
                        height: 200
                        clip: true

                        Flickable {
                            id: schedFlickable
                            anchors.fill: parent
                            contentHeight: Math.max(200, schedRepeater.count * 42 + 8)
                            boundsBehavior: Flickable.StopAtBounds
                            clip: false

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                interactive: true
                            }

                            Column {
                                id: schedColumn
                                width: parent.width
                                spacing: 2
                                leftPadding: Theme.spacingS
                                rightPadding: Theme.spacingS

                                StyledText {
                                    text: "No schedulers available"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: root.schedList.length === 0
                                }

                                Repeater {
                                    id: schedRepeater
                                    model: root.schedList

                                    delegate: StyledRect {
                                        id: schedItem
                                        required property string modelData
                                        required property int index

                                        property var info: root.schedDescriptions[modelData] || ["", ""]

                                        width: parent.width - Theme.spacingS
                                        height: 40
                                        radius: Theme.cornerRadius
                                        color: root.currentSched === modelData
                                            ? Theme.primary
                                            : (itemMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)

                                        Behavior on color {
                                            enabled: root.readAnimate()
                                            ColorAnimation { duration: 100 }
                                        }

                                        Row {
                                            spacing: Theme.spacingXS
                                            anchors.left: parent.left
                                            anchors.leftMargin: Theme.spacingS
                                            anchors.verticalCenter: parent.verticalCenter

                                            DankIcon {
                                                name: "play_arrow"
                                                size: 14
                                                color: root.currentSched === modelData ? Theme.onPrimary : "transparent"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Column {
                                                spacing: 0
                                                anchors.verticalCenter: parent.verticalCenter

                                                StyledText {
                                                    text: modelData.replace("scx_", "")
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    font.weight: root.currentSched === modelData ? Font.Bold : Font.Medium
                                                    color: root.currentSched === modelData ? Theme.onPrimary : Theme.surfaceText
                                                }

                                                StyledText {
                                                    text: schedItem.info[0]
                                                    font.pixelSize: Theme.fontSizeSmall - 2
                                                    color: root.currentSched === modelData
                                                        ? Theme.onPrimary
                                                        : Theme.surfaceVariantText
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: itemMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (root.currentSched !== modelData && !root.isLoading) {
                                                    root.switchScheduler(modelData, root.currentModeId)
                                                    Qt.callLater(popout.closePopout)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            onPositionChanged: mouse => {
                                var pt = schedColumn.mapFromItem(hoverArea, mouseX, mouseY)
                                var idx = Math.floor(pt.y / 42)
                                if (idx >= 0 && idx < root.schedList.length) {
                                    var info = root.schedDescriptions[root.schedList[idx]] || ["", ""]
                                    popout.hoverTip = info[1] || ""
                                } else {
                                    popout.hoverTip = ""
                                }
                            }
                            onExited: popout.hoverTip = ""
                        }
                    }

                    StyledRect {
                        id: tipBar
                        width: parent.width
                        height: Math.max(32, tipText.implicitHeight + Theme.spacingM)
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh
                        visible: popout.hoverTip !== ""

                        StyledText {
                            id: tipText
                            text: popout.hoverTip
                            font.pixelSize: Theme.fontSizeSmall - 1
                            color: Theme.surfaceText
                            wrapMode: Text.WordWrap
                            width: parent.width - Theme.spacingS * 2
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.top: parent.top
                            anchors.topMargin: Theme.spacingXS
                            lineHeight: 1.3
                        }
                    }

                    Row {
                        spacing: Theme.spacingS
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.isRunning

                        DankButton {
                            text: root.isLoading ? "Working..." : "Stop"
                            iconName: "stop"
                            backgroundColor: Theme.error
                            enabled: !root.isLoading
                            onClicked: {
                                root.stopSched()
                                Qt.callLater(popout.closePopout)
                            }
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 360
    popoutHeight: 460
}
