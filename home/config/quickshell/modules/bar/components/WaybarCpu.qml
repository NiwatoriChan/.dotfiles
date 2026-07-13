import QtQuick 6.10
import "../../../services" as QsServices

Item {
    id: root

    readonly property var system: QsServices.SystemUsage

    implicitWidth: cpuText.implicitWidth + 24
    implicitHeight: 28

    Text {
        id: cpuText
        anchors.centerIn: parent
        text: "\uf2db   " + Math.round(system.cpuPerc * 100) + "%"
        color: "#fda4af"
        font.family: "Inter Variable"
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }
}
