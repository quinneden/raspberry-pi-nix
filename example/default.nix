{ config, inputs, lib, modulesPath, pkgs, ... }: {
  imports = [
    ../rpi
  ];
  system.stateVersion = "24.05";
  nixpkgs.hostPlatform = "aarch64-linux";
  # TODO: stop using overlays
  nixpkgs.overlays = [
    (import ../overlays { inherit inputs; })
    (import ../overlays/libcamera.nix { inherit inputs; })
  ];
  boot.kernelParams = [ "console=serial0,115200n8" "console=tty1" "console=ttyAMA0" ];
  boot.consoleLogLevel = 7;
  time.timeZone = "America/New_York";
  users.users.root.initialPassword = "root";
  networking = {
    hostName = "example";
    useDHCP = false;
    interfaces = {
      wlan0.useDHCP = true;
      eth0.useDHCP = true;
    };
  };
  raspberry-pi-nix = {
    board = "bcm2711";
    uboot.enable = true;
  };
  hardware = {
    raspberry-pi = {
      config = {
        all = {
          base-dt-params = {
            BOOT_UART = {
              value = 1;
              enable = true;
            };
            uart_2ndstage = {
              value = 1;
              enable = true;
            };
          };
          dt-overlays = {
            disable-bt = {
              enable = true;
              params = { };
            };
          };
        };
      };
    };
  };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  fileSystems = {
    # TODO: this should be /boot/firmware
    "/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
  };
  system.build.image = (import "${toString modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    format = "raw";
    partitionTableType = "efi";
    copyChannel = false;
    diskSize = "auto";
    additionalSpace = "64M";
    bootSize = "128M";
    touchEFIVars = false;
    installBootLoader = true;
    label = "nixos";
  });
}
