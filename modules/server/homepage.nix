# Homepage dashboard configuration
{ config, pkgs, ... }:

{
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    allowedHosts = "192.168.0.10, localhost,localhost:8082,127.0.0.1,127.0.0.1:8082,jeff.lan,jeff.lan:8082,jeff,jeff:8082";
    # Basic configuration settings
    settings = {

      title = "Server Dashboard";
      background = {
        image = "https://images.unsplash.com/photo-1579546929518-9e396f3cc809?auto=format&fit=crop&w=1920&q=80";
        opacity = 0.85;
      };
      theme = "dark";
      color = "zinc";
    };

    # Bookmark list
    bookmarks = [
      {
        Developer = [
          {
            GitHub = [
              {
                abbr = "GH";
                href = "https://github.com/";
              }
            ];
          }
        ];
      }
    ];

    # Header widgets
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      {
        datetime = {
          format = {
            date = "dddd, MMMM D";
            time = "h:mm A";
          };
        };
      }
    ];

    # Services list, grouped by categories
    services = [
      {
        "Media & Downloads" = [
          {
            Jellyfin = {
              icon = "jellyfin.png";
              href = "http://192.168.0.10:8096";
              description = "Media Streaming Server";
              widget = {
                type = "jellyfin";
                url = "http://127.0.0.1:8096";
              };
            };
          }
          {
            Transmission = {
              icon = "transmission.png";
              href = "http://192.168.0.10:9091";
              description = "Torrent Downloader";
              widget = {
                type = "transmission";
                url = "http://192.168.0.10:9091";
              };
            };
          }
        ];
      }
      {
        "Network Services" = [
          {
            Samba = {
              icon = "samba.png";
              href = "smb://localhost/private";
              description = "Samba File Share";
            };
          }
          {
            OpenVPN = {
              icon = "openvpn.png";
              description = "Virtual Private Network";
            };
          }
        ];
      }
    ];
  };
}
