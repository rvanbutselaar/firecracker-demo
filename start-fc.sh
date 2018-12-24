#!/bin/bash -e
#set -x
SB_ID="${1:-0}" # Default to sb_id=0
API_SOCKET="/tmp/firecracker-sb${SB_ID}.sock"

echo "ID: $SB_ID"
echo -e "API Socket: $API_SOCKET \n"

echo 'prepare before starting firecracker..'
sudo setfacl -m u:${USER}:rw /dev/kvm
sudo modprobe kvm_intel
sudo sysctl -w net.ipv4.conf.all.forwarding=1 > /dev/null
pkill firecracker || true
rm -vf "$API_SOCKET"

echo 'starting firecracker'
/usr/local/bin/firecracker --api-sock "$API_SOCKET" --context '{"id": "fc-'${SB_ID}'", "jailed": false, "seccomp_level": 0, "start_time_us": 0, "start_time_cpu_us": 0}'
