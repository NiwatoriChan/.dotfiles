import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../services" as QsServices
import "../../config" as QsConfig
import "../../components"
import "../../components/effects"
import "components"

PanelWindow {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property var network: QsServices.Network
    readonly property var bluetooth: QsServices.Bluetooth
    readonly property var audio: QsServices.Audio
    readonly property var brightness: QsServices.Brightness
    readonly property var mpris: QsServices.Players
    readonly property var notifs: QsServices.Notifs
    readonly property var systemUsage: QsServices.SystemUsage
    readonly property var idleInhibitor: QsServices.IdleInhibitor
    readonly property var gamingMode: QsServices.GamingMode
    readonly property var settings: QsServices.Settings

    property bool shouldShow: false

    screen: Quickshell.screens[0]
    anchors { top: true; right: true }
    margins { right: 12; top: 12 }
    
    implicitWidth: 420
    implicitHeight: Math.min(760, screen.height - 40)
    color: "transparent"
    visible: shouldShow || panelContent.opacity > 0

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    function toggleMenu(): void {
        if (root.shouldShow) {
            closeMenu()
        } else {
            openMenu()
        }
    }

    function openMenu(): void {
        root.shouldShow = true
        Qt.callLater(() => panelContent.forceActiveFocus())
    }

    function closeMenu(): void {
        root.shouldShow = false
    }

    IpcHandler {
        target: "controlcenter"

        function toggle(): void {
            root.toggleMenu()
        }

        function open(): void {
            root.openMenu()
        }

        function close(): void {
            root.closeMenu()
        }
    }

    // M3 Solid Color Tokens
    readonly property color cSurface: pywal.surface
    readonly property color cSurfaceContainer: pywal.surfaceContainer
    readonly property color cSurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cSecondary: pywal.secondary
    readonly property color cOnSurface: pywal.foreground
    readonly property color cOnSurfaceVariant: pywal.onSurfaceMuted

    FocusScope {
        id: panelContent
        anchors.fill: parent

        transformOrigin: Item.TopRight
        scale: root.shouldShow ? 1.0 : 0.75
        opacity: root.shouldShow ? 1.0 : 0.0

        focus: true
        Keys.onEscapePressed: root.closeMenu()

        MouseArea { anchors.fill: parent; z: -1; onClicked: root.closeMenu() }

        Behavior on scale { NumberAnimation { duration: 350; easing.bezierCurve: Material3Anim.springBounce } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.bezierCurve: Material3Anim.standard } }

        Rectangle {
            id: panel
            anchors.fill: parent
            radius: 28
            color: root.cSurface
            clip: true

            MouseArea { anchors.fill: parent; onClicked: (mouse) => mouse.accepted = true }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // 1. Top Sliders Card (Volume & Brightness)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 128
                    radius: 22
                    color: root.cSurfaceContainer

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        VolumeSlider {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            audio: root.audio
                            pywal: root.pywal
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            height: 1
                            color: Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.06)
                        }

                        BrightnessSlider {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            brightness: root.brightness
                            pywal: root.pywal
                        }
                    }
                }

                // 2. Quick Toggles Grid (6 system toggles)
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    QuickToggle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        icon: "󰖩"
                        label: "Wi-Fi"
                        subLabel: root.network.connected ? root.network.ssid : "Off"
                        active: root.network.wifiEnabled
                        activeColor: root.cPrimary
                        onClicked: root.network.toggleWifi()
                    }

                    QuickToggle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        icon: "󰂯"
                        label: "Bluetooth"
                        subLabel: root.bluetooth.powered ? "On" : "Off"
                        active: root.bluetooth.powered
                        activeColor: root.cPrimary
                        onClicked: root.bluetooth.togglePower()
                    }

                    QuickToggle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        icon: "󰔎"
                        label: "Do Not Disturb"
                        subLabel: root.notifs.dnd ? "On" : "Off"
                        active: root.notifs.dnd
                        activeColor: pywal.warning
                        onClicked: root.notifs.toggleDnd()
                    }

                    QuickToggle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        icon: "󰅶"
                        label: "Caffeine"
                        subLabel: root.idleInhibitor.inhibited ? "Active" : "Off"
                        active: root.idleInhibitor.inhibited
                        activeColor: pywal.info
                        onClicked: root.idleInhibitor.inhibited = !root.idleInhibitor.inhibited
                    }

                    QuickToggle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        icon: "󰾴"
                        label: "Gaming Mode"
                        subLabel: root.gamingMode.enabled ? "Performance" : "Balanced"
                        active: root.gamingMode.enabled
                        activeColor: pywal.success
                        onClicked: root.gamingMode.toggle()
                    }

                    QuickToggle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        icon: "󰄉"
                        label: "Focus Mode"
                        subLabel: root.settings.focusModeEnabled ? `${root.settings.focusModeMinutesLeft} min remaining` : "25 min timer"
                        active: root.settings.focusModeEnabled
                        activeColor: pywal.info
                        onClicked: {
                            root.settings.focusModeEnabled = !root.settings.focusModeEnabled
                            if (root.settings.focusModeEnabled) {
                                root.settings.focusModeMinutesLeft = 25
                                root.notifs.dnd = true
                            }
                        }
                    }
                }

                // 3. Media Player Card (Visible only when playing)
                MediaCard {
                    Layout.fillWidth: true
                    visible: root.mpris?.active !== null
                    mpris: root.mpris
                    pywal: root.pywal
                }

                // 4. Notifications Section
                NotificationList {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 140
                    notifs: root.notifs
                    pywal: root.pywal
                }

                // 5. Bottom Action Bar (Close, Settings, Lock, Power)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    spacing: 10

                    // Bouton Fermer
                    Rectangle {
                        width: 46; height: 46; radius: 23
                        color: closeBtnMouse.pressed ? Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.15)
                             : closeBtnMouse.containsMouse ? Qt.rgba(pywal.error.r, pywal.error.g, pywal.error.b, 0.15)
                             : root.cSurfaceContainer
                        Behavior on color { ColorAnimation { duration: 150 } }
                        scale: closeBtnMouse.pressed ? 0.92 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100; easing.bezierCurve: Material3Anim.springGentle } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: "Material Design Icons"
                            font.pixelSize: 22
                            color: closeBtnMouse.containsMouse ? pywal.error : root.cOnSurfaceVariant
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: closeBtnMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: root.closeMenu()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Bouton Paramètres
                    Rectangle {
                        width: 46; height: 46; radius: 23
                        color: settingsBtnMouse.pressed ? Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.15)
                             : settingsBtnMouse.containsMouse ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.15)
                             : root.cSurfaceContainer
                        Behavior on color { ColorAnimation { duration: 150 } }
                        scale: settingsBtnMouse.pressed ? 0.92 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100; easing.bezierCurve: Material3Anim.springGentle } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰒓"
                            font.family: "Material Design Icons"
                            font.pixelSize: 22
                            color: settingsBtnMouse.containsMouse ? root.cPrimary : root.cOnSurfaceVariant
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: settingsBtnMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                root.closeMenu()
                                Quickshell.execDetached(["nm-connection-editor"])
                            }
                        }
                    }

                    // Bouton Verrouillage
                    Rectangle {
                        width: 46; height: 46; radius: 23
                        color: lockBtnMouse.pressed ? Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.15)
                             : lockBtnMouse.containsMouse ? Qt.rgba(pywal.warning.r, pywal.warning.g, pywal.warning.b, 0.15)
                             : root.cSurfaceContainer
                        Behavior on color { ColorAnimation { duration: 150 } }
                        scale: lockBtnMouse.pressed ? 0.92 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100; easing.bezierCurve: Material3Anim.springGentle } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰌾"
                            font.family: "Material Design Icons"
                            font.pixelSize: 22
                            color: lockBtnMouse.containsMouse ? pywal.warning : root.cOnSurfaceVariant
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: lockBtnMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                root.closeMenu()
                                Quickshell.execDetached(["dbus-send", "--system", "--type=method_call", "--print-reply", "--dest=org.freedesktop.DisplayManager", "/org/freedesktop/DisplayManager/Seat0", "org.freedesktop.DisplayManager.Seat.SwitchToGreeter"])
                            }
                        }
                    }

                    // Bouton Éteindre / Session
                    Rectangle {
                        width: 46; height: 46; radius: 23
                        color: powerBtnMouse.pressed ? Qt.rgba(pywal.error.r, pywal.error.g, pywal.error.b, 0.25)
                             : powerBtnMouse.containsMouse ? Qt.rgba(pywal.error.r, pywal.error.g, pywal.error.b, 0.15)
                             : root.cSurfaceContainer
                        Behavior on color { ColorAnimation { duration: 150 } }
                        scale: powerBtnMouse.pressed ? 0.92 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100; easing.bezierCurve: Material3Anim.springGentle } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰐥"
                            font.family: "Material Design Icons"
                            font.pixelSize: 22
                            color: powerBtnMouse.containsMouse ? pywal.error : root.cOnSurfaceVariant
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: powerBtnMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                root.closeMenu()
                                Quickshell.execDetached(["wlogout"])
                            }
                        }
                    }
                }
            }
        }
    }
}
