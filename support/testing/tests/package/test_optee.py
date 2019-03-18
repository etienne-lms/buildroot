import os

import infra.basetest


class TestOptee(infra.basetest.BRTest):

    with open(os.path.join(os.getcwd(), 'configs/qemu_armv7a_tz_virt_defconfig'), 'r') as config_file:
        config = "".join(line for line in config_file if line[:1]!='#') + \
                """
                BR2_TOOLCHAIN_EXTERNAL=y
                """

    def test_run(self):
        qemu_options = ['-machine', 'virt,secure=on']
        qemu_options.extend(['-cpu', 'cortex-a15'])
        qemu_options.extend(['-m', '1024'])
        qemu_options.extend(['-semihosting-config', 'enable,target=native'])
        qemu_options.extend(['-bios', 'bl1.bin'])

        # Prepare env for Qemu/armv7a to find the boot images
        os.chdir(os.path.join(self.builddir, 'images'))
        if not os.path.exists('bl33.bin'):
            os.symlink('u-boot.bin', 'bl33.bin')
        if not os.path.exists('bl32.bin'):
            os.symlink('tee-header_v2.bin', 'bl32.bin')
        if not os.path.exists('bl32_extra1.bin'):
            os.symlink('tee-pager_v2.bin', 'bl32_extra1.bin')
        if not os.path.exists('bl32_extra2.bin'):
            os.symlink('tee-pageable_v2.bin', 'bl32_extra2.bin')

        self.emulator.boot(arch='armv7', options=qemu_options)
        self.emulator.login()

        # Trick test trace since it prints "# " and corrupts emulator run method
        # Print test trace only if test fails.
        cmd = 'echo "Silent test while a while, be patient..."; ' + \
              'xtest -t regression > /tmp/xtest.log || (cat /tmp/xtest.log && false)'
        output, exit_code = self.emulator.run(cmd, timeout=240)
        self.assertEqual(exit_code, 0)
