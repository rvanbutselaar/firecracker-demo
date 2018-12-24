#!/usr/bin/env bash

echo 'building...'
(cd webserver && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -ldflags="-w -s" -o webserver)

echo 'mount and copy file(s)...'
./mount-rootfs.sh

sudo cp -vf webserver/webserver /tmp/rootfs/usr/local/bin/webserver

./unmount-rootfs.sh
