import QtQuick 6.10
import qs.services

Item {
    id: root

    implicitWidth: clockText.implicitWidth + 24
    implicitHeight: 28

    Text {
        id: clockText
        anchors.centerIn: parent
        text: "\uf017   " + Time.format("dd-MM-yyyy   HH:mm")
        color: "#c084fc"
        font.family: "Inter Variable"
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }
}
