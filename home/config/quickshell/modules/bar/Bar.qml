import Quickshell
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "components" as BarComponents
import "../../config" as QsConfig
import "../../services" as QsServices

Item {
    id: root

    property var screen
    property var barWindow

    property string activePopup: ""
    readonly property bool hasPopup: activePopup !== ""
    readonly property real popupAreaHeight: hasPopup ? popupHost.height : 0

    function togglePopup(name: string) {
        activePopup = activePopup === name ? "" : name
    }

    function closePopup() {
        activePopup = ""
    }

    function popupAnchorTarget() {
        if (activePopup === "network") return networkLoader
        if (activePopup === "bluetooth") return bluetoothLoader
        return rightSection
    }

    readonly property var config: QsConfig.Config
    readonly property color barBackground: Qt.rgba(18 / 255, 18 / 255, 18 / 255, 0.65)
    readonly property color barBorder: Qt.rgba(1, 1, 1, 0.08)
    readonly property color defaultText: "#f1f5f9"

    Rectangle {
        id: barContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: config.bar.height

        color: root.barBackground
        border.width: 0
        border.color: root.barBorder

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: root.barBorder
        }

        RowLayout {
            id: leftSection
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 6
            spacing: 0

            Loader {
                source: "components/NixosButton.qml"
            }

            Loader {
                id: workspacesLoader
                source: "components/WaybarWorkspaces.qml"
                Binding {
                    target: workspacesLoader.item
                    property: "screen"
                    value: root.screen
                    when: workspacesLoader.status === Loader.Ready && root.screen !== undefined
                }
            }

            Loader {
                source: "components/Taskbar.qml"
            }
        }

        RowLayout {
            id: centerSection
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Loader {
                source: "components/WaybarClock.qml"
            }

            Loader {
                source: "components/WaybarMpris.qml"
            }
        }

        RowLayout {
            id: rightSection
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 6
            spacing: 0

            Loader {
                source: "components/BlueLight.qml"
            }

            Loader {
                source: "components/WaybarVolume.qml"
            }

            Loader {
                source: "components/WaybarCpu.qml"
            }

            Loader {
                source: "components/WaybarMemory.qml"
            }

            Loader {
                source: "components/WaybarBattery.qml"
            }

            Loader {
                id: networkLoader
                source: "components/Network.qml"
                Binding {
                    target: networkLoader.item
                    property: "barWindow"
                    value: root.barWindow
                    when: networkLoader.status === Loader.Ready && root.barWindow !== undefined
                }
                Binding {
                    target: networkLoader.item
                    property: "bar"
                    value: root
                    when: networkLoader.status === Loader.Ready
                }
            }

            Loader {
                id: bluetoothLoader
                source: "components/Bluetooth.qml"
                Binding {
                    target: bluetoothLoader.item
                    property: "barWindow"
                    value: root.barWindow
                    when: bluetoothLoader.status === Loader.Ready && root.barWindow !== undefined
                }
                Binding {
                    target: bluetoothLoader.item
                    property: "bar"
                    value: root
                    when: bluetoothLoader.status === Loader.Ready
                }
            }

            Loader {
                id: trayLoader
                source: "components/WaybarTray.qml"
                visible: trayLoader.item?.hasItems ?? false
            }
        }
    }

    Item {
        id: popupHost
        anchors.top: barContainer.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: hasPopup ? popupContentWrapper.height + 12 : 0
        clip: true
        visible: hasPopup

        property bool mouseHasEntered: false
        property bool mouseInside: popupHoverHandler.hovered

        Timer {
            id: popupCloseTimer
            interval: 400
            onTriggered: {
                if (!popupHost.mouseInside && popupHost.mouseHasEntered && root.hasPopup) {
                    root.closePopup()
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closePopup()
        }

        Item {
            id: popupContentWrapper
            y: 4
            x: {
                const w = width
                const hostPadding = 12
                const anchor = root.popupAnchorTarget()
                if (anchor && anchor.mapToItem) {
                    const centerInHost = anchor.mapToItem(popupHost, anchor.width / 2, anchor.height).x
                    return Math.max(hostPadding, Math.min(popupHost.width - w - hostPadding, centerInHost - (w / 2)))
                }
                return Math.max(hostPadding, popupHost.width - w - hostPadding)
            }
            width: activePopup === "network" ? 340 : 320
            height: {
                if (btPanelLoader.active && btPanelLoader.item)
                    return btPanelLoader.item.implicitHeight
                if (netPanelLoader.active && netPanelLoader.item)
                    return netPanelLoader.item.implicitHeight
                return 0
            }

            HoverHandler {
                id: popupHoverHandler
                onHoveredChanged: {
                    if (hovered) {
                        popupHost.mouseHasEntered = true
                        popupCloseTimer.stop()
                    } else if (popupHost.mouseHasEntered && root.hasPopup) {
                        popupCloseTimer.restart()
                    }
                }
            }

            Loader {
                id: btPanelLoader
                anchors.fill: parent
                active: root.activePopup === "bluetooth"
                source: "components/BluetoothPanel.qml"
                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }
                Connections {
                    target: btPanelLoader.item
                    function onCloseRequested() { root.closePopup() }
                }
            }

            Loader {
                id: netPanelLoader
                anchors.fill: parent
                active: root.activePopup === "network"
                source: "components/NetworkPanel.qml"
                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }
                Connections {
                    target: netPanelLoader.item
                    function onCloseRequested() { root.closePopup() }
                }
            }
        }
    }
}
