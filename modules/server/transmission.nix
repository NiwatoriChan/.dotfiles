
{ pkgs, ... }: 
{


    services.transmission = { 
        enable = true; #Enable transmission daemon
        openRPCPort = true; #Open firewall for RPC
        settings = { #Override default settings
          rpc-bind-address = "[IP_ADDRESS]"; #Bind to own IP
         
         # 403 Forbidden Fixes
            rpc-whitelist-enabled = true;
            rpc-whitelist = "127.0.0.1,192.168.0.*,jeff.lan, [IP_ADDRESS]"; # Add jeff.lan to the whitelist
            rpc-host-whitelist-enabled = false;

            # Target Directories
            download-dir = "/mnt/torrent/Download/complete";
            incomplete-dir = "/mnt/torrent/Download/incomplete";
            incomplete-dir-enabled = true;
            watch-dir = "/mnt/torrent/Watch";
            watch-dir-enabled = true;

            # Sets created file permissions (002 in octal = 2 in decimal)
            umask = 2;

        };
        
        
  };

}

