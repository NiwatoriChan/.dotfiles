
{ pkgs, ... }: 
{


    services.transmission = { 
        enable = true; #Enable transmission daemon
        openRPCPort = true; #Open firewall for RPC
        settings = { #Override default settings
          rpc-bind-address = "192.168.0.10"; #Bind to own IP
          #rpc-whitelist = "[IP_ADDRESS]"; #Whitelist your remote machine (10.0.0.1 in this example)
        };
  };

}

