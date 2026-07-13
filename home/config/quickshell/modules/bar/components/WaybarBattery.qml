import QtQuick 6.10
import Quickshell.Services.UPower

Item {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property int level: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool isCharging: battery?.state === UPowerDevice.Charging
    readonly property bool isPlugged: isCharging || battery?.state === UPowerDevice.FullyCharged
    readonly property bool isFull: battery?.state === UPowerDevice.FullyCharged
    readonly property bool isWarning: level <= 30 && level > 15
    readonly property bool isCritical: level <= 15 && !isPlugged

    readonly property string icon: {
        if (isCharging) return "\uf0e7"
        if (isPlugged && isFull) return "\uf1e6"
        if (isPlugged) return "\uf1e6"
        if (level >= 80) return "\uf240"
        if (level >= 60) return "\uf241"
        if (level >= 40) return "\uf242"
        if (level >= 20) return "\uf243"
        return "\uf244"
    }

    readonly property string label: {
        if (isPlugged && isFull) return "Full"
        return level + "%"
    }

    readonly property color textColor: {
        if (isCharging || isPlugged) return "#fde047"
        if (isCritical) return "#fca5a5"
        if (isWarning) return "#fdba74"
        return "#6ee7b7"
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
