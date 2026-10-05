{
  description = ''
    RPI5 Sel4 firmware build
    Based on - https://docs.sel4.systems/Hardware/Rpi5.html
    '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    u-boot = {
      url = "github:u-boot/u-boot";
      flake = false;
    };
    raspberrypi-firmware = {
      url = "github:raspberrypi/firmware";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, u-boot, raspberrypi-firmware }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      rpi5 = import ./nix/rpi5.nix {
        inherit pkgs u-boot raspberrypi-firmware;
      };

    in {
      packages.${system} = {
        inherit (rpi5)
          rpi5-uboot
          rpi5-boot-files;

        default = rpi5.rpi5-boot-files;
      };
    };
}
