import Quickshell
import Quickshell.Hyprland
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../services" as QsServices

Item {
    id: root

    property var screen

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

            // Filter windows with no title and no class
            const hasTitle = ipc.title && ipc.title.trim().length > 0;
            const hasClass = ipc.class && ipc.class.trim().length > 0;
            if (!hasTitle && !hasClass) return false;
        }

        // 3. Filter empty titles and classes
        const title = (tl.title || tl.wayland?.title || tl.lastIpcObject?.title || "").trim();
        const appClass = (tl.wayland?.appId || tl.lastIpcObject?.class || tl.lastIpcObject?.initialClass || "").trim();
        if (!title && !appClass) return false;

        // 4. Ignore Wine / Proton / DirectX / XWayland dummy & helper windows
        const ignoredPattern = /^(Default IME|MSCTFIME UI|OleMainThreadWndName|Direct3D.*|IDirect3D.*|D3D.*|Wine|about:blank.*)$/i;
        if (ignoredPattern.test(title)) return false;
        if (ignoredPattern.test(appClass)) return false;

        return true;
    }

    function taskMatchesScreen(tl) {
        if (!root.screen) return true
        const screenName = root.screen.name
        if (!screenName) return true

        const ws = tl.workspace
        const wsMon = ws?.monitor?.name ?? ws?.lastIpcObject?.monitor ?? tl.lastIpcObject?.monitor
        if (wsMon) {
            return wsMon === screenName
        }

        const wsId = ws ? (ws.id > 0 ? ws.id : (parseInt(ws.name) || 0)) : 0
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

                Image {
                    id: appIcon
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    sourceSize.width: 32
                    sourceSize.height: 32
                    smooth: true
                    fillMode: Image.PreserveAspectFit
                    source: {
                        let appId = modelData.wayland?.appId;
                        if (!appId && modelData.lastIpcObject) {
                            appId = modelData.lastIpcObject.class || modelData.lastIpcObject.initialClass;
                        }
                        if (!appId) return "";
                        
                        let path = Quickshell.iconPath(appId, true);
                        if (!path) path = Quickshell.iconPath(appId.toLowerCase(), true);
                        
                        if (!path && appId.includes(".")) {
                            let parts = appId.split(".");
                            let lastPart = parts[parts.length - 1];
                            path = Quickshell.iconPath(lastPart, true);
                            if (!path) path = Quickshell.iconPath(lastPart.toLowerCase(), true);
                        }
                        return path;
                    }
                    visible: status === Image.Ready
                }

                Text {
                    id: taskTextFallback
                    anchors.centerIn: parent
                    text: modelData.title?.charAt(0)?.toUpperCase() ?? "?"
                    color: "#f1f5f9"
                    font.family: "Inter Variable"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    visible: !appIcon.visible
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.workspace) {
                            if (typeof modelData.workspace.activate === "function") {
                                modelData.workspace.activate();
                            } else {
                                const wsId = modelData.workspace.id > 0 ? modelData.workspace.id : (parseInt(modelData.workspace.name) || 0);
                                QsServices.Hypr.dispatch("workspace " + (wsId > 0 ? wsId : modelData.workspace.name));
                            }
                        }
                        if (typeof modelData.focus === "function") {
                            modelData.focus();
                        } else if (typeof modelData.activate === "function") {
                            modelData.activate();
                        } else if (modelData.address) {
                            QsServices.Hypr.dispatch("focuswindow address:" + modelData.address);
                        }
                    }
                }
            }
        }
    }
}
