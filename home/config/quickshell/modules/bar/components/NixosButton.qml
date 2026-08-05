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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["kitty"])
            } else {
                Quickshell.execDetached([
                    "/home/niwatorichan/.config/waybar/scripts/power-menu.sh"
                ])
            }
        }
    }
}
