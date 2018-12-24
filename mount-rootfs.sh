#!/usr/bin/env bash
MOUNT=/tmp/rootfs
ROOTFS=hello-rootfs.ext4

mkdir -p $MOUNT

sudo mount $ROOTFS $MOUNT

echo "$ROOTFS mounted at: $MOUNT"
