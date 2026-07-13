import QtQuick 6.10

QtObject {
    readonly property var workspaces: QtObject {
        property int count: 10
        property bool showOccupiedIndicator: true
        property bool showActiveIndicator: true
        property bool unifiedPill: false
        property int pillPadding: 8
        property bool enableClickAnimation: true
        property bool enableSwitchAnimation: true
        property int animationDuration: 200
        property string activeColor: "#ffffff"
        property string occupiedColor: "#f1f5f9"
        property string emptyColor: "#666666"
        property string activeTextColor: "#ffffff"
        property string inactiveTextColor: "#999999"
        property string backgroundColor: "#121212"
        property string pillBackgroundColor: "#121212"
        property int workspaceSize: 18
        property int spacing: 0
        property int cornerRadius: 6
        property int indicatorSize: 4
    }

    readonly property int height: 36
    readonly property int padding: 0
    readonly property real backgroundOpacity: 0.65

    readonly property var islands: QtObject {
        property int borderRadius: 0
        property real surfaceOpacity: 0.65
        property real borderOpacity: 0.08
        property int spacing: 0
    }
}
