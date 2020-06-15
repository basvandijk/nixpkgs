{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.maas;

in {
  options = {
    maas = {
      baseImageSize = mkOption {
        type = types.int;
        default = 2048;
        description = ''
          The size of the MAAS base image in MiB.
        '';
      };
      imgDerivationName = mkOption {
        type = types.str;
        default = "nixos-maas-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
        description = ''
          The name of the derivation for the MAAS image.
        '';
      };
      imgFileName = mkOption {
        type = types.str;
        default = "nixos-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.tgz";
        description = ''
          The file name of the MAAS image.
        '';
      };
    };
  };

  config = {
    system.build.maasImage = import ../../lib/make-disk-image.nix {
      name = cfg.imgDerivationName;
      postVM = ''
        tar -cz -f $out/${cfg.imgFileName} -C $out nixos.img
        rm $diskImage
      '';
      format = "raw";
      diskSize = cfg.baseImageSize;
      partitionTableType = "efi";
      inherit config lib pkgs;
    };

    boot = {
      loader.grub = {
        version = 2;
        device = "nodev";
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
      growPartition = true;
    };

    fileSystems = {
      "/boot" = {
        device = "/dev/disk/by-label/ESP";
        fsType = "vfat";
      };
      "/" = {
        device = "/dev/disk/by-label/nixos";
        autoResize = true;
        fsType = "ext4";
      };
    };

    # TODO: we probably need to enable and configure cloud-init:
    #services.cloud-init = {
    #  enable = true;
    #  config = ''
    #    system_info:
    #      distro: nixos
    #    users:
    #       - root
    #
    #    disable_root: false
    #    preserve_hostname: false
    #
    #    cloud_init_modules:
    #     - migrator
    #     - seed_random
    #     - bootcmd
    #     - write-files
    #     - growpart
    #     - resizefs
    #     - update_etc_hosts
    #     - ca-certs
    #     - rsyslog
    #     - users-groups
    #
    #    cloud_config_modules:
    #     - disk_setup
    #     - mounts
    #     - ssh-import-id
    #     - set-passwords
    #     - timezone
    #     - disable-ec2-metadata
    #     - runcmd
    #     - ssh
    #
    #    cloud_final_modules:
    #     - rightscale_userdata
    #     - scripts-vendor
    #     - scripts-per-once
    #     - scripts-per-boot
    #     - scripts-per-instance
    #     - scripts-user
    #     - ssh-authkey-fingerprints
    #     - keys-to-console
    #     - phone-home
    #     - final-message
    #     - power-state-change
    #  '';
    #};
  };
}
