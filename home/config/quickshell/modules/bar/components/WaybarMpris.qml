import Quickshell
import Quickshell.Io
import QtQuick 6.10
import qs.services

Item {
    id: root

    readonly property var player: Players.active
    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: player?.isPlaying ?? false

    implicitWidth: hasPlayer ? mprisText.implicitWidth + 24 : 0
    implicitHeight: 28
    visible: hasPlayer

    Text {
        id: mprisText
        anchors.centerIn: parent
        text: {
            const icon = root.isPlaying ? "\uf04b" : "\uf04c"
            const artist = root.player?.artist ?? ""
            const title = root.player?.title ?? ""
            const label = `${artist} - ${title}`.trim()
            const full = `${icon}   ${label}`
            return full.length > 35 ? full.substring(0, 32) + "..." : full
        }
        color: "#a78bfa"
        font.family: "Inter Variable"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        font.italic: !root.isPlaying
    }
}
