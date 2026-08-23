# Storage configuration for Jeff — RAID5 (EXP6), Torrent HDD, and Partage HDD
{ ... }:

{
  # Linux Software RAID (mdadm) support for the 3x4TB RAID5 array
  boot.swraid = {
    enable = true;
    mdadmConf = ''
      ARRAY /dev/md/EXP6 UUID=7cdf93d9:1c68ac95:28ad9c10:2f7388d5
    '';
  };

  fileSystems = {
    # RAID 5 Array (3x 4TB WD Red — jeff:EXP6)
    "/mnt/exp6" = {
      device = "/dev/md/EXP6";
      fsType = "ext4";
      options = [ "defaults" "nofail" ];
    };

    # Torrent HDD (1TB WD Green)
    "/mnt/torrent" = {
      device = "/dev/disk/by-uuid/35eb403e-7808-4037-971b-d5def2fdf9af";
      fsType = "ext4";
      options = [ "defaults" "nofail" ];
    };

    # Partage HDD (1TB WD Blue)
    "/mnt/partage" = {
      device = "/dev/disk/by-uuid/27ea7953-10f3-4011-926b-9e2047befda7";
      fsType = "ext4";
      options = [ "defaults" "nofail" ];
    };
  };
}
