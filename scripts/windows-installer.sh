#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/build/windows"
OUT_DIR="$ROOT/out/windows-installer"

mkdir -p "$BUILD_DIR"
mkdir -p "$OUT_DIR"

cp -v "$BUILD_DIR/Win32/Release/hydra_driver.dll" "$OUT_DIR/hydra_win32.dll" >/dev/null 2>&1 || true
cp -v "$BUILD_DIR/x64/Release/hydra_driver.dll" "$OUT_DIR/hydra_x64.dll" >/dev/null 2>&1 || true
cat <<'EOF' > "$OUT_DIR/hydra.inf"
[Version]
Signature="$Windows NT$"
Class=Hydra
ClassGuid={4D36E978-E325-11CE-BFC1-08002BE10318}
Provider=%ManufacturerName%

[Manufacturer]
%ManufacturerName%=Hydra,NTamd64,NTx86

[Hydra.NTamd64]
hydra_win64.sys

[Hydra.NTx86]
hydra_win32.sys

[SourceDisksNames]
1=%DiskId1%,,,.

[Strings]
ManufacturerName="Hydra"
DiskId1="Hydra Driver"
EOF

echo "[windows-installer] Installer stage ready at $OUT_DIR"
