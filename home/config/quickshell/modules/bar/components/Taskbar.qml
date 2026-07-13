import Quickshell
import Quickshell.Hyprland
import QtQuick 6.10
import QtQuick.Layouts 6.10

Item {
    id: root

    readonly property var toplevels: {
        const list = []
        for (const tl of Hyprland.toplevels.values)
            list.push(tl)
        return list
    }

    implicitWidth: taskbarRow.implicitWidth + 8
    implicitHeight: 28
    visible: toplevels.length > 0

    RowLayout {
        id: taskbarRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: root.toplevels

            delegate: Rectangle {
                required property var modelData
                readonly property bool isActive: Hyprland.activeToplevel?.handle === modelData.handle

                Layout.preferredHeight: 24
                Layout.preferredWidth: appIcon.visible ? 24 : Math.max(24, taskTextFallback.width + 16)
                radius: 6
                color: isActive
                    ? Qt.rgba(1, 1, 1, 0.15)
                    : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : "transparent")
                border.width: isActive ? 1 : 0
                border.color: Qt.rgba(1, 1, 1, 0.1)

                Image {
                    id: appIcon
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    sourceSize.width: 32
                    sourceSize.height: 32
                    smooth: true
                    fillMode: Image.PreserveAspectFit
                    source: {
                        let appId = modelData.wayland?.appId;
                        if (!appId && modelData.lastIpcObject) {
                            appId = modelData.lastIpcObject.class || modelData.lastIpcObject.initialClass;
                        }
                        if (!appId) return "";
                        
                        let path = Quickshell.iconPath(appId, true);
                        if (!path) path = Quickshell.iconPath(appId.toLowerCase(), true);
                        
                        if (!path && appId.includes(".")) {
                            let parts = appId.split(".");
                            let lastPart = parts[parts.length - 1];
                            path = Quickshell.iconPath(lastPart, true);
                            if (!path) path = Quickshell.iconPath(lastPart.toLowerCase(), true);
                        }
                        return path;
                    }
                    visible: status === Image.Ready
                }

                Text {
                    id: taskTextFallback
                    anchors.centerIn: parent
                    text: modelData.title?.charAt(0)?.toUpperCase() ?? "?"
                    color: "#f1f5f9"
                    font.family: "Inter Variable"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    visible: !appIcon.visible
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.workspace) {
                            if (typeof modelData.workspace.activate === "function") {
                                modelData.workspace.activate();
                            } else {
                                Hyprland.dispatch("workspace " + modelData.workspace.id);
                            }
                        }
                        modelData.activate();
                    }
                }
            }
        }
    }
}
