import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../services" as QsServices

// Clean Network indicator - No shadows, proper alignment
Item {
    id: root
    
    property var barWindow
    property var bar  // Reference to Bar.qml root for inline popup toggle
    
    readonly property var pywal: QsServices.Pywal
    readonly property var network: QsServices.Network
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property bool isEthernetPlugged: network?.ethernetPlugged ?? false
    readonly property bool isEthernetConnected: network?.ethernetConnected ?? false
    readonly property bool hasWifi: network?.hasWifiDevice ?? true
    readonly property bool isWifiConnected: network?.wifiConnected ?? false
    readonly property bool isWifiEnabled: network?.wifiEnabled ?? false
    readonly property int signalStrength: network?.signalStrength ?? 0
    readonly property string networkName: isEthernetConnected ? (network?.ethernetConnection || "Ethernet") : (network?.ssid ?? "Connected")

    visible: isEthernetPlugged || hasWifi
    implicitWidth: (isEthernetPlugged || hasWifi) ? (networkRow.implicitWidth + 16) : 0
    implicitHeight: 20
    
    RowLayout {
        id: networkRow
        anchors.centerIn: parent
        spacing: 5

        // RJ45 / Ethernet icon (only shown when plugged in)
        Text {
            id: ethernetIcon
            visible: root.isEthernetPlugged
            Layout.alignment: Qt.AlignVCenter
            
            text: "󰈀"
            font.family: "Material Design Icons"
            font.pixelSize: 15
            
            color: {
                if (!root.isEthernetConnected) return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.4)
                if (root.isHovered) return pywal.primary
                return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.85)
            }
            
            Behavior on color { ColorAnimation { duration: 150 } }
            
            scale: root.isHovered ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }
        }
        
        // WiFi icon
        Text {
            id: wifiIcon
            visible: root.hasWifi && (root.isWifiConnected || !root.isEthernetPlugged)
            Layout.alignment: Qt.AlignVCenter
            
            text: {
                if (!root.isWifiEnabled) return "󰖪"
                if (!root.isWifiConnected) return "󰖪"
                if (root.signalStrength >= 75) return "󰤨"
                if (root.signalStrength >= 50) return "󰤥"
                if (root.signalStrength >= 25) return "󰤢"
                return "󰤟"
            }
            
            font.family: "Material Design Icons"
            font.pixelSize: 14
            
            color: {
                if (!root.isWifiEnabled) return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.3)
                if (!root.isWifiConnected) return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.4)
                if (root.isHovered) return pywal.primary
                return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.8)
            }
            
            Behavior on color { ColorAnimation { duration: 150 } }
            
            scale: root.isHovered ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }
        }
    }
    
    // Click handler
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        
        onClicked: {
            if (root.bar) {
                root.bar.togglePopup("network")
            }
        }
    }
}
