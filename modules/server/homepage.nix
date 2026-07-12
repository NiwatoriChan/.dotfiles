# Homepage dashboard configuration
{ config, pkgs, ... }:

{
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;

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
        "Media Stack" = [
          {
            Jellyfin = {
              icon = "jellyfin.png";
              href = "http://localhost:8096";
              description = "Media Server";
              widget = {
                type = "jellyfin";
                url = "http://localhost:8096";
              };
            };
          }
          {
            Sonarr = {
              icon = "sonarr.png";
              href = "http://localhost:8989";
              description = "TV Show Downloader";
              widget = {
                type = "sonarr";
                url = "http://localhost:8989";
              };
            };
          }
          {
            Radarr = {
              icon = "radarr.png";
              href = "http://localhost:7878";
              description = "Movie Downloader";
              widget = {
                type = "radarr";
                url = "http://localhost:7878";
              };
            };
          }
          {
            Prowlarr = {
              icon = "prowlarr.png";
              href = "http://localhost:9696";
              description = "Torrent Indexer Manager";
              widget = {
                type = "prowlarr";
                url = "http://localhost:9696";
              };
            };
          }
          {
            Transmission = {
              icon = "transmission.png";
              href = "http://localhost:9091";
              description = "Torrent Downloader";
              widget = {
                type = "transmission";
                url = "http://localhost:9091";
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
