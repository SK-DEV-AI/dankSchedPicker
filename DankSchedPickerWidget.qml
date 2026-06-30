import QtQuick
import QtQuick.Controls
import QtQuick.Effects
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
        var v = PluginService.loadPluginData("dankSchedPicker", key)
        return v !== undefined ? v : defaultVal
    }

    function readPollInterval() {
        return Math.max(1000, Math.min(300000, readSetting("pollInterval", 3) * 1000))
    }

    function readListInterval() {
        return Math.max(5000, Math.min(600000, readSetting("listInterval", 15) * 1000))
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
                    id: pillIcon
                    name: "bolt"
                    size: Theme.iconSize - 4
                    color: root.isRunning ? Theme.primary : Theme.surfaceVariantText

                    scale: root.isLoading ? 1.15 : 1

                    Behavior on scale {
                        enabled: root.readAnimate()
                        NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                    }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 1
                        shadowBlur: 0.5
                        shadowColor: Theme.shadowMedium
                        shadowOpacity: 0.15
                    }
                }

                StyledText {
                    text: root.isRunning ? root.currentSched.replace("scx_", "") : "off"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: root.isRunning ? Theme.surfaceText : Theme.surfaceVariantText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    text: root.isRunning ? root.currentMode : ""
                    font.pixelSize: Theme.fontSizeSmall - 1
                    font.weight: Font.Normal
                    color: Theme.primary
                    visible: root.isRunning
                }
            }
        }
    }

    verticalBarPill: Component {
        MouseArea {
            implicitWidth: contentColumn.implicitWidth + 4
            implicitHeight: contentColumn.implicitHeight + 4
            acceptedButtons: Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                if (root.isRunning)
                    root.stopSched()
            }

            Column {
                id: contentColumn
                spacing: 1
                anchors.centerIn: parent

                DankIcon {
                    name: "bolt"
                    size: Theme.iconSize - 6
                    color: root.isRunning ? Theme.primary : Theme.surfaceVariantText
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    text: root.isRunning ? root.currentSched.replace("scx_", "") : ""
                    font.pixelSize: Theme.fontSizeSmall - 1
                    font.weight: Font.Medium
                    color: root.isRunning ? Theme.surfaceText : Theme.surfaceVariantText
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.isRunning
                }

                StyledText {
                    text: root.currentMode
                    font.pixelSize: Theme.fontSizeSmall - 3
                    font.weight: Font.Normal
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
            headerText: root.isRunning ? root.currentSched : "CPU Scheduler"
            detailsText: root.isRunning
                ? root.currentMode
                : (root.schedList.length > 0 ? "No scheduler running" : "scx_loader unreachable \u00B7 check sched-ext")
            showCloseButton: true

            property string hoverTip: ""

            Item {
                width: parent.width
                implicitHeight: contentColumn.implicitHeight + Theme.spacingL

                // Loading overlay — absolutely positioned over everything
                Rectangle {
                    anchors.fill: parent
                    z: 10
                    visible: root.isLoading
                    color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.85)
                    radius: Theme.cornerRadius

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        DankIcon {
                            name: "refresh"
                            size: 28
                            color: Theme.primary
                            anchors.horizontalCenter: parent.horizontalCenter

                            NumberAnimation on rotation {
                                from: 0; to: 360
                                duration: 1200
                                loops: Animation.Infinite
                                running: root.isLoading
                            }
                        }

                        StyledText {
                            text: "Switching scheduler\u2026"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                Column {
                    id: contentColumn
                    width: parent.width
                    spacing: Theme.spacingS

                    Rectangle {
                        width: parent.width - Theme.spacingL * 2
                        height: 1
                        color: Theme.withAlpha(Theme.outline, 0.12)
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.isRunning
                    }

                    Flow {
                        spacing: Theme.spacingXS
                        visible: root.isRunning
                        leftPadding: Theme.spacingL
                        rightPadding: Theme.spacingL
                        width: parent.width

                        Repeater {
                            model: root.modeNames
                            delegate: Item {
                                required property int index
                                required property string modelData

                                width: modeLabel.implicitWidth + 20
                                height: 28

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 14
                                    color: root.currentModeId === index
                                        ? Theme.primary
                                        : (modeMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent")

                                    Behavior on color {
                                        enabled: root.readAnimate()
                                        ColorAnimation { duration: 120 }
                                    }

                                    StyledText {
                                        id: modeLabel
                                        text: modelData
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: root.currentModeId === index ? Font.Medium : Font.Normal
                                        color: root.currentModeId === index ? Theme.onPrimary : Theme.surfaceText
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        id: modeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.currentModeId !== index) {
                                                root.switchMode(index)
                                                Qt.callLater(popout.closePopout)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width - Theme.spacingL * 2
                        height: 1
                        color: Theme.withAlpha(Theme.outline, 0.12)
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.isRunning
                    }

                    StyledText {
                        text: "Schedulers"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        leftPadding: Theme.spacingL
                    }

                    Item {
                        width: parent.width
                        height: 180
                        clip: true

                        Flickable {
                            id: schedFlickable
                            anchors.fill: parent
                            contentHeight: Math.max(180, schedRepeater.count * 46)
                            boundsBehavior: Flickable.StopAtBounds
                            clip: false

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                interactive: true
                            }

                            Column {
                                id: schedColumn
                                width: parent.width - Theme.spacingM
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 2

                                Column {
                                    id: emptyStateColumn
                                    width: parent.width
                                    spacing: Theme.spacingXS
                                    visible: root.schedList.length === 0
                                    topPadding: Theme.spacingM

                                    DankIcon {
                                        name: root.isRunning ? "inbox" : "power_off"
                                        size: 24
                                        color: Theme.surfaceVariantText
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    StyledText {
                                        text: root.isRunning ? "No schedulers available" : "scx_loader not detected"
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: Theme.surfaceText
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    StyledText {
                                        text: root.isRunning
                                            ? "scx_loader D-Bus service is running but no schedulers found"
                                            : "Install scx-scheds or check scx_loader.service"
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        color: Theme.surfaceVariantText
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        wrapMode: Text.WordWrap
                                        width: parent.width - Theme.spacingXL
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                Repeater {
                                    id: schedRepeater
                                    model: root.schedList

                                    delegate: Rectangle {
                                        id: schedItem
                                        required property string modelData
                                        required property int index

                                        property var info: root.schedDescriptions[modelData] || ["", ""]

                                        width: parent.width
                                        height: 44
                                        radius: Theme.cornerRadius
                                        color: {
                                            if (root.currentSched === modelData)
                                                return Theme.primary
                                            if (itemMouse.containsMouse)
                                                return Theme.surfaceContainerHighest
                                            return "transparent"
                                        }

                                        Behavior on color {
                                            enabled: root.readAnimate()
                                            ColorAnimation { duration: 100 }
                                        }

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.topMargin: 8
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 8
                                            width: 3
                                            radius: 1.5
                                            visible: root.currentSched === modelData
                                            color: Theme.onPrimary
                                        }

                                        Row {
                                            spacing: Theme.spacingS
                                            anchors.left: parent.left
                                            anchors.leftMargin: Theme.spacingL
                                            anchors.verticalCenter: parent.verticalCenter

                                            Column {
                                                spacing: 1
                                                anchors.verticalCenter: parent.verticalCenter

                                                StyledText {
                                                    text: modelData.replace("scx_", "")
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    font.weight: root.currentSched === modelData ? Font.DemiBold : Font.Normal
                                                    color: root.currentSched === modelData ? Theme.onPrimary : Theme.surfaceText
                                                }

                                                StyledText {
                                                    text: schedItem.info[0]
                                                    font.pixelSize: Theme.fontSizeSmall - 2
                                                    color: root.currentSched === modelData
                                                        ? Theme.withAlpha(Theme.onPrimary, 0.7)
                                                        : Theme.surfaceVariantText
                                                }
                                            }
                                        }

                                        Row {
                                            anchors.right: parent.right
                                            anchors.rightMargin: Theme.spacingS
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Theme.spacingXS
                                            visible: root.currentSched === modelData

                                            DankIcon {
                                                name: "check_circle"
                                                size: 16
                                                color: Theme.onPrimary
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
                                var idx = Math.floor(pt.y / 46)
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
                        height: 48
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh

                        StyledText {
                            id: tipText
                            text: popout.hoverTip
                            font.pixelSize: Theme.fontSizeSmall - 1
                            color: popout.hoverTip ? Theme.surfaceText : Theme.surfaceVariantText
                            wrapMode: Text.WordWrap
                            width: parent.width - Theme.spacingL * 2
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingL
                            anchors.verticalCenter: parent.verticalCenter
                            lineHeight: 1.3
                            maximumLineCount: 3
                            clip: true
                        }
                    }

                    Rectangle {
                        width: parent.width - Theme.spacingL * 2
                        height: 1
                        color: Theme.withAlpha(Theme.outline, 0.12)
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.isRunning
                    }

                    Row {
                        spacing: Theme.spacingM
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.isRunning

                        DankButton {
                            text: root.isLoading ? "Switching\u2026" : "Stop"
                            iconName: "stop"
                            backgroundColor: Theme.error
                            textColor: Theme.white
                            enabled: !root.isLoading
                            onClicked: {
                                root.stopSched()
                                Qt.callLater(popout.closePopout)
                            }
                        }

                        DankButton {
                            text: "Refresh"
                            iconName: "refresh"
                            enabled: !root.isLoading
                            onClicked: {
                                Qt.callLater(root.refreshList)
                                getProcess.command = ["sh", "-c", root.schedHelper + " current"]
                                getProcess.running = true
                            }
                        }
                    }

                    Item {
                        width: 1
                        height: Theme.spacingXS
                        visible: root.isRunning
                    }
                }
            }
        }
    }

    popoutWidth: 360
    popoutHeight: 480
}
