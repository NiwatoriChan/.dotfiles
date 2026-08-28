import Quickshell
import Quickshell.Hyprland
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../services" as QsServices

Item {
    id: root

    property var screen

    function workspaceMatchesScreen(ws) {
        if (!root.screen) return true
        const screenName = root.screen.name
        if (!screenName) return true

        const wsMon = ws.monitor?.name ?? ws.lastIpcObject?.monitor
        if (wsMon) {
            return wsMon === screenName
        }

        if (screenName === "DP-1") {
            return ws.id >= 1 && ws.id <= 10
        } else if (screenName === "HDMI-A-1") {
            return ws.id === 11 || ws.id > 10
        }

        return true
    }

    readonly property var workspaces: {
        const list = []
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id > 0 && workspaceMatchesScreen(ws))
                list.push(ws)
        }
        list.sort((a, b) => a.id - b.id)
        return list
    }

    implicitWidth: workspaceRow.implicitWidth + 8
    implicitHeight: 28

    Row {
        id: workspaceRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Repeater {
            model: root.workspaces

            delegate: Item {
                id: wsItem
                required property var modelData
                readonly property bool isActive: Hyprland.focusedWorkspace?.id === modelData.id
                readonly property bool isUrgent: modelData.urgent ?? false

                implicitWidth: wsButton.implicitWidth + 20
                implicitHeight: 28

                Text {
                    id: wsButton
                    anchors.centerIn: parent
                    text: modelData.name ?? String(modelData.id)
                    color: {
                        if (isUrgent) return "#ff5555"
                        if (isActive) return "#ffffff"
                        return Qt.rgba(1, 1, 1, 0.4)
                    }
                    font.family: "Inter Variable"
                    font.pixelSize: 13
                    font.weight: isActive || isUrgent ? Font.Bold : Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof modelData.activate === "function") {
                            modelData.activate();
                        } else {
                            QsServices.Hypr.dispatch("workspace " + modelData.id);
                        }
                    }
                    onEntered: if (!isActive) wsButton.color = "#ffffff"
                    onExited: if (!isActive && !isUrgent) wsButton.color = Qt.rgba(1, 1, 1, 0.4)
                }
            }
        }
    }

    WheelHandler {
        onWheel: event => {
            const list = root.workspaces
            if (list.length === 0) return

            const currentFocused = Hyprland.focusedWorkspace?.id ?? 1
            let currentIndex = list.findIndex(ws => ws.id === currentFocused)
            if (currentIndex === -1) currentIndex = 0

            let nextIndex = 0
            if (event.angleDelta.y > 0) {
                nextIndex = (currentIndex + 1) % list.length
            } else {
                nextIndex = (currentIndex - 1 + list.length) % list.length
            }

            const targetWs = list[nextIndex]
            if (targetWs) {
                if (typeof targetWs.activate === "function") {
                    targetWs.activate()
                } else {
                    QsServices.Hypr.dispatch("workspace " + targetWs.id)
                }
            }
        }
    }
}

