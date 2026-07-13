//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded

import Quickshell
import QtQuick 6.10
import "services" as QsServices

ShellRoot {
    id: root

    readonly property var audio: QsServices.Audio
    readonly property var brightness: QsServices.Brightness
    readonly property var pywal: QsServices.Pywal

    Loader {
        id: barLoader
        source: "modules/bar/BarWrapper.qml"
    }

    Loader {
        id: osdLoader
        source: "modules/osd/Wrapper.qml"
        onStatusChanged: {
            if (status === Loader.Ready) {
                osdLoader.item.pywal = QsServices.Pywal
            }
        }
    }

    Component.onCompleted: {
        QsServices.Logger.info("Shell", "Waybar-style quickshell loaded")
    }
}
