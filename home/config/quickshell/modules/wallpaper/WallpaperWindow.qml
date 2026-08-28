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
    property string selectedScreen: "all" // "all" or specific monitor name like "DP-1"
    property var wallpapers: []
    property string wallpaperDir: Quickshell.env("HOME") + "/wallpaper"

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property color cSurface: pywal.surface
    readonly property color cSurfaceContainer: pywal.surfaceContainer
    readonly property color cSurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted
    readonly property color cBorder: Qt.rgba(1, 1, 1, 0.08)

    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            if (root.shouldShow) {
                root.closeMenu()
            } else {
                root.openMenu()
            }
        }

        function open(): void {
            root.openMenu()
        }

        function close(): void {
            root.closeMenu()
        }
    }

    // Process to scan wallpapers directory
    Process {
        id: scanProc
        command: [
            "find",
            root.wallpaperDir,
            "-maxdepth", "2",
            "-type", "f",
            "(",
            "-iname", "*.jpg",
            "-o", "-iname", "*.jpeg",
            "-o", "-iname", "*.png",
            "-o", "-iname", "*.webp",
            "-o", "-iname", "*.gif",
            ")"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                const items = []
                for (let i = 0; i < lines.length; ++i) {
                    const fullPath = lines[i]
                    const filename = fullPath.substring(fullPath.lastIndexOf("/") + 1)
                    items.push({
                        path: fullPath,
                        filename: filename,
                        lowerName: filename.toLowerCase()
                    })
                }
                items.sort((a, b) => a.filename.localeCompare(b.filename))
                root.wallpapers = items
            }
        }
    }

    function reloadWallpapers() {
        scanProc.running = true
    }

    function openMenu() {
        shouldShow = true
        searchField.text = ""
        query = ""
        selectedIndex = 0
        reloadWallpapers()
        searchField.forceActiveFocus()
    }

    function closeMenu() {
        shouldShow = false
        searchField.text = ""
        query = ""
        selectedIndex = 0
    }

    readonly property var filteredWallpapers: {
        const q = query.trim().toLowerCase()
        if (q === "") return wallpapers

        return wallpapers.filter(w => w.lowerName.includes(q))
    }

    function applyWallpaper(item) {
        if (!item || !item.path) return

        const scriptPath = Quickshell.env("HOME") + "/.dotfiles/home/config/scripts/wallpaper-picker.sh"
        Quickshell.execDetached([scriptPath, "--set", item.path, root.selectedScreen])
        root.closeMenu()
    }

    function applyRandom() {
        const scriptPath = Quickshell.env("HOME") + "/.dotfiles/home/config/scripts/wallpaper-picker.sh"
        Quickshell.execDetached([scriptPath, "--random", root.selectedScreen])
        root.closeMenu()
    }

    function openFolder() {
        Quickshell.execDetached(["thunar", root.wallpaperDir])
        root.closeMenu()
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
        onClicked: root.closeMenu()
    }

    FocusScope {
        id: panel
        anchors.centerIn: parent
        width: 760
        height: 560

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

        Keys.onEscapePressed: root.closeMenu()

        Keys.onLeftPressed: {
            if (root.filteredWallpapers.length > 0) {
                root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                grid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
            }
        }
        Keys.onRightPressed: {
            if (root.filteredWallpapers.length > 0) {
                root.selectedIndex = Math.min(root.filteredWallpapers.length - 1, root.selectedIndex + 1)
                grid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
            }
        }
        Keys.onUpPressed: {
            if (root.filteredWallpapers.length > 0) {
                root.selectedIndex = Math.max(0, root.selectedIndex - 3)
                grid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
            }
        }
        Keys.onDownPressed: {
            if (root.filteredWallpapers.length > 0) {
                root.selectedIndex = Math.min(root.filteredWallpapers.length - 1, root.selectedIndex + 3)
                grid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
            }
        }
        Keys.onReturnPressed: {
            if (root.filteredWallpapers.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredWallpapers.length) {
                root.applyWallpaper(root.filteredWallpapers[root.selectedIndex])
            }
        }
        Keys.onEnterPressed: {
            if (root.filteredWallpapers.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredWallpapers.length) {
                root.applyWallpaper(root.filteredWallpapers[root.selectedIndex])
            }
        }

        // Frosted Glass Window Container
        Rectangle {
            id: panelBg
            anchors.fill: parent
            radius: 24
            color: Qt.rgba(root.cSurface.r, root.cSurface.g, root.cSurface.b, 0.72)
            border.width: 1
            border.color: root.cBorder

            // Consume clicks inside window
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                // ==========================================
                // 1. TOP BAR: [Wallpaper Icon] + [Search Bar]
                // ==========================================
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        radius: 14
                        color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.15)
                        border.width: 1
                        border.color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.3)

                        Text {
                            anchors.centerIn: parent
                            text: "󰸉" // Wallpaper picture glyph
                            font.family: "Material Design Icons"
                            font.pixelSize: 24
                            color: root.cPrimary
                        }
                    }

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
                                placeholderText: "Search wallpapers..."
                                placeholderTextColor: root.cSubText
                                background: Item {}
                                selectByMouse: true

                                onTextChanged: {
                                    root.query = text
                                    root.selectedIndex = 0
                                }

                                Keys.onEscapePressed: root.closeMenu()
                                Keys.onLeftPressed: panel.Keys.onLeftPressed(event)
                                Keys.onRightPressed: panel.Keys.onRightPressed(event)
                                Keys.onUpPressed: panel.Keys.onUpPressed(event)
                                Keys.onDownPressed: panel.Keys.onDownPressed(event)
                                Keys.onReturnPressed: panel.Keys.onReturnPressed(event)
                                Keys.onEnterPressed: panel.Keys.onEnterPressed(event)
                            }

                            Item {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24

                                Text {
                                    anchors.centerIn: parent
                                    visible: searchField.text.length === 0
                                    text: "󰍉"
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
                                        text: "󰅖"
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
                // 2. CONTROLS: Screen Selector Pills + Actions
                // ==========================================
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Screen selection label
                    Text {
                        text: "Screen:"
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: root.cSubText
                    }

                    // "All Displays" Pill
                    Rectangle {
                        Layout.preferredHeight: 32
                        Layout.preferredWidth: allText.implicitWidth + 24
                        radius: 16
                        readonly property bool isCurrent: root.selectedScreen === "all"
                        color: isCurrent
                            ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.22)
                            : allHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: isCurrent
                            ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.4)
                            : Qt.rgba(1, 1, 1, 0.06)

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            id: allText
                            anchors.centerIn: parent
                            text: "🖥️ All Displays"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 12
                            color: parent.isCurrent ? root.cPrimary : root.cText
                        }

                        HoverHandler { id: allHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedScreen = "all"
                        }
                    }

                    // Individual Screen Pills
                    Repeater {
                        model: Quickshell.screens

                        delegate: Rectangle {
                            required property var modelData
                            Layout.preferredHeight: 32
                            Layout.preferredWidth: scrText.implicitWidth + 24
                            radius: 16
                            readonly property bool isCurrent: root.selectedScreen === modelData.name
                            color: isCurrent
                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.22)
                                : scrHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                            border.width: 1
                            border.color: isCurrent
                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.4)
                                : Qt.rgba(1, 1, 1, 0.06)

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                id: scrText
                                anchors.centerIn: parent
                                text: "🖥️ " + modelData.name
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: 12
                                color: parent.isCurrent ? root.cPrimary : root.cText
                            }

                            HoverHandler { id: scrHover }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedScreen = modelData.name
                            }
                        }
                    }

                    Item { Layout.fillWidth: true } // Spacer

                    // Random Wallpaper Button
                    Rectangle {
                        Layout.preferredHeight: 32
                        Layout.preferredWidth: randText.implicitWidth + 24
                        radius: 16
                        color: randHover.hovered
                            ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.25)
                            : Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.14)
                        border.width: 1
                        border.color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.3)

                        Text {
                            id: randText
                            anchors.centerIn: parent
                            text: "🎲 Random"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: root.cPrimary
                        }

                        HoverHandler { id: randHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.applyRandom()
                        }
                    }

                    // Open Folder Button
                    Rectangle {
                        Layout.preferredHeight: 32
                        Layout.preferredWidth: folderText.implicitWidth + 20
                        radius: 16
                        color: folderHover.hovered ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            id: folderText
                            anchors.centerIn: parent
                            text: "📂 Folder"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 12
                            color: root.cSubText
                        }

                        HoverHandler { id: folderHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openFolder()
                        }
                    }
                }

                // ==========================================
                // 3. WALLPAPER GRID
                // ==========================================
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    GridView {
                        id: grid
                        anchors.fill: parent
                        cellWidth: parent.width / 3
                        cellHeight: 140
                        model: root.filteredWallpapers
                        boundsBehavior: Flickable.StopAtBounds
                        cacheBuffer: 600

                        QQC.ScrollBar.vertical: QQC.ScrollBar {
                            policy: QQC.ScrollBar.AsNeeded
                            width: 6
                        }

                        delegate: Item {
                            id: delegateItem
                            required property var modelData
                            required property int index

                            width: grid.cellWidth
                            height: grid.cellHeight

                            readonly property bool isSelected: root.selectedIndex === index
                            readonly property bool isHovered: cardHover.hovered

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 6
                                radius: 14
                                color: Qt.rgba(root.cSurfaceContainer.r, root.cSurfaceContainer.g, root.cSurfaceContainer.b, 0.6)
                                border.width: delegateItem.isSelected ? 2 : 1
                                border.color: delegateItem.isSelected
                                    ? root.cPrimary
                                    : delegateItem.isHovered
                                        ? Qt.rgba(1, 1, 1, 0.2)
                                        : Qt.rgba(1, 1, 1, 0.06)

                                scale: delegateItem.isHovered || delegateItem.isSelected ? 1.02 : 1.0
                                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                                Behavior on border.color { ColorAnimation { duration: 100 } }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 13
                                    clip: true
                                    color: "transparent"

                                    Image {
                                        anchors.fill: parent
                                        source: "file://" + modelData.path
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        sourceSize.width: 320
                                        sourceSize.height: 180
                                    }

                                    // Gradient overlay for text readability
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 36
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: "transparent" }
                                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.8) }
                                        }
                                    }

                                    // Filename label
                                    Text {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.margins: 8
                                        text: modelData.filename
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                        elide: Text.ElideMiddle
                                    }
                                }

                                HoverHandler { id: cardHover }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedIndex = index
                                        root.applyWallpaper(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // Empty state when no wallpapers found
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: root.filteredWallpapers.length === 0
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰸉"
                            font.family: "Material Design Icons"
                            font.pixelSize: 42
                            color: root.cSubText
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.wallpapers.length === 0
                                ? "No wallpapers found in ~/wallpaper"
                                : "No matching wallpapers"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 14
                            color: root.cSubText
                        }
                    }
                }
            }
        }
    }
}
