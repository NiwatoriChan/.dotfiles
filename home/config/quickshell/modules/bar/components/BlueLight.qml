import Quickshell
import Quickshell.Io
import QtQuick 6.10

Item {
    id: root

    property bool active: false

    implicitWidth: iconText.implicitWidth + 24
    implicitHeight: 28

    Process {
        id: statusProc
        command: ["/home/niwatorichan/.config/waybar/scripts/wlsunset.sh", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.active = text.includes('"class": "on"')
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }

    Text {
        id: iconText
        anchors.centerIn: parent
        text: root.active ? "\uf186" : "\uf185"
        font.family: "Font Awesome 6 Free"
        font.pixelSize: 13
        font.weight: Font.Bold
        color: root.active ? "#fdba74" : "#f1f5f9"
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached([
            "/home/niwatorichan/.config/waybar/scripts/wlsunset.sh",
            "toggle"
        ])
    }
}
