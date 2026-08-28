pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool ready: false
    property bool muted: false
    property real volume: 0
    readonly property int percentage: Math.round(volume * 100)

    property bool sourceReady: false
    property bool sourceMuted: false
    property real sourceVolume: 0
    readonly property int sourcePercentage: Math.round(sourceVolume * 100)

    property var sinks: []
    property var streams: []
    property var streamCache: ({})

    function parseWpctlStatus(output) {
        const lines = output.split("\n");
        let currentSection = "";
        const parsedSinks = [];
        const activeIds = {};
        
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const trimmed = line.trim();
            if (trimmed.includes("Sinks:")) {
                currentSection = "sinks";
                continue;
            } else if (trimmed.includes("Sources:")) {
                currentSection = "sources";
                continue;
            } else if (trimmed.includes("Streams:")) {
                currentSection = "streams";
                continue;
            } else if (trimmed === "" || trimmed.includes("Video") || trimmed.includes("Settings")) {
                if (currentSection !== "") {
                    currentSection = "";
                }
            }
            
            if (currentSection === "sinks") {
                const isDefault = line.includes("*");
                const match = line.match(/(?:\*|\s)\s*(\d+)\.\s*([^\t\[]+)(?:\[vol:\s*([0-9.]+)(?:\s*\[MUTED\])?)?/);
                if (match) {
                    const id = parseInt(match[1]);
                    const name = match[2].trim();
                    const vol = match[3] ? parseFloat(match[3]) : 1.0;
                    const isMuted = line.includes("[MUTED]");
                    parsedSinks.push({ "id": id, "name": name, "isDefault": isDefault, "volume": vol, "muted": isMuted });
                }
            } else if (currentSection === "streams") {
                const normalized = line.replace("│", " ");
                const isStream = normalized.startsWith("        ") && !normalized.startsWith("         ");
                if (isStream) {
                    const match = normalized.match(/\s*(\d+)\.\s*([^\t\[\r\n]+)/);
                    if (match) {
                        const id = parseInt(match[1]);
                        const name = match[2].trim();
                        activeIds[id] = true;
                        
                        if (streamCache[id] === undefined) {
                            streamCache[id] = { "id": id, "name": name, "volume": 1.0, "muted": false, "sinkId": -1 };
                        }
                    }
                }
            }
        }
        
        // Clean up stale IDs from cache
        const cacheKeys = Object.keys(streamCache);
        for (let k = 0; k < cacheKeys.length; k++) {
            const kid = parseInt(cacheKeys[k]);
            if (!activeIds[kid]) {
                delete streamCache[kid];
            }
        }
        
        return parsedSinks;
    }

    function queryAllStreams(ids) {
        if (ids.length === 0) return;
        let cmd = "";
        for (let i = 0; i < ids.length; i++) {
            cmd += "echo STREAM_ID:" + ids[i] + " && wpctl inspect " + ids[i] + " && wpctl get-volume " + ids[i] + " ; ";
        }
        queryAllStreamsProc.command = ["sh", "-c", cmd];
        queryAllStreamsProc.running = true;
    }

    function parseAllStreamsOutput(text) {
        const sections = text.split("STREAM_ID:");
        for (let i = 1; i < sections.length; i++) {
            const sec = sections[i];
            const lines = sec.split("\n");
            if (lines.length === 0) continue;
            const id = parseInt(lines[0].trim());
            if (isNaN(id)) continue;
            
            const driverMatch = sec.match(/node\.driver-id\s*=\s*"(\d+)"/);
            const volMatch = sec.match(/Volume:\s*([0-9.]+)/);
            const isMuted = sec.includes("[MUTED]");
            const sinkId = driverMatch ? parseInt(driverMatch[1]) : -1;
            const vol = volMatch ? parseFloat(volMatch[1]) : 1.0;
            
            if (streamCache[id] !== undefined) {
                streamCache[id].volume = vol;
                streamCache[id].muted = isMuted;
                streamCache[id].sinkId = sinkId;
            }
        }
        
        // Force refresh of streams
        const parsedStreams = [];
        const currentKeys = Object.keys(streamCache);
        for (let k = 0; k < currentKeys.length; k++) {
            parsedStreams.push(streamCache[currentKeys[k]]);
        }
        streams = parsedStreams;
    }

    function refreshStatus() {
        if (!getStatusProc.running)
            getStatusProc.running = true
    }

    function pollVolume() {
        if (!getSink.running)
            getSink.running = true
        if (!getSource.running)
            getSource.running = true
    }

    // Fast volume polling timer for external keypresses / changes
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: pollVolume()
    }

    // Periodic device & stream structure discovery (every 3 seconds)
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: refreshStatus()
    }

    Timer {
        id: syncTimer
        interval: 80
        running: false
        repeat: false
        onTriggered: pollVolume()
    }

    Process {
        id: getStatusProc
        command: ["wpctl", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parsedSinks = parseWpctlStatus(text);
                root.sinks = parsedSinks;
                const activeKeys = Object.keys(root.streamCache);
                if (activeKeys.length > 0) {
                    root.queryAllStreams(activeKeys);
                } else {
                    root.streams = [];
                }
            }
        }
    }

    Process {
        id: getSink
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                const m = s.match(/Volume:\s*([0-9.]+)/)
                if (m) {
                    const v = parseFloat(m[1])
                    if (!isNaN(v)) {
                        root.ready = true
                        root.volume = Math.max(0, Math.min(1.5, v))
                    }
                }
                root.muted = /\[MUTED\]/.test(s)
            }
        }
    }

    Process {
        id: getSource
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                const m = s.match(/Volume:\s*([0-9.]+)/)
                if (m) {
                    const v = parseFloat(m[1])
                    if (!isNaN(v)) {
                        root.sourceReady = true
                        root.sourceVolume = Math.max(0, Math.min(1.5, v))
                    }
                }
                root.sourceMuted = /\[MUTED\]/.test(s)
            }
        }
    }

    function setVolume(newVolume) {
        const v = Math.max(0, Math.min(1.5, newVolume));
        root.ready = true;
        root.volume = v;
        root.muted = false;
        Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", v.toFixed(3)]);
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"]);
        syncTimer.restart();
    }

    function increaseVolume() {
        setVolume(Math.min(1.5, Math.round((volume + 0.05) * 100) / 100));
    }

    function decreaseVolume() {
        setVolume(Math.max(0, Math.round((volume - 0.05) * 100) / 100));
    }

    function setMute(m) {
        root.muted = m;
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", m ? "1" : "0"]);
        syncTimer.restart();
    }

    function toggleMute() {
        root.muted = !root.muted;
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
        syncTimer.restart();
    }

    function setSourceVolume(newVolume) {
        const v = Math.max(0, Math.min(1.5, newVolume));
        root.sourceReady = true;
        root.sourceVolume = v;
        root.sourceMuted = false;
        Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SOURCE@", v.toFixed(3)]);
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "0"]);
        syncTimer.restart();
    }

    function setSourceMute(m) {
        root.sourceMuted = m;
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", m ? "1" : "0"]);
        syncTimer.restart();
    }

    function toggleSourceMute() {
        root.sourceMuted = !root.sourceMuted;
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]);
        syncTimer.restart();
    }

    function setDefaultSink(id) {
        Quickshell.execDetached(["wpctl", "set-default", String(id)]);
        refreshTimer.restart();
    }

    function setNodeVolume(id, vol) {
        const v = Math.max(0, Math.min(1.5, vol));
        if (streamCache[id] !== undefined) {
            streamCache[id].volume = v;
            streamCache[id].muted = false;
            const parsedStreams = [];
            const currentKeys = Object.keys(streamCache);
            for (let k = 0; k < currentKeys.length; k++) {
                parsedStreams.push(streamCache[currentKeys[k]]);
            }
            streams = parsedStreams;
        }
        Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.5", String(id), v.toFixed(3)]);
        Quickshell.execDetached(["wpctl", "set-mute", String(id), "0"]);
        refreshTimer.restart();
    }

    function setNodeMute(id, mute) {
        if (streamCache[id] !== undefined) {
            streamCache[id].muted = mute;
            const parsedStreams = [];
            const currentKeys = Object.keys(streamCache);
            for (let k = 0; k < currentKeys.length; k++) {
                parsedStreams.push(streamCache[currentKeys[k]]);
            }
            streams = parsedStreams;
        }
        Quickshell.execDetached(["wpctl", "set-mute", String(id), mute ? "1" : "0"]);
        refreshTimer.restart();
    }

    function moveStream(streamId, sinkId) {
        Quickshell.execDetached(["pw-metadata", "-n", "default", String(streamId), "target.object", String(sinkId)]);
        refreshTimer.restart();
    }

    Timer {
        id: refreshTimer
        interval: 200
        running: false
        repeat: false
        onTriggered: refreshStatus()
    }

    Process {
        id: queryAllStreamsProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.parseAllStreamsOutput(text);
            }
        }
    }

    Component.onCompleted: {
        pollVolume();
        refreshStatus();
    }
}
