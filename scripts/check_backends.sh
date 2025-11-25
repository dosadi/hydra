#!/usr/bin/env bash
set -euo pipefail

# Lightweight backend probe: reports SDL2 presence and available video/render drivers.
# Exits 77 when SDL2 is missing so CI can skip gracefully.

if ! command -v sdl2-config >/dev/null 2>&1; then
  echo "check_backends: sdl2-config not found; skipping" >&2
  exit 77
fi

echo "check_backends: SDL version $(sdl2-config --version)"

# Attempt a tiny SDL program via python -c using ctypes to list video drivers.
python - <<'PYCODE'
import sys
try:
    import ctypes
    sdl = ctypes.CDLL("libSDL2.so")
    sdl.SDL_Init.argtypes = [ctypes.c_uint32]
    sdl.SDL_Init.restype = ctypes.c_int
    sdl.SDL_Quit.argtypes = []
    sdl.SDL_Quit.restype = None
    sdl.SDL_GetNumVideoDrivers.restype = ctypes.c_int
    sdl.SDL_GetVideoDriver.restype = ctypes.c_char_p
    if sdl.SDL_Init(0x00000020) != 0:  # SDL_INIT_VIDEO
        print("check_backends: SDL_Init failed", file=sys.stderr)
        sys.exit(1)
    n = sdl.SDL_GetNumVideoDrivers()
    drivers = [sdl.SDL_GetVideoDriver(i).decode() for i in range(n)]
    print("check_backends: video drivers:", ",".join(drivers))
    sdl.SDL_Quit()
except Exception as e:
    print(f"check_backends: probe failed: {e}", file=sys.stderr)
    sys.exit(1)
PYCODE
