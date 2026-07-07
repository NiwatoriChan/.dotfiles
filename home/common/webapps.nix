{ pkgs, ... }:

let
  fetchFavicon = { name, url, sha256, faviconDomain ? null }:
    let
      sanitized = builtins.replaceStrings [ " " ] [ "-" ] name;
      domain =
        if faviconDomain != null
        then faviconDomain
        else builtins.head (builtins.match "https://([^/]+).*" url);
      rawIcon = pkgs.fetchurl {
        url = "https://www.google.com/s2/favicons?domain=${domain}&sz=256";
        name = "${sanitized}-favicon.png";
        inherit sha256;
      };
    in
    rawIcon;

  mkWebApp = { name, url, sha256, faviconDomain ? null }:
    let
      iconPath = fetchFavicon { inherit name url sha256 faviconDomain; };
    in
    {
      inherit name;
      # Use Helium since it is the installed browser on the system
      exec = "helium --start-maximized --app=${url}";
      icon = "${iconPath}";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
    };

  webApps = [
    {
      name = "Gemini";
      url = "https://gemini.google.com";
      sha256 = "sha256-AnTkjUvIjwDRpVScFrVR2yCFJg7nVosviKYgGYBjDc8=";
    }
    {
      name = "Messenger";
      url = "https://www.facebook.com/messages/";
      sha256 = "sha256-MlSBZ4hJknZLFP/r7ZBzzbM1YrUfzVriQC8mKuY1U8U=";
    }

  ];
in
{
  xdg.desktopEntries = builtins.listToAttrs (map (app: {
    name = app.name;
    value = mkWebApp app;
  }) webApps);
}
