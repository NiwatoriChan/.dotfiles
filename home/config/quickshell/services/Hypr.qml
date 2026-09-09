pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick 6.10

Singleton {
    id: root

    readonly property var toplevels: Hyprland.toplevels
    readonly property var workspaces: Hyprland.workspaces
    readonly property var monitors: Hyprland.monitors

    readonly property var activeToplevel: Hyprland.activeToplevel
    readonly property var focusedWorkspace: Hyprland.focusedWorkspace
    readonly property var focusedMonitor: Hyprland.focusedMonitor
    readonly property int activeWsId: focusedWorkspace?.id ?? 1

    function dispatch(request: string): void {
        if (!request || request.length === 0) return;
        const trimmed = request.trim();

        if (trimmed.startsWith("workspace ")) {
            let target = trimmed.substring("workspace ".length).trim();
            if (target === "e+1") target = "+1";
            else if (target === "e-1") target = "-1";
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${target}" })`);
            return;
        }

        if (trimmed.startsWith("focuswindow address:")) {
            let addr = trimmed.substring("focuswindow address:".length).trim();
            while (addr.startsWith("0x0x")) addr = addr.substring(2);
            if (!addr.startsWith("0x")) addr = "0x" + addr;
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:${addr}" })`);
            return;
        }

        if (trimmed.startsWith("focuswindow ")) {
            const target = trimmed.substring("focuswindow ".length).trim();
            Hyprland.dispatch(`hl.dsp.focus({ window = "${target}" })`);
            return;
        }

        Hyprland.dispatch(request);
    }

    function monitorFor(screen: var): var {
        return Hyprland.monitorFor(screen);
    }

    // Get occupied workspaces (workspaces with windows)
    function getOccupiedWorkspaces(): var {
        const occupied = {};
        for (const ws of workspaces.values) {
            occupied[ws.id] = (ws.lastIpcObject?.windows ?? 0) > 0;
        }
        return occupied;
    }

    // Refresh timer to ensure updates when events are missed
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            Hyprland.refreshWorkspaces();
        }
    }

    // Debounced refresh timers to avoid IPC flooding
    Timer {
        id: debounceWorkspaces
        interval: 150
        repeat: false
        onTriggered: Hyprland.refreshWorkspaces()
    }

    Timer {
        id: debounceMonitors
        interval: 150
        repeat: false
        onTriggered: Hyprland.refreshMonitors()
    }

    // MRU window address tracking
    property var mruAddresses: []

    function normalizeAddress(addr: string): string {
        if (!addr) return "";
        let clean = addr.trim().toLowerCase();
        while (clean.startsWith("0x0x")) clean = clean.substring(2);
        if (!clean.startsWith("0x") && clean.length > 0) clean = "0x" + clean;
        return clean;
    }

    function recordActiveWindow(): void {
        const cur = Hyprland.activeToplevel;
        if (!cur) return;
        let addr = (cur.address || cur.lastIpcObject?.address || "").trim();
        if (!addr && cur.handle !== undefined) {
            addr = `${cur.handle}`;
        }
        addr = normalizeAddress(addr);
        if (!addr) return;

        const next = [addr];
        for (let i = 0; i < mruAddresses.length; ++i) {
            if (mruAddresses[i] !== addr) {
                next.push(mruAddresses[i]);
            }
        }
        if (next.length > 50) next.length = 50;
        mruAddresses = next;
    }

    function getMruIndex(addr: string): int {
        const clean = normalizeAddress(addr);
        if (!clean) return -1;
        return mruAddresses.indexOf(clean);
    }

    Connections {
        target: Hyprland

        function onActiveToplevelChanged(): void {
            recordActiveWindow();
        }

        function onRawEvent(event: var): void {
            const n = event.name;
            if (!n || n.endsWith("v2"))
                return;

            if (["workspace", "moveworkspace", "activespecial", "focusedmon", "activewindow"].includes(n)) {
                debounceWorkspaces.restart();
                debounceMonitors.restart();
                if (n === "activewindow") {
                    recordActiveWindow();
                }
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                debounceWorkspaces.restart();
            }
        }
    }

    Component.onCompleted: {
        recordActiveWindow();
    }
}

