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

  services.input-remapper = {
    enable = true;
    # Optional: enable udev rules for specific devices like controllers
    enableUdevRules = true;
  };

  # Udev rules for gaming controllers (PlayStation DS4/DualSense, Xbox, Nintendo, etc.)
  services.udev.packages = [ pkgs.game-devices-udev-rules ];

  # Allow input-remapper GUI to run helper via pkexec without password prompt
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id === "inputremapper" ||
           (action.id === "org.freedesktop.policykit.exec" &&
            action.lookup("program") &&
            action.lookup("program").indexOf("input-remapper-control") !== -1)) &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

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
