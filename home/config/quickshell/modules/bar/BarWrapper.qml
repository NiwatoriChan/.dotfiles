import Quickshell
import Quickshell.Wayland
import QtQuick 6.10
import "../../config" as QsConfig

Scope {
    readonly property var config: QsConfig.Config

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            property var modelData

            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }

            exclusiveZone: config.bar.height
            implicitHeight: config.bar.height + (barLoader.item?.popupAreaHeight ?? 0)
            color: "transparent"

            WlrLayershell.keyboardFocus: (barLoader.item?.hasPopup ?? false)
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None

            Loader {
                id: barLoader
                anchors.fill: parent
                source: "Bar.qml"

                onStatusChanged: {
                    if (status === Loader.Ready) {
                        item.screen = Qt.binding(() => modelData)
                        item.barWindow = Qt.binding(() => window)
                    }
                }
            }
        }
    }
}
