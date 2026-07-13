# Shared Waybar configuration — imported by MangoWM and Hyprland profiles
{ config, lib, pkgs, ... }:

with lib;

{
  options.programs.waybar.custom = {
    modules-left = mkOption {
      type = types.listOf types.str;
      description = "Waybar left modules list";
    };
    extraSettings = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra settings to merge into the main configuration block";
    };
  };

  config = {
    programs.waybar = {
      enable = true;
      settings = [
        ({
          layer = "top";
          position = "top";
          height = 36;
          modules-left = [ "custom/nixos" ] ++ config.programs.waybar.custom.modules-left ++ [ "wlr/taskbar" ];
          modules-center = [ "clock" "mpris" ];
          modules-right = [ "custom/bluelight" "pulseaudio" "cpu" "memory" "battery" "tray" ];

          "custom/bluelight" = {
            format = "{}";
            tooltip = true;
            interval = 2;
            exec = "${config.home.homeDirectory}/.config/waybar/scripts/wlsunset.sh status";
            on-click = "${config.home.homeDirectory}/.config/waybar/scripts/wlsunset.sh toggle";
            return-type = "json";
          };

          "custom/nixos" = {
            format = "";
            tooltip = false;
            on-click = "${config.home.homeDirectory}/.config/waybar/scripts/power-menu.sh";
          };

          "wlr/taskbar" = {
            format = "{icon}";
            on-click = "activate";
            icon-theme = "Papirus-Dark";
            icon-size = 18;
          };

          clock = {
            format = "   {:%d-%m-%Y   %H:%M}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };

          mpris = {
            format = "{status_icon} {artist} - {title}";
            format-paused = "{status_icon} <i>{artist} - {title}</i>";
            status-icons = {
              playing = "";
              paused = "";
            };
            max-length = 35;
          };

          cpu = {
            format = "   {usage}%";
            interval = 2;
          };

          memory = {
            format = "   {percentage}%";
            interval = 2;
          };

          pulseaudio = {
            format = "   {volume}%";
            format-muted = "   Muted";
            on-click = "pwvucontrol";
          };

          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon}  {capacity}%";
            format-charging = "  {capacity}%";
            format-plugged = "  {capacity}%";
            format-full = "  Full";
            format-icons = [ "" "" "" "" "" ];
            tooltip-format-charging = "Charging: {capacity}% — {timeTo}";
            tooltip-format-discharging = "Discharging: {capacity}% — {timeTo}";
            tooltip-format-full = "Fully charged";
            tooltip-format-plugged = "Plugged in: {capacity}%";
          };

          tray = {
            icon-size = 16;
            spacing = 10;
          };
        } // config.programs.waybar.custom.extraSettings)
      ];
      style = ''
        * {
            font-family: "Inter Variable", "Font Awesome 6 Free", "Font Awesome 5 Free", "Symbols Nerd Font", sans-serif;
            font-size: 13px;
            font-weight: 600;
        }

        window#waybar {
            background-color: rgba(18, 18, 18, 0.65);
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
            color: #e2e8f0;
            box-shadow: 0 4px 30px rgba(0, 0, 0, 0.3);
        }

        #workspaces button, #tags button {
            padding: 0 10px;
            color: rgba(255, 255, 255, 0.4);
            background-color: transparent;
            border: none;
            transition: all 0.2s ease-in-out;
        }

        #workspaces button.active, #tags button.focused {
            color: #ffffff;
            background-color: transparent;
            font-weight: bold;
        }

        #workspaces button.urgent, #tags button.urgent {
            color: #ff5555;
            font-weight: bold;
        }

        #workspaces button:hover, #tags button:hover {
            background-color: rgba(255, 255, 255, 0.1);
            color: #ffffff;
            border-radius: 6px;
        }

        #custom-nixos {
            background-color: transparent;
            border: none;
            padding: 2px 10px;
            margin: 4px 3px;
            color: #7ebae4;
            font-size: 18px;
            transition: all 0.3s ease;
        }

        #custom-nixos:hover {
            color: #a8d4f2;
        }

        #clock, #cpu, #memory, #pulseaudio, #battery, #tray, #custom-bluelight, #mpris {
            background-color: transparent;
            border: none;
            padding: 2px 12px;
            margin: 4px 3px;
            color: #f1f5f9;
            transition: all 0.3s ease;
        }

        #custom-bluelight.on {
            color: #fdba74;
        }

        #clock {
            color: #c084fc;
        }

        #mpris {
            color: #a78bfa;
        }

        #cpu {
            color: #fda4af;
        }

        #memory {
            color: #93c5fd;
        }

        #pulseaudio {
            color: #fde047;
        }

        #battery , #battery.full {
            color: #6ee7b7;
        }

        #battery.charging, #battery.plugged {
            color: #fde047;
        }

        #battery.warning {
            color: #fdba74;
        }

        #battery.critical {
            color: #fca5a5;
        }

        #tray {
            background-color: transparent;
            border: none;
        }

        #taskbar button {
            padding: 0 8px;
            margin: 4px 2px;
            border-radius: 6px;
            background-color: transparent;
            border: none;
            transition: all 0.2s ease;
        }

        #taskbar button.active {
            background-color: rgba(255, 255, 255, 0.15);
            border: 1px solid rgba(255, 255, 255, 0.1);
        }

        #taskbar button:hover {
            background-color: rgba(255, 255, 255, 0.25);
        }
      '';
    };
  };
}
