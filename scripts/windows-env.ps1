<#
    SPDX-License-Identifier: BSD-3-Clause
    Install prerequisites on Windows (Chocolatey) for Hydra host builds.
#>

Param()

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Error "Chocolatey is required. Install it from https://chocolatey.org/install and rerun."
    exit 1
}

choco install -y sdl2 sdl2-ttf python --params "/InstallDir:C:\tools\Python"
python -m pip install --upgrade pip
python -m pip install cocotb pytest

Write-Host "Windows env ready. Use cmake --preset windows to build."
