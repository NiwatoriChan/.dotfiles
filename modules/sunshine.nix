# Sunshine game streaming service configuration
{ pkgs, ... }:

{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  # Sunshine requires uinput permissions to emulate input devices.
  hardware.uinput.enable = true;
  users.users.niwatorichan.extraGroups = [ "uinput" ];
}
