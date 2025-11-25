# Hydra udev rule example

Create `/etc/udev/rules.d/99-hydra.rules`:

```
SUBSYSTEM=="pci", DRIVERS=="hydra_pcie", GROUP="plugdev", MODE="0660", SYMLINK+="hydra_pcie"
```

Reload rules:

```
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Adjust `GROUP` as needed for your system to grant non-root access to `/dev/hydra_pcie`.
