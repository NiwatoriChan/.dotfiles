# Desktop shortcut overrides — rename or customise .desktop entries
{ lib, osConfig ? null, ... }:

{
  xdg.desktopEntries = {
    # Force Gnome Disk Utility (Disks) to run as administrator/root and prompt for password
    "org.gnome.DiskUtility" = {
      name = "Disks";
      exec = "/home/niwatorichan/.local/bin/gnome-disks-admin";
      icon = "org.gnome.DiskUtility";
      comment = "Manage Drives and Media";
      terminal = false;
      categories = [ "GNOME" "GTK" "Utility" "X-GNOME-Utilities" ];
      settings = {
        DBusActivatable = "false";
      };
    };

    # Fuzzel application launcher desktop entry (needed for KWin/KDE global shortcuts)
    fuzzel = {
      name = "Fuzzel";
      exec = "fuzzel";
      icon = "fuzzel";
      comment = "Application Launcher";
      terminal = false;
      type = "Application";
      categories = [ "System" "Utility" ];
    };
  } // lib.optionalAttrs (osConfig == null || osConfig.networking.hostName != "PotatoMonster") {
    # Rename the native Discord client in app launchers
    discord = {
      name = "Native Discord";
      exec = "Discord";
      icon = "discord";
      terminal = false;
      type = "Application";
      categories = [ "Network" "InstantMessaging" ];
      mimeType = [ "x-scheme-handler/discord" ];
      startupNotify = false;
      settings.StartupWMClass = "discord";
    };
  };
}


