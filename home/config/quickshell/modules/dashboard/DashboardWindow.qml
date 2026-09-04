import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"

PanelWindow {
    id: root

    property bool shouldShow: false

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property var time: QsServices.Time

    readonly property color cSurface: pywal.surfaceContainerHighest
    readonly property color cSurfaceContainer: pywal.surfaceContainerHigh
    readonly property color cSurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted
    readonly property color cBorder: pywal.outlineVariant

    // Date & Calendar State
    readonly property var currentDate: time.date
    readonly property int currentMonth: currentDate.getMonth()
    readonly property int currentYear: currentDate.getFullYear()
    readonly property int currentDay: currentDate.getDate()

    property int monthOffset: 0

    readonly property var displayDate: new Date(currentYear, currentMonth + monthOffset, 1)
    readonly property int displayMonth: displayDate.getMonth()
    readonly property int displayYear: displayDate.getFullYear()

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var dayLabels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    readonly property int calendarOffset: {
        const first = new Date(displayYear, displayMonth, 1).getDay()
        return (first + 6) % 7
    }
    readonly property int calendarDays: new Date(displayYear, displayMonth + 1, 0).getDate()
    readonly property var calendarCells: {
        const cells = []
        const prevMonthDays = new Date(displayYear, displayMonth, 0).getDate()
        const isCurrentRealMonth = (displayYear === currentYear && displayMonth === currentMonth)
        for (let index = 0; index < 42; index++) {
            const dayNumber = index - calendarOffset + 1
            if (dayNumber < 1) {
                cells.push({ day: prevMonthDays + dayNumber, current: false, today: false })
            } else if (dayNumber > calendarDays) {
                cells.push({ day: dayNumber - calendarDays, current: false, today: false })
            } else {
                cells.push({
                    day: dayNumber,
                    current: true,
                    today: isCurrentRealMonth && (dayNumber === currentDay)
                })
            }
        }
        return cells
    }

    function toggleDashboard() {
        if (root.shouldShow) {
            closeDashboard()
        } else {
            openDashboard()
        }
    }

    function openDashboard() {
        monthOffset = 0
        shouldShow = true
        Qt.callLater(() => panel.forceActiveFocus())
    }

    function closeDashboard() {
        shouldShow = false
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            root.toggleDashboard()
        }

        function open(): void {
            root.openDashboard()
        }

        function close(): void {
            root.closeDashboard()
        }
    }

    screen: Quickshell.screens[0]
    anchors {
        top: true
        left: true
    }
    margins {
        top: (config.bar.height ?? 34) + (config.dashboard.margin ?? 12)
        left: Math.max(0, Math.round((screen.width - root.implicitWidth) / 2))
    }
    implicitWidth: config.dashboard.width ?? 360
    implicitHeight: shouldShow || panel.opacity > 0 ? Math.min(config.dashboard.height ?? 410, screen.height - margins.top - 24) : 0
    visible: (config.dashboard.enabled ?? true) && (shouldShow || panel.opacity > 0)
    color: "transparent"

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: panel
        anchors.fill: parent
        property real revealOffset: shouldShow ? 0 : -18
        scale: shouldShow ? 1.0 : 0.975
        opacity: shouldShow ? 1.0 : 0.0
        focus: root.shouldShow
        transform: Translate { y: panel.revealOffset }

        Keys.onEscapePressed: root.closeDashboard()

        Behavior on scale {
            NumberAnimation { duration: 240; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] }
        }

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        Behavior on revealOffset {
            NumberAnimation { duration: 260; easing.bezierCurve: [0.05, 0.7, 0.1, 1.0] }
        }

        AuroraSurface {
            anchors.fill: parent
            radius: 24
            color: root.cSurface
            strokeColor: root.cBorder
            accentColor: root.cPrimary
            elevation: 4
            highlighted: root.shouldShow

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                // Date Header Section
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: time.format("dddd")
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 22
                            font.weight: Font.Bold
                            color: root.cText
                        }

                        Text {
                            text: time.format("MMMM d, yyyy")
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: root.cSubText
                        }
                    }

                    // "Today" jump button if user navigated away from current month
                    Rectangle {
                        visible: root.monthOffset !== 0
                        Layout.preferredHeight: 28
                        Layout.preferredWidth: todayLabel.implicitWidth + 16
                        radius: 14
                        color: todayMouse.containsMouse
                            ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.24)
                            : Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.12)
                        border.width: 1
                        border.color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.35)

                        Text {
                            id: todayLabel
                            anchors.centerIn: parent
                            text: "Today"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: root.cPrimary
                        }

                        MouseArea {
                            id: todayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.monthOffset = 0
                        }
                    }
                }

                // Divider line
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(root.cBorder.r, root.cBorder.g, root.cBorder.b, 0.35)
                }

                // Month & Navigation Header
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: `${root.monthNames[root.displayMonth]} ${root.displayYear}`
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        color: root.cText
                    }

                    Item { Layout.fillWidth: true }

                    // Previous Month
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        color: prevMouse.containsMouse ? root.cSurfaceContainerHigh : "transparent"
                        border.width: prevMouse.containsMouse ? 1 : 0
                        border.color: root.cBorder

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            color: prevMouse.containsMouse ? root.cText : root.cSubText
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.monthOffset--
                        }
                    }

                    // Next Month
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        color: nextMouse.containsMouse ? root.cSurfaceContainerHigh : "transparent"
                        border.width: nextMouse.containsMouse ? 1 : 0
                        border.color: root.cBorder

                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            color: nextMouse.containsMouse ? root.cText : root.cSubText
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.monthOffset++
                        }
                    }
                }

                // Calendar Grid
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 4

                    // Day of week headers
                    Repeater {
                        model: root.dayLabels

                        Text {
                            id: dayHeader
                            required property var modelData
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: dayHeader.modelData
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: root.cSubText
                        }
                    }

                    // Day cells
                    Repeater {
                        model: root.calendarCells

                        Rectangle {
                            id: dayCell
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 28
                            radius: 14
                            color: dayCell.modelData.today
                                ? root.cPrimary
                                : cellMouse.containsMouse && dayCell.modelData.current
                                    ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.08)
                                    : dayCell.modelData.current
                                        ? "transparent"
                                        : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.02)

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: `${dayCell.modelData.day}`
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: 12
                                font.weight: dayCell.modelData.today ? Font.Bold : Font.Medium
                                color: dayCell.modelData.today
                                    ? pywal.onPrimary
                                    : dayCell.modelData.current
                                        ? root.cText
                                        : root.cSubText
                                opacity: dayCell.modelData.today ? 1.0 : dayCell.modelData.current ? 1.0 : 0.35
                            }

                            MouseArea {
                                id: cellMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }
        }
    }
}