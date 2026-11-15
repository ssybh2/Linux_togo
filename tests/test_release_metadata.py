"""Optional real DEB audit. Run with LTG_RELEASE_AUDIT_DIR pointing to downloads."""
import os
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(os.environ.get('LTG_RELEASE_AUDIT_DIR'), 'real release downloads not configured')
class ReleaseMetadataTests(unittest.TestCase):
    def test_downloaded_app_and_ros_source_hashes_and_metadata(self):
        directory = Path(os.environ['LTG_RELEASE_AUDIT_DIR'])
        for arch in ['amd64', 'arm64']:
            for module, prefix, package in [('clash-verge', 'clash', 'clash-verge'),
                                             ('nomachine', 'nomachine', 'nomachine')]:
                with self.subTest(arch=arch, package=package):
                    code = f'''set -Eeuo pipefail
source lib/common.sh; source lib/{module}.sh
asset="$({prefix}_asset_name {arch})"
verify_sha256 "$LTG_RELEASE_AUDIT_DIR/$asset" "$({prefix}_asset_sha256 {arch})"
validate_deb_package "$LTG_RELEASE_AUDIT_DIR/$asset" {package} {arch}
'''
                    r = subprocess.run(['bash', '-c', code], cwd=ROOT, capture_output=True, text=True)
                    self.assertEqual(r.returncode, 0, r.stderr)
        for version, mode in [('20.04', 'ros1'), ('22.04', 'ros2'), ('24.04', 'ros2')]:
            code = f'''set -Eeuo pipefail
source lib/common.sh; source lib/ros.sh
LTG_UBUNTU_VERSION={version}
download_file() {{ cp "$LTG_RELEASE_AUDIT_DIR/${{1##*/}}" "$2"; }}
apt_install() {{ dpkg-deb -f "$1" Package; }}
install_ros_source {mode}
'''
            r = subprocess.run(['bash', '-c', code], cwd=ROOT, capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertIn('apt-source', r.stdout)
