import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components/effects"

PanelWindow {
    id: root

    property bool shouldShow: false
    property string query: ""
    property int selectedIndex: 0

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal

    // Color tokens
    readonly property color cSurface: pywal.surfaceContainerLowest || "#121316"
    readonly property color cSurfaceContainer: pywal.surfaceContainer || "#1c1d22"
    readonly property color cSurfaceContainerHigh: pywal.surfaceContainerHigh || "#26272e"
    readonly property color cPrimary: pywal.primary || "#a8c7fa"
    readonly property color cOnPrimary: pywal.onPrimary || "#003062"
    readonly property color cText: pywal.foreground || "#e3e2e6"
    readonly property color cSubText: pywal.onSurfaceMuted || "#8e9199"
    readonly property color cBorder: Qt.rgba(1, 1, 1, 0.08)
    readonly property color cActiveHighlight: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.18)

    screen: Quickshell.screens[0]
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    implicitWidth: screen.width
    implicitHeight: screen.height
    color: "transparent"
    visible: shouldShow || panelWrapper.opacity > 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "switcher"

        function toggle(): void {
            if (root.shouldShow) {
                root.closeSwitcher()
            } else {
                root.openSwitcher()
            }
        }

        function open(): void {
            root.openSwitcher()
        }

        function close(): void {
            root.closeSwitcher()
        }
    }

    // Icon resolution helper
    readonly property var iconCache: ({})
    function resolveIcon(appId, title) {
        if (!appId && !title) return ""
        const key = `${appId || ""}|${title || ""}`
        if (root.iconCache[key] !== undefined) return root.iconCache[key]

        let path = ""
        if (appId) {
            path = Quickshell.iconPath(appId, true)
            if (!path) path = Quickshell.iconPath(appId.toLowerCase(), true)
            if (!path && appId.includes(".")) {
                const parts = appId.split(".")
                const lastPart = parts[parts.length - 1]
                path = Quickshell.iconPath(lastPart, true) || Quickshell.iconPath(lastPart.toLowerCase(), true)
            }
        }
        if (!path && title) {
            path = Quickshell.iconPath(title.toLowerCase(), true)
        }

        root.iconCache[key] = path || ""
        return root.iconCache[key]
    }

    // Dynamic windows list
    readonly property var allWindows: {
        const raw = Hyprland.toplevels?.values ?? []
        const list = []
        const activeHandle = Hyprland.activeToplevel?.handle

        for (let i = 0; i < raw.length; ++i) {
            const tl = raw[i]
            if (!tl) continue

            let appId = tl.wayland?.appId || ""
            if (!appId && tl.lastIpcObject) {
                appId = tl.lastIpcObject.class || tl.lastIpcObject.initialClass || ""
            }

            const title = tl.title || appId || "Untitled Window"
            const ws = tl.workspace
            const wsId = ws?.id ?? 1
            const wsName = ws?.name ?? `${wsId}`
            const monitorName = ws?.monitor?.name ?? ws?.lastIpcObject?.monitor ?? tl.lastIpcObject?.monitor ?? ""
            const isActive = tl.handle === activeHandle
            const iconPath = root.resolveIcon(appId, title)

            list.push({
                toplevel: tl,
                title: title,
                appId: appId,
                wsId: wsId,
                wsName: wsName,
                monitorName: monitorName,
                isActive: isActive,
                iconPath: iconPath,
                address: tl.address || (tl.lastIpcObject?.address ? `0x${tl.lastIpcObject.address}` : ""),
                lowerTitle: title.toLowerCase(),
                lowerAppId: appId.toLowerCase()
            })
        }

        // Put active window at index 0 or sort naturally
        list.sort((a, b) => {
            if (a.isActive) return -1
            if (b.isActive) return 1
            return a.wsId - b.wsId
        })

        return list
    }

    // Filtered windows
    readonly property var visibleWindows: {
        const q = query.trim().toLowerCase()
        if (!q.length) return allWindows

        return allWindows.filter(w => {
            return w.lowerTitle.includes(q) || w.lowerAppId.includes(q) || `${w.wsId}` === q
        })
    }

    function openSwitcher() {
        root.query = ""
        root.shouldShow = true
        // Default to the 2nd window (previous window) if available, standard Alt-Tab behavior
        root.selectedIndex = (allWindows.length > 1) ? 1 : 0
        Qt.callLater(() => {
            searchField.forceActiveFocus()
            if (windowListView && root.selectedIndex >= 0) {
                windowListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
            }
        })
    }

    function closeSwitcher() {
        root.shouldShow = false
        root.query = ""
    }

    function activateWindow(item) {
        if (!item) return
        closeSwitcher()

        const tl = item.toplevel
        if (!tl) return

        if (tl.workspace) {
            if (typeof tl.workspace.activate === "function") {
                tl.workspace.activate()
            } else {
                QsServices.Hypr.dispatch("workspace " + tl.workspace.id)
            }
        }

        if (typeof tl.focus === "function") {
            tl.focus()
        } else if (typeof tl.activate === "function") {
            tl.activate()
        } else if (item.address) {
            QsServices.Hypr.dispatch("focuswindow address:" + item.address)
        }
    }

    function closeWindow(item) {
        if (!item) return
        if (item.toplevel && typeof item.toplevel.close === "function") {
            item.toplevel.close()
        } else if (item.address) {
            Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "address:" + item.address])
        }
    }

    function selectNext() {
        const count = visibleWindows.length
        if (count === 0) return
        root.selectedIndex = (root.selectedIndex + 1) % count
        windowListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    }

    function selectPrev() {
        const count = visibleWindows.length
        if (count === 0) return
        root.selectedIndex = (root.selectedIndex - 1 + count) % count
        windowListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    }

    // Scrim / Background dim
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        opacity: root.shouldShow ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeSwitcher()
        }
    }

    // Modal Card
    FocusScope {
        id: panelWrapper
        anchors.centerIn: parent
        width: Math.min(680, root.screen.width - 48)
        height: Math.min(560, root.screen.height - 96)

        scale: root.shouldShow ? 1.0 : 0.94
        opacity: root.shouldShow ? 1.0 : 0.0
        transformOrigin: Item.Center

        Behavior on scale {
            NumberAnimation { duration: 250; easing.bezierCurve: Material3Anim.springBounce }
        }
        Behavior on opacity {
            NumberAnimation { duration: 180; easing.bezierCurve: Material3Anim.standard }
        }

        Keys.onEscapePressed: root.closeSwitcher()
        Keys.onTabPressed: (event) => {
            event.accepted = true
            if (event.modifiers & Qt.ShiftModifier) {
                root.selectPrev()
            } else {
                root.selectNext()
            }
        }
        Keys.onBacktabPressed: (event) => {
            event.accepted = true
            root.selectPrev()
        }
        Keys.onDownPressed: (event) => {
            event.accepted = true
            root.selectNext()
        }
        Keys.onUpPressed: (event) => {
            event.accepted = true
            root.selectPrev()
        }
        Keys.onReturnPressed: (event) => {
            event.accepted = true
            if (visibleWindows.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < visibleWindows.length) {
                root.activateWindow(visibleWindows[root.selectedIndex])
            }
        }
        Keys.onDeletePressed: (event) => {
            event.accepted = true
            if (visibleWindows.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < visibleWindows.length) {
                root.closeWindow(visibleWindows[root.selectedIndex])
            }
        }

        Rectangle {
            id: panelBody
            anchors.fill: parent
            radius: 24
            color: root.cSurface
            border.width: 1
            border.color: root.cBorder
            clip: true

            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => mouse.accepted = true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // Header & Search Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: 14
                        color: root.cSurfaceContainer
                        border.width: searchField.activeFocus ? 1.5 : 1
                        border.color: searchField.activeFocus ? root.cPrimary : root.cBorder

                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            Text {
                                text: "󰍉"
                                font.family: "Material Design Icons"
                                font.pixelSize: 20
                                color: searchField.activeFocus ? root.cPrimary : root.cSubText
                            }

                            QQC.TextField {
                                id: searchField
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                placeholderText: "Search open windows or workspaces..."
                                placeholderTextColor: root.cSubText
                                color: root.cText
                                font.family: "Inter Variable"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                background: Item {}
                                text: root.query
                                onTextChanged: {
                                    root.query = text
                                    root.selectedIndex = 0
                                }

                                Keys.onEscapePressed: root.closeSwitcher()
                                Keys.onTabPressed: (event) => {
                                    event.accepted = true
                                    if (event.modifiers & Qt.ShiftModifier) {
                                        root.selectPrev()
                                    } else {
                                        root.selectNext()
                                    }
                                }
                                Keys.onBacktabPressed: (event) => {
                                    event.accepted = true
                                    root.selectPrev()
                                }
                                Keys.onDownPressed: (event) => {
                                    event.accepted = true
                                    root.selectNext()
                                }
                                Keys.onUpPressed: (event) => {
                                    event.accepted = true
                                    root.selectPrev()
                                }
                                Keys.onReturnPressed: (event) => {
                                    event.accepted = true
                                    if (visibleWindows.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < visibleWindows.length) {
                                        root.activateWindow(visibleWindows[root.selectedIndex])
                                    }
                                }
                            }

                            Rectangle {
                                visible: root.query.length > 0
                                width: 24
                                height: 24
                                radius: 12
                                color: clearMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    font.family: "Material Design Icons"
                                    font.pixelSize: 14
                                    color: root.cSubText
                                }

                                MouseArea {
                                    id: clearMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        searchField.text = ""
                                        root.query = ""
                                    }
                                }
                            }
                        }
                    }

                    // Window count badge
                    Rectangle {
                        Layout.preferredHeight: 48
                        implicitWidth: countText.implicitWidth + 24
                        radius: 14
                        color: root.cSurfaceContainer
                        border.width: 1
                        border.color: root.cBorder

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: `${root.visibleWindows.length} / ${root.allWindows.length}`
                            font.family: "Inter Variable"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: root.cSubText
                        }
                    }
                }

                // Window Cards List
                ListView {
                    id: windowListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: root.visibleWindows
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: cardRoot
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: index === root.selectedIndex
                        readonly property bool isHovered: itemMouse.containsMouse

                        Layout.fillWidth: true
                        width: windowListView.width
                        height: 56
                        radius: 12

                        color: isSelected
                            ? root.cActiveHighlight
                            : (isHovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent")

                        border.width: isSelected ? 1.5 : 0
                        border.color: isSelected ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.45) : "transparent"

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activateWindow(cardRoot.modelData)
                            onEntered: root.selectedIndex = cardRoot.index
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // App Icon
                            Rectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                radius: 8
                                color: cardRoot.isSelected ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.15) : root.cSurfaceContainer

                                Image {
                                    id: itemIcon
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    sourceSize.width: 44
                                    sourceSize.height: 44
                                    smooth: true
                                    fillMode: Image.PreserveAspectFit
                                    source: cardRoot.modelData.iconPath || ""
                                    visible: status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: cardRoot.modelData.title?.charAt(0)?.toUpperCase() ?? "󰣆"
                                    font.family: "Inter Variable"
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    color: cardRoot.isSelected ? root.cPrimary : root.cSubText
                                    visible: !itemIcon.visible
                                }
                            }

                            // Window Details
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: cardRoot.modelData.title
                                    font.family: "Inter Variable"
                                    font.pixelSize: 13
                                    font.weight: cardRoot.isSelected ? Font.Bold : Font.Medium
                                    color: cardRoot.isSelected ? root.cPrimary : root.cText
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: cardRoot.modelData.appId || "Application"
                                    font.family: "Inter Variable"
                                    font.pixelSize: 11
                                    color: root.cSubText
                                    elide: Text.ElideRight
                                }
                            }

                            // Workspace & Monitor Badge
                            Rectangle {
                                Layout.preferredHeight: 24
                                implicitWidth: wsBadgeText.implicitWidth + 16
                                radius: 6
                                color: cardRoot.isSelected ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.2) : root.cSurfaceContainer

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: "󰍹"
                                        font.family: "Material Design Icons"
                                        font.pixelSize: 12
                                        color: cardRoot.isSelected ? root.cPrimary : root.cSubText
                                    }

                                    Text {
                                        id: wsBadgeText
                                        text: cardRoot.modelData.monitorName ? `${cardRoot.modelData.monitorName}:${cardRoot.modelData.wsName}` : `WS ${cardRoot.modelData.wsName}`
                                        font.family: "Inter Variable"
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: cardRoot.isSelected ? root.cPrimary : root.cSubText
                                    }
                                }
                            }

                            // Active Tag
                            Rectangle {
                                visible: cardRoot.modelData.isActive
                                Layout.preferredHeight: 24
                                implicitWidth: activeTagText.implicitWidth + 14
                                radius: 6
                                color: Qt.rgba(pywal.success.r, pywal.success.g, pywal.success.b, 0.2)

                                Text {
                                    id: activeTagText
                                    anchors.centerIn: parent
                                    text: "Active"
                                    font.family: "Inter Variable"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: pywal.success
                                }
                            }

                            // Close Window Button
                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 6
                                color: closeBtnMouse.containsMouse ? Qt.rgba(pywal.error.r, pywal.error.g, pywal.error.b, 0.25) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    font.family: "Material Design Icons"
                                    font.pixelSize: 14
                                    color: closeBtnMouse.containsMouse ? pywal.error : root.cSubText
                                }

                                MouseArea {
                                    id: closeBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.closeWindow(cardRoot.modelData)
                                }
                            }
                        }
                    }
                }

                // Empty state if no windows match search
                Item {
                    visible: root.visibleWindows.length === 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰈔"
                            font.family: "Material Design Icons"
                            font.pixelSize: 36
                            color: root.cSubText
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No open windows found"
                            font.family: "Inter Variable"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: root.cSubText
                        }
                    }
                }

                // Footer Keyboard Hints
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "󰌌  Tab / ↑↓ Navigate   •   Enter Focus   •   Del Close   •   Esc Dismiss"
                        font.family: "Inter Variable"
                        font.pixelSize: 11
                        color: root.cSubText
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
