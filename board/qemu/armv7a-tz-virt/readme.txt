Board qemu_armv7a_tz_virt builds a Qemu Armv7-A target system with
OP-TEE running in the TrustZone secure wolrd setup and a Linux based
OS running in the non-secure wolrd. The board also builds the Qemu
host to run the Arm target emulation.

  make qemu_armv7a_tz_virt_defconfig
  make

BIOS used in the Qemu host is the Arm Trusted Firmware-A (TF-A). TF-A
uses Qemu semihosting file access to access boot image files. The
Qemu platform is quite specific for that in TF-A and one needs to
rename some image files and run the emulation from the image directory
for TF-A to boot the secure and non-secure world.

I.e:
  ln -s ./u-boot.bin output/images/bl33.bin
  ln -s ./tee-header_v2.bin output/images/bl32.bin
  ln -s ./tee-pager_v2.bin output/images/bl32_extra1.bin
  ln -s ./tee-pageable_v2.bin output/images/bl32_extra2.bin

Run the emulation from the output/images directory with:

  cd output/images && ../host/bin/qemu-system-arm \
	-machine virt -machine secure=on -cpu cortex-a15 \
	-smp 1 -s -m 1024 -d unimp \
	-serial stdio \
	-netdev user,id=vmnic -device virtio-net-device,netdev=vmnic \
	-semihosting-config enable,target=native \
	-bios bl1.bin

The boot stage traces (if any) followed by the login prompt will appear
in the terminal that started Qemu.

If you want to emulate more cores use "-smp {1|2|3|4}" to select the
number of cores.

Note "-netdev user,id=vmnic -device virtio-net-device,netdev=vmnic"
brings virtfs support for file sharing with the hosted Linux OS. Board
Linux configuration file for armv7a-tz-virt enables the requiredresources.
BR2_PACKAGE_HOST_QEMU_VIRTFS=y build Qemu with required resources.

Tested with QEMU 2.12.0

-- Boot Details --

TF-A is used as Qemu BIOS. Its BL1 image boots and load its BL2 image. In turn, this
image loads the OP-TEE secure world (Armv7-A BL32 stage) and the U-boot as non-secure
bootloader (BL33 stage).

The Qemu natively host and loads in RAM the Qemu Arm target device tree. OP-TEE reads
and modifes its content according to OP-TEE configuration.

Enable TF-A traces from LOG_LEVEL (I.e LOG_LEVEL=40) from
BR2_TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES.

-- OP-TEE Traces --

Secure boot stages and/or secure runtime services may use a serial link for
their traces.

The Arm Trusted Firmware outputs its traces on the Qemu standard (first)
serial  interface.

The OP-TEE OS uses the Qemu second serial interface.

To get the OP-TEE OS traces one shall append a second -serial argument after
-serial stdio in the Qemu command line. I.e the following enables 2 serial
consoles over telnet connections:

  cd output/images && ../host/bin/qemu-system-arm \
	-machine virt -machine secure=on -cpu cortex-a15 \
	-smp 1 -s -m 1024 -d unimp \
	-serial telnet:127.0.0.1:1235,server \
	-serial telnet:127.0.0.1:1236,server \
	-netdev user,id=vmnic -device virtio-net-device,netdev=vmnic \
	-semihosting-config enable,target=native \
	-bios bl1.bin

Qemu is now waiting for the telnet connection. From another shell, open a
telnet connection on the port for the U-boot and Linux consoles:
  telnet 127.0.0.1 1235

and again for the secure console
  telnet 127.0.0.1 1236

-- Using gdb --

One can debug the OP-TEE secure world using GDB through the Qemu host.

Details to clarify /TODO/
Qemu/GDB setup from https://github.com/OP-TEE/build/blob/master/docs/qemu.md#6-remote-debugging-of-normal-world-applications
Builds with BR2_ENABLE_DEBUG=y / BR2_PACKAGE_GDB=y / BR2_PACKAGE_HOST_GDB=y.
Run Qemu with -netdev user,hostfwd=tcp::12345-:12345.
