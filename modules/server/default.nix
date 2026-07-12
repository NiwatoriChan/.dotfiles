# Server profile — entrypoint importing specific stack components
{ pkgs, ... }:

{
  imports = [
    ./nixarr.nix
    ./samba.nix
    ./homepage.nix
    ./openvpn.nix
    ./reverse-proxy.nix
    ../secrets.nix
  ];

  # --- System-Level (NixOS) Configuration ---

  # SSH daemon settings
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Firewall allowing SSH
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # Essential packages for headless/server environment
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
    jq
    bat
    fastfetch
  ];

  # --- User-Level (Home Manager) Configuration ---
  home-manager.users.niwatorichan = { ... }: {
    # Currently empty, placeholder for any user-level server configuration
  };
}
