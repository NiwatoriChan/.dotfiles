import QtQuick 6.10
import "../../../services" as QsServices

Item {
    id: root

    readonly property var system: QsServices.SystemUsage

    implicitWidth: memRow.implicitWidth + 24
    implicitHeight: 28

    Row {
        id: memRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "\uefc5"
            color: "#93c5fd"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: Math.round(system.memPerc * 100) + "%"
            color: "#93c5fd"
            font.family: "Inter Variable"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
