# Hydra Mesa/Gallium Stub (Placeholder)

This is a sketch for a Mesa Gallium driver. No build system is wired here; the intent is to drop these sources into Mesa’s `src/gallium/drivers/hydra/` when you are ready to stand up a render-only driver.

Suggested starter files (to be authored in Mesa tree):
- `hydra_screen.c`: implements `pipe_screen` create/destroy, queries, fence imports, and forwards BO alloc/import to kernel IOCTLs.
- `hydra_context.c`: minimal `pipe_context` with stubbed draw/compute hooks returning `PIPE_ERROR`.
- `hydra_resource.c`: surface/texture/buffer wrappers that translate to PCIe DMA or BAR mappings.
- `meson.build`: register the driver, enable for Linux only, depend on libdrm hydra UAPI headers.

Notes:
- Target render-only initially; reuse DRM dumb-buffers or BO IOCTLs once defined in the kernel driver.
- Keep UAPI in `drivers/linux/uapi/`; mirror any new IOCTLs in Mesa side.
- When ready, add CI jobs in Mesa to build `gallium-drivers=hudra` (optional, off by default).
