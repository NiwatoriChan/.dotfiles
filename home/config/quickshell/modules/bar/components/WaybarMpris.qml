import Quickshell
import Quickshell.Io
import QtQuick 6.10
import qs.services

Item {
    id: root

    readonly property var player: Players.active
    readonly property bool isPlaying: player !== null && player.isPlaying

    implicitWidth: player !== null ? mprisText.implicitWidth + 24 : 0
    implicitHeight: 28
    visible: player !== null

    Text {
        id: mprisText
        anchors.centerIn: parent
        text: {
            const icon = root.isPlaying ? "\uf04b" : "\uf04c"
            const artist = root.player?.trackArtist ?? ""
            const title = root.player?.trackTitle ?? ""
            const label = artist ? `${artist} - ${title}` : title
            const full = `${icon}   ${label}`.trim()
            return full.length > 35 ? full.substring(0, 32) + "..." : full
        }
        color: "#a78bfa"
        font.family: "Inter Variable"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        font.italic: !root.isPlaying
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Players.togglePlaying(root.player?.desktopEntry ?? "")
        }
    }
}
