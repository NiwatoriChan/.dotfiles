import QtQuick 6.10
import "../../../services" as QsServices

Item {
    id: root

    readonly property var system: QsServices.SystemUsage

    implicitWidth: memText.implicitWidth + 24
    implicitHeight: 28

    Text {
        id: memText
        anchors.centerIn: parent
        text: "\uf538   " + Math.round(system.memPerc * 100) + "%"
        color: "#93c5fd"
        font.family: "Inter Variable"
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }
}
