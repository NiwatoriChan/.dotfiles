# Actions System

The Actions system provides a dynamic, folder-based registry of system capabilities.
Every action lives in its own subdirectory inside this folder and is defined by an `action.json` manifest.

## How to add a new action

Create a new directory inside `~/.dotfiles/actions/`:
```bash
mkdir ~/.dotfiles/actions/my-action
```

Create `~/.dotfiles/actions/my-action/action.json`:
```json
{
  "id": "my-action",
  "name": "My Action",
  "description": "Short explanation of what it does",
  "icon": "󰘳",
  "keywords": ["tag1", "tag2"],
  "visible": true,
  "exec": ["notify-send", "Hello from action!"]
}
```

The action will be automatically discovered by Quickshell. You can trigger it from:
1. **Launcher**: Open launcher, type `!my-action` (or search for it in standard app search).
2. **Terminal / Keybindings**: Run `quickshell ipc call actions run my-action`.

---

## Manifest Schema (`action.json`)

| Field | Type | Default | Description |
|---|---|---|---|
| `id` | `string` | folder name | Unique identifier used for IPC and search |
| `name` | `string` | folder name | Display title in launcher |
| `description` | `string` | `""` | Subtitle / description in launcher |
| `icon` | `string` | `"󰘳"` | Nerd Font glyph or icon name |
| `keywords` | `string[]` | `[]` | Extra terms for fuzzy search in launcher |
| `visible` | `boolean` | `true` | Show in launcher search |
| `closeLauncher` | `boolean` | `true` | Automatically close launcher after executing |
| `order` | `number` | `100` | Sorting priority (lower numbers appear first) |
| `hosts` | `string[]` | `[]` | Limit action to specific hosts (e.g. `["potatomonster"]`) |
| `requires` | `string[]` | `[]` | Binaries required on PATH (action is disabled if missing) |

### Action Kinds (Choose exactly ONE)

#### 1. Command Execution (`exec`)
Runs an executable with arguments:
```json
{
  "exec": ["brightnessctl", "set", "+5%"]
}
```

#### 2. Shell Script (`script`)
Runs a script located inside the action folder:
```json
{
  "script": "toggle.sh",
  "args": ["--force"]
}
```

#### 3. Quickshell IPC (`ipc`)
Calls a Quickshell `IpcHandler` target:
```json
{
  "ipc": {
    "target": "dashboard",
    "function": "toggle"
  }
}
```

#### 4. Multi-Step Chaining (`steps`)
Executes multiple other actions sequentially with optional delay:
```json
{
  "steps": [
    "volume-mute",
    { "id": "toggle-controlcenter", "delayMs": 150 }
  ]
}
```

#### 5. Custom GUI (`gui`)
Opens an interactive QML component loaded dynamically into Quickshell's `ActionHost`:
```json
{
  "gui": "Gui.qml"
}
```

---

## Parameters (custom actions with arguments)

Declare `params` and reference them as `{name}` in `exec`, `script` `args`,
`ipc.args`, or a step's `args`. If a required param is missing, a GUI form opens
(with a file/folder browser) before the action runs.

```json
{
  "id": "compress",
  "name": "Compress",
  "params": [
    { "name": "path", "type": "file" },
    { "name": "format", "type": "choice", "choices": ["gz", "zst", "xz"] }
  ],
  "script": "compress.sh",
  "args": ["{path}", "{format}"]
}
```

| Param field | Default | Description |
|---|---|---|
| `name` | required | Identifier used as `{name}` |
| `label` | name | Form label |
| `type` | `text` | `text`, `file`, `directory`, `choice`, `number`, `bool` (`"true"`/`"false"`) |
| `default` | `""` | Initial value (first choice for `choice`) |
| `required` | `true` | Show the form if empty |
| `choices` | `[]` | Options for `choice` |
| `placeholder` | `""` | Hint text |
| `startDir` | `~` | Folder the browser opens in |
| `filter` | `[]` | Extensions shown for `file` (e.g. `["png","jpg"]`) |

GUI actions (`gui`) receive the values as the `args` property.

**Passing arguments**
- Launcher: `!compress ~/notes.txt zst` (positional; last param takes the rest),
  `!compress format=xz`, or `!compress :file` to pick that one in the GUI.
- IPC: `quickshell ipc call actions runWith compress '~/notes.txt zst'`
- Steps: `{ "id": "compress", "args": { "path": "{path}" } }`

---

## Dynamic State (Toggle Actions)

Actions can define a `state` block to reflect current status (e.g. Android running/stopped):
```json
{
  "state": {
    "exec": ["waydroid", "status"],
    "match": "RUNNING",
    "onName": "Stop Android Subsystem",
    "offName": "Start Android Subsystem",
    "onIcon": "󰀲",
    "offIcon": "󰀲"
  }
}
```
The state is checked asynchronously on launcher open and after action execution.
