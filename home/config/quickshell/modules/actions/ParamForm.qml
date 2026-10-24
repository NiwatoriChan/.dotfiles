import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import "../../config" as QsConfig

// Generic form for an action's "params". Loaded by ActionHost when required
// params are missing. Submitting calls actions.run(action.id, values).
Rectangle {
    id: root

    // injected by ActionHost
    property var action: null
    property var args: ({})
    property var host: null
    property var actions: null
    property var pywal: null
    property var config: null

    readonly property var params: action ? action.params : []
    property var values: ({})
    property var invalid: ({})

    // file browser state
    property bool browsing: false
    property var browseParam: null
    property string browseDir: ""
    property bool showHidden: false
    property var entries: []

    readonly property color cSurface: pywal ? pywal.surface : "#1e1e2e"
    readonly property color cContainer: pywal ? pywal.surfaceContainer : "#252536"
    readonly property color cHigh: pywal ? pywal.surfaceContainerHigh : "#303046"
    readonly property color cPrimary: pywal ? pywal.primary : "#89b4fa"
    readonly property color cText: pywal ? pywal.foreground : "#cdd6f4"
    readonly property color cMuted: pywal ? pywal.onSurfaceMuted : "#9399b2"
    readonly property color cError: "#f38ba8"
    readonly property string fontFamily: QsConfig.Config.appearance.fontFamily
    readonly property string iconFont: "Material Design Icons"
    readonly property string home: Quickshell.env("HOME")

    implicitWidth: 480
    implicitHeight: browsing ? 460 : formColumn.implicitHeight + 40
    color: cContainer
    radius: 18
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.08)
    clip: true

    Behavior on implicitHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    onArgsChanged: values = Object.assign({}, args || {})

    function setValue(name, v) {
        const c = Object.assign({}, values)
        c[name] = v
        values = c
        if (invalid[name]) {
            const i = Object.assign({}, invalid)
            delete i[name]
            invalid = i
        }
    }

    function submit() {
        if (!action || !actions) return
        const bad = {}
        for (const p of params) {
            if (p.required && p.type !== "bool" && !String(values[p.name] ?? "").length) bad[p.name] = true
        }
        invalid = bad
        if (Object.keys(bad).length) return
        const id = action.id
        host.close()
        actions.run(id, values)
    }

    // ------------------------------------------------------------- browser

    function openBrowser(p) {
        browseParam = p
        const cur = String(values[p.name] ?? "")
        let start = cur.length ? cur : p.startDir
        if (cur.length && p.type === "file") start = cur.slice(0, Math.max(cur.lastIndexOf("/"), 0)) || "/"
        browseTo(start)
        browsing = true
    }

    function browseTo(dir) {
        let d = String(dir || "~")
        if (d === "~") d = home
        else if (d.startsWith("~/")) d = home + "/" + d.slice(2)
        lsProc.command = ["sh", "-c",
            'cd "$1" 2>/dev/null || exit 1; pwd -P; if [ "$2" = 1 ]; then ls -1Ap; else ls -1p; fi',
            "sh", d, showHidden ? "1" : "0"]
        lsProc.running = true
    }

    function parseListing(text) {
        const lines = text.split("\n")
        const cwd = lines.shift()
        if (!cwd) return
        browseDir = cwd
        const dirs = []
        const files = []
        const filter = browseParam ? browseParam.filter : []
        for (const l of lines) {
            if (!l) continue
            if (l.endsWith("/")) dirs.push({ name: l.slice(0, -1), dir: true })
            else if (browseParam && browseParam.type === "file") {
                const ext = l.includes(".") ? l.slice(l.lastIndexOf(".") + 1).toLowerCase() : ""
                if (!filter.length || filter.includes(ext)) files.push({ name: l, dir: false })
            }
        }
        const up = cwd === "/" ? [] : [{ name: "..", dir: true }]
        entries = up.concat(dirs, files)
        listView.positionViewAtBeginning()
    }

    function choose(path) {
        if (browseParam) setValue(browseParam.name, path)
        // sync the visible text field
        const item = fieldRepeater.itemAt(params.indexOf(browseParam))
        if (item) item.setText(path)
        browsing = false
        root.forceActiveFocus()
    }

    Process {
        id: lsProc
        stdout: StdioCollector {
            onStreamFinished: root.parseListing(text)
        }
    }

    Keys.onEscapePressed: (event) => {
        if (root.browsing) {
            root.browsing = false
            event.accepted = true
        } else {
            root.host.close()
            event.accepted = true
        }
    }

    // ---------------------------------------------------------------- form

    ColumnLayout {
        id: formColumn
        visible: !root.browsing
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 40; height: 40; radius: 12
                color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.16)
                Text {
                    anchors.centerIn: parent
                    text: root.action ? root.action.icon : ""
                    color: root.cPrimary
                    font.family: root.iconFont
                    font.pixelSize: 22
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    text: root.action ? root.action.name : ""
                    color: root.cText
                    font.family: root.fontFamily
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.action ? root.action.description : ""
                    color: root.cMuted
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }

        Repeater {
            id: fieldRepeater
            model: root.params

            delegate: ColumnLayout {
                id: field
                required property var modelData
                required property int index
                readonly property bool bad: root.invalid[modelData.name] === true
                function setText(t) { input.text = t }

                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: field.modelData.label + (field.modelData.required ? "" : "  (optional)")
                    color: field.bad ? root.cError : root.cMuted
                    font.family: root.fontFamily
                    font.pixelSize: 12
                }

                // text / number / file / directory
                RowLayout {
                    visible: ["text", "number", "file", "directory"].includes(field.modelData.type)
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: 10
                        color: root.cHigh
                        border.width: 1
                        border.color: field.bad ? root.cError : (input.activeFocus ? root.cPrimary : "transparent")

                        TextInput {
                            id: input
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            color: root.cText
                            selectionColor: root.cPrimary
                            font.family: root.fontFamily
                            font.pixelSize: 14
                            inputMethodHints: field.modelData.type === "number" ? Qt.ImhFormattedNumbersOnly : Qt.ImhNone
                            text: String(root.args[field.modelData.name] ?? field.modelData.default ?? "")
                            onTextChanged: root.setValue(field.modelData.name, text)
                            onAccepted: root.submit()
                            Component.onCompleted: if (field.index === 0) forceActiveFocus()
                        }

                        Text {
                            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                            visible: input.text.length === 0
                            text: field.modelData.placeholder || (field.modelData.type === "file" ? "Select a file…" : field.modelData.type === "directory" ? "Select a folder…" : "")
                            color: Qt.rgba(root.cMuted.r, root.cMuted.g, root.cMuted.b, 0.6)
                            font.family: root.fontFamily
                            font.pixelSize: 14
                        }
                    }

                    Rectangle {
                        visible: field.modelData.type === "file" || field.modelData.type === "directory"
                        width: 38; height: 38; radius: 10
                        color: browseArea.containsMouse ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.3) : Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.16)
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text {
                            anchors.centerIn: parent
                            text: field.modelData.type === "file" ? "\uDB80\uDE14" : "\uDB80\uDE4B"
                            color: root.cPrimary
                            font.family: root.iconFont
                            font.pixelSize: 20
                        }
                        MouseArea {
                            id: browseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openBrowser(field.modelData)
                        }
                    }
                }

                // choice
                Flow {
                    visible: field.modelData.type === "choice"
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: field.modelData.choices
                        delegate: Rectangle {
                            required property string modelData
                            readonly property bool selected: (root.values[field.modelData.name] ?? field.modelData.default) === modelData
                            height: 32
                            width: chipText.implicitWidth + 24
                            radius: 16
                            color: selected ? root.cPrimary : root.cHigh
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                id: chipText
                                anchors.centerIn: parent
                                text: parent.modelData
                                color: parent.selected ? root.cSurface : root.cText
                                font.family: root.fontFamily
                                font.pixelSize: 13
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setValue(field.modelData.name, parent.modelData)
                            }
                        }
                    }
                }

                // bool
                Rectangle {
                    id: toggle
                    visible: field.modelData.type === "bool"
                    readonly property bool on: (root.values[field.modelData.name] ?? field.modelData.default) === "true"
                    width: 44; height: 24; radius: 12
                    color: on ? root.cPrimary : root.cHigh
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Rectangle {
                        width: 18; height: 18; radius: 9
                        y: 3
                        x: toggle.on ? parent.width - width - 3 : 3
                        color: toggle.on ? root.cSurface : root.cMuted
                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setValue(field.modelData.name, toggle.on ? "false" : "true")
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 8

            Item { Layout.fillWidth: true }

            Rectangle {
                width: cancelText.implicitWidth + 28; height: 36; radius: 10
                color: cancelArea.containsMouse ? root.cHigh : "transparent"
                Text {
                    id: cancelText
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: root.cMuted
                    font.family: root.fontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    id: cancelArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.host.close()
                }
            }

            Rectangle {
                width: runText.implicitWidth + 32; height: 36; radius: 10
                color: runArea.containsMouse ? Qt.lighter(root.cPrimary, 1.12) : root.cPrimary
                Behavior on color { ColorAnimation { duration: 100 } }
                Text {
                    id: runText
                    anchors.centerIn: parent
                    text: "Run"
                    color: root.cSurface
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                }
                MouseArea {
                    id: runArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.submit()
                }
            }
        }
    }

    // ------------------------------------------------------------- browser

    ColumnLayout {
        visible: root.browsing
        anchors { fill: parent; margins: 16 }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: root.browseDir
                elide: Text.ElideMiddle
                color: root.cText
                font.family: root.fontFamily
                font.pixelSize: 13
                font.bold: true
            }

            Rectangle {
                width: hiddenText.implicitWidth + 20; height: 28; radius: 8
                color: root.showHidden ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.25) : root.cHigh
                Text {
                    id: hiddenText
                    anchors.centerIn: parent
                    text: "Hidden"
                    color: root.showHidden ? root.cPrimary : root.cMuted
                    font.family: root.fontFamily
                    font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.showHidden = !root.showHidden; root.browseTo(root.browseDir) }
                }
            }

            Rectangle {
                visible: root.browseParam && root.browseParam.type === "directory"
                width: selectText.implicitWidth + 20; height: 28; radius: 8
                color: root.cPrimary
                Text {
                    id: selectText
                    anchors.centerIn: parent
                    text: "Select this folder"
                    color: root.cSurface
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.choose(root.browseDir)
                }
            }

            Rectangle {
                width: 28; height: 28; radius: 8
                color: root.cHigh
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: root.cMuted
                    font.pixelSize: 13
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.browsing = false
                }
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.entries
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                required property var modelData
                width: listView.width
                height: 34
                radius: 8
                color: rowArea.containsMouse ? root.cHigh : "transparent"

                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    spacing: 10
                    Text {
                        text: parent.parent.modelData.name === ".." ? "\u2191" : (parent.parent.modelData.dir ? "\uDB80\uDE4B" : "\uDB80\uDE14")
                        color: parent.parent.modelData.dir ? root.cPrimary : root.cMuted
                        font.family: root.iconFont
                        font.pixelSize: 18
                    }
                    Text {
                        Layout.fillWidth: true
                        text: parent.parent.modelData.name
                        elide: Text.ElideRight
                        color: root.cText
                        font.family: root.fontFamily
                        font.pixelSize: 13
                    }
                }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const m = parent.modelData
                        if (m.dir) root.browseTo(root.browseDir + "/" + m.name)
                        else root.choose((root.browseDir === "/" ? "" : root.browseDir) + "/" + m.name)
                    }
                }
            }
        }
    }
}
