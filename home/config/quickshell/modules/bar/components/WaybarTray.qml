import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../../config" as QsConfig

Item {
    id: root

    property var barWindow
    readonly property var config: QsConfig.Config

    readonly property var ignoredItems: config.tray?.ignoredItems ?? [
        "nm-applet",
        "network-manager-applet",
        "networkmanager",
        "blueman",
        "blueman-applet",
        "blueman-tray"
    ]

    function isItemIgnored(item) {
        if (!item) return true
        const id = (item.id ?? "").toLowerCase()
        const title = (item.title ?? "").toLowerCase()
        const icon = (item.icon ?? "").toLowerCase()

        for (const pattern of ignoredItems) {
            const p = pattern.toLowerCase()
            if (id.includes(p) || title.includes(p)) {
                return true
            }
        }
        if (icon.startsWith("nm-") || icon.startsWith("network-") || icon.startsWith("blueman")) {
            return true
        }
        return false
    }

    readonly property var visibleItems: {
        const list = []
        for (const item of SystemTray.items.values) {
            if (!isItemIgnored(item)) {
                list.push(item)
            }
        }
        return list
    }

    readonly property bool hasItems: visibleItems.length > 0

    implicitWidth: hasItems ? trayRow.implicitWidth + 8 : 0
    implicitHeight: 20
    visible: hasItems

    RowLayout {
        id: trayRow
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: root.visibleItems

            delegate: Item {
                id: itemDelegate
                required property var modelData

                Layout.preferredWidth: 16
                Layout.preferredHeight: 16

                QsMenuAnchor {
                    id: menuAnchor
                    menu: itemDelegate.modelData?.menu
                    anchor.item: itemDelegate
                }

                IconImage {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: itemDelegate.modelData?.icon ?? ""
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: mouse => {
                        const item = itemDelegate.modelData
                        if (!item) return

                        if (mouse.button === Qt.LeftButton) {
                            if (item.onlyMenu) {
                                if (item.hasMenu) {
                                    menuAnchor.open()
                                } else if (typeof item.display === "function") {
                                    item.display(root.barWindow ?? itemDelegate.QsWindow.window, mouse.x, mouse.y)
                                }
                            } else {
                                item.activate()
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            item.secondaryActivate()
                        } else if (mouse.button === Qt.RightButton) {
                            if (item.hasMenu) {
                                menuAnchor.open()
                            } else if (typeof item.display === "function") {
                                item.display(root.barWindow ?? itemDelegate.QsWindow.window, mouse.x, mouse.y)
                            } else {
                                item.activate()
                            }
                        }
                    }

                    onWheel: wheel => {
                        if (itemDelegate.modelData) {
                            itemDelegate.modelData.scroll(wheel.angleDelta.y, false)
                        }
                    }
                }
            }
        }
    }
}
