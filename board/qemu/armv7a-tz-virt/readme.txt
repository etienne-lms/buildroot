Board qemu_armv7a_tz_virt builds a Qemu Armv7-A target with
OP-TEE running in the TrustZone secure world setup and a Linux based
OS running in the non-secure world.

This setup is usually booted with the Arm Trsuted Firmware-A (TF-A from
package boot/arm-trusted-firmware). However the current Buildroot package
needs few changes to build TF-A for OP-TEE support.

Until BR arm-trusted-firmware is updated this board allows one to only
build the secure and non-secure boot images if not the BIOS for the Qemu
host.
