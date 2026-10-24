import QtQuick 6.10
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../config" as QsConfig
import "../../services" as QsServices

// Hosts GUI actions (actions whose manifest has a "gui": "File.qml").
// The loaded component may declare any of these properties, which are injected:
//   property var action    // the normalized action object
//   property var host      // this window: host.close()
//   property var actions   // QsServices.Actions (run other actions, list, states)
//   property var pywal     // QsServices.Pywal (theme colors)
//   property var config    // QsConfig.Config
//   property var args      // resolved param values { name: value }
// The component sizes itself with implicitWidth / implicitHeight.
// Actions with missing required "params" get the built-in ParamForm.qml first.
PanelWindow {
    id: root

    property bool shouldShow: false
    property var currentAction: null

    readonly property var pywal: QsServices.Pywal

    property var currentArgs: ({})

    function load(action, url, args) {
        const mon = QsServices.Hypr.focusedMonitor
        if (mon && mon.name) {
            const found = Quickshell.screens.find(s => s.name === mon.name)
            if (found) root.screen = found
        }
        if (currentAction && currentAction.id === action.id && shouldShow && url === guiLoader.source.toString()) {
            close()
            return
        }
        currentAction = action
        currentArgs = args || {}
        guiLoader.source = ""
        guiLoader.source = url
        shouldShow = true
    }

    function openAction(action, args) {
        load(action, action.guiUrl, args)
    }

    function openParams(action, values) {
        load(action, Qt.resolvedUrl("ParamForm.qml"), values)
    }

    function close() {
        shouldShow = false
    }

    Connections {
        target: QsServices.Actions
        function onGuiRequested(action, args) {
            root.openAction(action, args)
        }
        function onParamsRequested(action, values) {
            root.openParams(action, values)
        }
    }

    IpcHandler {
        target: "actionhost"
        function close(): void { root.close() }
    }

    screen: Quickshell.screens[0]
    WlrLayershell.namespace: "quickshell-actions"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: shouldShow || panel.opacity > 0

    onVisibleChanged: if (!visible) guiLoader.source = ""

    // Dimmed backdrop, click to dismiss
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        opacity: root.shouldShow ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

        MouseArea {
            anchors.fill: parent
            enabled: root.shouldShow
            onClicked: root.close()
        }
    }

    FocusScope {
        id: panel
        anchors.centerIn: parent
        width: guiLoader.item ? guiLoader.item.implicitWidth : 0
        height: guiLoader.item ? guiLoader.item.implicitHeight : 0
        focus: root.shouldShow

        opacity: root.shouldShow ? 1 : 0
        scale: root.shouldShow ? 1 : 0.96
        transform: Translate {
            y: root.shouldShow ? 0 : 10
            Behavior on y { NumberAnimation { duration: 180; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] } }
        }
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 180; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] } }

        Keys.onEscapePressed: root.close()

        // Swallow clicks so they don't reach the backdrop
        MouseArea { anchors.fill: parent }

        Loader {
            id: guiLoader
            anchors.fill: parent
            focus: true

            onLoaded: {
                const inject = {
                    action: root.currentAction,
                    args: root.currentArgs,
                    host: root,
                    actions: QsServices.Actions,
                    pywal: QsServices.Pywal,
                    config: QsConfig.Config
                }
                for (const key in inject) {
                    if (key in item) item[key] = inject[key]
                }
                item.forceActiveFocus()
            }

            onStatusChanged: {
                if (status === Loader.Error) {
                    QsServices.Logger.error("ActionHost", `Failed to load GUI for '${root.currentAction?.id}': ${guiLoader.source}`)
                    root.close()
                }
            }
        }
    }
}
