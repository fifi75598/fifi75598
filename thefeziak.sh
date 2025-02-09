#!/bin/sh

ROOTFS_DIR=/home/container

ALPINE_VERSION="3.18"
ALPINE_FULL_VERSION="3.18.3"
APK_TOOLS_VERSION="2.14.0-r2"
PROOT_VERSION="5.3.0"

ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}"
  exit 1
fi

if [ ! -e $ROOTFS_DIR/.installed ]; then
    curl -Lo /tmp/rootfs.tar.gz \
    "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/${ARCH}/alpine-minirootfs-${ALPINE_FULL_VERSION}-${ARCH}.tar.gz"
    tar -xzf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
fi

if [ ! -e $ROOTFS_DIR/.installed ]; then
    curl -Lo /tmp/apk-tools-static.apk "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main/${ARCH}/apk-tools-static-${APK_TOOLS_VERSION}.apk"
    curl -Lo $ROOTFS_DIR/usr/local/bin/proot "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    tar -xzf /tmp/apk-tools-static.apk -C /tmp/
    /tmp/sbin/apk.static -X "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main/" -U --allow-untrusted --root $ROOTFS_DIR add alpine-base apk-tools
    chmod 755 $ROOTFS_DIR/usr/local/bin/proot
fi

if [ ! -e $ROOTFS_DIR/.installed ]; then
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
    rm -rf /tmp/apk-tools-static.apk /tmp/rootfs.tar.gz /tmp/sbin
    touch $ROOTFS_DIR/.installed
fi

$ROOTFS_DIR/usr/local/bin/proot \
--rootfs="${ROOTFS_DIR}" \
--link2symlink \
--kill-on-exit \
--root-id \
--cwd=/root \
--bind=/proc \
--bind=/dev \
--bind=/sys \
--bind=/tmp \
/bin/sh
