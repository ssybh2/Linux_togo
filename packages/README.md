# Local NoMachine package override

NoMachine binaries are not committed to this public repository. If you already have a legally obtained NoMachine package, place it in this directory before running the repository-local CLI, or pass its absolute path with:

```bash
LINUX_TO_GO_NOMACHINE_DEB=/path/to/nomachine_9.7.3_1_amd64.deb linux-to-go --apps-only
```

Use amd64 packages on Intel/AMD PCs and arm64 packages on ARM devices. The installer checks both `Package: nomachine` and the host architecture. A missing explicit path fails without downloading a replacement. Arbitrary local versions do not have a pinned checksum: use a trusted installer.

Automatic discovery of this directory works with `./bin/linux-to-go` from the repository. After `sudo ./install.sh`, the global command needs the explicit package path shown above. Legacy vendor amd64 URLs no longer serve DEBs, so amd64 requires a local package unless NoMachine is already installed. ARM64 can download the verified repository release automatically.

For the supplied ARM64 package used while developing this project:

```text
Package: nomachine
Version: 9.8.3-1
Architecture: arm64
SHA-256: be874820b9539e836d44fdfb2311a588253bd192e0e43393d819251e42a057ad
```
