# Hydra systemd service example

Create `/etc/systemd/system/hydra.service`:

```
[Unit]
Description=Hydra PCIe driver
After=basic.target

[Service]
Type=oneshot
ExecStart=/sbin/modprobe hydra_pcie
ExecStartPost=/bin/chmod 0660 /dev/hydra_pcie
ExecStartPost=/bin/chgrp plugdev /dev/hydra_pcie
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Reload and enable:

```
sudo systemctl daemon-reload
sudo systemctl enable --now hydra.service
```

Adjust group/permissions as needed for your environment.***
