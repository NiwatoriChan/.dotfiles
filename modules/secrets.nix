# Secrets management module utilizing Agenix
{ inputs, pkgs, ... }:

{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  # Install the agenix CLI tool so it is available globally
  environment.systemPackages = [
    inputs.agenix.packages.${pkgs.system}.default
  ];

  # Setup standard age decryption keys
  # (Defaults to /etc/ssh/ssh_host_ed25519_key and /etc/ssh/ssh_host_rsa_key)
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  # Example of declaring a secret:
  # age.secrets.example-secret = {
  #   file = ../secrets/example-secret.age;
  #   owner = "niwatorichan";
  #   group = "users";
  #   mode = "0400";
  # };
}
