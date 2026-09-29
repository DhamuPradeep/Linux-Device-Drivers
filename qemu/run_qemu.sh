#!/bin/bash
# Helper script to launch QEMU ARM with Versatile Express Cortex-A9
KERNEL_IMG="../linux_arm/arch/arm/boot/zImage"
DTB_FILE="../linux_arm/arch/arm/boot/dts/vexpress-v2p-ca9.dtb"
INITRD_IMG="../qemu_arm/initramfs.cpio.gz"
qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel "$KERNEL_IMG" \
  -dtb "$DTB_FILE" \
  -initrd "$INITRD_IMG" \
  -append "console=ttyAMA0 rdinit=/bin/sh" \
  -nographic
