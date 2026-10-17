{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, makeWrapper
, gtk3
, webkitgtk_4_1
, glib
, libsoup_3
, cairo
, gdk-pixbuf
, dbus
, wayland
}:

let
  pname = "rclone-manager";
  version = "0.3.3";

  sources = {
    x86_64-linux = {
      url = "https://github.com/Zarestia-Dev/rclone-manager/releases/download/v${version}/RClone.Manager_${version}_amd64.deb";
      hash = "sha256-1dlirLxMp3yvGI7WjUdKbA5AF+doAUXVCxyNdWYpPnQ=";
    };
    aarch64-linux = {
      url = "https://github.com/Zarestia-Dev/rclone-manager/releases/download/v${version}/RClone.Manager_${version}_arm64.deb";
      hash = "sha256-tvP5/eQcA0OM5JPJD/cRORxnqGvbOhI7zu8ZcfnqPCs=";
    };
  };
in
stdenv.mkDerivation rec {
  inherit pname version;

  src = fetchurl (sources.${stdenv.hostPlatform.system} or (throw "Unsupported architecture: ${stdenv.hostPlatform.system}"));

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    gtk3
    webkitgtk_4_1
    glib
    libsoup_3
    cairo
    gdk-pixbuf
    dbus
    wayland
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir -p $out
    cp -r usr/* $out/
  '';

  meta = with lib; {
    description = "Desktop GUI for Rclone";
    homepage = "https://github.com/Zarestia-Dev/rclone-manager";
    license = licenses.gpl3Plus;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "rclone-manager";
  };
}
