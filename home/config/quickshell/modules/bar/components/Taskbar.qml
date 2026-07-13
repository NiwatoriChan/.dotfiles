import Quickshell
import Quickshell.Hyprland
import QtQuick 6.10
import QtQuick.Layouts 6.10

Item {
    id: root

    readonly property var toplevels: {
        const list = []
        for (const tl of Hyprland.toplevels.values)
            list.push(tl)
        return list
    }

    implicitWidth: taskbarRow.implicitWidth + 8
    implicitHeight: 28
    visible: toplevels.length > 0

    RowLayout {
        id: taskbarRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: root.toplevels

            delegate: Rectangle {
                required property var modelData
                readonly property bool isActive: Hyprland.activeToplevel?.handle === modelData.handle

                Layout.preferredHeight: 24
                Layout.preferredWidth: Math.max(24, taskIcon.width + 16)
                radius: 6
                color: isActive
                    ? Qt.rgba(1, 1, 1, 0.15)
                    : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : "transparent")
                border.width: isActive ? 1 : 0
                border.color: Qt.rgba(1, 1, 1, 0.1)

                Text {
                    id: taskIcon
                    anchors.centerIn: parent
                    text: modelData.title?.charAt(0)?.toUpperCase() ?? "?"
                    color: "#f1f5f9"
                    font.family: "Inter Variable"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.activate()
                }
            }
        }
    }
}
