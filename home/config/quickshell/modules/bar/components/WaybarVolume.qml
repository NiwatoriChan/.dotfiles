import Quickshell
import QtQuick 6.10
import "../../../services" as QsServices

Item {
    id: root

    readonly property var audio: QsServices.Audio
    readonly property bool isMuted: audio.muted
    readonly property int percentage: audio.percentage

    implicitWidth: volumeText.implicitWidth + 24
    implicitHeight: 28

    Text {
        id: volumeText
        anchors.centerIn: parent
        text: isMuted ? "\uf669   Muted" : "\uf028   " + percentage + "%"
        color: "#fde047"
        font.family: "Inter Variable"
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["pwvucontrol"])
    }
}
