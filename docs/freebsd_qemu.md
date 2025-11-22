# FreeBSD QEMU Quickstart (for Hydra kmod stub)

This guide assumes you have QEMU on the host. It sets up a lightweight FreeBSD VM to build/test the Hydra FreeBSD kmod stub. Networking/VM downloads are manual; this repo does not fetch images.

## 1) Get a FreeBSD image
- Download a FreeBSD amd64 qcow2 or raw image (e.g., 14.0-RELEASE) from the FreeBSD release mirrors.
- Optionally resize:
  ```bash
  qemu-img resize freebsd-14.0-amd64.qcow2 +10G
  cp freebsd-14.0-amd64.qcow2 freebsd-hydra.qcow2
  ```

## 2) Launch QEMU
Example (KVM, user networking, ssh forward on host port 2222):
```bash
qemu-system-x86_64 -m 4096 -smp 4 \
  -drive file=freebsd-hydra.qcow2,if=virtio \
  -net nic,model=virtio -net user,hostfwd=tcp::2222-:22 \
  -enable-kvm
```
Log in via console; enable sshd if desired (`sudo service sshd enable && sudo service sshd start`) and use `ssh -p 2222 user@localhost`.

## 3) Install build dependencies in the VM
```bash
sudo pkg install git llvm15 gmake
sudo pkg install freebsd-src    # for kernel headers/sources if not present
```

## 4) Build and load the Hydra FreeBSD stub
Copy/clone the repo into the VM, then:
```bash
cd drivers/bsd
gmake -f Makefile.kmod
sudo kldload ./hydra.ko
sudo kldunload hydra
```
(Stub only: maps BAR0/1 and exposes INFO/RD32/WR32/DMA IOCTLs; DMA/IRQ are emulated.)

## Notes
- This flow does not set up a QEMU PCI Hydra device; IOCTLs operate on the stubbed BAR image only.
- For PCI device emulation, you’d need to add a small QEMU PCI model exposing BAR0/1 RAM and rebuild QEMU (not provided here).
- cocotb/sim flows remain Linux/icarus-friendly; run them on the host or in WSL/MSYS2 rather than in this VM.
