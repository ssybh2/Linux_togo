# Local NoMachine package override

NoMachine binaries are not committed to this public repository. If you already have a legally obtained NoMachine package, place it in this directory before running the repository-local CLI, or pass its absolute path with:

```bash
LINUX_TO_GO_NOMACHINE_DEB=/path/to/nomachine_9.8.3_1_arm64.deb linux-to-go -ros2
```

The installer reads the Debian package metadata and refuses to install a package whose `Architecture` does not match the host.

For the supplied ARM64 package used while developing this project:

```text
Package: nomachine
Version: 9.8.3-1
Architecture: arm64
SHA-256: be874820b9539e836d44fdfb2311a588253bd192e0e43393d819251e42a057ad
```
