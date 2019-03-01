Board qemu_aarch64_tz_virt builds a Qemu Armv8-A Aarch64 target system with
OP-TEE running in the TrustZone secure wolrd setup and a Linux based
OS running in the non-secure wolrd. The board also builds the Qemu
host to run the Arm target emulation.

  make qemu_aarch64_tz_virt_defconfig
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

  cd output/images && ../host/bin/qemu-system-aarch64 \
	-machine virt -machine secure=on -cpu cortex-a57 \
	-nographic -smp 1 \
	-serial stdio \
	-serial telnet:127.0.0.1:1235,server \
	-netdev user,id=eth0 -device virtio-net-device,netdev=eth0 \
	-semihosting-config enable,target=native \
	-bios bl1.bin

# -M virt
#-drive file=output/images/rootfs.ext4,if=none,format=raw,id=hd0
#-device virtio-blk-device,drive=hd0

Until BR arm-trusted-firmware is updated this board allows one to only
build the secure and non-secure boot images if not the BIOS for the Qemu
host.
