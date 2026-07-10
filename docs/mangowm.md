# MangoWM Configuration

This page details the custom tiled window manager setup configured in `home/config/mango/config.conf`. Used on the **PotatoMonster** profile, this desktop uses the scroll-tiling behavior of **MangoWM**.

---

## 🥭 MangoWM Window Manager Settings

Managed in `home/config/mango/config.conf`, MangoWM handles tiling layout structures, window focus, trackpad gestures, and keybindings.

### 📐 Gaps & Visual Effects
- **Border Radius**: Curved corners set to `12px` to fit modern aesthetics.
- **Inner Gaps**: `4px` horizontal and vertical spacing between adjacent windows.
- **Outer Gaps**: `6px` padding between windows and screen borders.
- **Smart Gaps**: Disabled (`smartgaps=0`), keeping gaps even when only a single window is open on a workspace.
- **Window Blur**: High-quality frosted glass background blur enabled with optimized caching:
  - Radius: `6`
  - Passes: `2`

### 📜 Scroller Layout (Niri-Style Tiling)
MangoWM is set up to emulate Niri's signature scroller-tiling:
- Windows are organized into horizontal columns.
- **Layout rules**: The `scroller` layout is explicitly configured as the default for all workspaces (tags) 1 through 9. Layout structures are disabled (`scroller_structs = 0`).
- **Proportion rules**: 
  - Single windows open at `100%` width.
  - Subsequent windows open at `50%` width by default.
  - A sizing preset configures columns to cycle through `50%`, `80%`, and `100%` widths (`scroller_proportion_preset = 0.5,0.8,1.0`).

### 🪟 Custom Window Opacity Rules
Global windows have custom transparency thresholds, customized specifically for Dolphin and Zed:
- **Dolphin File Manager**: `85%` focused opacity, `75%` unfocused opacity.
- **Zed Editor**: `90%` focused opacity, `80%` unfocused opacity.

### 🎨 Qt & Dolphin Dark Mode
To ensure Qt applications (like Dolphin) open in Dark Mode under MangoWM (which has no built-in DE settings daemon), we map your shared KDE Plasma configuration files directly:
- **KDE Globals**: `~/.config/kdeglobals` is symlinked to `home/kde-config/kdeglobals` to apply the Breeze-Dark color palette.
- **Dolphin Config**: `~/.config/dolphinrc` is symlinked to `home/kde-config/dolphinrc` to preserve file manager specific settings.

---

## ⌨️ MangoWM Keybindings

The keyboard controls map to high-speed desktop navigation:

### General & Applications
- **Launch Fuzzel (App Search)**: `Super + Space`
- **Launch Kitty Terminal**: `Super + T`
- **Launch Firefox Browser**: `Super + B`
- **Reload Configuration**: `Super + R`
- **Kill Active Window**: `Super + X`
- **Toggle Fullscreen**: `Super + F`
- **Toggle Floating Status**: `Super + G`

### Window Navigation & Column Resizing
- **Switch Column Focus**: `Ctrl + Alt + Left` / `Right`
- **Move Window within Workspace**: `Ctrl + Alt + Shift + Left` / `Right`
- **Shift Workspace (Vertical Navigation)**: `Ctrl + Alt + Up` / `Down`
- **Move Window to Workspace**: `Ctrl + Alt + Shift + Up` / `Down`
- **Resize Window Width**: `Super + Shift + Left` / `Right`
- **Cycle Column Widths (50% / 80% / 100%)**: `Super + M`

### Gestures & Media
- **Trackpad (3-Finger Swipes)**: Focus left/right columns on horizontal swipe; change workspaces on vertical swipe.
- **Volume**: Media keys call `amixer` to toggle mute or alter volume levels in `5%` steps.
- **Backlight**: Brightness keys run `brightnessctl`.
- **Screenshots**:
  - `Print`: Region selection to copy to clipboard (`grim -g "$(slurp)" - | wl-copy`)
  - `Ctrl + Print`: Full monitor capture to clipboard (`grim - | wl-copy`)
  - `Alt + Print`: Focused window capture to clipboard (`grim` window capture)
