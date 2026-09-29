# ARM Linux Platform Character Device Driver with Device Tree (QEMU)

An ARM Linux platform character device driver demonstrating **Device Tree (OF) bindings**, dynamic device probing, character device registration, and custom hardware property parsing. 

Configured and tested on a virtual **ARM Cortex-A9 (Versatile Express)** platform using **QEMU**

---

## Architecture Overview

```
 +-------------------------------------------------------+
 |                  User Space Applications              |
 |              (cat, echo, test app)             |
 +-------------------------------------------------------+
                            |
                     VFS System Calls
               (open, read, write, lseek)
                            |
 +--------------------------v----------------------------+
 |                   Linux Kernel Space                  |
 |                                                       |
 |   /dev/pcdev-0    /dev/pcdev-1    /dev/pcdev-2 ...    |
 |         |               |               |             |
 |   +-----v---------------v---------------v---------+   |
 |   |        PCD Platform Driver (Core Logic)       |   |
 |   +-----------------------------------------------+   |
 |        ^ of_match_table         ^ of_property_read    |
 |   +----+------------------------+-----------------+   |
 |   |          Device Tree Subsystem (OF)           |   |
 |   +-----------------------------------------------+   |
 |                           |                           |
 |   +-----------------------v-----------------------+   |
 |   | Flattened Device Tree (.dtb) / vexpress-ca9   |   |
 |   +-----------------------------------------------+   |
 +-------------------------------------------------------+
                            |
 +--------------------------v----------------------------+
 |                  Hardware / Emulator                  |
 |          QEMU ARM Versatile Express (Cortex-A9)       |
 +-------------------------------------------------------+
```

---

## Features

- **Device Tree Probing:** Utilizes `of_match_table` matching against compatible strings (`pcdev-A1x`, `pcdev-B1x`, etc.).
- **Dynamic Property Extraction:** Parses custom device tree attributes (`org,size`, `org,perm`, and `org,device-serial-num`) using `of_property_read_*` APIs.
- **Resource Management:** Managed kernel memory allocation (`devm_kzalloc`) tied to the device lifecycle.
- **Dynamic Device Node Creation:** Automatically creates `/dev/pcdev-X` device nodes via `class_create` and `device_create`.
- **Full File Operations Support:** Implements `open()`, `release()`, `read()`, `write()`, and `llseek()` with boundary checks and permission enforcement.
- **QEMU Integration:** Runs in QEMU `vexpress-a9` with BusyBox initramfs for rapid debugging without physical board flashing.

---

## Project Structure

```text
.
├── driver/
│   ├── Makefile                   # Out-of-tree module compilation Makefile
│   ├── pcd_platform_driver_dt.c   # Main platform driver implementation
│   └── platform.h                 # Driver structs and platform data definitions
├── dts/
│   └── vexpress-v2p-ca9.dts       # Device Tree source with pcdev platform nodes
├── qemu/
│   └── run_qemu.sh                # Helper script to launch QEMU virtual machine
├── .gitignore                     # Excludes binary modules (*.ko, *.o, *.cmd)
└── README.md
```

---

## Device Tree Configuration

The driver matches platform devices declared in the board's Device Tree (`dts/vexpress-v2p-ca9.dts`):

```dts
pcdev1: pcdev-1 {
    compatible = "pcdev-A1x";
    org,size = <512>;
    org,device-serial-num = "PCDEV1ABC123";
    org,perm = <0x11>;
};

pcdev2: pcdev-2 {
    compatible = "pcdev-B1x";
    org,size = <1024>;
    org,device-serial-num = "PCDEV2ABC456";
    org,perm = <0x11>;
};
```

---

## Prerequisites

Install the ARM 32-bit cross-compiler and QEMU emulator:

```bash
sudo apt update
sudo apt install -y build-essential gcc-arm-linux-gnueabihf bison flex \
                    libssl-dev bc dtc qemu-system-arm
```

---

## Build & Run Guide

### 1. Build the Driver Module

Compile the kernel module against the target ARM kernel:

```bash
cd driver
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- KERN_DIR=<path-to-kernel-source>
cd ..
```
*Output: `driver/pcd_platform_driver_dt.ko`*

---

### 2. Update Rootfs & Package Initramfs

Copy the compiled module into your BusyBox root filesystem and update the initramfs:

```bash
cp driver/pcd_platform_driver_dt.ko <path-to-rootfs>/drivers/

cd <path-to-rootfs>
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
```

---

### 3. Launch QEMU

Run QEMU with the compiled `zImage`, `vexpress-v2p-ca9.dtb`, and `initramfs.cpio.gz`:

```bash
qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel <path-to-zImage> \
  -dtb <path-to-dtb> \
  -initrd <path-to-initramfs.cpio.gz> \
  -append "console=ttyAMA0 rdinit=/bin/sh" \
  -nographic
```
*(To exit QEMU: press `Ctrl + A` then `X`)*

---

## Verification & Testing in QEMU

Once inside the QEMU shell:

### 1. Mount Virtual Filesystems
```sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
```

### 2. Verify Device Tree Nodes
```sh
ls -d /sys/firmware/devicetree/base/pcdev*
```

### 3. Insert Driver Module
```sh
insmod /drivers/pcd_platform_driver_dt.ko
```

Check the kernel log to confirm device probing and parameter parsing:
```sh
dmesg | tail -n 20
```

### 4. Test Read and Write Operations
```sh
# Write test string to device 0
echo "Testing ARM Linux Driver in QEMU!" > /dev/pcdev-0

# Read back from device
head -n 1 /dev/pcdev-0
```

### 5. Remove Driver
```sh
rmmod pcd_platform_driver_dt
dmesg | tail -n 5
```

---
