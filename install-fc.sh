#!/usr/bin/env bash
VERSION="${1:-0.11.0}" # Default to 0.11.0

curl -LOJ https://github.com/firecracker-microvm/firecracker/releases/download/v$VERSION/firecracker-v$VERSION && \
chmod +x ./firecracker-v$VERSION && \
sudo  mv firecracker-v$VERSION /usr/local/bin/firecracker
firecracker --version
