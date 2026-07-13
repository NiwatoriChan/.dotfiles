import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root

    readonly property bool hasItems: SystemTray.items.length > 0

    implicitWidth: hasItems ? trayRow.implicitWidth + 12 : 0
    implicitHeight: 28
    visible: hasItems

    RowLayout {
        id: trayRow
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: SystemTray.items

            delegate: Item {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16

                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: {
                        const icon = modelData.icon ?? ""
                        if (typeof icon === "string" && icon.includes("?path=")) {
                            const parts = icon.split("?path=")
                            const name = parts[0]
                            const base = parts[1] ?? ""
                            const fileName = name.slice(name.lastIndexOf("/") + 1)
                            return Qt.resolvedUrl(`${base}/${fileName}`)
                        }
                        return icon
                    }
                    visible: status === Image.Ready
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate(0, 0)
                        } else {
                            modelData.menu.open(0, 0)
                        }
                    }
                }
            }
        }
    }
}
