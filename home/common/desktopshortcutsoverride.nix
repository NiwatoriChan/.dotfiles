# Desktop shortcut overrides — rename or customise .desktop entries
{ ... }:

{
  xdg.desktopEntries = {
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
  };
}

