# Linux To Go 🚀

> **เครื่องมือปรับแต่งสภาพแวดล้อม Ubuntu สำหรับการพัฒนา Robotics แบบอัตโนมัติ**

---

## แนะนำโครงการ

`Linux To Go` เป็นเครื่องมือสำหรับนักพัฒนา Robotics, ROS และ AI ที่ช่วยตั้งค่า Ubuntu development environment แบบอัตโนมัติ

เพียงติดตั้งครั้งเดียว ระบบสามารถช่วยจัดเตรียม:

- พื้นฐานสำหรับการพัฒนา
- Clash Verge Rev 2.5.2
- NoMachine 9.8.3 สำหรับ Remote Desktop
- การตรวจสอบและติดตั้ง ROS

เป้าหมายคือทำให้เครื่อง Ubuntu ใหม่สามารถกลายเป็น workstation สำหรับงาน Robotics ได้อย่างรวดเร็ว

---

## ระบบที่รองรับ

| Ubuntu | คำสั่ง | ROS |
|---|---|---|
| Ubuntu 20.04 LTS | `linux-to-go -ros1` | ROS 1 Noetic |
| Ubuntu 22.04 LTS | `linux-to-go -ros2` | ROS 2 Humble |

รองรับสถาปัตยกรรม:

- amd64
- arm64

ระบบจะตรวจสอบความเข้ากันได้:

- Ubuntu 20.04 → ROS 1 Noetic
- Ubuntu 22.04 → ROS 2 Humble

---

## การเริ่มต้นใช้งานอย่างรวดเร็ว

```bash
git clone https://github.com/ssybh2/Linux_togo.git
cd Linux_togo
sudo ./install.sh
```

หลังจากติดตั้ง:

Ubuntu 20.04:

```bash
linux-to-go -ros1
```

Ubuntu 22.04:

```bash
linux-to-go -ros2
```

---

## กระบวนการทำงานอัตโนมัติ

```text
linux-to-go
    |
    +-- ตรวจสอบเวอร์ชัน Ubuntu
    +-- ตรวจสอบ CPU architecture
    +-- ตรวจสอบ ROS ที่ติดตั้งอยู่
    +-- ติดตั้ง Clash Verge Rev 2.5.2
    +-- ติดตั้ง NoMachine 9.8.3
    +-- ติดตั้ง ROS Noetic / Humble
    +-- ตั้งค่า environment สำหรับการพัฒนา
```

ซอฟต์แวร์ที่ติดตั้งแล้วจะถูกตรวจสอบและข้ามโดยอัตโนมัติ เพื่อป้องกันการติดตั้งซ้ำ

---

## คุณสมบัติหลัก

### 🌐 Clash Verge Rev 2.5.2

- รองรับ amd64 / arm64
- ดาวน์โหลดจาก Release อย่างเป็นทางการ
- ตรวจสอบ SHA-256

### 🖥 NoMachine 9.8.3

- รองรับ ARM64 และ AMD64
- ตรวจสอบ architecture อัตโนมัติ

### 🤖 ROS Management

รองรับ:

- ROS 1 Noetic
- ROS 2 Humble

ตรวจสอบก่อนติดตั้ง:

```text
ติดตั้งแล้ว → SKIP
ยังไม่ได้ติดตั้ง → ติดตั้งอัตโนมัติ
```

---

## โครงสร้าง Repository

```text
Linux_togo/
├── install.sh
├── bin/linux-to-go
├── lib/
│   ├── common.sh
│   ├── system.sh
│   ├── clash-verge.sh
│   ├── nomachine.sh
│   └── ros.sh
├── packages/
└── tests/
```

---

## การอัปเดต

```bash
cd Linux_togo
git pull
sudo ./install.sh
```

---

เอกสารภาษาอื่น:

- 中文: [README.md](./README.md)
- English: [README_EN.md](./README_EN.md)
- 한국어: [README_KR.md](./README_KR.md)
