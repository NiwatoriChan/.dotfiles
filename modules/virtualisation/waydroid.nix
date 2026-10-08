# Waydroid Android container configuration
{ pkgs, ... }:

{
  # Enable Waydroid container and networking
  virtualisation.waydroid.enable = true;

  # Avoid waydroid-container service crash loop on fresh boot before images are initialized
  systemd.services.waydroid-container = {
    unitConfig = {
      ConditionPathExists = "/var/lib/waydroid/images/system.img";
    };
  };

  # Ensure image directory and preinstalled search path exists
  systemd.tmpfiles.rules = [
    "d /var/lib/waydroid/images 0755 root root -"
    "L+ /etc/waydroid-extra/images - - - - /var/lib/waydroid/images"
  ];

  # Waydroid helper packages and convenience scripts
  environment.systemPackages = with pkgs; [
    waydroid-helper
    curl
    unzip
    jq

    # Robust script to initialize Waydroid with GAPPS
    # Resolves direct mirror endpoints via HEAD requests to bypass institutional SSL inspection firewalls (e.g. Fortinet)
    (writeShellScriptBin "waydroid-init-gapps" ''
      set -euo pipefail

      DEST_DIR="/var/lib/waydroid/images"
      TMP_DIR="/tmp/waydroid-download"

      resolve_direct_url() {
        local current="$1"
        for _ in {1..5}; do
          local next
          next=$(curl -k -s -I "$current" | grep -i "^location:" | awk '{print $2}' | tr -d '\r')
          if [ -z "$next" ]; then
            break
          fi
          current="$next"
        done
        echo "$current"
      }

      echo "==> Preparing Waydroid GAPPS installation..."
      sudo mkdir -p "$DEST_DIR" "$TMP_DIR" /etc/waydroid-extra
      sudo ln -sfn "$DEST_DIR" /etc/waydroid-extra/images

      if [ -f "$DEST_DIR/system.img" ] && [ -f "$DEST_DIR/vendor.img" ]; then
        echo "==> Images already exist in $DEST_DIR."
      else
        echo "==> Fetching latest OTA URLs..."
        SYSTEM_URL=$(curl -k -sL "https://ota.waydro.id/system/lineage/waydroid_x86_64/GAPPS.json" | ${pkgs.jq}/bin/jq -r '.response[0].url' 2>/dev/null || true)
        VENDOR_URL=$(curl -k -sL "https://ota.waydro.id/vendor/waydroid_x86_64/MAINLINE.json" | ${pkgs.jq}/bin/jq -r '.response[0].url' 2>/dev/null || true)

        if [ -z "$SYSTEM_URL" ] || [ "$SYSTEM_URL" = "null" ]; then
          SYSTEM_URL="https://sourceforge.net/projects/waydroid/files/images/system/lineage/waydroid_x86_64/lineage-20.0-20260927-GAPPS-waydroid_x86_64-system.zip/download"
        fi
        if [ -z "$VENDOR_URL" ] || [ "$VENDOR_URL" = "null" ]; then
          VENDOR_URL="https://sourceforge.net/projects/waydroid/files/images/vendor/waydroid_x86_64/lineage-20.0-20260927-MAINLINE-waydroid_x86_64-vendor.zip/download"
        fi

        echo "==> Resolving direct mirror URLs (bypassing firewall block on download portals)..."
        DIRECT_SYSTEM_URL=$(resolve_direct_url "$SYSTEM_URL")
        DIRECT_VENDOR_URL=$(resolve_direct_url "$VENDOR_URL")

        sudo rm -rf "$TMP_DIR"
        sudo mkdir -p "$TMP_DIR"

        echo "==> Downloading GAPPS system image (approx. 1.1 GB)..."
        sudo curl -k -L --progress-bar "$DIRECT_SYSTEM_URL" -o "$TMP_DIR/system.zip"

        echo "==> Downloading MAINLINE vendor image (approx. 190 MB)..."
        sudo curl -k -L --progress-bar "$DIRECT_VENDOR_URL" -o "$TMP_DIR/vendor.zip"

        echo "==> Extracting images to $DEST_DIR..."
        sudo ${pkgs.unzip}/bin/unzip -o -q "$TMP_DIR/system.zip" -d "$DEST_DIR"
        sudo ${pkgs.unzip}/bin/unzip -o -q "$TMP_DIR/vendor.zip" -d "$DEST_DIR"
        sudo rm -rf "$TMP_DIR"
      fi

      echo "==> Initializing Waydroid container..."
      sudo systemctl stop waydroid-container 2>/dev/null || true
      sudo waydroid init -f

      echo "==> Restarting Waydroid container service..."
      sudo systemctl restart waydroid-container

      echo "==> Waydroid initialized with GAPPS successfully!"
      echo "==> You can now run 'waydroid session start' or 'waydroid show-full-ui'."
    '')

    # Convenience script to fetch Google Services Framework (GSF) ID for Play Store certification
    (writeShellScriptBin "waydroid-get-android-id" ''
      echo "Retrieving Google Services Framework (GSF) Android ID for Play Store certification..."
      echo "Note: Waydroid must be running and Google Play Store opened at least once."
      echo ""
      ID=$(sudo waydroid shell 'sqlite3 /data/data/com.google.android.gsf/databases/gservices.db "select * from main where name = \"android_id\";"' 2>/dev/null | awk -F'|' '{print $2}')
      if [ -z "$ID" ]; then
        ID=$(sudo waydroid shell 'python3 -c "import sqlite3; con=sqlite3.connect(\"/data/data/com.google.android.gsf/databases/gservices.db\"); print(con.execute(\"select * from main where name=\\\"android_id\\\"\").fetchone()[1])"' 2>/dev/null || true)
      fi
      if [ -n "$ID" ]; then
        echo "Found Android ID: $ID"
        echo ""
        echo "Register your device at Google Play certification:"
        echo "https://www.google.com/android/uncertified/"
      else
        echo "Android ID not found yet."
        echo "Make sure you started Waydroid ('waydroid session start' or app launcher),"
        echo "opened the Play Store app once to trigger registration, and then re-run this command."
      fi
    '')
  ];
}
