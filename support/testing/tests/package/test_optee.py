import os

import infra.basetest

# This test enforces locally built emulator to prevent old Qemu to
# dump secure trace to stdio and corrupting trace synchro expected
# through pexpect.

class TestOptee(infra.basetest.BRTest):

    with open(os.path.join(os.getcwd(), 'configs',
                           'qemu_arm_vexpress_tz_defconfig'),
              'r') as config_file:
        config = "".join(line for line in config_file if line[:1] != '#') + \
                 """
                 BR2_PACKAGE_HOST_QEMU=y
                 BR2_PACKAGE_HOST_QEMU_SYSTEM_MODE=y
                 BR2_TOOLCHAIN_EXTERNAL=y
                 """
    config_emulator = ''

    def test_run(self):

        qemu_options = ['-machine', 'virt,secure=on']
        qemu_options.extend(['-cpu', 'cortex-a15'])
        qemu_options.extend(['-m', '1024'])
        qemu_options.extend(['-semihosting-config', 'enable,target=native'])
        qemu_options.extend(['-bios', 'bl1.bin'])

        # This test expects Qemu is run from the image direcotry
        os.chdir(os.path.join(self.builddir, 'images'))

        self.emulator.boot(arch='armv7', options=qemu_options, local=True)
        self.emulator.login()

        # Trick traces since xtest prints "# " which corrupts emulator run
        # method. Tests are dumped only if test fails.
        cmd = 'echo "Silent test takes a while, be patient..."; ' + \
              'xtest -t regression > /tmp/xtest.log ||' + \
              '(cat /tmp/xtest.log && false)'
        output, exit_code = self.emulator.run(cmd, timeout=240)
        self.assertEqual(exit_code, 0)
