import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import "../../../components/effects"
import "../../../services" as QsServices

FocusScope {
    id: popupPanel

    property bool shouldShow: false
    signal closeRequested()
    readonly property var pywal: QsServices.Pywal
    readonly property var audio: QsServices.Audio

    readonly property color cSurface: pywal.surface
    readonly property color cSurfaceContainer: pywal.surfaceContainer
    readonly property color cSurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cOnSurface: pywal.foreground
    readonly property color cOnSurfaceVariant: pywal.onSurfaceMuted

    implicitWidth: 340
    implicitHeight: contentColumn.implicitHeight + 32
    focus: true

    Keys.onEscapePressed: {
        closeRequested()
    }

    Rectangle {
        anchors.fill: parent
        radius: 24
        color: Qt.rgba(cSurface.r, cSurface.g, cSurface.b, 0.65)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 36
                    height: 36
                    radius: 12
                    color: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15)

                    Text {
                        anchors.centerIn: parent
                        text: audio.muted ? "󰝟" : "󰕾"
                        font.family: "Material Design Icons"
                        font.pixelSize: 18
                        color: cPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Sound Control"
                        font.family: "Inter"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        color: cOnSurface
                    }

                    Text {
                        text: audio.muted ? "Muted" : `Volume: ${audio.percentage}%`
                        font.family: "Inter"
                        font.pixelSize: 11
                        color: cOnSurfaceVariant
                    }
                }
            }

            // Global Volume Slider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                radius: 16
                color: Qt.rgba(cSurfaceContainer.r, cSurfaceContainer.g, cSurfaceContainer.b, 0.4)
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: muteArea.pressed ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15) : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: audio.muted ? "󰝟" : "󰕾"
                            font.family: "Material Design Icons"
                            font.pixelSize: 16
                            color: audio.muted ? cOnSurfaceVariant : cPrimary
                        }
                        
                        MouseArea {
                            id: muteArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: audio.toggleMute()
                        }
                    }

                    QQC.Slider {
                        id: globalSlider
                        value: audio.volume
                        from: 0
                        to: 1.0
                        Layout.fillWidth: true
                        
                        background: Rectangle {
                            x: globalSlider.leftPadding
                            y: globalSlider.topPadding + globalSlider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 6
                            width: globalSlider.availableWidth
                            height: implicitHeight
                            radius: 3
                            color: Qt.rgba(cOnSurface.r, cOnSurface.g, cOnSurface.b, 0.15)

                            Rectangle {
                                width: globalSlider.visualPosition * parent.width
                                height: parent.height
                                color: audio.muted ? cOnSurfaceVariant : cPrimary
                                radius: 3
                            }
                        }

                        handle: Rectangle {
                            x: globalSlider.leftPadding + globalSlider.visualPosition * (globalSlider.availableWidth - width)
                            y: globalSlider.topPadding + globalSlider.availableHeight / 2 - height / 2
                            implicitWidth: 16
                            implicitHeight: 16
                            radius: 8
                            color: globalSlider.pressed ? cPrimary : "#ffffff"
                            border.color: cPrimary
                            border.width: globalSlider.hovered ? 2 : 0
                            Behavior on border.width { NumberAnimation { duration: 100 } }
                        }

                        onMoved: {
                            audio.setVolume(value)
                        }
                    }

                    Text {
                        text: `${audio.percentage}%`
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: cOnSurface
                        Layout.preferredWidth: 32
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            // Output Devices Section
            Text {
                text: "Output Devices"
                font.family: "Inter"
                font.pixelSize: 12
                font.weight: Font.Bold
                color: cOnSurfaceVariant
                Layout.topMargin: 4
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(deviceList.contentHeight + 8, 120)
                radius: 16
                color: Qt.rgba(cSurfaceContainerHigh.r, cSurfaceContainerHigh.g, cSurfaceContainerHigh.b, 0.4)
                clip: true

                ListView {
                    id: deviceList
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 2
                    model: audio.sinks
                    clip: true

                    delegate: Rectangle {
                        id: deviceItem
                        width: deviceList.width
                        height: 40
                        radius: 12
                        color: modelData.isDefault ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15) : (deviceArea.pressed ? Qt.rgba(cOnSurface.r, cOnSurface.g, cOnSurface.b, 0.12) : deviceArea.containsMouse ? Qt.rgba(cOnSurface.r, cOnSurface.g, cOnSurface.b, 0.08) : "transparent")
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: modelData.name.toLowerCase().includes("headphone") || modelData.name.toLowerCase().includes("headset") ? "󰋋" : "󰕾"
                                font.family: "Material Design Icons"
                                font.pixelSize: 16
                                color: modelData.isDefault ? cPrimary : cOnSurface
                            }

                            Text {
                                text: modelData.name
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: modelData.isDefault ? Font.Medium : Font.Normal
                                color: modelData.isDefault ? cPrimary : cOnSurface
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: modelData.isDefault
                                text: "󰄲"
                                font.family: "Material Design Icons"
                                font.pixelSize: 14
                                color: cPrimary
                            }
                        }

                        MouseArea {
                            id: deviceArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: audio.setDefaultSink(modelData.id)
                        }
                    }
                }
                
                Text {
                    anchors.centerIn: parent
                    visible: audio.sinks.length === 0
                    text: "No output devices found"
                    font.family: "Inter"
                    font.pixelSize: 11
                    color: cOnSurfaceVariant
                }
            }

            // Application Volume Section
            Text {
                text: "Applications"
                font.family: "Inter"
                font.pixelSize: 12
                font.weight: Font.Bold
                color: cOnSurfaceVariant
                Layout.topMargin: 4
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(appList.contentHeight + 8, 220)
                radius: 16
                color: Qt.rgba(cSurfaceContainerHigh.r, cSurfaceContainerHigh.g, cSurfaceContainerHigh.b, 0.4)
                clip: true

                ListView {
                    id: appList
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 2
                    model: audio.streams
                    clip: true

                    delegate: Rectangle {
                        id: appItem
                        width: appList.width
                        height: 74
                        radius: 12
                        color: "transparent"
                        
                        readonly property var appData: modelData

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: appItem.appData.name
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: cOnSurface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                RowLayout {
                                    spacing: 8

                                    Rectangle {
                                        width: 24; height: 24; radius: 12
                                        color: appMuteArea.pressed ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15) : "transparent"
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: appItem.appData.muted ? "󰝟" : "󰕾"
                                            font.family: "Material Design Icons"
                                            font.pixelSize: 12
                                            color: appItem.appData.muted ? cOnSurfaceVariant : cPrimary
                                        }
                                        
                                        MouseArea {
                                            id: appMuteArea
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                audio.setNodeMute(appItem.appData.id, !appItem.appData.muted)
                                            }
                                        }
                                    }

                                    QQC.Slider {
                                        id: appSlider
                                        value: appItem.appData.volume
                                        from: 0
                                        to: 1.0
                                        Layout.preferredWidth: 120
                                        
                                        background: Rectangle {
                                            x: appSlider.leftPadding
                                            y: appSlider.topPadding + appSlider.availableHeight / 2 - height / 2
                                            implicitWidth: 120
                                            implicitHeight: 4
                                            width: appSlider.availableWidth
                                            height: implicitHeight
                                            radius: 2
                                            color: Qt.rgba(cOnSurface.r, cOnSurface.g, cOnSurface.b, 0.15)

                                            Rectangle {
                                                width: appSlider.visualPosition * parent.width
                                                height: parent.height
                                                color: appItem.appData.muted ? cOnSurfaceVariant : cPrimary
                                                radius: 2
                                            }
                                        }

                                        handle: Rectangle {
                                            x: appSlider.leftPadding + appSlider.visualPosition * (appSlider.availableWidth - width)
                                            y: appSlider.topPadding + appSlider.availableHeight / 2 - height / 2
                                            implicitWidth: 12
                                            implicitHeight: 12
                                            radius: 6
                                            color: appSlider.pressed ? cPrimary : "#ffffff"
                                            border.color: cPrimary
                                            border.width: appSlider.hovered ? 1.5 : 0
                                            Behavior on border.width { NumberAnimation { duration: 100 } }
                                        }

                                        onMoved: {
                                            audio.setNodeVolume(appItem.appData.id, value)
                                        }
                                    }

                                    Text {
                                        text: `${Math.round(appItem.appData.volume * 100)}%`
                                        font.family: "Inter"
                                        font.pixelSize: 10
                                        color: cOnSurface
                                        Layout.preferredWidth: 28
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }

                            // Routing Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: audio.sinks.length > 1

                                Text {
                                    text: "Route to:"
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    color: cOnSurfaceVariant
                                    verticalAlignment: Text.AlignVCenter
                                }

                                RowLayout {
                                    spacing: 4
                                    
                                    Repeater {
                                        model: audio.sinks
                                        delegate: Rectangle {
                                            width: 24
                                            height: 24
                                            radius: 6
                                            color: modelData.id === appItem.appData.sinkId ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15) : (routeArea.containsMouse ? Qt.rgba(cOnSurface.r, cOnSurface.g, cOnSurface.b, 0.08) : "transparent")
                                            border.color: modelData.id === appItem.appData.sinkId ? cPrimary : "transparent"
                                            border.width: 1
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.name.toLowerCase().includes("headphone") || modelData.name.toLowerCase().includes("headset") ? "󰋋" : "󰕾"
                                                font.family: "Material Design Icons"
                                                font.pixelSize: 12
                                                color: modelData.id === appItem.appData.sinkId ? cPrimary : cOnSurfaceVariant
                                            }
                                            
                                            QQC.ToolTip {
                                                visible: routeArea.containsMouse
                                                text: modelData.name
                                                delay: 400
                                            }
                                            
                                            MouseArea {
                                                id: routeArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    audio.moveStream(appItem.appData.id, modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: audio.streams.length === 0
                    text: "No applications playing audio"
                    font.family: "Inter"
                    font.pixelSize: 11
                    color: cOnSurfaceVariant
                }
            }
        }
    }
}
