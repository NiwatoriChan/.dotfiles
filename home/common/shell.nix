# Zsh configuration via home-manager
# Moved from the system-level programs.zsh in configuration.nix
{ config, pkgs, ... }:

{
  # Deploy p10k config to ~/.p10k.zsh
  home.file.".p10k.zsh".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/common/p10k.zsh";

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      edit = "sudo -e";
      update = "sudo nixos-rebuild switch";
      nu = "$HOME/.dotfiles/nu";
    };

    history = {
      size = 10000;
      path = "$HOME/.zsh_history";
      ignoreAllDups = true;
    };

    # Powerlevel10k prompt
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    # Source the p10k config
    initContent = ''
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
    '';
  };
}
