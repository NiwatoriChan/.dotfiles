import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import "../../config" as QsConfig
import "../../services" as QsServices

PanelWindow {
    id: root

    property bool shouldShow: false
    property string query: ""
    property int selectedIndex: 0
    property var cachedApps: []

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property color cSurface: pywal.surface
    readonly property color cSurfaceContainer: pywal.surfaceContainer
    readonly property color cSurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted
    readonly property color cBorder: Qt.rgba(1, 1, 1, 0.08)

    readonly property var terminalCommand: Array.isArray(config.launcher.terminalCommand) && config.launcher.terminalCommand.length > 0
        ? config.launcher.terminalCommand
        : ["kitty"]

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (root.shouldShow) {
                root.closeLauncher()
            } else {
                root.openLauncher()
            }
        }

        function open(): void {
            root.openLauncher()
        }

        function close(): void {
            root.closeLauncher()
        }
    }

    readonly property var iconCache: ({})

    function resolveIcon(iconName, name) {
        if (!iconName && !name) return ""
        const key = `${iconName || ""}|${name || ""}`
        if (root.iconCache[key] !== undefined) return root.iconCache[key]

        let path = ""
        if (iconName) {
            path = Quickshell.iconPath(iconName, true)
            if (!path) path = Quickshell.iconPath(iconName.toLowerCase(), true)
            if (!path && iconName.includes(".")) {
                const parts = iconName.split(".")
                const lastPart = parts[parts.length - 1]
                path = Quickshell.iconPath(lastPart, true) || Quickshell.iconPath(lastPart.toLowerCase(), true)
            }
        }
        if (!path && name) {
            path = Quickshell.iconPath(name.toLowerCase(), true)
        }

        root.iconCache[key] = path || ""
        return root.iconCache[key]
    }

    function reloadApps() {
        const raw = DesktopEntries.applications.values ?? []
        const list = []
        for (let i = 0; i < raw.length; ++i) {
            const entry = raw[i]
            if (!entry) continue
            const name = entry.name ?? ""
            const comment = entry.comment || entry.genericName || entry.execString || "Launch application"
            const iconPath = root.resolveIcon(entry.icon, name)
            list.push({
                entry: entry,
                name: name,
                comment: comment,
                iconPath: iconPath,
                lowerName: name.toLowerCase(),
                lowerComment: (entry.comment ?? "").toLowerCase(),
                lowerGeneric: (entry.genericName ?? "").toLowerCase(),
                lowerExec: (entry.execString ?? "").toLowerCase(),
                lowerId: (entry.id ?? "").toLowerCase()
            })
        }
        list.sort((a, b) => a.name.localeCompare(b.name))
        cachedApps = list
    }

    Component.onCompleted: {
        reloadApps()
    }

    Timer {
        id: reloadDebounceTimer
        interval: 300
        repeat: false
        onTriggered: root.reloadApps()
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            reloadDebounceTimer.restart()
        }
    }



    readonly property var actionEntries: [
        {
            id: "action-terminal",
            name: "Open Terminal",
            comment: "Launch configured terminal",
            glyph: "󰆍",
            type: "action",
            onTriggered: () => Quickshell.execDetached(terminalCommand)
        },
        {
            id: "action-files",
            name: "Open Files",
            comment: "Open your home directory",
            glyph: "󰉋",
            type: "action",
            onTriggered: () => Quickshell.execDetached(["xdg-open", Quickshell.env("HOME")])
        },
        {
            id: "action-screenshots",
            name: "Open Captures",
            comment: "Browse screenshots and recordings",
            glyph: "󰄄",
            type: "action",
            onTriggered: () => QsServices.Screenshot.openScreenshotsFolder()
        },
        {
            id: "action-network",
            name: "Network Settings",
            comment: "Open nm-connection-editor",
            glyph: "󰖩",
            type: "action",
            onTriggered: () => Quickshell.execDetached(["nm-connection-editor"])
        }
    ]

    readonly property var visibleEntries: {
        const rawQ = query.trim()
        if (rawQ.startsWith(">")) {
            const actionQuery = rawQ.slice(1).trim()
            const lowerAction = actionQuery.toLowerCase()
            const list = []
            if (actionQuery.length > 0) {
                list.push({
                    id: "action-run-terminal",
                    name: `Run '${actionQuery}'`,
                    comment: `Execute '${actionQuery}' in terminal`,
                    glyph: "󰆍",
                    type: "action",
                    onTriggered: () => Quickshell.execDetached([...terminalCommand, "sh", "-c", `${actionQuery}; echo; read -n 1 -s -r -p 'Press any key to close...'`])
                })
            }
            for (const act of actionEntries) {
                if (!lowerAction.length || act.name.toLowerCase().includes(lowerAction) || act.comment.toLowerCase().includes(lowerAction)) {
                    list.push(act)
                }
            }
            return list
        }

        const q = rawQ.toLowerCase()
        const apps = cachedApps

        if (!q.length) {
            return apps
        }

        const results = []
        for (let i = 0; i < apps.length; ++i) {
            const item = apps[i]
            let rank = 0
            if (item.lowerName === q) rank = 1000
            else if (item.lowerName.startsWith(q)) rank = 900
            else if (item.lowerGeneric.startsWith(q) || item.lowerId.startsWith(q)) rank = 750
            else if (item.lowerName.includes(q)) rank = 650
            else if (item.lowerGeneric.includes(q) || item.lowerComment.includes(q)) rank = 500
            else if (item.lowerExec.includes(q)) rank = 400

            if (rank > 0) {
                results.push({ item: item, rank: rank })
            }
        }

        results.sort((a, b) => {
            if (b.rank !== a.rank) return b.rank - a.rank
            return a.item.name.localeCompare(b.item.name)
        })

        const mapped = results.map(r => r.item)
        if (mapped.length === 0 && rawQ.length > 0) {
            return [{
                id: "action-run-terminal-fallback",
                name: `Run '${rawQ}'`,
                comment: "Execute in terminal",
                glyph: "󰆍",
                type: "action",
                onTriggered: () => Quickshell.execDetached([...terminalCommand, "sh", "-c", `${rawQ}; echo; read -n 1 -s -r -p 'Press any key to close...'`])
            }]
        }

        return mapped
    }

    function closeLauncher() {
        shouldShow = false
        query = ""
        selectedIndex = 0
    }

    function openLauncher() {
        shouldShow = true
        query = ""
        selectedIndex = 0
        searchField.forceActiveFocus()
    }

    function launchEntry(item) {
        if (!item) return

        if (item.type === "action" && typeof item.onTriggered === "function") {
            item.onTriggered()
            closeLauncher()
            return
        }

        const entry = item.entry || item

        if (entry.runInTerminal) {
            Quickshell.execDetached({
                command: [...terminalCommand, ...entry.command],
                workingDirectory: entry.workingDirectory
            })
        } else {
            Quickshell.execDetached({
                command: entry.command,
                workingDirectory: entry.workingDirectory
            })
        }

        closeLauncher()
    }


    onShouldShowChanged: {
        if (shouldShow) {
            selectedIndex = 0
            searchField.forceActiveFocus()
        }
    }

    onVisibleEntriesChanged: {
        if (selectedIndex >= visibleEntries.length) {
            selectedIndex = Math.max(0, visibleEntries.length - 1)
        }
    }

    screen: Quickshell.screens[0]
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"
    visible: shouldShow || panel.opacity > 0

    // Backdrop click-to-dismiss
    MouseArea {
        anchors.fill: parent
        enabled: root.shouldShow
        onClicked: root.closeLauncher()
    }

    FocusScope {
        id: panel
        anchors.centerIn: parent
        width: 640
        height: 520

        scale: shouldShow ? 1.0 : 0.97
        opacity: shouldShow ? 1.0 : 0.0
        focus: root.shouldShow

        transform: Translate {
            y: root.shouldShow ? 0 : -8
            Behavior on y {
                NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
            }
        }

        Behavior on scale {
            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
        }

        Keys.onEscapePressed: root.closeLauncher()
        Keys.onDownPressed: {
            if (root.visibleEntries.length > 0) {
                root.selectedIndex = Math.min(root.selectedIndex + 1, root.visibleEntries.length - 1)
                resultsListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
            }
        }
        Keys.onUpPressed: {
            if (root.visibleEntries.length > 0) {
                root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                resultsListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
            }
        }
        Keys.onReturnPressed: {
            if (root.visibleEntries.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.visibleEntries.length) {
                root.launchEntry(root.visibleEntries[root.selectedIndex])
            }
        }
        Keys.onEnterPressed: {
            if (root.visibleEntries.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.visibleEntries.length) {
                root.launchEntry(root.visibleEntries[root.selectedIndex])
            }
        }

        // Frosted Glass Window Container
        Rectangle {
            id: panelBg
            anchors.fill: parent
            radius: 24
            color: Qt.rgba(root.cSurface.r, root.cSurface.g, root.cSurface.b, 0.68)
            border.width: 1
            border.color: root.cBorder

            // Consume clicks inside window to prevent closing
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                // ==========================================
                // 1. TOP BAR: [App Launcher Icon] + [Search Bar]
                // ==========================================
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // "Application launcher" icon badge (Grid of squares)
                    Rectangle {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        radius: 14
                        color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.15)
                        border.width: 1
                        border.color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.3)

                        Text {
                            anchors.centerIn: parent
                            text: "󰕰" // 3x3 App Grid glyph
                            font.family: "Material Design Icons"
                            font.pixelSize: 24
                            color: root.cPrimary
                        }
                    }

                    // "Search menu" bar
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: 14
                        color: Qt.rgba(root.cSurfaceContainer.r, root.cSurfaceContainer.g, root.cSurfaceContainer.b, 0.75)
                        border.width: 1
                        border.color: searchField.activeFocus
                            ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.45)
                            : Qt.rgba(1, 1, 1, 0.08)

                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            QQC.TextField {
                                id: searchField
                                Layout.fillWidth: true
                                color: root.cText
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: 15
                                placeholderText: "Search applications..."
                                placeholderTextColor: root.cSubText
                                background: Item {}
                                selectByMouse: true

                                onTextChanged: {
                                    root.query = text
                                    root.selectedIndex = 0
                                }

                                Keys.onEscapePressed: root.closeLauncher()
                                Keys.onDownPressed: {
                                    if (root.visibleEntries.length > 0) {
                                        root.selectedIndex = Math.min(root.selectedIndex + 1, root.visibleEntries.length - 1)
                                        resultsListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                    }
                                }
                                Keys.onUpPressed: {
                                    if (root.visibleEntries.length > 0) {
                                        root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                                        resultsListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                    }
                                }
                                Keys.onReturnPressed: {
                                    if (root.visibleEntries.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.visibleEntries.length) {
                                        root.launchEntry(root.visibleEntries[root.selectedIndex])
                                    }
                                }
                                Keys.onEnterPressed: {
                                    if (root.visibleEntries.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.visibleEntries.length) {
                                        root.launchEntry(root.visibleEntries[root.selectedIndex])
                                    }
                                }
                            }

                            // Clear button if searching, or Search Icon
                            Item {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24

                                Text {
                                    anchors.centerIn: parent
                                    visible: searchField.text.length === 0
                                    text: "󰍉" // Search glyph
                                    font.family: "Material Design Icons"
                                    font.pixelSize: 20
                                    color: searchField.activeFocus ? root.cPrimary : root.cSubText
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    visible: searchField.text.length > 0
                                    radius: 12
                                    color: clearHover.hovered ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖" // Close / clear glyph
                                        font.family: "Material Design Icons"
                                        font.pixelSize: 16
                                        color: root.cSubText
                                    }

                                    HoverHandler { id: clearHover }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            searchField.text = ""
                                            searchField.forceActiveFocus()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ==========================================
                // 2. CENTER: "Results" Application List
                // ==========================================
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        id: resultsListView
                        anchors.fill: parent
                        model: root.visibleEntries
                        spacing: 6
                        boundsBehavior: Flickable.StopAtBounds
                        reuseItems: true
                        cacheBuffer: 400

                        QQC.ScrollBar.vertical: QQC.ScrollBar {
                            policy: QQC.ScrollBar.AsNeeded
                            width: 6
                        }

                        delegate: Rectangle {
                            id: resultItem
                            required property var modelData
                            required property int index

                            width: resultsListView.width - (resultsListView.contentHeight > resultsListView.height ? 12 : 0)
                            height: 54
                            radius: 14

                            readonly property bool isSelected: root.selectedIndex === index
                            readonly property bool isHovered: itemHover.hovered

                            color: isSelected
                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.18)
                                : isHovered
                                    ? Qt.rgba(1, 1, 1, 0.07)
                                    : Qt.rgba(1, 1, 1, 0.03)

                            border.width: 1
                            border.color: isSelected
                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.35)
                                : Qt.rgba(1, 1, 1, 0.04)

                            Behavior on color { ColorAnimation { duration: 80 } }
                            Behavior on border.color { ColorAnimation { duration: 80 } }

                            HoverHandler { id: itemHover }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selectedIndex = resultItem.index
                                onClicked: root.launchEntry(resultItem.modelData)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 14
                                spacing: 14

                                // Application Icon
                                Item {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36

                                    Image {
                                        id: appIconImage
                                        anchors.centerIn: parent
                                        width: 32
                                        height: 32
                                        sourceSize.width: 32
                                        sourceSize.height: 32
                                        smooth: true
                                        fillMode: Image.PreserveAspectFit
                                        source: resultItem.modelData.iconPath ?? ""
                                        visible: status === Image.Ready
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 10
                                        color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.12)
                                        visible: !appIconImage.visible

                                        Text {
                                            anchors.centerIn: parent
                                            text: resultItem.modelData.type === "action"
                                                ? (resultItem.modelData.glyph ?? "󰣆")
                                                : (resultItem.modelData.name ?? "?").slice(0, 1).toUpperCase()
                                            font.family: resultItem.modelData.type === "action"
                                                ? "Material Design Icons"
                                                : QsConfig.Config.appearance.fontFamily
                                            font.pixelSize: resultItem.modelData.type === "action" ? 20 : 16
                                            font.weight: Font.Bold
                                            color: root.cPrimary
                                        }
                                    }

                                }

                                // Application Title and Comment / Subtitle
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: resultItem.modelData.name ?? "Application"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                        color: resultItem.isSelected ? root.cPrimary : root.cText
                                        elide: Text.ElideRight
                                        Behavior on color { ColorAnimation { duration: 80 } }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: resultItem.modelData.comment || "Launch application"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 11
                                        color: root.cSubText
                                        elide: Text.ElideRight
                                    }
                                }

                                // Selection arrow indicator
                                Text {
                                    visible: resultItem.isSelected
                                    text: "󰁔" // Chevron Right
                                    font.family: "Material Design Icons"
                                    font.pixelSize: 18
                                    color: root.cPrimary
                                }
                            }
                        }
                    }

                    // Empty State if no match
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: root.visibleEntries.length === 0
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰍉"
                            font.family: "Material Design Icons"
                            font.pixelSize: 36
                            color: Qt.rgba(root.cSubText.r, root.cSubText.g, root.cSubText.b, 0.4)
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No applications found"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 13
                            color: root.cSubText
                        }
                    }
                }

                // Divider line above footer
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Qt.rgba(1, 1, 1, 0.06)
                }

                // ==========================================
                // 3. FOOTER: [Shutdown] [Reboot] [Lock] ... [Open About Menu]
                // ==========================================
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // Button 1: Shutdown
                    Rectangle {
                        id: btnShutdown
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: 19
                        color: hoverShutdown.hovered
                            ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.25)
                            : Qt.rgba(1, 1, 1, 0.05)
                        border.width: 1
                        border.color: hoverShutdown.hovered
                            ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.5)
                            : Qt.rgba(1, 1, 1, 0.08)

                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰐥" // Power off glyph
                            font.family: "Material Design Icons"
                            font.pixelSize: 18
                            color: hoverShutdown.hovered ? "#ef4444" : root.cText
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        HoverHandler { id: hoverShutdown }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.closeLauncher()
                                Quickshell.execDetached(["systemctl", "poweroff"])
                            }
                        }

                        QQC.ToolTip.visible: hoverShutdown.hovered
                        QQC.ToolTip.text: "Shutdown"
                        QQC.ToolTip.delay: 150
                    }

                    // Button 2: Reboot
                    Rectangle {
                        id: btnReboot
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: 19
                        color: hoverReboot.hovered
                            ? Qt.rgba(249 / 255, 115 / 255, 22 / 255, 0.25)
                            : Qt.rgba(1, 1, 1, 0.05)
                        border.width: 1
                        border.color: hoverReboot.hovered
                            ? Qt.rgba(249 / 255, 115 / 255, 22 / 255, 0.5)
                            : Qt.rgba(1, 1, 1, 0.08)

                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰜉" // Reboot / restart glyph
                            font.family: "Material Design Icons"
                            font.pixelSize: 18
                            color: hoverReboot.hovered ? "#f97316" : root.cText
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        HoverHandler { id: hoverReboot }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.closeLauncher()
                                Quickshell.execDetached(["systemctl", "reboot"])
                            }
                        }

                        QQC.ToolTip.visible: hoverReboot.hovered
                        QQC.ToolTip.text: "Reboot"
                        QQC.ToolTip.delay: 150
                    }

                    // Button 3: Lock
                    Rectangle {
                        id: btnLock
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: 19
                        color: hoverLock.hovered
                            ? Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.25)
                            : Qt.rgba(1, 1, 1, 0.05)
                        border.width: 1
                        border.color: hoverLock.hovered
                            ? Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.5)
                            : Qt.rgba(1, 1, 1, 0.08)

                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰌾" // Lock glyph
                            font.family: "Material Design Icons"
                            font.pixelSize: 18
                            color: hoverLock.hovered ? "#38bdf8" : root.cText
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        HoverHandler { id: hoverLock }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.closeLauncher()
                                Quickshell.execDetached([
                                    "dbus-send",
                                    "--system",
                                    "--type=method_call",
                                    "--print-reply",
                                    "--dest=org.freedesktop.DisplayManager",
                                    "/org/freedesktop/DisplayManager/Seat0",
                                    "org.freedesktop.DisplayManager.Seat.SwitchToGreeter"
                                ])
                            }
                        }

                        QQC.ToolTip.visible: hoverLock.hovered
                        QQC.ToolTip.text: "Lock Session"
                        QQC.ToolTip.delay: 150
                    }

                    // Spacer between left buttons and right button
                    Item { Layout.fillWidth: true }

                    // Button 4: Open About Menu (Right side)
                    Rectangle {
                        id: btnAbout
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: 19
                        color: hoverAbout.hovered
                            ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.25)
                            : Qt.rgba(1, 1, 1, 0.05)
                        border.width: 1
                        border.color: hoverAbout.hovered
                            ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.5)
                            : Qt.rgba(1, 1, 1, 0.08)

                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰋽" // Information / About glyph
                            font.family: "Material Design Icons"
                            font.pixelSize: 18
                            color: hoverAbout.hovered ? root.cPrimary : root.cText
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        HoverHandler { id: hoverAbout }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.closeLauncher()
                                Quickshell.execDetached([
                                    "kitty",
                                    "--class", "nixos-about",
                                    "--title", "About This System",
                                    "sh", "-c", "fastfetch; echo; read -n 1 -s -r -p '  Press any key to close...'"
                                ])
                            }
                        }

                        QQC.ToolTip.visible: hoverAbout.hovered
                        QQC.ToolTip.text: "About This System"
                        QQC.ToolTip.delay: 150
                    }
                }
            }
        }
    }
}