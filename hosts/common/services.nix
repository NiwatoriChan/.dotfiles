# Shared services — audio, printing, bluetooth, display manager, flatpak
{ pkgs, ... }:

{
  # SDDM Display Manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    extraPackages = with pkgs; [
      sddm-astronaut
    ];
  };

  # Audio — PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Printing
  services.printing.enable = true;

  # Flatpak
  services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  # Virtual Filesystem & Thumbnail support for Thunar
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # KDE Connect (enables service & opens firewall TCP/UDP ports 1714-1764)
  programs.kdeconnect.enable = true;
}

