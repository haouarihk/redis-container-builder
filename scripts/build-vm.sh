#!/bin/bash
set -e

# Configuration
IMAGE_SIZE=2G
IMAGE_NAME="redis-alpine.qcow2"
MOUNT_POINT="./tmp_mount"
OUTPUT_DIR="output"
ALPINE_VERSION="3.21" # Or specify a version
REDIS_VERSION="8.0.0"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create a QEMU image
qemu-img create -f qcow2 "$OUTPUT_DIR/$IMAGE_NAME" "$IMAGE_SIZE"

# Create a temporary mount point
mkdir -p "$MOUNT_POINT"

# Create a temporary directory for the root filesystem
TMP_ROOT="$MOUNT_POINT/rootfs"
mkdir -p "$TMP_ROOT"

# Use debootstrap to install Alpine Linux into the temporary directory
debootstrap --arch amd64 alpine "$TMP_ROOT" "https://mirrors.alpinelinux.org/mirrors/${ALPINE_VERSION}/main"

# Mount the QEMU image
kpartx -av "$OUTPUT_DIR/$IMAGE_NAME" | grep loop | awk '{print $3}' | while read -r PART
do
  LOOP_DEV="/dev/$PART"
  mount -o loop "$LOOP_DEV" "$MOUNT_POINT"
  break # Mount only the first partition
done

# Copy necessary files and configure the system
cp -a "$TMP_ROOT"/* "$MOUNT_POINT"

# Install Redis and dependencies
chroot "$MOUNT_POINT" /bin/sh -c "apk update && apk add --no-cache redis"

# Configure Redis (example: bind all interfaces, set password)
REDIS_CONF="/etc/redis/redis.conf"
chroot "$MOUNT_POINT" /bin/sh -c "sed -i 's/^bind 127.0.0.1$/bind 0.0.0.0/' $REDIS_CONF"
chroot "$MOUNT_POINT" /bin/sh -c "sed -i 's/^# requirepass foobared/requirepass yoursecurepassword/' $REDIS_CONF" # Replace with secure password

# Add Redis to startup
chroot "$MOUNT_POINT" /bin/sh -c "rc-update add redis default"

# Clean up and unmount
umount "$MOUNT_POINT"
kpartx -dv "$OUTPUT_DIR/$IMAGE_NAME"

echo "VM image created at $OUTPUT_DIR/$IMAGE_NAME"