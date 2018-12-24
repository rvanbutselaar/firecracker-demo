# firecracker-demo

## Verify if you can run firecracker

```console
sudo setfacl -m u:${USER}:rw /dev/kvm
ls -l  /dev/kvm
err=""; [ "$(uname) $(uname -m)" = "Linux x86_64" ] || err="ERROR: your system is not Linux x86_64."; [ -r /dev/kvm ] && [ -w /dev/kvm ] || err="$err\nERROR: /dev/kvm is innaccessible."; (( $(uname -r | cut -d. -f1)*1000 + $(uname -r | cut -d. -f2) >= 4014 )) || err="$err\nERROR: your kernel version ($(uname -r)) is too old."; dmesg | grep -i "hypervisor detected" && echo "WARNING: you are running in a virtual machine. Firecracker is not well tested under nested virtualization."; [ -z "$err" ] && echo "Your system looks ready for Firecracker!" || echo -e "$err"
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
