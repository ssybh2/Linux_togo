> Historical guide. For the current GUI installer and Release packages, use [README](README.md) or [English](README_EN.md).

# Linux To Go 🚀

> 로봇 개발을 위한 Ubuntu 자동 환경 구축 도구

언어:

- 🇨🇳 [中文](./README.md)
- 🇬🇧 [English](./README_EN.md)
- 🇰🇷 **한국어 (현재 페이지)**

---

## 소개

`Linux To Go`는 로봇, ROS, AI 개발자를 위한 Ubuntu 환경 자동 설정 도구입니다.

한 번의 초기 설정 후 다음 항목을 자동으로 구성합니다.

- 개발 기본 환경
- Clash Verge Rev 2.5.2
- NoMachine 9.8.3
- ROS 환경 확인 및 설치

새로운 Ubuntu PC를 빠르게 로봇 연구용 워크스테이션으로 변환하는 것이 목표입니다.

---

## 지원 환경

| Ubuntu | 명령어 | ROS |
|---|---|---|
| Ubuntu 20.04 LTS | `linux-to-go -ros1` | ROS 1 Noetic |
| Ubuntu 22.04 LTS | `linux-to-go -ros2` | ROS 2 Humble |

지원 CPU:

- amd64
- arm64

Ubuntu 버전과 ROS 버전은 자동으로 검사됩니다.

---

## 빠른 시작

```bash
git clone https://github.com/ssybh2/Linux_togo.git
cd Linux_togo
sudo ./install.sh
```

ROS가 이미 설치된 PC에서는 `--apps-only`를 사용하세요. ROS 설정과 컴파일 도구를 추가로 설치하지 않습니다.

Intel Core i5 PC는 **amd64**입니다. 먼저 신뢰할 수 있는 기존 설치 파일을 새 PC로 복사하세요:

```bash
LINUX_TO_GO_NOMACHINE_DEB="$HOME/Downloads/nomachine_9.7.3_1_amd64.deb" linux-to-go --apps-only
linux-to-go --check
```

NoMachine이 이미 설치되어 있거나 ARM64 PC라면 `linux-to-go --apps-only`만 실행하면 됩니다. 새 Personal Edition으로 자동 대체하지 않습니다. 자세한 내용은 [English](README_EN.md)를 참고하세요.

ROS 설치도 필요한 경우:

Ubuntu 20.04:

```bash
linux-to-go -ros1
```

Ubuntu 22.04:

```bash
linux-to-go -ros2
```

---

## 주요 기능

### Clash Verge Rev 2.5.2

- amd64 / arm64 지원
- 공식 Release 사용
- SHA-256 검증

### NoMachine 9.8.3

- ARM64 자동 설치 지원
- AMD64는 신뢰할 수 있는 로컬 DEB 필요 (기존 공식 URL은 더 이상 유효하지 않음)
- 아키텍처 자동 확인

### ROS 관리

지원:

- ROS 1 Noetic
- ROS 2 Humble

이미 설치된 ROS는 자동으로 감지하여 재설치하지 않습니다.

---

## 업데이트

```bash
cd Linux_togo
git pull --ff-only
sudo ./install.sh
```

중국어 문서: [README.md](./README.md)

English 문서: [README_EN.md](./README_EN.md)
