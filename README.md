# firecracker-demo

## Verify if you can run firecracker

```console
sudo setfacl -m u:${USER}:rw /dev/kvm
ls -l  /dev/kvm
err=""; [ "$(uname) $(uname -m)" = "Linux x86_64" ] || err="ERROR: your system is not Linux x86_64."; [ -r /dev/kvm ] && [ -w /dev/kvm ] || err="$err\nERROR: /dev/kvm is innaccessible."; (( $(uname -r | cut -d. -f1)*1000 + $(uname -r | cut -d. -f2) >= 4014 )) || err="$err\nERROR: your kernel version ($(uname -r)) is too old."; dmesg | grep -i "hypervisor detected" && echo "WARNING: you are running in a virtual machine. Firecracker is not well tested under nested virtualization."; [ -z "$err" ] && echo "Your system looks ready for Firecracker!" || echo -e "$err"
```

## Install firecracker

```console
./install-fc.sh 0.12.0
```

## Run firecracker

- Open 2 ssh sessions.

SSH Session 1: Start firecracker
```console
./start-fc.sh
```

SSH Session 2: Run a microvm (1 vCPU & 64 Mib)
```console
./run-vm.sh
```

- Go back to session 1 and login with root:root and start webserver with:

SSH Session 1: Start simple go webserver
```console
localhost:~# webserver
```

- Go to session 2 and curl the webserver:

SSH Session 2: curl webserver
```console
curl http://169.254.0.1:8080
```

- When you're done, issuing a reboot command inside the guest will shutdown Firecracker gracefully.

## Mount / unmount hello-rootfs.ext4 to modify / add content

```console
./mount-rootfs.sh

# now you can modify / add content inside: /tmp/rootfs

/unmount-rootfs.sh
```

# Build and copy webserver

```console
./build-copy-webserver.sh
```

# Enable internet access from inside the microvm (default disabled)

Execute on the host and not inside the microvm

```console
sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i tap0 -o ens33 -j ACCEPT
```

# You might need to configure DNS resolving inside the microvm

```console
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

## Setup serverless python image

# Create 100MB image rootfs

```console
curl -fsSL -o hello-rootfs-python.ext4 https://s3.amazonaws.com/spec.ccfc.min/img/hello/fsfiles/hello-rootfs.ext4
e2fsck -f hello-rootfs-python.ext4 && resize2fs hello-rootfs-python.ext4 100M
```

# Boot the image and install requirements

```console
./run-vm-data.sh
```

```console
apk add python

cat << EOF >> /etc/fstab
/dev/vdb 	/data/		ext4	defaults 0 2
EOF

cat << EOF > /etc/init.d/serverless
#!/sbin/openrc-run

pidfile="/var/run/python.pid"
command="/usr/bin/python"
command_args="/data/`cat /data/run.txt`"
command_background=true
EOF

chmod +x /etc/init.d/serverless && rc-update add serverless

reboot

rm data.ext4
```

# Now you can create a data disk based on a git repo with python script(s)

Note: You need to specify the python script you would like to run inside the
GIT repo using a run.txt file

echo 'webserver.py' > run.txt

```console
rm -f data.ext4 && fallocate -l 30M data.ext4 && mkfs.ext4 data.ext4 && \
TEMP=`mktemp -d` && \
sudo mount data.ext4 $TEMP && sudo rmdir $TEMP/lost+found && \
sudo chown -R `whoami` $TEMP && \
git clone https://github.com/rvanbutselaar/python-webserver.git $TEMP/ && \
sudo umount $TEMP
```

# now you can run this with:

```console
./start-fc.sh
./run-vm-data.sh
```

# script to build this (todo)

```console
./run-vm-data.sh [GIT_REPO] [script_name]
```
