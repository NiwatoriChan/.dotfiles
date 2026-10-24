pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import "." as QsServices

// Actions Service
// ---------------------------------------------------------------------------
// Data-driven registry of "things the system can do".
// Every action is a folder in ~/.dotfiles/actions containing an action.json
// manifest (see ~/.dotfiles/actions/README.md for the schema).
//
// Kinds (exactly one per manifest):
//   exec   : ["cmd", "arg", ...]                 run a command
//   script : "file.sh"                           run a script inside the action folder
//   ipc    : { target, function, args? }         call a quickshell IpcHandler
//   steps  : ["id", { "id": "x", "delayMs": 200 }] run other actions in order
//   gui    : "Gui.qml"                           load a QML component in ActionHost
//
// Params: an optional "params" array declares arguments, referenced as {name}
// inside exec / script args / ipc args / gui. Missing required params open a
// form (ActionHost) with pickers (file, directory, choice, text, number, bool).
//   "params": [{ "name": "file", "type": "file", "label": "File" }]
//   "exec":   ["tar", "czf", "{file}.tar.gz", "{file}"]
//
// IPC:  quickshell ipc call actions run <id>
//       quickshell ipc call actions runWith <id> '<args>'   (positional / key=value)
//       quickshell ipc call actions list
//       quickshell ipc call actions reload
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string actionsDir: Quickshell.env("QS_ACTIONS_DIR") || `${home}/.dotfiles/actions`
    readonly property var kinds: ["exec", "script", "ipc", "steps", "gui"]

    property var actions: []          // all parsed actions (incl. hidden/unavailable)
    property var states: ({})         // id -> bool, for actions with a "state" block
    property string hostname: ""
    property bool loaded: false

    readonly property var availableActions: actions.filter(a => a.available)
    readonly property var visibleActions: availableActions.filter(a => a.visible)

    signal guiRequested(var action, var args)
    signal paramsRequested(var action, var values)
    signal actionRan(string id)

    // ---------------------------------------------------------------- lookup

    function get(id) {
        for (let i = 0; i < actions.length; ++i) {
            if (actions[i].id === id) return actions[i]
        }
        return null
    }

    function isOn(id) {
        return states[id] === true
    }

    function displayName(action) {
        if (!action) return ""
        const st = action.state
        if (st && states[action.id] !== undefined) {
            return states[action.id] ? (st.onName || action.name) : (st.offName || action.name)
        }
        return action.name
    }

    function displayIcon(action) {
        if (!action) return ""
        const st = action.state
        if (st && states[action.id] !== undefined) {
            return states[action.id] ? (st.onIcon || action.icon) : (st.offIcon || action.icon)
        }
        return action.icon
    }

    // Rank an action against a lowercase query. 0 = no match.
    function rank(action, q) {
        if (!q) return 1
        const name = displayName(action).toLowerCase()
        const base = action.name.toLowerCase()
        if (name === q || base === q || action.id === q) return 1000
        if (name.startsWith(q) || base.startsWith(q) || action.id.startsWith(q)) return 900
        if (action.keywords.some(k => k.startsWith(q))) return 750
        if (name.includes(q) || base.includes(q)) return 650
        if (action.keywords.some(k => k.includes(q)) || action.description.toLowerCase().includes(q)) return 500
        return 0
    }

    function search(query) {
        const q = (query || "").trim().toLowerCase()
        const scored = []
        for (const a of visibleActions) {
            const r = rank(a, q)
            if (r > 0) scored.push({ action: a, rank: r })
        }
        scored.sort((x, y) => (y.rank - x.rank) || (x.action.order - y.action.order) || x.action.name.localeCompare(y.action.name))
        return scored
    }

    // ----------------------------------------------------------------- run

    // values: optional object { paramName: value } (or an array of positional values).
    // If required params are missing the params form is opened instead of running.
    function run(id, values, _stack) {
        const action = get(id)
        if (!action) {
            QsServices.Logger.warn("Actions", `Unknown action '${id}'`)
            return false
        }
        if (!action.available) {
            QsServices.Logger.warn("Actions", `Action '${id}' is not available on this system`)
            return false
        }

        const stack = _stack || []
        if (stack.includes(id)) {
            QsServices.Logger.error("Actions", `Cycle detected: ${stack.concat([id]).join(" -> ")}`)
            return false
        }

        const vals = resolveValues(action, values)
        if (action.params.length && missingParams(action, vals).length) {
            root.paramsRequested(action, vals)
            return true
        }

        QsServices.Logger.debug("Actions", `Running '${id}' (${action.kind})`)
        const sub = arg => expand(arg, action, vals)

        switch (action.kind) {
        case "exec":
            Quickshell.execDetached({
                command: action.exec.map(sub),
                workingDirectory: action.dir
            })
            break
        case "script":
            Quickshell.execDetached({
                command: [`${action.dir}/${action.script}`, ...action.args.map(sub)],
                workingDirectory: action.dir
            })
            break
        case "ipc":
            Quickshell.execDetached(["quickshell", "ipc", "call", action.ipc.target, action.ipc.function, ...action.ipc.args.map(sub)])
            break
        case "steps":
            runSteps(action, stack.concat([id]), vals)
            break
        case "gui":
            root.guiRequested(action, vals)
            break
        }

        if (action.state) stateRefreshTimer.restart()
        root.actionRan(id)
        return true
    }

    // Run with a raw argument string: `file.txt`, `"my file" zstd`, `file=a.txt level=9`.
    // A bare `:` or `:name` token means "leave unset, ask me in the form".
    function runWith(id, argString) {
        const action = get(id)
        if (!action) return run(id)
        return run(id, parseArgs(action, argString))
    }

    function runSteps(action, stack, vals) {
        let delay = 0
        for (const step of action.steps) {
            delay += step.delayMs
            // Step args may reference this action's values via {name}
            const stepArgs = {}
            for (const k in step.args) stepArgs[k] = expand(step.args[k], action, vals)
            if (delay <= 0) {
                run(step.id, stepArgs, stack)
            } else {
                later(delay, () => run(step.id, stepArgs, stack))
            }
        }
    }

    // ---------------------------------------------------------------- params

    function resolveValues(action, values) {
        const out = {}
        for (const p of action.params) out[p.name] = p.default
        if (Array.isArray(values)) {
            action.params.forEach((p, i) => { if (values[i] !== undefined) out[p.name] = String(values[i]) })
        } else if (values && typeof values === "object") {
            for (const p of action.params) if (values[p.name] !== undefined) out[p.name] = String(values[p.name])
        }
        return out
    }

    function missingParams(action, vals) {
        return action.params.filter(p => p.required && p.type !== "bool" && !String(vals[p.name] ?? "").length)
    }

    function tokenize(s) {
        const out = []
        const re = /"((?:[^"\\]|\\.)*)"|'([^']*)'|(\S+)/g
        let m
        while ((m = re.exec(s || "")) !== null)
            out.push(m[1] !== undefined ? m[1].replace(/\\(.)/g, "$1") : (m[2] !== undefined ? m[2] : m[3]))
        return out
    }

    function parseArgs(action, argString) {
        const vals = {}
        const names = action.params.map(p => p.name)
        const tokens = tokenize(argString)
        let pos = 0
        for (let i = 0; i < tokens.length; ++i) {
            const t = tokens[i]
            const eq = t.indexOf("=")
            if (eq > 0 && names.includes(t.slice(0, eq))) {
                vals[t.slice(0, eq)] = t.slice(eq + 1)
                continue
            }
            if (pos >= names.length) break
            const name = names[pos++]
            if (t === ":" || t === `:${name}`) continue          // ask in form
            // last param swallows the remainder
            if (pos === names.length) {
                vals[name] = [t].concat(tokens.slice(i + 1).filter(x => !x.includes("=") || !names.includes(x.slice(0, x.indexOf("="))))).join(" ")
                break
            }
            vals[name] = t
        }
        return vals
    }

    // Human readable signature, e.g. "<file> [level]"
    function signature(action) {
        return action.params.map(p => p.required ? `<${p.name}>` : `[${p.name}]`).join(" ")
    }

    function later(ms, fn) {
        const t = Qt.createQmlObject("import QtQuick 6.10; Timer { repeat: false }", root)
        t.interval = ms
        t.triggered.connect(() => { fn(); t.destroy() })
        t.start()
    }

    function expand(arg, action, vals) {
        let s = String(arg)
        if (vals && action.params) {
            // whole-arg `:name` shorthand
            if (s.startsWith(":") && s.slice(1) in vals) s = `{${s.slice(1)}}`
            s = s.replace(/\{(\w+)\}/g, (m, n) => {
                if (!(n in vals)) return m
                let v = String(vals[n] ?? "")
                if (v === "~") v = root.home
                else if (v.startsWith("~/")) v = `${root.home}/${v.slice(2)}`
                return v
            })
        }
        if (s === "~") s = root.home
        else if (s.startsWith("~/")) s = `${root.home}/${s.slice(2)}`
        return s.replace(/\$\{?HOME\}?/g, root.home)
                .replace(/\$\{?ACTION_DIR\}?/g, action.dir)
                .replace(/\$\{?ACTIONS_DIR\}?/g, root.actionsDir)
    }

    // ---------------------------------------------------------------- load

    function reload() {
        if (scanProc.running) return
        scanProc.running = true
    }

    // Rescan manifests + refresh toggle states (called when the launcher opens).
    function refresh() {
        reload()
    }

    readonly property var paramTypes: ["text", "file", "directory", "choice", "number", "bool"]

    function normalizeParams(raw) {
        if (!Array.isArray(raw)) return []
        return raw.map(p => {
            if (typeof p === "string") p = { name: p }
            if (!p || !/^\w+$/.test(String(p.name || "")))
                throw new Error("each param needs a 'name' (letters, digits, _)")
            const type = paramTypes.includes(p.type) ? p.type : "text"
            const choices = Array.isArray(p.choices) ? p.choices.map(String) : []
            if (type === "choice" && !choices.length) throw new Error(`param '${p.name}': 'choice' needs 'choices'`)
            return {
                name: String(p.name),
                label: String(p.label || p.name),
                type: type,
                default: p.default !== undefined ? String(p.default) : (type === "choice" ? choices[0] : (type === "bool" ? "false" : "")),
                required: p.required !== false,
                choices: choices,
                placeholder: String(p.placeholder || ""),
                startDir: String(p.startDir || "~"),
                filter: Array.isArray(p.filter) ? p.filter.map(f => String(f).toLowerCase().replace(/^\./, "")) : []
            }
        })
    }

    function normalize(raw, dir) {
        if (typeof raw !== "object" || raw === null || Array.isArray(raw))
            throw new Error("manifest must be a JSON object")

        const folder = dir.slice(dir.lastIndexOf("/") + 1)
        const present = kinds.filter(k => raw[k] !== undefined)
        if (present.length !== 1)
            throw new Error(`expected exactly one of ${kinds.join("/")}, found ${present.length ? present.join(", ") : "none"}`)

        const kind = present[0]
        const a = {
            id: String(raw.id || folder),
            name: String(raw.name || folder),
            description: String(raw.description || ""),
            icon: String(raw.icon || "󰘳"),
            keywords: (Array.isArray(raw.keywords) ? raw.keywords : []).map(k => String(k).toLowerCase()),
            visible: raw.visible !== false,
            hosts: Array.isArray(raw.hosts) ? raw.hosts.map(String) : [],
            requires: Array.isArray(raw.requires) ? raw.requires.map(String) : [],
            closeLauncher: raw.closeLauncher !== false,
            order: Number(raw.order ?? 100),
            kind: kind,
            dir: dir,
            state: null,
            available: true,
            params: normalizeParams(raw.params)
        }

        switch (kind) {
        case "exec":
            if (!Array.isArray(raw.exec) || raw.exec.length === 0)
                throw new Error("'exec' must be a non-empty array")
            a.exec = raw.exec.map(String)
            break
        case "script":
            if (typeof raw.script !== "string" || !raw.script.length)
                throw new Error("'script' must be a file name")
            a.script = raw.script
            a.args = Array.isArray(raw.args) ? raw.args.map(String) : []
            break
        case "ipc":
            if (!raw.ipc || !raw.ipc.target || !raw.ipc.function)
                throw new Error("'ipc' needs 'target' and 'function'")
            a.ipc = {
                target: String(raw.ipc.target),
                function: String(raw.ipc.function),
                args: Array.isArray(raw.ipc.args) ? raw.ipc.args.map(String) : []
            }
            break
        case "steps":
            if (!Array.isArray(raw.steps) || raw.steps.length === 0)
                throw new Error("'steps' must be a non-empty array")
            a.steps = raw.steps.map(s => typeof s === "string"
                ? { id: s, delayMs: 0, args: {} }
                : { id: String(s.id), delayMs: Number(s.delayMs ?? 0), args: (s.args && typeof s.args === "object") ? s.args : {} })
            break
        case "gui":
            if (typeof raw.gui !== "string" || !raw.gui.length)
                throw new Error("'gui' must be a QML file name")
            a.gui = raw.gui
            a.guiUrl = `file://${dir}/${raw.gui}`
            break
        }

        if (raw.state) {
            if (!Array.isArray(raw.state.exec) || raw.state.exec.length === 0 || !raw.state.match)
                throw new Error("'state' needs 'exec' (array) and 'match' (regex)")
            a.state = {
                exec: raw.state.exec.map(String),
                match: String(raw.state.match),
                onName: raw.state.onName ? String(raw.state.onName) : "",
                offName: raw.state.offName ? String(raw.state.offName) : "",
                onIcon: raw.state.onIcon ? String(raw.state.onIcon) : "",
                offIcon: raw.state.offIcon ? String(raw.state.offIcon) : ""
            }
        }

        return a
    }

    function parseScan(text) {
        const chunks = text.split("\x1e")
        root.hostname = (chunks.shift() || "").trim()

        const list = []
        const seen = {}
        for (const chunk of chunks) {
            const sep = chunk.indexOf("\x1f")
            if (sep < 0) continue
            const dir = chunk.slice(0, sep)
            try {
                const action = normalize(JSON.parse(chunk.slice(sep + 1)), dir)
                if (seen[action.id]) {
                    QsServices.Logger.warn("Actions", `Duplicate id '${action.id}' in ${dir} (already defined in ${seen[action.id]}), skipping`)
                    continue
                }
                seen[action.id] = dir
                if (action.hosts.length && !action.hosts.includes(root.hostname)) action.available = false
                list.push(action)
            } catch (e) {
                QsServices.Logger.warn("Actions", `Skipping ${dir}/action.json: ${e?.message ?? e}`)
            }
        }
        list.sort((x, y) => (x.order - y.order) || x.name.localeCompare(y.name))

        // Resolve "requires" (binaries that must be on PATH) before publishing.
        const required = []
        for (const a of list) {
            for (const r of a.requires) if (!required.includes(r)) required.push(r)
        }
        if (required.length) {
            root._pending = list
            requiresProc.command = ["sh", "-c", 'for c in "$@"; do command -v "$c" >/dev/null 2>&1 && echo "$c"; done', "sh", ...required]
            requiresProc.running = true
        } else {
            publish(list)
        }
    }

    property var _pending: []

    function publish(list) {
        root.actions = list
        root.loaded = true
        QsServices.Logger.info("Actions", `Loaded ${list.length} actions (${list.filter(a => a.available).length} available) from ${root.actionsDir}`)
        refreshStates()
    }

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    function refreshStates() {
        if (stateProc.running) return
        const stateful = actions.filter(a => a.available && a.state)
        if (!stateful.length) return
        const lines = stateful.map(a =>
            `printf '\\036%s\\037' ${shellQuote(a.id)}; ${a.state.exec.map(arg => shellQuote(expand(arg, a))).join(" ")} 2>&1 || true`)
        stateProc.command = ["sh", "-c", lines.join("\n")]
        stateProc.running = true
    }

    Process {
        id: scanProc
        command: ["sh", "-c",
            'cat /etc/hostname 2>/dev/null || hostname 2>/dev/null; ' +
            'for f in "$1"/*/action.json; do [ -f "$f" ] || continue; printf "\\036%s\\037" "${f%/action.json}"; cat "$f"; done',
            "sh", root.actionsDir]
        stdout: StdioCollector {
            onStreamFinished: root.parseScan(text)
        }
    }

    Process {
        id: requiresProc
        stdout: StdioCollector {
            onStreamFinished: {
                const found = text.split("\n").map(s => s.trim()).filter(s => s.length)
                const list = root._pending
                for (const a of list) {
                    const missing = a.requires.filter(r => !found.includes(r))
                    if (missing.length) {
                        a.available = false
                        QsServices.Logger.debug("Actions", `'${a.id}' unavailable, missing: ${missing.join(", ")}`)
                    }
                }
                root._pending = []
                root.publish(list)
            }
        }
    }

    Process {
        id: stateProc
        stdout: StdioCollector {
            onStreamFinished: {
                const next = {}
                for (const chunk of text.split("\x1e")) {
                    const sep = chunk.indexOf("\x1f")
                    if (sep < 0) continue
                    const id = chunk.slice(0, sep)
                    const action = root.get(id)
                    if (!action || !action.state) continue
                    try {
                        next[id] = new RegExp(action.state.match, "m").test(chunk.slice(sep + 1))
                    } catch (e) {
                        QsServices.Logger.warn("Actions", `Bad state regex for '${id}': ${e?.message ?? e}`)
                    }
                }
                root.states = next
            }
        }
    }

    // Re-check toggle states shortly after a stateful action runs.
    Timer {
        id: stateRefreshTimer
        interval: 1500
        repeat: false
        onTriggered: root.refreshStates()
    }

    IpcHandler {
        target: "actions"

        function run(id: string): string {
            return root.run(id) ? "ok" : `failed: ${id}`
        }

        function runWith(id: string, args: string): string {
            return root.runWith(id, args) ? "ok" : `failed: ${id}`
        }

        function list(): string {
            return root.actions.map(a =>
                `${a.available ? (a.visible ? "+" : "-") : "x"} ${a.id.padEnd(24)} ${a.kind.padEnd(7)} ${root.displayName(a)}`
            ).join("\n")
        }

        function reload(): void {
            root.reload()
        }
    }

    Component.onCompleted: reload()
}
