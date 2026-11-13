"""Exercise real CLI/module code with tiny DEBs and intercepted apt/curl/sudo.

No network, system package installation, services, or real home files are used.
"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class InstallationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='linux-togo-tests-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / 'mock-bin'
        self.bin.mkdir()
        self.log = self.root / 'operations.log'
        self.env = os.environ.copy()
        for key in list(self.env):
            if key.startswith(('LTG_', 'LINUX_TO_GO_')):
                del self.env[key]
        self.env.update(PATH=str(self.bin) + os.pathsep + self.env['PATH'],
                        LTG_LOG=str(self.log), LTG_TEST_OS_ID='ubuntu',
                        LTG_TEST_UBUNTU_VERSION='22.04', LTG_TEST_ARCH='amd64',
                        LTG_TEST_SKIP_COMMON='1', LTG_TEST_CLASH_PRESENT='1',
                        LTG_TEST_NOMACHINE_PRESENT='1', LTG_TEST_ROS2_PRESENT='1')
        self.command('sudo', 'exec "$@"')
        self.command('apt-get', '''printf 'apt %s\\n' "$*" >> "$LTG_LOG"
if [[ "${LTG_FAIL_APT:-0}" == 1 && "$1" == install ]]; then exit 42; fi''')
        self.command('curl', 'printf "unexpected network\\n" >> "$LTG_LOG"; exit 90')

    def command(self, name, body):
        path = self.bin / name
        path.write_text('#!/bin/bash\nset -eu\n' + body + '\n')
        path.chmod(0o755)

    def run_bash(self, code, **env):
        return subprocess.run(['bash', '-c', code], cwd=ROOT, env={**self.env, **env},
                              text=True, capture_output=True, timeout=10)

    def module(self, name, code, **env):
        return self.run_bash(f'set -Eeuo pipefail; source lib/common.sh; source lib/{name}.sh; {code}', **env)

    def operations(self):
        return self.log.read_text() if self.log.exists() else ''

    def deb(self, name='nomachine', version='9.7.3-1', arch='amd64'):
        directory = self.root / (name + '-' + arch + '-' + version)
        (directory / 'DEBIAN').mkdir(parents=True)
        (directory / 'DEBIAN/control').write_text(
            f'Package: {name}\nVersion: {version}\nArchitecture: {arch}\n'
            'Maintainer: Test <test@example.invalid>\nDescription: isolated test fixture\n')
        output = directory.with_suffix('.deb')
        subprocess.run(['dpkg-deb', '--build', str(directory), str(output)], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        return str(output)

    def test_bootstrap_and_cli_are_executable(self):
        self.assertTrue(os.access(ROOT / 'install.sh', os.X_OK))
        self.assertTrue(os.access(ROOT / 'bin/linux-to-go', os.X_OK))

    def test_installed_cli_uses_library_subdirectory(self):
        prefix = self.root / 'usr/local'
        (prefix / 'bin').mkdir(parents=True)
        shutil.copytree(ROOT / 'lib', prefix / 'lib/linux-to-go')
        shutil.copy2(ROOT / 'bin/linux-to-go', prefix / 'bin/linux-to-go')
        result = subprocess.run([str(prefix / 'bin/linux-to-go'), '--apps-only'],
                                env=self.env, text=True, capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Apps-only', result.stdout)
        self.assertFalse(self.operations())

    def test_apps_only_never_calls_ros_installation_or_environment_setup(self):
        library = self.root / 'lib'
        shutil.copytree(ROOT / 'lib', library)
        with (library / 'ros.sh').open('a') as out:
            out.write('\ninstall_requested_ros() { echo "ROS MUTATION" >> "$LTG_LOG"; return 99; }\n')
        result = self.run_bash('bin/linux-to-go --apps-only',
                               LINUX_TO_GO_LIB_DIR=str(library), LTG_TEST_ROS2_PRESENT='0')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.operations())

    def test_apps_only_installs_both_apps_from_valid_fixtures_without_touching_ros(self):
        library = self.root / 'lib'
        shutil.copytree(ROOT / 'lib', library)
        with (library / 'clash-verge.sh').open('a') as out:
            out.write('''
download_file() { cp "$LTG_TEST_CLASH_DEB" "$2"; }
clash_asset_sha256() { sha256sum "$LTG_TEST_CLASH_DEB" | awk '{print $1}'; }
''')
        with (library / 'ros.sh').open('a') as out:
            out.write('\ninstall_requested_ros() { echo "ROS MUTATION" >> "$LTG_LOG"; return 99; }\n')
        result = self.run_bash('bin/linux-to-go --apps-only',
            LINUX_TO_GO_LIB_DIR=str(library), LTG_TEST_CLASH_PRESENT='0',
            LTG_TEST_NOMACHINE_PRESENT='0', LTG_TEST_ROS2_PRESENT='1',
            LTG_TEST_CLASH_DEB=self.deb('clash-verge', '2.5.2'),
            LINUX_TO_GO_NOMACHINE_DEB=self.deb())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Linux To Go completed', result.stdout)
        self.assertEqual(self.operations().count('apt install '), 2)
        self.assertNotIn('ROS MUTATION', self.operations())
        self.assertNotIn('unexpected network', self.operations())

    def test_check_reports_missing_components_without_installation(self):
        result = self.run_bash('bin/linux-to-go --check', LTG_TEST_CLASH_PRESENT='0',
                               LTG_TEST_NOMACHINE_PRESENT='0', LTG_TEST_ROS2_PRESENT='0')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('not installed', result.stderr)
        self.assertFalse(self.operations())

    def test_unsupported_os_fails_before_changes(self):
        result = self.run_bash('bin/linux-to-go --apps-only', LTG_TEST_UBUNTU_VERSION='24.04')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.operations())

    def test_missing_amd64_nomachine_fails_before_clash_download(self):
        result = self.run_bash('bin/linux-to-go --apps-only', LTG_TEST_NOMACHINE_PRESENT='0', LTG_TEST_CLASH_PRESENT='0')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('LINUX_TO_GO_NOMACHINE_DEB', result.stderr)
        self.assertFalse(self.operations())

    def test_apps_only_dependencies_are_minimal_and_missing_only(self):
        result = self.run_bash('''set -Eeuo pipefail; source lib/common.sh
package_installed() { [[ "$1" == ca-certificates ]]; }
install_common_packages --apps-only''', LTG_TEST_SKIP_COMMON='0')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('curl', self.operations())
        self.assertNotIn('build-essential', self.operations())
        self.assertNotIn('ca-certificates', self.operations())
        self.assertIn('--no-install-recommends', self.operations())

    def test_missing_explicit_local_package_never_downloads_a_replacement(self):
        result = self.module('nomachine', 'LTG_ARCH=amd64; install_nomachine',
                             LTG_TEST_NOMACHINE_PRESENT='0', LINUX_TO_GO_NOMACHINE_DEB=str(self.root / 'missing.deb'))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('does not exist', result.stderr)
        self.assertFalse(self.operations())

    def test_wrong_package_or_architecture_cannot_reach_apt_even_in_if(self):
        for name, arch in [('nomachine', 'arm64'), ('unrelated-package', 'amd64')]:
            with self.subTest(name=name, arch=arch):
                result = self.module('nomachine', '''LTG_ARCH=amd64
if install_nomachine; then exit 91; else exit 0; fi''',
                    LTG_TEST_NOMACHINE_PRESENT='0', LINUX_TO_GO_NOMACHINE_DEB=self.deb(name=name, arch=arch))
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn('Wrong package', result.stderr)
                self.assertFalse(self.operations())

    def test_local_amd64_package_uses_apt_dependency_resolution(self):
        result = self.module('nomachine', 'LTG_ARCH=amd64; install_nomachine',
                             LTG_TEST_NOMACHINE_PRESENT='0', LINUX_TO_GO_NOMACHINE_DEB=self.deb())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('apt update', self.operations())
        self.assertIn('apt install -y --no-install-recommends', self.operations())
        self.assertNotIn('unexpected network', self.operations())

    def test_nomachine_apt_failure_never_reports_success(self):
        result = self.module('nomachine', '''LTG_ARCH=amd64
if install_nomachine; then exit 91; else exit 0; fi''',
            LTG_TEST_NOMACHINE_PRESENT='0', LINUX_TO_GO_NOMACHINE_DEB=self.deb(), LTG_FAIL_APT='1')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('[OK] NoMachine installed', result.stdout)

    def test_html_response_is_not_a_nomachine_deb(self):
        result = self.module('nomachine', '''download_file() { echo '<html>vendor homepage</html>' > "$2"; }
if _download_nomachine arm64 "$LTG_TEST_OUTPUT"; then exit 91; else exit 0; fi''',
                             LTG_TEST_OUTPUT=str(self.root / 'html.deb'))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Not a valid DEB', result.stderr)
        self.assertFalse(self.operations())

    def test_local_package_search_filters_by_architecture(self):
        packages = self.root / 'packages'
        packages.mkdir()
        (packages / 'nomachine_9.8.3_1_arm64.deb').touch()
        expected = packages / 'nomachine_9.7.3_1_amd64.deb'
        expected.touch()
        result = self.module('nomachine', 'find_nomachine_local_package amd64', LTG_NOMACHINE_PACKAGE_DIR=str(packages))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(expected))

    def test_clash_hash_mismatch_stops_before_apt(self):
        result = self.module('clash-verge', '''LTG_ARCH=amd64
download_file() { cp "$LTG_TEST_DEB" "$2"; }
if install_clash_verge; then exit 91; else exit 0; fi''',
            LTG_TEST_CLASH_PRESENT='0', LTG_TEST_DEB=self.deb('clash-verge', '2.5.2'))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('SHA-256 mismatch', result.stderr)
        self.assertFalse(self.operations())

    def test_clash_success_and_apt_failure_do_not_report_false_success(self):
        package = self.deb('clash-verge', '2.5.2')
        code = '''LTG_ARCH=amd64
download_file() { cp "$LTG_TEST_DEB" "$2"; }
clash_asset_sha256() { sha256sum "$LTG_TEST_DEB" | awk '{print $1}'; }
install_clash_verge'''
        result = self.module('clash-verge', code, LTG_TEST_CLASH_PRESENT='0', LTG_TEST_DEB=package)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('[OK] Clash Verge Rev 2.5.2 installed', result.stdout)
        result = self.module('clash-verge', code, LTG_TEST_CLASH_PRESENT='0', LTG_TEST_DEB=package, LTG_FAIL_APT='1')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('[OK] Clash Verge Rev 2.5.2 installed', result.stdout)

    def test_other_ros2_distribution_does_not_count_as_humble(self):
        for distro in ('jazzy', 'unknown'):
            with self.subTest(distro=distro):
                result = self.module('ros', '''package_installed() { return 1; }
command_exists() { [[ "$1" == ros2 ]]; }
detect_ros2''', LTG_ROS_ROOT=str(self.root / 'empty-ros-root'), ROS_DISTRO=distro,
                    LTG_TEST_ROS2_PRESENT='', LTG_TEST_DISABLE_COMMAND_DETECTION='0')
                self.assertNotEqual(result.returncode, 0)


if __name__ == '__main__':
    unittest.main()
