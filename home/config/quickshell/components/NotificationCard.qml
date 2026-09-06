import QtQuick 6.10
import QtQuick.Layouts
import "../services" as QsServices
import "../config" as QsConfig

Item {
    id: root

    required property var notification

    // Feature flags
    property bool showCloseButton: true
    property bool showTimestamp: false
    property bool showUnreadDot: false
    property bool showActions: true
    property bool showBody: true
    property bool showAppIcon: true

    // Color tokens (overridable by consumer)
    property color primaryColor: pywal?.primary ?? "#88cc88"
    property color onSurfaceColor: pywal?.foreground ?? "#dddddd"
    property color onSurfaceVariantColor: pywal?.onSurfaceMuted ?? "#999999"
    property color errorColor: pywal?.error ?? "#ff4444"
    property color surfaceContainerHighColor: pywal?.surfaceContainerHigh ?? "#1a1a1a"

    property var pywal: null

    function urgencyColor(urgency) {
        if (urgency === 2) return errorColor
        if (urgency === 0) return Qt.rgba(onSurfaceColor.r, onSurfaceColor.g, onSurfaceColor.b, 0.5)
        return primaryColor
    }

    function iconSource(icon) {
        if (!icon) return ""
        if (icon.startsWith("/") || icon.startsWith("file://")) return icon
        return "image://icon/" + icon
    }

    implicitHeight: contentLayout.implicitHeight

    ColumnLayout {
        id: contentLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        // --- Header Row: icon + summary + timestamp + close ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // App icon badge
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                Layout.alignment: Qt.AlignTop
                radius: 12
                visible: showAppIcon
                color: Qt.rgba(urgencyColor(notification?.urgency ?? 1).r,
                               urgencyColor(notification?.urgency ?? 1).g,
                               urgencyColor(notification?.urgency ?? 1).b, 0.14)
                border.width: 1
                border.color: Qt.rgba(urgencyColor(notification?.urgency ?? 1).r,
                                      urgencyColor(notification?.urgency ?? 1).g,
                                      urgencyColor(notification?.urgency ?? 1).b, 0.28)

                Image {
                    anchors.centerIn: parent
                    width: 22; height: 22
                    visible: notification?.appIcon && notification.appIcon.length > 0
                    source: root.iconSource(notification?.appIcon ?? "")
                    fillMode: Image.PreserveAspectFit
                    smooth: true; cache: true; asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: !notification?.appIcon || notification.appIcon.length === 0
                    text: "󰂚"
                    font.family: "Material Design Icons"
                    font.pixelSize: 20
                    color: urgencyColor(notification?.urgency ?? 1)
                    opacity: 0.85
                }
            }

            // Summary + app name
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: notification?.summary ?? "Notification"
                    font.family: QsConfig.Config.appearance.fontFamily ?? "Inter"
                    font.pixelSize: 13.5
                    font.weight: Font.DemiBold
                    color: onSurfaceColor
                    elide: Text.ElideRight
                    font.letterSpacing: -0.1
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: (notification?.appName?.length ?? 0) > 0 || (showTimestamp && (notification?.timeString?.length ?? 0) > 0)

                    Text {
                        text: notification?.appName ?? ""
                        font.family: QsConfig.Config.appearance.fontFamily ?? "Inter"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: onSurfaceVariantColor
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }

                    Text {
                        text: "•"
                        font.pixelSize: 10
                        color: Qt.rgba(onSurfaceVariantColor.r, onSurfaceVariantColor.g, onSurfaceVariantColor.b, 0.5)
                        visible: (notification?.appName?.length ?? 0) > 0 && showTimestamp && (notification?.timeString?.length ?? 0) > 0
                    }

                    Text {
                        visible: showTimestamp
                        text: notification?.timeString ?? ""
                        font.family: QsConfig.Config.appearance.fontFamily ?? "Inter"
                        font.pixelSize: 10.5
                        color: onSurfaceVariantColor
                    }
                }
            }

            // Unread dot
            Rectangle {
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                Layout.alignment: Qt.AlignTop
                radius: 4
                visible: showUnreadDot && notification && !notification.read
                color: primaryColor
                Layout.topMargin: 4
            }

            // Close button
            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                Layout.alignment: Qt.AlignTop
                radius: 13
                visible: showCloseButton
                color: closeMouse.containsMouse
                    ? Qt.rgba(errorColor.r, errorColor.g, errorColor.b, 0.16)
                    : Qt.rgba(1, 1, 1, 0.04)
                border.width: 1
                border.color: closeMouse.containsMouse
                    ? Qt.rgba(errorColor.r, errorColor.g, errorColor.b, 0.3)
                    : Qt.rgba(1, 1, 1, 0.06)
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: "Material Design Icons"
                    font.pixelSize: 13
                    color: closeMouse.containsMouse ? errorColor : Qt.rgba(onSurfaceColor.r, onSurfaceColor.g, onSurfaceColor.b, 0.55)
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.notification && root.notification.close)
                            root.notification.close()
                    }
                }
            }
        }

        // --- Body text ---
        Text {
            Layout.fillWidth: true
            text: notification?.body ?? ""
            font.family: QsConfig.Config.appearance.fontFamily ?? "Inter"
            font.pixelSize: 12
            color: Qt.rgba(onSurfaceColor.r, onSurfaceColor.g, onSurfaceColor.b, 0.75)
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            lineHeight: 1.35
            visible: showBody && text.length > 0
        }

        // --- Image preview ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            radius: 10
            clip: true
            visible: notification?.image && notification.image.length > 0
            color: surfaceContainerHighColor
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.06)

            Image {
                anchors.fill: parent
                anchors.margins: 1
                source: root.iconSource(notification?.image ?? "")
                fillMode: Image.PreserveAspectCrop
                smooth: true; cache: true; asynchronous: true
            }
        }

        // --- Action buttons ---
        Flow {
            Layout.fillWidth: true
            spacing: 8
            visible: showActions && notification?.actions && notification.actions.length > 0

            Repeater {
                model: notification?.actions ?? []

                Rectangle {
                    required property var modelData
                    width: actionLabel.implicitWidth + 24
                    height: 28
                    radius: 14
                    color: actionMouse.containsMouse
                        ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.22)
                        : Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.10)
                    border.width: 1
                    border.color: actionMouse.containsMouse
                        ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.45)
                        : Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.22)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                    scale: actionMouse.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: modelData.text ?? modelData.identifier ?? ""
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.family: QsConfig.Config.appearance.fontFamily ?? "Inter"
                        font.letterSpacing: 0.2
                        color: primaryColor
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.invoke)
                                modelData.invoke()
                            if (root.notification && root.notification.close)
                                root.notification.close()
                        }
                    }
                }
            }
        }
    }
}
