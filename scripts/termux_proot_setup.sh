#!/usr/bin/env bash
set -euo pipefail

# termux_proot_setup.sh
# Usage: run on Termux host. Prepares a proot-distro Ubuntu environment,
# installs build dependencies (including Verilator if missing), clones
# the hydra repo, checks out branch `test/axi-wrap`, and runs the AXI wrap test.

UBU_DISTRO=${1:-ubuntu-22.04}
REPO_URL=${2:-https://github.com/dosadi/hydra.git}
REPO_BRANCH=${3:-test/axi-wrap}

echo "Starting Termux -> proot-distro setup"

if ! command -v pkg >/dev/null 2>&1; then
    echo "This script is intended to run on Termux (pkg not found). Exiting." >&2
    exit 1
fi

echo "Installing required Termux packages: proot-distro, git, wget"
pkg update -y
pkg install -y proot-distro git wget curl

echo "Installing distro: $UBU_DISTRO (if not present)"
if ! proot-distro list | grep -q "^$UBU_DISTRO"; then
    proot-distro install $UBU_DISTRO
fi

echo "Entering $UBU_DISTRO to perform apt installs and repo setup..."

proot-distro login $UBU_DISTRO -- bash -lc "set -euo pipefail
echo 'Inside $UBU_DISTRO: update/upgrade'
apt update -y
apt upgrade -y

echo 'Installing common build packages'
apt install -y build-essential git autoconf automake flex bison pkg-config python3 python3-pip cmake make libboost-all-dev libfl-dev wget curl ca-certificates sudo

# SDL and related
apt install -y libsdl2-dev libsdl2-ttf-dev

echo 'Check for verilator'
if ! command -v verilator >/dev/null 2>&1; then
    echo 'Verilator not found; building from source (this may take a while)'
    apt install -y perl python3-docutils
    git clone --depth 1 https://github.com/verilator/verilator.git /tmp/verilator
    cd /tmp/verilator
    autoconf && ./configure
    make -j\$(nproc)
    make install
    ldconfig || true
else
    echo "Verilator present: \$(verilator --version)"
fi

echo 'Cloning repository and checking out branch'
cd /root
if [ -d hydra ]; then
    cd hydra && git fetch --all && git checkout $REPO_BRANCH && git pull
else
    git clone $REPO_URL
    cd hydra
    git checkout $REPO_BRANCH || git checkout -b $REPO_BRANCH origin/$REPO_BRANCH || true
fi

echo 'Build: attempt sim tests (may require additional packages).'
cd sim/tests || cd sim || true
chmod +x run_axi_wrap_test.sh || true
./run_axi_wrap_test.sh || (echo "run_axi_wrap_test.sh failed; you can try 'cd sim && make' or inspect logs" && exit 2)
echo 'AXI wrap test run completed (see above output).'
"

echo "All done. To enter the distro interactively run: proot-distro login $UBU_DISTRO"
