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
      # Developed on x86
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
      };

      crossPkgs = pkgs.pkgsCross.aarch64-multiplatform;

      criticalConfigTxt = pkgs.writeText "config.txt" ''
        # Specified by Sel4 documentation, required to boot
        arm_64bit=1
        kernel=u-boot.bin
      '';

      rpiConfigTxt = pkgs.writeText "config.txt" ''
        # Raspberry Pi configuration
      '';

      # The cross compiler used by U-Boot
      # We change the `aarch64-linux-gnu` from docs to `aarch64-unknown-linux-gnu-` as its what nixpkgs provide
      crossPrefix = "aarch64-unknown-linux-gnu-";

      rpi5-uboot = pkgs.stdenv.mkDerivation {
        pname = "rpi5-uboot";
        version = "dev";

        src = u-boot;

        nativeBuildInputs = [
          # Host tools
          pkgs.gnumake
          pkgs.bison
          pkgs.flex
          pkgs.openssl
          pkgs.gnutls
          pkgs.perl

          # Cross compiler
          crossPkgs.stdenv.cc
        ];

        postPatch = ''
          patchShebangs .
        '';

        buildPhase = ''
          make CROSS_COMPILE=${crossPrefix} rpi_arm64_defconfig
          make CROSS_COMPILE=${crossPrefix} -j$NIX_BUILD_CORES
        '';

        installPhase = ''
          mkdir -p $out
          cp u-boot $out/
        '';
      };

      sdcard-populate = pkgs.stdenv.mkDerivation {
        pname = "sdcard-filesystem";
        version = "dev";

        src = raspberrypi-firmware;

        installPhase = ''
          mkdir -p $out
          cp boot/start4.elf $out/start4.elf
          cp boot/fixup4.dat $out/fixup4.dat
          cp boot/bcm2712-rpi-5-b.dtb $out/bcm2712-rpi-5-b.dtb
          cp -r boot/overlays $out/overlays/

          cat ${rpiConfigTxt} \
            ${criticalConfigTxt} \
            > $out/config.txt

          cp ${rpi5-uboot}/u-boot $out/u-boot.bin
        '';
      };
    in {
      packages.${system} = {
        inherit rpi5-uboot sdcard-populate;
        default = sdcard-populate;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          rpi5-uboot.nativeBuildInputs
        ];
      };
    };
}
