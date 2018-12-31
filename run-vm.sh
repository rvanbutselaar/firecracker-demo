#!/bin/bash -e
#set -x
SB_ID="${1:-0}" # Default to sb_id=0

KERNEL="$PWD/hello-vmlinux.bin"
RO_DRIVE="$PWD/hello-rootfs.ext4"

TAP_DEV="fc-${SB_ID}-tap0"
KERNEL_BOOT_ARGS="panic=1 pci=off reboot=k ipv6.disable=1"
#KERNEL_BOOT_ARGS="console=ttyS0 panic=1 pci=off reboot=k"
#console=ttyS0 reboot=k panic=1 pci=off
LOGFILE="$PWD/output/fc-sb${SB_ID}-log"
METRICSFILE="$PWD/output/fc-sb${SB_ID}-metrics"

API_SOCKET="/tmp/firecracker-sb${SB_ID}.sock"
CURL=(curl --silent --show-error --header Content-Type:application/json --unix-socket "${API_SOCKET}" --write-out "HTTP %{http_code}")

# Setup TAP device that uses proxy ARP
MASK_LONG="255.255.255.252"
MASK_SHORT="/30"
FC_IP="$(printf '169.254.%s.%s' $(((4 * SB_ID + 1) / 256)) $(((4 * SB_ID + 1) % 256)))"
TAP_IP="$(printf '169.254.%s.%s' $(((4 * SB_ID + 2) / 256)) $(((4 * SB_ID + 2) % 256)))"
FC_MAC="$(printf '02:FC:00:00:%02X:%02X' $((SB_ID / 256)) $((SB_ID % 256)))"

KERNEL_BOOT_ARGS="${KERNEL_BOOT_ARGS} ip=${FC_IP}::${TAP_IP}:${MASK_LONG}::eth0:off"

curl_put() {
    local URL_PATH="$1"
    local OUTPUT RC
    OUTPUT="$("${CURL[@]}" -X PUT --data @- "http://localhost/${URL_PATH#/}" 2>&1)"
    RC="$?"
    if [ "$RC" -ne 0 ]; then
        echo "Error: curl PUT ${URL_PATH} failed with exit code $RC, output:"
        echo "$OUTPUT"
        return 1
    fi
    # Error if output doesn't end with "HTTP 2xx"
    if [[ "$OUTPUT" != *HTTP\ 2[0-9][0-9] ]]; then
        echo "Error: curl PUT ${URL_PATH} failed with non-2xx HTTP status code, output:"
        echo "$OUTPUT"
        return 1
    fi
}

sudo ip link del "$TAP_DEV" 2> /dev/null || true
sudo ip tuntap add dev "$TAP_DEV" mode tap
sudo sysctl -w net.ipv4.conf.${TAP_DEV}.proxy_arp=1 > /dev/null
sudo sysctl -w net.ipv6.conf.${TAP_DEV}.disable_ipv6=1 > /dev/null
sudo ip addr add "${TAP_IP}${MASK_SHORT}" dev "$TAP_DEV"
sudo ip link set dev "$TAP_DEV" up

echo > output/fc-sb${SB_ID}-log
echo > output/fc-sb${SB_ID}-metrics

echo "ID: $SB_ID"
echo "KERNEL: $KERNEL"
echo "TAP_DEV: $TAP_DEV"
echo "KERNEL_BOOT_ARGS: $KERNEL_BOOT_ARGS"
echo "MASK: $MASK_LONG"
echo "IP: $FC_IP"
echo -e "MAC: $FC_MAC \n"

# Wait for API server to start
while [ ! -e "$API_SOCKET" ]; do
    echo "FC $SB_ID still not ready..."
    sleep 0.01s
done

curl_put '/logger' <<EOF
{
  "log_fifo": "$LOGFILE",
  "metrics_fifo": "$METRICSFILE",
  "level": "Info",
  "show_level": false,
  "show_log_origin": false
}
EOF

curl_put '/machine-config' <<EOF
{
  "vcpu_count": 1,
  "mem_size_mib": 64
}
EOF

curl_put '/boot-source' <<EOF
{
  "kernel_image_path": "$KERNEL",
  "boot_args": "$KERNEL_BOOT_ARGS"
}
EOF

curl_put '/drives/rootfs' <<EOF
{
  "drive_id": "rootfs",
  "path_on_host": "$RO_DRIVE",
  "is_root_device": true,
  "is_read_only": false
}
EOF

curl_put '/network-interfaces/1' <<EOF
{
  "iface_id": "1",
  "guest_mac": "$FC_MAC",
  "host_dev_name": "$TAP_DEV"
}
EOF

curl_put '/actions' <<EOF
{
  "action_type": "InstanceStart"
}
EOF

echo "microvm started with ip: $FC_IP"
ping 169.254.0.1 -c 4
