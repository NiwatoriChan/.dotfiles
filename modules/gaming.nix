# Gaming system profile — Steam, Lutris, and Heroic
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    lutris
    heroic
    mangohud
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  # Feral Interactive GameMode daemon & wrapper
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        softrealtime = "auto";
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'GameMode activated' -i input-gaming";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'GameMode deactivated' -i input-gaming";
      };
    };
  };

  # Allow user niwatorichan to set CPU scaling governor without password prompt (for Quickshell)
  security.sudo.extraRules = [
    {
      users = [ "niwatorichan" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
