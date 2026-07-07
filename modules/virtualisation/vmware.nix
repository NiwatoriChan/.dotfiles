# VMware Workstation host virtualisation module
{ pkgs, ... }:

{
  # Enable VMware Workstation host support
  virtualisation.vmware.host.enable = true;
}
