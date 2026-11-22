//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=basic

import Quickshell
import Quickshell.Io
import QtQuick 6.10
import "services" as QsServices

ShellRoot {
    id: root

    readonly property var audio: QsServices.Audio
    readonly property var brightness: QsServices.Brightness
    readonly property var pywal: QsServices.Pywal

    component LazyOverlay: Scope {
        id: overlay
        required property string source
        property bool keepAlive: false
        readonly property alias item: loader.item

        function ensureLoaded() {
            unloadTimer.stop()
            if (!loader.active) {
                loader.active = true
            }
            return loader.item
        }

        LazyLoader {
            id: loader
            active: overlay.keepAlive
            source: Qt.resolvedUrl(overlay.source)
        }

        Timer {
            id: unloadTimer
            interval: 200
            repeat: false
            onTriggered: {
                if (overlay.keepAlive) return
                if (loader.item && !loader.item.visible && !loader.item.shouldShow) {
                    loader.active = false
                    Qt.callLater(gc)
                }
            }
        }

        Connections {
            target: loader.item
            ignoreUnknownSignals: true

            function onVisibleChanged() {
                if (overlay.keepAlive || !loader.item) return
                if (!loader.item.visible && !loader.item.shouldShow) {
                    unloadTimer.restart()
                } else {
                    unloadTimer.stop()
                }
            }

            function onShouldShowChanged() {
                if (overlay.keepAlive || !loader.item) return
                if (loader.item.shouldShow) {
                    unloadTimer.stop()
                } else if (!loader.item.visible) {
                    unloadTimer.restart()
                }
            }
        }
    }

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

    LazyOverlay {
        id: launcherOverlay
        keepAlive: true
        source: "modules/launcher/LauncherWindow.qml"
    }

    LazyOverlay {
        id: wallpaperOverlay
        source: "modules/wallpaper/WallpaperWindow.qml"
    }

    LazyOverlay {
        id: controlCenterOverlay
        source: "modules/controlcenter/ControlCenterWindow.qml"
    }

    LazyOverlay {
        id: dashboardOverlay
        source: "modules/dashboard/DashboardWindow.qml"
    }

    LazyOverlay {
        id: switcherOverlay
        source: "modules/switcher/SwitcherWindow.qml"
    }

    LazyOverlay {
        id: actionHostOverlay
        source: "modules/actions/ActionHost.qml"
    }

    Connections {
        target: QsServices.Actions
        function onGuiRequested(action, args) {
            const host = actionHostOverlay.ensureLoaded()
            if (host) host.openAction(action, args)
        }
        function onParamsRequested(action, values) {
            const host = actionHostOverlay.ensureLoaded()
            if (host) host.openParams(action, values)
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            const w = launcherOverlay.ensureLoaded()
            if (!w) return
            if (w.shouldShow) {
                w.closeLauncher()
            } else {
                w.openLauncher()
            }
        }

        function open(): void {
            const w = launcherOverlay.ensureLoaded()
            if (w) w.openLauncher()
        }

        function close(): void {
            if (launcherOverlay.item) launcherOverlay.item.closeLauncher()
        }
    }

    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            const w = wallpaperOverlay.ensureLoaded()
            if (!w) return
            if (w.shouldShow) {
                w.closeMenu()
            } else {
                w.openMenu()
            }
        }

        function open(): void {
            const w = wallpaperOverlay.ensureLoaded()
            if (w) w.openMenu()
        }

        function close(): void {
            if (wallpaperOverlay.item) wallpaperOverlay.item.closeMenu()
        }
    }

    IpcHandler {
        target: "controlcenter"

        function toggle(): void {
            const w = controlCenterOverlay.ensureLoaded()
            if (w) w.toggleMenu()
        }

        function open(): void {
            const w = controlCenterOverlay.ensureLoaded()
            if (w) w.openMenu()
        }

        function close(): void {
            if (controlCenterOverlay.item) controlCenterOverlay.item.closeMenu()
        }

        function toggleCaffeine(): void {
            QsServices.IdleInhibitor.inhibited = !QsServices.IdleInhibitor.inhibited
        }

        function toggleEthernetSharing(): void {
            QsServices.Network.toggleEthernetSharing()
        }
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            const w = dashboardOverlay.ensureLoaded()
            if (w) w.toggleDashboard()
        }

        function open(): void {
            const w = dashboardOverlay.ensureLoaded()
            if (w) w.openDashboard()
        }

        function close(): void {
            if (dashboardOverlay.item) dashboardOverlay.item.closeDashboard()
        }
    }

    IpcHandler {
        target: "switcher"

        function toggle(): void {
            const w = switcherOverlay.ensureLoaded()
            if (!w) return
            if (w.shouldShow) {
                w.selectNext()
            } else {
                w.openSwitcher()
            }
        }

        function open(): void {
            const w = switcherOverlay.ensureLoaded()
            if (w) w.openSwitcher()
        }

        function close(): void {
            if (switcherOverlay.item) {
                switcherOverlay.item.closeSwitcher()
            } else {
                Quickshell.execDetached(["hyprctl", "dispatch", "submap", "reset"])
            }
        }

        function next(): void {
            const w = switcherOverlay.ensureLoaded()
            if (!w) return
            if (!w.shouldShow) {
                w.openSwitcher()
            } else {
                w.selectNext()
            }
        }

        function prev(): void {
            const w = switcherOverlay.ensureLoaded()
            if (!w) return
            if (!w.shouldShow) {
                w.openSwitcher()
                if (w.visibleWindows.length > 1) {
                    w.selectedIndex = w.visibleWindows.length - 1
                }
            } else {
                w.selectPrev()
            }
        }

        function release(): void {
            if (switcherOverlay.item && switcherOverlay.item.shouldShow) {
                switcherOverlay.item.confirmAndSwitch()
            } else {
                Quickshell.execDetached(["hyprctl", "dispatch", "submap", "reset"])
            }
        }
    }

    IpcHandler {
        target: "actionhost"
        function close(): void {
            if (actionHostOverlay.item) actionHostOverlay.item.close()
        }
    }

    Loader {
        id: notificationPopupsLoader
        source: "modules/bar/components/NotificationPopups.qml"
        onStatusChanged: {
            if (status === Loader.Error) {
                QsServices.Logger.error("Shell", "notificationPopupsLoader error: " + sourceComponent.errorString())
            }
        }
    }

    Component.onCompleted: {
        QsServices.Logger.info("Shell", "Waybar-style quickshell loaded")
    }
}
