import QtQuick 6.10
import Quickshell
import "../../../services" as QsServices

Item {
    id: root

    implicitWidth: clockText.implicitWidth + 24
    implicitHeight: 28

    Rectangle {
        id: bgHover
        anchors.fill: parent
        anchors.margins: 2
        radius: 6
        color: clockMouse.containsMouse ? Qt.rgba(192 / 255, 132 / 255, 252 / 255, 0.15) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        text: "\uf017   " + QsServices.Time.format("dd-MM-yyyy   HH:mm")
        color: clockMouse.containsMouse ? "#d8b4fe" : "#c084fc"
        font.family: "Inter Variable"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached(["quickshell", "ipc", "call", "dashboard", "toggle"])
        }
    }
}


