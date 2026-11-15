"""System/ROS choices and backend integration, with no package mutations."""
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('installer_gui', ROOT / 'lib/installer_gui.py')
gui = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gui)


class WizardTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.path = Path(self.tmp.name)
        self.env = {k: v for k, v in os.environ.items() if not k.startswith(('LTG_', 'LINUX_TO_GO_'))}
        self.env.update(LTG_TEST_OS_ID='ubuntu', LTG_TEST_UBUNTU_VERSION='22.04',
                        LTG_TEST_ARCH='amd64', LTG_TEST_CLASH_PRESENT='0',
                        LTG_TEST_NOMACHINE_PRESENT='0', LTG_TEST_ROS1_PRESENT='0',
                        LTG_TEST_ROS2_PRESENT='0', LTG_TEST_DISABLE_COMMAND_DETECTION='1')

    def bash(self, code, **env):
        return subprocess.run(['bash', '-c', code], cwd=ROOT, env={**self.env, **env},
                              capture_output=True, text=True, timeout=10)

    def test_compatible_choices_and_existing_ros_default(self):
        for version, expected in [('20.04', 'ros1'), ('22.04', 'ros2'), ('24.04', 'ros2')]:
            status = dict(version=version, ros1='', ros2='')
            self.assertEqual(gui.initial_mode(status), expected)
            allowed = {key for key, label, enabled in gui.ros_choices(status) if enabled}
            self.assertEqual(allowed, {expected, '--apps-only'})
            status['ros2'] = 'jazzy'
            self.assertEqual(gui.initial_mode(status), '--apps-only')

    def test_ui_uses_argument_list_and_propagates_skips_and_dryrun(self):
        self.assertEqual(gui.install_args('/path with spaces/backend', 'ros2', False, True, True),
                         ['/path with spaces/backend', '--ros2', '--skip-clash', '--dry-run'])

    def test_ubuntu_architecture_dry_run_matrix(self):
        for version, mode in [('20.04', '--ros1'), ('22.04', '--ros2'), ('24.04', '--ros2')]:
            for arch in ('amd64', 'arm64'):
                with self.subTest(version=version, arch=arch):
                    extra = '--skip-clash' if version == '20.04' else ''
                    result = self.bash(f'bin/linux-to-go {mode} {extra} --dry-run',
                                       LTG_TEST_UBUNTU_VERSION=version, LTG_TEST_ARCH=arch)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertIn('no changes made', result.stdout)
                    self.assertIn(arch + '.deb', result.stdout)
                    if version == '24.04':
                        self.assertIn('jazzy', result.stdout)

    def test_incompatible_ros_rejected_before_any_install(self):
        for version, mode in [('20.04', '--ros2'), ('22.04', '--ros1'), ('24.04', '--ros1')]:
            r = self.bash(f'bin/linux-to-go {mode} --dry-run', LTG_TEST_UBUNTU_VERSION=version)
            self.assertNotEqual(r.returncode, 0)
            self.assertNotIn('[INSTALL]', r.stdout)

    def test_focal_clash_dependency_is_reported_before_changes(self):
        r = self.bash('bin/linux-to-go --ros1 --dry-run', LTG_TEST_UBUNTU_VERSION='20.04')
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('--skip-clash', r.stderr)
        self.assertNotIn('[INSTALL]', r.stdout)

    def test_missing_desktop_and_stdin_does_not_start_install(self):
        r = self.bash('bin/linux-to-go --auto', DISPLAY='', WAYLAND_DISPLAY='')
        self.assertNotEqual(r.returncode, 0)
        self.assertNotIn('[INSTALL]', r.stdout)

    def test_auto_with_existing_ros_skips_ros(self):
        r = self.bash('bin/linux-to-go --auto --dry-run', LTG_TEST_ROS2_PRESENT='1')
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('mode=--apps-only', r.stdout)

    def test_unsourced_ros_installations_and_both_generations(self):
        for distro in ['melodic', 'noetic', 'humble', 'jazzy']:
            p = self.path / distro
            p.mkdir()
            (p / 'setup.bash').touch()
        r = self.bash('source lib/common.sh; source lib/ros.sh; detect_ros1; echo "$LTG_DETECTED_ROS1_DISTRO"; detect_ros2; echo "$LTG_DETECTED_ROS2_DISTRO"',
                      LTG_ROS_ROOT=str(self.path), LTG_TEST_ROS1_PRESENT='', LTG_TEST_ROS2_PRESENT='')
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('melodic', r.stdout)
        self.assertIn('humble', r.stdout)

    def test_future_ros_distro_detected_from_environment_metadata(self):
        p = self.path / 'custom/share/ros_environment/environment'
        p.mkdir(parents=True)
        (self.path / 'custom/setup.bash').touch()
        (p / '1.ros_version.sh').write_text('export ROS_VERSION=2\n')
        r = self.bash('source lib/common.sh; source lib/ros.sh; detect_ros2; echo "$LTG_DETECTED_ROS2_DISTRO"',
                      LTG_ROS_ROOT=str(self.path), LTG_TEST_ROS2_PRESENT='')
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('custom', r.stdout)

    def test_ros_source_download_failure_prevents_apt(self):
        r = self.bash('''set -Eeuo pipefail
source lib/common.sh; source lib/ros.sh
LTG_UBUNTU_VERSION=22.04
download_file() { return 1; }
apt_install() { echo UNEXPECTED_APT; return 0; }
if install_ros_source ros2; then exit 99; else exit 0; fi''')
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertNotIn('UNEXPECTED_APT', r.stdout)

    def test_ros_happy_paths_initialize_rosdep_and_environment_after_install(self):
        for version, mode, distro in [('20.04', 'ros1', 'noetic'),
                                      ('22.04', 'ros2', 'humble'),
                                      ('24.04', 'ros2', 'jazzy')]:
            with self.subTest(version=version):
                p = self.path / distro
                p.mkdir()
                (p / 'setup.bash').touch()
                code = '''set -Eeuo pipefail
source lib/common.sh; source lib/system.sh; source lib/ros.sh
detect_system
apt_install() { echo "APT:$*"; }
run_as_root() { echo "ROOT:$*"; }
install_ros_source() { echo "SOURCE:$1"; }
setup_rosdep() { echo ROSDEP; }
_add_ros_env_line() { echo "BASHRC:$1"; }
install_ros_distribution "$LTG_TEST_MODE"
'''
                r = self.bash(code, LTG_TEST_UBUNTU_VERSION=version,
                              LTG_TEST_MODE=mode, LTG_ROS_ROOT=str(self.path))
                self.assertEqual(r.returncode, 0, r.stderr)
                package = 'desktop-full' if mode == 'ros1' else 'desktop'
                self.assertIn(f'ros-{distro}-{package}', r.stdout)
                self.assertIn('ROSDEP', r.stdout)
                self.assertIn('BASHRC:' + distro, r.stdout)
                self.assertLess(r.stdout.index('ROSDEP'), r.stdout.index('BASHRC:'))
                self.assertIn('[OK]', r.stdout)

    def test_failed_ros_package_install_never_configures_shell_or_reports_success(self):
        r = self.bash('''set -Eeuo pipefail
source lib/common.sh; source lib/system.sh; source lib/ros.sh
detect_system
apt_install() { [[ "$*" != *ros-humble-desktop* ]]; }
run_as_root() { return 0; }
install_ros_source() { return 0; }
_add_ros_env_line() { echo UNEXPECTED_SHELL_CHANGE; }
if install_ros_distribution ros2; then exit 99; else exit 0; fi''')
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertNotIn('UNEXPECTED_SHELL_CHANGE', r.stdout)
        self.assertNotIn('[OK]', r.stdout)


if __name__ == '__main__':
    unittest.main()
