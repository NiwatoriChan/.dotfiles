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
    property bool currentWorkspaceOnly: false

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
                root.selectNext()
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

        function next(): void {
            if (!root.shouldShow) {
                root.openSwitcher()
            } else {
                root.selectNext()
            }
        }

        function prev(): void {
            if (!root.shouldShow) {
                root.openSwitcher()
                if (root.visibleWindows.length > 1) {
                    root.selectedIndex = root.visibleWindows.length - 1
                }
            } else {
                root.selectPrev()
            }
        }

        function release(): void {
            if (root.shouldShow) {
                root.confirmAndSwitch()
            }
        }
    }

    // User home path for local icon discovery
    readonly property string userHome: Quickshell.env("HOME") || "/home/niwatorichan"

    // Window validity filter — strips Wine / Proton dummy handles, unmapped surfaces & zero-sized helpers
    function isValidWindow(tl) {
        if (!tl) return false

        // 1. Child / Popup / Subsurface check
        if (tl.wayland?.parent) return false

        // 2. Hyprland metadata checks via lastIpcObject
        if (tl.lastIpcObject) {
            const ipc = tl.lastIpcObject
            // Skip unmapped windows
            if (ipc.mapped === false) return false
            // Skip hidden windows
            if (ipc.hidden === true) return false
            // Skip dummy / zero-sized windows (Wine & XWayland helpers are typically 0x0 or 1x1)
            if (ipc.size && (ipc.size[0] <= 1 || ipc.size[1] <= 1)) return false
        }

        // 3. Extract titles and classes
        const title = (tl.title || tl.wayland?.title || tl.lastIpcObject?.title || "").trim()
        const initialTitle = (tl.lastIpcObject?.initialTitle || "").trim()
        const appClass = (tl.wayland?.appId || tl.lastIpcObject?.class || "").trim()
        const initialClass = (tl.lastIpcObject?.initialClass || "").trim()

        // 4. Must have at least a meaningful title or class
        if (!title && !appClass) return false
        if (!title && (/^(xwayland|xwaylandvideobridge)$/i.test(appClass) || appClass.length === 0)) return false

        // 5. Filter Wine / Proton / DirectX / System dummy helper window titles
        const wineDummyTitlePatterns = [
            /^Default IME$/i,
            /^MSCTFIME UI$/i,
            /^OleMainThreadWndName$/i,
            /^Wine System Tray$/i,
            /^Direct3D/i,
            /^IDirect3D/i,
            /^D3D/i,
            /^Wine Gecko Installer$/i,
            /^Wine Mono Installer$/i,
            /^Desktop$/i,
            /^about:blank/i,
            /^Steam Keyboard$/i
        ]

        for (let i = 0; i < wineDummyTitlePatterns.length; ++i) {
            const pat = wineDummyTitlePatterns[i]
            if (pat.test(title)) return false
            if (initialTitle && pat.test(initialTitle)) return false
        }

        // 6. Filter Wine helper daemons & background service classes
        const wineDummyClassPatterns = [
            /^wineboot\.exe$/i,
            /^services\.exe$/i,
            /^winedevice\.exe$/i,
            /^plugplay\.exe$/i,
            /^tabtip\.exe$/i,
            /^conhost\.exe$/i,
            /^xwaylandvideobridge$/i
        ]

        for (let j = 0; j < wineDummyClassPatterns.length; ++j) {
            const pat = wineDummyClassPatterns[j]
            if (pat.test(appClass)) return false
            if (initialClass && pat.test(initialClass)) return false
        }

        // Wine explorer.exe is only a tray/desktop dummy in Wine prefixes
        if (/^explorer\.exe$/i.test(appClass)) {
            if (!title || /^(wine system tray|desktop|explorer\.exe)$/i.test(title)) {
                return false
            }
        }

        return true
    }

    // Icon resolution helper with deep Steam, Wine, DesktopEntries, and fallback integration
    readonly property var iconCache: ({})
    function resolveIcon(appId, title) {
        if (!appId && !title) return ""
        const key = `${appId || ""}|${title || ""}`
        if (root.iconCache[key] !== undefined) return root.iconCache[key]

        let resolved = ""
        const candidates = []

        // 1. Direct custom/local overrides map
        const directMap = {
            "antigravity": `${root.userHome}/.local/share/icons/antigravity.png`,
            "antigravity-ide": `${root.userHome}/.local/share/icons/antigravity.png`,
            "syncplay": `${root.userHome}/.local/share/icons/syncplay.png`
        }

        const cleanApp = (appId || "").trim()
        const lowerApp = cleanApp.toLowerCase()

        if (directMap[lowerApp]) {
            resolved = directMap[lowerApp]
        }

        // 2. Steam App ID mapping: steam_app_<id> -> steam_icon_<id>
        if (!resolved && cleanApp.startsWith("steam_app_")) {
            const steamId = cleanApp.replace("steam_app_", "")
            candidates.push(`steam_icon_${steamId}`)
            candidates.push(`${root.userHome}/.local/share/icons/hicolor/64x64/apps/steam_icon_${steamId}.png`)
            candidates.push(`${root.userHome}/.local/share/icons/hicolor/128x128/apps/steam_icon_${steamId}.png`)
            candidates.push(`${root.userHome}/.local/share/icons/candy-icons/apps/scalable/steam_icon_${steamId}.svg`)
        }

        // 3. Clean Windows .exe suffixes (e.g. "Game.exe" -> "Game")
        const noExe = cleanApp.replace(/\.exe$/i, "")
        if (noExe && noExe !== cleanApp) {
            candidates.push(noExe)
            candidates.push(noExe.toLowerCase())
        }

        // 4. Reverse-DNS IDs (e.g. com.github.flxzt.rnote -> rnote)
        if (cleanApp.includes(".")) {
            const parts = cleanApp.split(".")
            const last = parts[parts.length - 1]
            if (last && last.length > 1) {
                candidates.push(last)
                candidates.push(last.toLowerCase())
            }
        }

        // 5. Common app suffixes (e.g. antigravity-ide -> antigravity)
        if (cleanApp.includes("-")) {
            candidates.push(cleanApp.replace(/-ide$/i, ""))
            candidates.push(cleanApp.replace(/-desktop$/i, ""))
            candidates.push(cleanApp.replace(/-browser$/i, ""))
            candidates.push(cleanApp.replace(/-client$/i, ""))
            candidates.push(cleanApp.split("-")[0])
        }

        // 6. Base candidates
        if (cleanApp) {
            candidates.push(cleanApp)
            candidates.push(lowerApp)
        }

        // 7. Cross-reference with DesktopEntries via C++ heuristic lookup
        try {
            const de = DesktopEntries.heuristicLookup(noExe || cleanApp) || DesktopEntries.byId(cleanApp)
            if (de && de.icon) {
                if (de.icon.startsWith("/") || de.icon.startsWith("file://")) {
                    candidates.unshift(de.icon)
                } else {
                    candidates.push(de.icon)
                    candidates.push(de.icon.toLowerCase())
                }
            }
        } catch (e) {}

        // 8. Title-based hints (e.g. "Track Parcel — Mozilla Firefox", "Videos - Thunar")
        if (title) {
            const cleanTitle = title.toLowerCase()
            if (cleanTitle.includes("firefox")) candidates.push("firefox")
            else if (cleanTitle.includes("antigravity")) candidates.push("antigravity")
            else if (cleanTitle.includes("thunar")) candidates.push("thunar")
            else if (cleanTitle.includes("steam")) candidates.push("steam")
            else if (cleanTitle.includes("discord")) candidates.push("discord")
            else if (cleanTitle.includes("rnote")) candidates.push("rnote")
            else if (cleanTitle.includes("kitty")) candidates.push("kitty")
            else if (cleanTitle.includes("obsidian")) candidates.push("obsidian")
        }

        // 9. Gaming / Wine fallbacks
        if (cleanApp.startsWith("steam_app_") || cleanApp.endsWith(".exe") || /^[Gg]amescope$/i.test(cleanApp)) {
            candidates.push("steam")
            candidates.push("applications-games")
            candidates.push("input-gaming")
        }

        // Try resolving each candidate
        for (let j = 0; j < candidates.length; ++j) {
            const cand = candidates[j]
            if (!cand) continue

            // Direct path
            if (cand.startsWith("/") || cand.startsWith("file://")) {
                resolved = cand
                break
            }

            // Quickshell iconPath lookup
            const p = Quickshell.iconPath(cand, true)
            if (p) {
                resolved = p
                break
            }

            if (directMap[cand]) {
                resolved = directMap[cand]
                break
            }
        }

        root.iconCache[key] = resolved || ""
        return root.iconCache[key]
    }

    // Context-aware fallback icon information when no image icon is available
    function getFallbackData(appId, title) {
        const cleanApp = (appId || "").toLowerCase()
        const cleanTitle = (title || "").toLowerCase()

        // 1. Gaming
        if (cleanApp.startsWith("steam_app_") || cleanApp.endsWith(".exe") || cleanApp.includes("lutris") || cleanApp.includes("heroic") || cleanApp.includes("game")) {
            return { icon: "󰊴", isMdi: true } // Gamepad
        }

        // 2. Terminal
        if (cleanApp.includes("kitty") || cleanApp.includes("terminal") || cleanApp.includes("alacritty") || cleanApp.includes("foot") || cleanTitle === "zsh" || cleanTitle === "bash") {
            return { icon: "󰞷", isMdi: true } // Console
        }

        // 3. Web Browser
        if (cleanApp.includes("firefox") || cleanApp.includes("chrome") || cleanApp.includes("brave") || cleanTitle.includes("firefox")) {
            return { icon: "󰈹", isMdi: true } // Browser
        }

        // 4. Code / Text Editor
        if (cleanApp.includes("antigravity") || cleanApp.includes("code") || cleanApp.includes("zed") || cleanApp.includes("editor")) {
            return { icon: "󰨞", isMdi: true } // Code
        }

        // 5. File Manager
        if (cleanApp.includes("thunar") || cleanApp.includes("dolphin") || cleanApp.includes("nautilus") || cleanApp.includes("files")) {
            return { icon: "󰉋", isMdi: true } // Folder
        }

        // 6. Media / Music / Video
        if (cleanApp.includes("mpv") || cleanApp.includes("vlc") || cleanApp.includes("spotify")) {
            return { icon: "󰕼", isMdi: true } // Media
        }

        // Default clean alphanumeric letter (strip leading punctuation like '.', '/', etc.)
        const stripped = (title || appId || "App").replace(/^[^a-zA-Z0-9]+/, "")
        const letter = stripped.length > 0 ? stripped.charAt(0).toUpperCase() : "󰣆"
        return { icon: letter, isMdi: false }
    }

    // MRU window ranking calculation
    function computeWindowRank(addr, focusHistoryID, isActive) {
        if (isActive) return 0
        const mruIdx = QsServices.Hypr.getMruIndex(addr)
        if (mruIdx >= 0) {
            return mruIdx
        }
        if (typeof focusHistoryID === "number" && focusHistoryID >= 0) {
            return focusHistoryID + 50
        }
        return 9999
    }

    // Dynamic windows list in true MRU order
    readonly property var allWindows: {
        if (!root.shouldShow) return []
        const raw = Hyprland.toplevels?.values ?? []
        const list = []
        const activeHandle = Hyprland.activeToplevel?.handle

        for (let i = 0; i < raw.length; ++i) {
            const tl = raw[i]
            if (!isValidWindow(tl)) continue

            let appId = tl.wayland?.appId || ""
            if (!appId && tl.lastIpcObject) {
                appId = tl.lastIpcObject.class || tl.lastIpcObject.initialClass || ""
            }

            const title = tl.title || appId || "Untitled Window"

            let wsId = 1
            if (tl.lastIpcObject?.workspace?.id !== undefined) {
                wsId = tl.lastIpcObject.workspace.id
            } else if (tl.workspace && typeof tl.workspace.id === "number" && tl.workspace.id > 0) {
                wsId = tl.workspace.id
            } else if (tl.workspace?.name) {
                wsId = parseInt(tl.workspace.name) || 1
            } else if (tl.lastIpcObject?.workspace?.name) {
                wsId = parseInt(tl.lastIpcObject.workspace.name) || 1
            }

            let wsName = `${wsId}`
            if (tl.lastIpcObject?.workspace?.name) {
                wsName = tl.lastIpcObject.workspace.name
            } else if (tl.workspace?.name) {
                wsName = tl.workspace.name
            }

            let monitorName = ""
            if (tl.workspace?.monitor?.name) {
                monitorName = tl.workspace.monitor.name
            } else if (tl.lastIpcObject?.monitor !== undefined) {
                const monId = tl.lastIpcObject.monitor
                monitorName = monId === 0 ? "DP-1" : (monId === 1 ? "HDMI-A-1" : `${monId}`)
            }

            const isActive = tl.handle === activeHandle
            const iconPath = root.resolveIcon(appId, title)
            const fallback = root.getFallbackData(appId, title)

            let focusHistoryID = 9999
            if (tl.lastIpcObject && typeof tl.lastIpcObject.focusHistoryID === "number") {
                focusHistoryID = tl.lastIpcObject.focusHistoryID
            }

            let rawAddr = (tl.address || tl.lastIpcObject?.address || "").trim()
            while (rawAddr.startsWith("0x0x")) rawAddr = rawAddr.substring(2)
            if (!rawAddr.startsWith("0x") && rawAddr.length > 0) rawAddr = "0x" + rawAddr
            rawAddr = rawAddr.toLowerCase()

            const rank = root.computeWindowRank(rawAddr, focusHistoryID, isActive)

            list.push({
                toplevel: tl,
                title: title,
                appId: appId,
                wsId: wsId,
                wsName: wsName,
                monitorName: monitorName,
                isActive: isActive,
                iconPath: iconPath,
                fallbackIcon: fallback.icon,
                fallbackIsMdi: fallback.isMdi,
                address: rawAddr,
                lowerTitle: title.toLowerCase(),
                lowerAppId: appId.toLowerCase(),
                rank: rank,
                focusHistoryID: focusHistoryID
            })
        }

        // Sort by MRU rank ascending, tie-breaking by wsId
        list.sort((a, b) => {
            if (a.rank !== b.rank) {
                return a.rank - b.rank
            }
            return a.wsId - b.wsId
        })

        return list
    }

    // Filtered windows
    readonly property var visibleWindows: {
        let base = allWindows
        if (currentWorkspaceOnly) {
            const curWs = QsServices.Hypr.activeWsId
            base = base.filter(w => w.wsId === curWs)
        }

        const q = query.trim().toLowerCase()
        if (!q.length) return base

        return base.filter(w => {
            return w.lowerTitle.includes(q) || w.lowerAppId.includes(q) || `${w.wsId}` === q
        })
    }

    function openSwitcher() {
        Hyprland.refreshToplevels()
        Hyprland.refreshWorkspaces()
        root.query = ""
        root.shouldShow = true
        // Default to the 2nd window (latest seen window before the current one)
        root.selectedIndex = (root.visibleWindows.length > 1) ? 1 : 0
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
        Quickshell.execDetached(["hyprctl", "dispatch", "submap", "reset"])
    }

    function confirmAndSwitch() {
        if (!root.shouldShow) return
        if (visibleWindows.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < visibleWindows.length) {
            root.activateWindow(visibleWindows[root.selectedIndex])
        } else {
            root.closeSwitcher()
        }
    }

    function activateWindow(item) {
        if (!item) return
        closeSwitcher()

        let addr = (item.address || "").trim()
        while (addr.startsWith("0x0x")) addr = addr.substring(2)
        if (!addr.startsWith("0x") && addr.length > 0) addr = "0x" + addr

        // 1. Switch workspace (switches monitor and active workspace in Hyprland)
        if (item.wsId && item.wsId > 0) {
            QsServices.Hypr.dispatch("workspace " + item.wsId)
        } else if (item.toplevel?.workspace) {
            if (typeof item.toplevel.workspace.activate === "function") {
                item.toplevel.workspace.activate()
            } else if (item.toplevel.workspace.id) {
                QsServices.Hypr.dispatch("workspace " + item.toplevel.workspace.id)
            }
        }

        // 2. Focus window by clean address (essential for XWayland like Steam & games)
        if (addr) {
            QsServices.Hypr.dispatch("focuswindow address:" + addr)
        }

        // 3. Complementary focus call
        const tl = item.toplevel
        if (tl) {
            if (typeof tl.focus === "function") {
                try { tl.focus() } catch (e) {}
            } else if (typeof tl.activate === "function") {
                try { tl.activate() } catch (e) {}
            }
        }
    }

    function closeWindow(item) {
        if (!item) return
        let addr = (item.address || "").trim()
        while (addr.startsWith("0x0x")) addr = addr.substring(2)
        if (!addr.startsWith("0x") && addr.length > 0) addr = "0x" + addr

        if (item.toplevel && typeof item.toplevel.close === "function") {
            try { item.toplevel.close() } catch (e) {}
        } else if (addr) {
            Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "address:" + addr])
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
        Keys.onRightPressed: (event) => {
            event.accepted = true
            root.selectNext()
        }
        Keys.onLeftPressed: (event) => {
            event.accepted = true
            root.selectPrev()
        }
        Keys.onReturnPressed: (event) => {
            event.accepted = true
            root.confirmAndSwitch()
        }
        Keys.onDeletePressed: (event) => {
            event.accepted = true
            if (visibleWindows.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < visibleWindows.length) {
                root.closeWindow(visibleWindows[root.selectedIndex])
            }
        }
        Keys.onReleased: (event) => {
            if (!root.shouldShow) return
            const k = event.key
            if (k === Qt.Key_Alt || k === Qt.Key_Meta ||
                k === Qt.Key_Super_L || k === Qt.Key_Super_R) {
                event.accepted = true
                root.confirmAndSwitch()
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
                                    root.confirmAndSwitch()
                                }
                                Keys.onReleased: (event) => {
                                    if (!root.shouldShow) return
                                    const k = event.key
                                    if (k === Qt.Key_Alt || k === Qt.Key_Meta ||
                                        k === Qt.Key_Super_L || k === Qt.Key_Super_R) {
                                        event.accepted = true
                                        root.confirmAndSwitch()
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

                    // Workspace Filter Pill
                    Rectangle {
                        Layout.preferredHeight: 48
                        implicitWidth: wsFilterText.implicitWidth + 28
                        radius: 14
                        color: root.currentWorkspaceOnly ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.18) : root.cSurfaceContainer
                        border.width: 1
                        border.color: root.currentWorkspaceOnly ? root.cPrimary : root.cBorder

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentWorkspaceOnly = !root.currentWorkspaceOnly
                                root.selectedIndex = 0
                            }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: root.currentWorkspaceOnly ? "󰍹" : "󰍺"
                                font.family: "Material Design Icons"
                                font.pixelSize: 14
                                color: root.currentWorkspaceOnly ? root.cPrimary : root.cSubText
                            }

                            Text {
                                id: wsFilterText
                                text: root.currentWorkspaceOnly ? `WS ${QsServices.Hypr.activeWsId}` : "All Desktops"
                                font.family: "Inter Variable"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: root.currentWorkspaceOnly ? root.cPrimary : root.cSubText
                            }
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
                                    text: cardRoot.modelData.fallbackIcon ?? "󰣆"
                                    font.family: cardRoot.modelData.fallbackIsMdi ? "Material Design Icons" : "Inter Variable"
                                    font.pixelSize: cardRoot.modelData.fallbackIsMdi ? 18 : 16
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
                                        text: cardRoot.modelData.monitorName ? `${cardRoot.modelData.monitorName} : WS ${cardRoot.modelData.wsName}` : `WS ${cardRoot.modelData.wsName}`
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
