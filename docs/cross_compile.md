# Cross-compiling Hydra (aarch64 example)

This is a lightweight note for cross-compiling the Linux driver and libhydra on aarch64.

## Prereqs (Ubuntu/Debian)

```
sudo apt-get install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
    crossbuild-essential-arm64
```

## Linux driver (kmod)

```
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
make -C /lib/modules/$(uname -r)/build M=$PWD/drivers/linux modules
```

You need kernel headers for your target kernel/defconfig.

## libhydra (static lib)

```
cmake -S . -B build/aarch64 \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
    -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
    -DCMAKE_INSTALL_PREFIX=/usr/aarch64-linux-gnu
cmake --build build/aarch64 --target libhydra
```

Adjust `CMAKE_INSTALL_PREFIX` to your sysroot as needed.
