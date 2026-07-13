import QtQuick 6.10
import Quickshell.Services.UPower

Item {
    id: root

    readonly property var battery: UPower.displayDevice
    // UPower percentage is in 0–1 range, convert to 0–100
    readonly property int level: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool isCharging: battery?.state === UPowerDevice.Charging
    readonly property bool isPlugged: isCharging || battery?.state === UPowerDevice.FullyCharged
    readonly property bool isFull: battery?.state === UPowerDevice.FullyCharged
    readonly property bool isWarning: level <= 30 && level > 15
    readonly property bool isCritical: level <= 15 && !isPlugged

    // Matches waybar format-icons = [ "" "" "" "" "" ]
    readonly property string icon: {
        if (isCharging) return "\uf0e7"   // bolt (charging)
        if (isFull)     return "\uf1e6"   // plug (full)
        if (isPlugged)  return "\uf1e6"   // plug (plugged)
        if (level >= 80) return "\uf240"  // battery-full
        if (level >= 60) return "\uf241"  // battery-three-quarters
        if (level >= 40) return "\uf242"  // battery-half
        if (level >= 20) return "\uf243"  // battery-quarter
        return "\uf244"                   // battery-empty
    }

    // Matches waybar: format-full = "  Full", format = "{icon}  {capacity}%"
    readonly property string label: {
        if (isFull) return "Full"
        return level + "%"
    }

    // Matches waybar CSS colors exactly
    readonly property color textColor: {
        if (isCharging || isPlugged) return "#fde047"  // battery.charging / battery.plugged
        if (isCritical) return "#fca5a5"               // battery.critical
        if (isWarning) return "#fdba74"                // battery.warning
        return "#6ee7b7"                               // battery / battery.full
    }

    implicitWidth: batteryText.implicitWidth + 24
    implicitHeight: 28

    Text {
        id: batteryText
        anchors.centerIn: parent
        text: root.icon + "  " + root.label
        color: root.textColor
        font.family: "Inter Variable"
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }
}
