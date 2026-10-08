# seL4 based hypervisor on RPI5

Because [RPI5 SoC does not seem to feature a secure memory controller](https://github.com/ARM-software/arm-trusted-firmware/blob/master/docs/plat/rpi5.rst?plain=1#L10-L13)
this is an research on using [seL4](https://sel4.systems/) for achieving separation of normal/secure world

[seL4 on RPI5 documentation](https://docs.sel4.systems/Hardware/Rpi5.html)

## Build / development

### Build

```sh
nix build .#<target>
```

### Getting buildInputs for testing

```sh
nix develop .#<target>
```
