-- ==============================================================================
-- Hyprland Lua Configuration File
-- Ported from MangoWM configuration
-- Save to ~/.config/hypr/hyprland.lua
-- ==============================================================================

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "1920x1080@60",
    position = "auto",
    scale    = 1,
})

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "fuzzel"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function () 
    hl.exec_cmd("xhost +si:localuser:root")
    -- hl.exec_cmd("waybar")
    hl.exec_cmd("quickshell")  -- Waybar-style bar; swap with waybar above to try
    hl.exec_cmd("mako")
    hl.exec_cmd("wpaperd")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("wlsunset -t 4000 -T 4000")
    hl.exec_cmd("hyprctl setcursor breeze_cursors 24")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "breeze_cursors")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        -- Inner and outer gaps matching MangoWM setup
        gaps_in  = 0,
        gaps_out = 0,

        border_size = 2,

        col = {
            active_border   = "rgba(ffffff30)", -- Subtle premium active border
            inactive_border = "rgba(ffffff10)",
        },

        resize_on_border = false,
        allow_tearing = false,

        -- Using the native scrolling layout for Niri-like column behavior
        layout = "scrolling",
    },

    decoration = {
        rounding       = 12, -- Matches MangoWM border_radius
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        -- Frosted glass blur matching MangoWM settings (size 6, passes 2)
        blur = {
            enabled        = true,
            size           = 6,
            passes         = 2,
            vibrancy       = 0.1696,
            popups         = true,
            ignore_opacity = true,
        },
    },

    -- Native Scrolling Layout Configuration (equivalent to MangoWM scroller)
    scrolling = {
        fullscreen_on_one_column = true,
        column_width             = 0.5,
        focus_fit_method         = 1, -- fit into view
        follow_focus             = true,
        explicit_column_widths   = "0.5, 0.8, 1.0", -- Matches scroller_proportion_preset
        direction                = "right",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },

    -- ca layout from xkb_rules_layout=ca
    input = {
        kb_layout    = "ca",
        kb_variant   = "",
        kb_model     = "",
        kb_options   = "",
        kb_rules     = "",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

--------------------
---- ANIMATIONS ----
--------------------

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "slidevert" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "slidevert" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "slidevert" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Launchers
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(fileManager))

-- Window Actions
hl.bind(mainMod .. " + X", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + G", hl.dsp.window.float({ action = "toggle" }))

-- Column/Window Focus & Window Moving (Horizontal)
hl.bind("CTRL + ALT + left", hl.dsp.layout("move -col"))
hl.bind("CTRL + ALT + right", hl.dsp.layout("move +col"))
hl.bind("CTRL + ALT + SHIFT + left", hl.dsp.layout("swapcol l"))
hl.bind("CTRL + ALT + SHIFT + right", hl.dsp.layout("swapcol r"))

-- Sizing Preset Switch (Niri-style cycle between 50%, 80%, 100%)
hl.bind(mainMod .. " + M", hl.dsp.layout("colresize +conf"))

-- Window Resizing (Horizontal)
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.layout("colresize -0.05"))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.layout("colresize +0.05"))

-- Workspace Navigation (Vertical Emulation)
hl.bind("CTRL + ALT + up", hl.dsp.focus({ workspace = "-1" }))
hl.bind("CTRL + ALT + down", hl.dsp.focus({ workspace = "+1" }))
hl.bind("CTRL + ALT + SHIFT + up", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("CTRL + ALT + SHIFT + down", hl.dsp.window.move({ workspace = "+1" }))

-- Switching / Moving using numbers 1 to 10
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end

-- Mouse Bindings
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + ALT + mouse:272", hl.dsp.window.resize(), { mouse = true })

-- Hardware / Media Keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("amixer set Master 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("amixer set Master 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("amixer set Master toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set +5%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("grim - | wl-copy"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("grim -o $(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name') - | wl-copy"))

-- Lock / Switch to SDDM Greeter cleanly
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("dbus-send --system --type=method_call --print-reply --dest=org.freedesktop.DisplayManager /org/freedesktop/DisplayManager/Seat0 org.freedesktop.DisplayManager.Seat.SwitchToGreeter"))

-- Bluelight Filter Toggle
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("/home/niwatorichan/.config/waybar/scripts/wlsunset.sh toggle"))

-- Configuration Reload Bind
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("hyprctl reload"))

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Suppress Maximize Requests
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix dragging issues with XWayland
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- Blurry transparent overrides for target applications
hl.window_rule({
    name = "thunar-opacity",
    match = { class = "[Tt]hunar" },
    opacity = "0.85 0.75",
})

hl.window_rule({
    name = "zed-opacity",
    match = { class = "dev.zed.Zed" },
    opacity = "0.90 0.80",
})

hl.window_rule({
    name = "blueman-opacity",
    match = { class = "blueman-manager" },
    opacity = "0.85 0.75",
})

hl.window_rule({
    name = "blueman-float",
    match = { class = "^(blueman-manager)$" },
    float = true,
})

hl.window_rule({
    name = "nm-connection-editor-float",
    match = { class = "^(nm-connection-editor)$" },
    float = true,
})


hl.window_rule({
    name = "emacs-opacity-1",
    match = { class = "emacs" },
    opacity = "0.85 0.75",
})

hl.window_rule({
    name = "emacs-opacity-2",
    match = { class = "org.gnu.emacs" },
    opacity = "0.85 0.75",
})

hl.window_rule({
    name = "emacs-opacity-3",
    match = { class = "Emacs" },
    opacity = "0.85 0.75",
})

hl.window_rule({
    name = "opencode-opacity-1",
    match = { class = "opencode-desktop" },
    opacity = "0.85 0.75",
})

hl.window_rule({
    name = "opencode-opacity-2",
    match = { class = "OpenCode" },
    opacity = "0.85 0.75",
})

hl.window_rule({
    name = "wofi-opacity",
    match = { class = "wofi" },
    opacity = "0.85 0.75",
})

-- Float and center the "About This System" fastfetch terminal
hl.window_rule({
    name = "nixos-about-float",
    match = { class = "nixos-about" },
    float = true,
    size = "1000 600",
    center = true,
})

hl.window_rule({
    name = "nixos-about-opacity",
    match = { class = "nixos-about" },
    opacity = "0.90 0.85",
})

hl.window_rule({
    name  = "quickshell-float",
    match = { class = "^(quickshell)$" },
    float = true,
})

hl.window_rule({
    name  = "quickshell-noblur",
    match = { class = "^(quickshell)$", title = "^(quickshell)$" },
    no_blur = true,
})

---------------------
---- LAYER RULES ----
---------------------

-- Frosted glass blur applied to waybar, fuzzel, and mako background layers
hl.layer_rule({
    name  = "blur-waybar",
    match = { namespace = "waybar" },
    blur  = true,
})

hl.layer_rule({
    name  = "blur-quickshell",
    match = { namespace = "^(quickshell.*)$" },
    blur  = true,
    ignore_alpha = 0.3,
})

hl.layer_rule({
    name  = "blur-fuzzel",
    match = { namespace = "^(fuzzel|launcher)$" },
    blur  = true,
    ignore_alpha = 0.01,
})

hl.layer_rule({
    name  = "blur-mako",
    match = { namespace = "mako" },
    blur  = true,
})

hl.layer_rule({
    name  = "blur-wofi",
    match = { namespace = "wofi" },
    blur  = true,
    ignore_alpha = 0.5,
})
