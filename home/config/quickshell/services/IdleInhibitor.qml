pragma Singleton

import Quickshell
import QtQuick
import "." as QsServices

Singleton {
    id: root
    
    property bool inhibited: false
    
    onInhibitedChanged: {
        QsServices.Logger.debug("IdleInhibitor", `Inhibited changed: ${inhibited}`)
        if (inhibited) {
            enableInhibitor()
        } else {
            disableInhibitor()
        }
        if (QsServices.Settings.caffeineEnabled !== inhibited) {
            QsServices.Settings.caffeineEnabled = inhibited
        }
    }
    
    function enableInhibitor() {
        QsServices.Logger.info("IdleInhibitor", "Enabling")
        Quickshell.execDetached([
            "systemd-inhibit",
            "--what=idle:sleep",
            "--who=QuickShell",
            "--why=Caffeine mode enabled",
            "sleep",
            "infinity"
        ])
    }
    
    function disableInhibitor() {
        QsServices.Logger.info("IdleInhibitor", "Disabling")
        Quickshell.execDetached(["pkill", "-f", "systemd-inhibit.*QuickShell"])
    }
    
    // Sync with saved settings on startup
    Connections {
        target: QsServices.Settings
        function on_LoadingChanged() {
            if (!QsServices.Settings._loading && QsServices.Settings.caffeineEnabled && !root.inhibited) {
                root.inhibited = true
            }
        }
    }
    
    Component.onCompleted: {
        QsServices.Logger.debug("IdleInhibitor", "Service loaded")
        if (!QsServices.Settings._loading && QsServices.Settings.caffeineEnabled) {
            root.inhibited = true
        }
    }
    
    Component.onDestruction: {
        if (root.inhibited) {
            disableInhibitor()
        }
    }
}
