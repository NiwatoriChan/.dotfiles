import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../services" as QsServices

Item {
    id: root

    property var screen

    readonly property string userHome: Quickshell.env("HOME") || "/home/niwatorichan"
    readonly property var iconCache: ({})

    function isValidTask(tl) {
        if (!tl) return false;

        // 1. If it has a wayland parent, it's a child / popup / dialog surface, not a main toplevel
        if (tl.wayland?.parent) return false;

        // 2. Inspect lastIpcObject if available (Hyprland window metadata)
        if (tl.lastIpcObject) {
            const ipc = tl.lastIpcObject;
            // Filter unmapped or hidden windows
            if (ipc.mapped === false) return false;
            if (ipc.hidden === true) return false;

            // Filter dummy / zero-sized windows (e.g. 0x0 or 1x1 helper windows)
            if (ipc.size && (ipc.size[0] <= 1 || ipc.size[1] <= 1)) return false;
        }

        // 3. Extract titles and classes
        const title = (tl.title || tl.wayland?.title || tl.lastIpcObject?.title || "").trim();
        const initialTitle = (tl.lastIpcObject?.initialTitle || "").trim();
        const appClass = (tl.wayland?.appId || tl.lastIpcObject?.class || "").trim();
        const initialClass = (tl.lastIpcObject?.initialClass || "").trim();

        // 4. Must have at least a meaningful title or class
        if (!title && !appClass) return false;
        if (!title && (/^(xwayland|xwaylandvideobridge)$/i.test(appClass) || appClass.length === 0)) return false;

        // 5. Ignore Wine / Proton / DirectX / XWayland dummy & helper windows
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
        ];

        for (let i = 0; i < wineDummyTitlePatterns.length; ++i) {
            const pat = wineDummyTitlePatterns[i];
            if (pat.test(title)) return false;
            if (initialTitle && pat.test(initialTitle)) return false;
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
        ];

        for (let j = 0; j < wineDummyClassPatterns.length; ++j) {
            const pat = wineDummyClassPatterns[j];
            if (pat.test(appClass)) return false;
            if (initialClass && pat.test(initialClass)) return false;
        }

        if (/^explorer\.exe$/i.test(appClass)) {
            if (!title || /^(wine system tray|desktop|explorer\.exe)$/i.test(title)) {
                return false;
            }
        }

        return true;
    }

    function resolveTaskIcon(tl) {
        if (!tl) return "";
        let appId = tl.wayland?.appId || "";
        if (!appId && tl.lastIpcObject) {
            appId = tl.lastIpcObject.class || tl.lastIpcObject.initialClass || "";
        }
        const title = (tl.title || tl.wayland?.title || tl.lastIpcObject?.title || "").trim();
        if (!appId && !title) return "";

        const key = `${appId}|${title}`;
        if (root.iconCache[key] !== undefined) return root.iconCache[key];

        let resolved = "";
        const candidates = [];

        const directMap = {
            "antigravity": `${root.userHome}/.local/share/icons/antigravity.png`,
            "antigravity-ide": `${root.userHome}/.local/share/icons/antigravity.png`,
            "syncplay": `${root.userHome}/.local/share/icons/syncplay.png`
        };

        const cleanApp = appId.trim();
        const lowerApp = cleanApp.toLowerCase();

        if (directMap[lowerApp]) {
            resolved = directMap[lowerApp];
        }

        // Steam app mapping
        if (!resolved && cleanApp.startsWith("steam_app_")) {
            const steamId = cleanApp.replace("steam_app_", "");
            candidates.push(`steam_icon_${steamId}`);
            candidates.push(`${root.userHome}/.local/share/icons/hicolor/64x64/apps/steam_icon_${steamId}.png`);
            candidates.push(`${root.userHome}/.local/share/icons/hicolor/128x128/apps/steam_icon_${steamId}.png`);
            candidates.push(`${root.userHome}/.local/share/icons/candy-icons/apps/scalable/steam_icon_${steamId}.svg`);
        }

        // Clean .exe
        const noExe = cleanApp.replace(/\.exe$/i, "");
        if (noExe && noExe !== cleanApp) {
            candidates.push(noExe);
            candidates.push(noExe.toLowerCase());
        }

        // Reverse-DNS
        if (cleanApp.includes(".")) {
            const parts = cleanApp.split(".");
            const last = parts[parts.length - 1];
            if (last && last.length > 1) {
                candidates.push(last);
                candidates.push(last.toLowerCase());
            }
        }

        // Hyphenated
        if (cleanApp.includes("-")) {
            candidates.push(cleanApp.replace(/-ide$/i, ""));
            candidates.push(cleanApp.replace(/-desktop$/i, ""));
            candidates.push(cleanApp.replace(/-browser$/i, ""));
            candidates.push(cleanApp.replace(/-client$/i, ""));
            candidates.push(cleanApp.split("-")[0]);
        }

        if (cleanApp) {
            candidates.push(cleanApp);
            candidates.push(lowerApp);
        }

        // DesktopEntries
        if (DesktopEntries?.applications?.values) {
            const apps = DesktopEntries.applications.values;
            const targetClean = noExe.toLowerCase();
            const targetTitle = title.toLowerCase();

            for (let i = 0; i < apps.length; ++i) {
                const entry = apps[i];
                if (!entry) continue;

                const entryId = (entry.id || "").toLowerCase();
                const entryName = (entry.name || "").toLowerCase();
                const entryWm = (entry.startupWmClass || "").toLowerCase();

                let match = false;
                if (cleanApp && (entryId === `${lowerApp}.desktop` || entryId === `${targetClean}.desktop`)) match = true;
                else if (cleanApp && entryWm && (entryWm === lowerApp || entryWm === targetClean)) match = true;
                else if (targetClean && entryName === targetClean) match = true;
                else if (targetTitle && (entryName === targetTitle || (targetTitle.length > 3 && targetTitle.includes(entryName)))) match = true;

                if (match && entry.icon) {
                    if (entry.icon.startsWith("/") || entry.icon.startsWith("file://")) {
                        candidates.unshift(entry.icon);
                    } else {
                        candidates.push(entry.icon);
                        candidates.push(entry.icon.toLowerCase());
                    }
                    break;
                }
            }
        }

        // Title hints
        if (title) {
            const cleanTitle = title.toLowerCase();
            if (cleanTitle.includes("firefox")) candidates.push("firefox");
            else if (cleanTitle.includes("antigravity")) candidates.push("antigravity");
            else if (cleanTitle.includes("thunar")) candidates.push("thunar");
            else if (cleanTitle.includes("steam")) candidates.push("steam");
            else if (cleanTitle.includes("discord")) candidates.push("discord");
            else if (cleanTitle.includes("rnote")) candidates.push("rnote");
            else if (cleanTitle.includes("kitty")) candidates.push("kitty");
            else if (cleanTitle.includes("obsidian")) candidates.push("obsidian");
        }

        // Gaming / Wine fallbacks
        if (cleanApp.startsWith("steam_app_") || cleanApp.endsWith(".exe") || /^[Gg]amescope$/i.test(cleanApp)) {
            candidates.push("steam");
            candidates.push("applications-games");
            candidates.push("input-gaming");
        }

        for (let j = 0; j < candidates.length; ++j) {
            const cand = candidates[j];
            if (!cand) continue;

            if (cand.startsWith("/") || cand.startsWith("file://")) {
                resolved = cand;
                break;
            }

            const p = Quickshell.iconPath(cand, true);
            if (p) {
                resolved = p;
                break;
            }

            if (directMap[cand]) {
                resolved = directMap[cand];
                break;
            }
        }

        root.iconCache[key] = resolved || "";
        return root.iconCache[key];
    }

    function getFallbackData(tl) {
        if (!tl) return { icon: "?", isMdi: false };
        let appId = tl.wayland?.appId || "";
        if (!appId && tl.lastIpcObject) {
            appId = tl.lastIpcObject.class || tl.lastIpcObject.initialClass || "";
        }
        const title = (tl.title || tl.wayland?.title || tl.lastIpcObject?.title || "").trim();

        const cleanApp = appId.toLowerCase();
        const cleanTitle = title.toLowerCase();

        if (cleanApp.startsWith("steam_app_") || cleanApp.endsWith(".exe") || cleanApp.includes("lutris") || cleanApp.includes("heroic") || cleanApp.includes("game")) {
            return { icon: "󰊴", isMdi: true };
        }
        if (cleanApp.includes("kitty") || cleanApp.includes("terminal") || cleanApp.includes("alacritty") || cleanApp.includes("foot") || cleanTitle === "zsh" || cleanTitle === "bash") {
            return { icon: "󰞷", isMdi: true };
        }
        if (cleanApp.includes("firefox") || cleanApp.includes("chrome") || cleanApp.includes("brave") || cleanTitle.includes("firefox")) {
            return { icon: "󰈹", isMdi: true };
        }
        if (cleanApp.includes("antigravity") || cleanApp.includes("code") || cleanApp.includes("zed") || cleanApp.includes("editor")) {
            return { icon: "󰨞", isMdi: true };
        }
        if (cleanApp.includes("thunar") || cleanApp.includes("dolphin") || cleanApp.includes("nautilus") || cleanApp.includes("files")) {
            return { icon: "󰉋", isMdi: true };
        }
        if (cleanApp.includes("mpv") || cleanApp.includes("vlc") || cleanApp.includes("spotify")) {
            return { icon: "󰕼", isMdi: true };
        }

        const stripped = (title || appId || "?").replace(/^[^a-zA-Z0-9]+/, "");
        const letter = stripped.length > 0 ? stripped.charAt(0).toUpperCase() : "?";
        return { icon: letter, isMdi: false };
    }

    function taskMatchesScreen(tl) {
        if (!root.screen) return true
        const screenName = root.screen.name
        if (!screenName) return true

        let wsId = 0
        if (tl.lastIpcObject?.workspace?.id !== undefined) {
            wsId = tl.lastIpcObject.workspace.id
        } else if (tl.workspace?.id && tl.workspace.id > 0) {
            wsId = tl.workspace.id
        } else if (tl.workspace?.name) {
            wsId = parseInt(tl.workspace.name) || 0
        }

        let monName = tl.workspace?.monitor?.name || ""
        if (!monName && tl.lastIpcObject?.monitor !== undefined) {
            const monId = tl.lastIpcObject.monitor
            monName = monId === 0 ? "DP-1" : (monId === 1 ? "HDMI-A-1" : `${monId}`)
        }

        if (monName) {
            return monName === screenName
        }

        if (screenName === "DP-1") {
            return wsId >= 1 && wsId <= 10
        } else if (screenName === "HDMI-A-1") {
            return wsId === 11 || wsId > 10
        }

        return true
    }

    readonly property var toplevels: {
        const list = []
        for (const tl of Hyprland.toplevels.values) {
            if (isValidTask(tl) && taskMatchesScreen(tl))
                list.push(tl)
        }
        return list
    }

    implicitWidth: taskbarRow.implicitWidth + 8
    implicitHeight: 28
    visible: toplevels.length > 0
    clip: true

    RowLayout {
        id: taskbarRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: root.toplevels

            delegate: Rectangle {
                id: delegateRoot
                required property var modelData
                readonly property bool isActive: Hyprland.activeToplevel?.handle === modelData.handle

                Layout.preferredHeight: 24
                Layout.preferredWidth: appIcon.visible ? 24 : Math.max(24, taskTextFallback.width + 16)
                radius: 6
                color: isActive
                    ? Qt.rgba(1, 1, 1, 0.15)
                    : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : "transparent")
                border.width: isActive ? 1 : 0
                border.color: Qt.rgba(1, 1, 1, 0.1)

                readonly property var fallbackInfo: root.getFallbackData(modelData)

                Image {
                    id: appIcon
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    sourceSize.width: 32
                    sourceSize.height: 32
                    smooth: true
                    fillMode: Image.PreserveAspectFit
                    source: root.resolveTaskIcon(modelData)
                    visible: status === Image.Ready
                }

                Text {
                    id: taskTextFallback
                    anchors.centerIn: parent
                    text: delegateRoot.fallbackInfo.icon
                    font.family: delegateRoot.fallbackInfo.isMdi ? "Material Design Icons" : "Inter Variable"
                    font.pixelSize: delegateRoot.fallbackInfo.isMdi ? 14 : 11
                    font.weight: Font.Bold
                    color: "#f1f5f9"
                    visible: !appIcon.visible
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const wsId = modelData.workspace ? (modelData.workspace.id > 0 ? modelData.workspace.id : (parseInt(modelData.workspace.name) || 0)) : 0;
                        if (wsId > 0) {
                            QsServices.Hypr.dispatch("workspace " + wsId);
                        } else if (modelData.workspace && typeof modelData.workspace.activate === "function") {
                            modelData.workspace.activate();
                        }

                        let addr = (modelData.address || modelData.lastIpcObject?.address || "").trim();
                        while (addr.startsWith("0x0x")) addr = addr.substring(2);
                        if (!addr.startsWith("0x") && addr.length > 0) addr = "0x" + addr;
                        if (addr) {
                            QsServices.Hypr.dispatch("focuswindow address:" + addr);
                        }

                        if (typeof modelData.focus === "function") {
                            try { modelData.focus(); } catch (e) {}
                        } else if (typeof modelData.activate === "function") {
                            try { modelData.activate(); } catch (e) {}
                        }
                    }
                }
            }
        }
    }
}
