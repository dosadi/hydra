# Placeholder meson.build for a future Hydra Gallium driver.
# Copy into Mesa's src/gallium/drivers/hydra/ and wire into
# top-level meson_options when implementing.

hydra_files = [
  'hydra_gallium_stub.c',
]

if with_gallium_hydra
  libgallium_hydra = static_library(
    'galliumhydra',
    files(hydra_files),
    include_directories : [inc_gallium, inc_include],
    dependencies : [dep_libdrm],
    gnu_symbol_visibility : 'hidden',
  )
  driver_hydra = declare_dependency(
    compile_args : '-DWITH_HYDRA',
    link_with : libgallium_hydra,
  )
endif
