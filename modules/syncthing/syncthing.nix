# Syncthing base daemon module — headless sync service
{ ... }:

{
  services.syncthing = {
    enable = true;
    user = "niwatorichan";
    dataDir = "/home/niwatorichan";
    configDir = "/home/niwatorichan/.config/syncthing";
    openDefaultPorts = true; # Open TCP/UDP 22000 (sync traffic) and UDP 21027 (discovery)

    # Don't delete folders/devices added manually through the GUI/Web UI
    overrideFolders = false;
    overrideDevices = false;

    settings.folders = {
      "SyncFolder" = {
        path = "/home/niwatorichan/SyncFolder";
        id = "SyncFolder";
        label = "SyncFolder";
      };
    };
  };
}