#!/usr/bin/env bash
MOUNT=/tmp/rootfs
ROOTFS=hello-rootfs.ext4

sudo umount $MOUNT
rmdir $MOUNT
