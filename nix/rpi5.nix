{ pkgs, u-boot, raspberrypi-firmware }:

let
  crossPkgs = pkgs.pkgsCross.aarch64-multiplatform;

  # The cross compiler used by U-Boot
  # We change the `aarch64-linux-gnu` from docs to `aarch64-unknown-linux-gnu-` as its what nixpkgs provide
  crossPrefix = "aarch64-unknown-linux-gnu-";

  criticalConfigTxt = pkgs.writeText "critical-config.txt" ''
    # Specified by seL4 documentation, required to boot
    arm_64bit=1
    kernel=u-boot.bin
  '';

  rpiConfigTxt = pkgs.writeText "rpi-config.txt" ''
    # Raspberry Pi configuration
  '';

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

      # Cross Compiler
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
      cp u-boot $out/u-boot
    '';
  };

  rpi5-boot-files = pkgs.stdenv.mkDerivation {
    pname = "rpi5-boot-files";
    version = "dev";

    src = raspberrypi-firmware;

    installPhase = ''
      mkdir -p $out

      cp boot/start4.elf $out/
      cp boot/fixup4.dat $out/
      cp boot/bcm2712-rpi-5-b.dtb $out/
      cp -r boot/overlays $out/

      cat ${rpiConfigTxt} \
          ${criticalConfigTxt} \
          > $out/config.txt

      cp ${rpi5-uboot}/u-boot $out/u-boot.bin
    '';
  };
in
{
  inherit rpi5-uboot rpi5-boot-files;
}
