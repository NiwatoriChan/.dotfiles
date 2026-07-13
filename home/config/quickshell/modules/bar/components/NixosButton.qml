import Quickshell
import QtQuick 6.10

Item {
    id: root

    implicitWidth: nixosText.implicitWidth + 20
    implicitHeight: 28

    Text {
        id: nixosText
        anchors.centerIn: parent
        text: "\uf313"
        font.family: "Font Awesome 6 Free"
        font.pixelSize: 18
        font.weight: Font.Bold
        color: mouseArea.containsMouse ? "#a8d4f2" : "#7ebae4"
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached([
            "/home/niwatorichan/.config/waybar/scripts/power-menu.sh"
        ])
    }
}
