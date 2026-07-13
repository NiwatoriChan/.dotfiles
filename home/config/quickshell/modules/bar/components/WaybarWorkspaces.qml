import Quickshell
import Quickshell.Hyprland
import QtQuick 6.10
import QtQuick.Layouts 6.10

Item {
    id: root

    property var screen

    readonly property var workspaces: {
        const list = []
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id > 0)
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
                    onClicked: Hyprland.dispatch("workspace " + modelData.id)
                    onEntered: if (!isActive) wsButton.color = "#ffffff"
                    onExited: if (!isActive && !isUrgent) wsButton.color = Qt.rgba(1, 1, 1, 0.4)
                }
            }
        }
    }

    WheelHandler {
        onWheel: event => {
            if (event.angleDelta.y > 0) {
                Hyprland.dispatch("workspace e+1")
            } else {
                Hyprland.dispatch("workspace e-1")
            }
        }
    }
}
