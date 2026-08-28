pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    
    property real brightness: 0.5
    property real maxBrightness: 1.0
    
    // Alias for easier access
    readonly property real level: brightness
    readonly property int percentage: Math.round(brightness * 100)
    
    property string _backlightDevice: ""
    readonly property string backlightPath: _backlightDevice !== "" ? `/sys/class/backlight/${_backlightDevice}/brightness` : ""
    readonly property string maxBrightnessPath: _backlightDevice !== "" ? `/sys/class/backlight/${_backlightDevice}/max_brightness` : ""
    
    property int currentValue: 0
    property int maxValue: 255

    property bool _isUserSetting: false

    Timer {
        id: cooldownTimer
        interval: 350
        running: false
        repeat: false
        onTriggered: {
            root._isUserSetting = false
            root.readBrightness()
        }
    }

    Component.onCompleted: {
        detectBacklightDevice()
    }

    function detectBacklightDevice() {
        detectProc.running = true
    }
    
    function readMaxBrightness() {
        if (maxBrightnessPath === "") return
        maxBrightnessProcess.command = ["cat", maxBrightnessPath]
        maxBrightnessProcess.running = true
    }

    function readBrightness() {
        if (backlightPath === "" || _isUserSetting) return
        if (!brightnessProcess.running) {
            brightnessProcess.command = ["cat", backlightPath]
            brightnessProcess.running = true
        }
    }
    
    function setBrightness(value) {
        // Clamp between 0.01 and 1.0
        const newValue = Math.max(0.01, Math.min(1.0, value))
        _isUserSetting = true
        cooldownTimer.restart()
        root.brightness = newValue
        if (maxValue > 0) {
            root.currentValue = Math.round(newValue * maxValue)
        }

        const percent = Math.round(newValue * 100)
        Quickshell.execDetached(["brightnessctl", "set", `${percent}%`])
    }
    
    function increaseBrightness() {
        setBrightness(Math.min(1.0, Math.round((brightness + 0.05) * 100) / 100))
    }
    
    function decreaseBrightness() {
        setBrightness(Math.max(0.01, Math.round((brightness - 0.05) * 100) / 100))
    }
    
    // Read max brightness device
    Process {
        id: detectProc
        command: ["sh", "-c", "ls -1 /sys/class/backlight 2>/dev/null | head -n 1"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const dev = text.trim()
                if (dev.length > 0) {
                    root._backlightDevice = dev
                } else {
                    root._backlightDevice = ""
                }

                root.readMaxBrightness()
                root.readBrightness()
                updateTimer.start()
            }
        }
    }

    Process {
        id: maxBrightnessProcess
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim())
                if (!isNaN(value) && value > 0) {
                    maxValue = value
                    readBrightness()
                }
            }
        }
    }
    
    // Read current brightness
    Process {
        id: brightnessProcess
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                if (root._isUserSetting) return
                const value = parseInt(data.trim())
                if (!isNaN(value)) {
                    currentValue = value
                    if (maxValue > 0) {
                        brightness = Math.max(0.01, Math.min(1.0, value / maxValue))
                    }
                }
            }
        }
    }
    
    // Responsive update timer for external brightness changes (200ms)
    Timer {
        id: updateTimer
        interval: 200
        repeat: true
        triggeredOnStart: true
        onTriggered: readBrightness()
    }
}
