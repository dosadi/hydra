# Hydra Data Formats & File I/O TODOs (0.0.7+ Cycle)

**Focus:** Voxel formats, scene serialization, import/export, file specifications.
Ensures interoperability and data portability.

**Status:** Mostly P2/P3 work; basic formats after core functionality stable.

---

## P2: Medium Priority Formats (Nice-to-Have)

### Native Format Specification

- TODO [P2]: Define Hydra native voxel format (.hydra)
  - **Coverage:**
    - Header: magic number, version, grid dimensions
    - Metadata: author, creation date, description, tags
    - Voxel data section: type, color, normal, emissive per voxel
    - Compression: Optional RLE or palette-based encoding
    - Extension chunks: Camera positions, render settings
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Voxel data structure finalized
  - **Validation:** Format specification document
  - **Deliverable:** `docs/hydra_format_spec.md`

- TODO [P2]: Implement .hydra file loader
  - **Coverage:**
    - Parse header and validate version
    - Decompress voxel data if needed
    - Load into voxel memory
    - Apply metadata (camera, render flags)
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Format spec (#1)
  - **Validation:** Load various .hydra files correctly
  - **Deliverable:** `sim/hydra_format_loader.cpp`

- TODO [P2]: Implement .hydra file writer
  - **Coverage:**
    - Serialize voxel grid to disk
    - Apply compression
    - Save metadata
    - Versioned format for backward compatibility
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Format spec (#1)
  - **Validation:** Round-trip save/load preserves data
  - **Deliverable:** `sim/hydra_format_writer.cpp`

### Import from External Formats

- TODO [P2]: Add MagicaVoxel .vox importer
  - **Coverage:**
    - Parse .vox file format
    - Convert voxel grid to Hydra format
    - Map MagicaVoxel palette to Hydra colors
    - Handle size mismatches (downsample/crop if needed)
  - **Effort:** Large (5-7 days)
  - **Dependencies:** .vox format documentation
  - **Validation:** Import MagicaVoxel scenes correctly
  - **Deliverable:** `sim/importers/magicavoxel_importer.cpp`

- TODO [P3]: Add Qubicle .qb importer
  - **Coverage:**
    - Parse Qubicle binary format
    - Convert to Hydra voxel grid
  - **Effort:** Large (3-5 days)
  - **Dependencies:** .qb format documentation
  - **Validation:** Import Qubicle models
  - **Deliverable:** `sim/importers/qubicle_importer.cpp`

- TODO [P3]: Add Minecraft schematic importer
  - **Coverage:**
    - Parse .schematic NBT format
    - Map Minecraft blocks to voxel types
    - Handle large schematics (downsample)
  - **Effort:** Very Large (7-10 days)
  - **Dependencies:** NBT library, block ID mapping
  - **Validation:** Import Minecraft builds
  - **Deliverable:** `sim/importers/minecraft_importer.cpp`

- TODO [P3]: Add voxel mesh importer (OBJ/PLY to voxels)
  - **Coverage:**
    - Load triangle mesh
    - Voxelize using ray casting or grid sampling
    - Configurable voxel resolution
  - **Effort:** Very Large (10-15 days)
  - **Dependencies:** Mesh library (Assimp, tinyobjloader)
  - **Validation:** Voxelize simple meshes
  - **Deliverable:** `sim/importers/mesh_voxelizer.cpp`

### Export to External Formats

- TODO [P2]: Add mesh exporter (voxels to OBJ)
  - **Coverage:**
    - Convert voxels to triangle mesh (marching cubes or naive)
    - Generate per-vertex normals
    - Export to OBJ with MTL material
  - **Effort:** Large (5-7 days)
  - **Dependencies:** Marching cubes implementation
  - **Validation:** Exported meshes open in Blender
  - **Deliverable:** `sim/exporters/obj_exporter.cpp`

- TODO [P3]: Add point cloud exporter (voxels to PLY)
  - **Coverage:**
    - Export voxel centers as points
    - Include color per point
    - Optional: include normals
  - **Effort:** Small (1-2 days)
  - **Dependencies:** None
  - **Validation:** Point clouds open in CloudCompare
  - **Deliverable:** `sim/exporters/ply_exporter.cpp`

- TODO [P3]: Add image slice exporter (PNG slices)
  - **Coverage:**
    - Export XY, XZ, YZ slices as PNG
    - Useful for debugging, documentation
    - Slice index selectable
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Image library (stb_image_write)
  - **Validation:** Slices match voxel grid
  - **Deliverable:** `sim/exporters/slice_exporter.cpp`

- TODO [P3]: Add MagicaVoxel .vox exporter
  - **Coverage:**
    - Convert Hydra grid to .vox
    - Map colors to MagicaVoxel palette
    - Handle size limits (256³ max in .vox)
  - **Effort:** Large (3-5 days)
  - **Dependencies:** .vox format spec
  - **Validation:** Exported files open in MagicaVoxel
  - **Deliverable:** `sim/exporters/magicavoxel_exporter.cpp`

---

## P3: Low Priority Formats (Future)

### Advanced Import

- TODO [P3]: Add texture atlas importer (heightmap to voxels)
  - **Coverage:**
    - Load heightmap image
    - Extrude to 3D voxel terrain
    - Apply texture colors to voxels
  - **Effort:** Large (5-7 days)
  - **Dependencies:** Image library
  - **Validation:** Heightmaps convert correctly
  - **Deliverable:** `sim/importers/heightmap_importer.cpp`

- TODO [P3]: Add voxel animation importer
  - **Coverage:**
    - Load sequence of voxel frames
    - Support .vox animations from MagicaVoxel
    - Playback in viewer
  - **Effort:** Very Large (10-15 days)
  - **Dependencies:** Animation format spec
  - **Validation:** Animations play correctly
  - **Deliverable:** `sim/importers/voxel_animation.cpp`

- TODO [P3]: Add procedural import from scripts
  - **Coverage:**
    - Load Lua/Python script
    - Execute to generate voxels
    - Useful for parametric designs
  - **Effort:** Very Large (10-15 days)
  - **Dependencies:** Scripting engine
  - **Validation:** Scripts generate voxels
  - **Deliverable:** `sim/importers/script_importer.cpp`

### Specialized Formats

- TODO [P3]: Add sparse voxel octree (SVO) format
  - **Coverage:**
    - Hierarchical representation
    - Memory-efficient for large scenes
    - Import/export SVO
  - **Effort:** Very Large (15-20 days)
  - **Dependencies:** SVO implementation
  - **Validation:** SVO compress/decompress losslessly
  - **Deliverable:** `sim/formats/svo_format.cpp`

- TODO [P3]: Add streaming voxel format
  - **Coverage:**
    - Stream voxels from disk/network
    - Load-on-demand for huge scenes
    - Chunk-based format
  - **Effort:** Very Large (20-30 days)
  - **Dependencies:** Streaming architecture
  - **Validation:** Stream large scenes smoothly
  - **Deliverable:** `sim/formats/streaming_format.cpp`

### Metadata and Auxiliary Data

- TODO [P2]: Define camera path format
  - **Coverage:**
    - Keyframes: time, position, direction
    - Interpolation type (linear, bezier, catmull-rom)
    - JSON or binary format
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Camera path recording feature
  - **Validation:** Paths load and play correctly
  - **Deliverable:** `docs/camera_path_format.md`

- TODO [P2]: Define render settings format
  - **Coverage:**
    - All render flags
    - Lighting parameters
    - Post-processing settings
    - JSON or INI format
  - **Effort:** Small (1 day)
  - **Dependencies:** None
  - **Validation:** Settings apply correctly
  - **Deliverable:** `docs/render_settings_format.md`

- TODO [P3]: Add scene graph format
  - **Coverage:**
    - Hierarchical scene structure
    - Multiple voxel objects with transforms
    - Instancing support
  - **Effort:** Very Large (15-20 days)
  - **Dependencies:** Scene graph implementation
  - **Validation:** Complex scenes load correctly
  - **Deliverable:** `docs/scene_graph_format.md`

### Compression and Optimization

- TODO [P3]: Implement palette-based compression
  - **Coverage:**
    - Detect frequently used colors
    - Compress to palette + indices
    - Significant space savings for simple scenes
  - **Effort:** Large (5-7 days)
  - **Dependencies:** None
  - **Validation:** Compression is lossless, reduces size
  - **Deliverable:** Compression in .hydra writer

- TODO [P3]: Add RLE compression for voxel data
  - **Coverage:**
    - Run-length encoding for empty space
    - Fast to compress/decompress
  - **Effort:** Medium (2-3 days)
  - **Dependencies:** None
  - **Validation:** Compression works, is fast
  - **Deliverable:** RLE codec in format library

- TODO [P3]: Implement delta compression for voxel edits
  - **Coverage:**
    - Store only changed voxels
    - Useful for undo/redo, versioning
  - **Effort:** Large (5-7 days)
  - **Dependencies:** Edit tracking
  - **Validation:** Delta compress/decompress correctly
  - **Deliverable:** Delta format specification

---

## File Format Ecosystem

### Format Converter Tool

- TODO [P2]: Create `hydra-convert` CLI tool
  - **Coverage:**
    - Convert between formats: .hydra, .vox, .qb, .obj, .ply
    - Batch processing
    - Command-line options for resolution, compression
  - **Effort:** Large (5-7 days)
  - **Dependencies:** All importers/exporters implemented
  - **Validation:** Tool converts correctly
  - **Deliverable:** `tools/hydra_convert/main.cpp`

- TODO [P3]: Add GUI for format converter
  - **Coverage:**
    - Drag-and-drop files
    - Preview before conversion
    - Progress bar for large files
  - **Effort:** Large (5-7 days)
  - **Dependencies:** GUI library (Dear ImGui, Qt)
  - **Validation:** GUI is intuitive
  - **Deliverable:** `tools/hydra_convert_gui/`

### Format Validation

- TODO [P2]: Create .hydra format validator
  - **Coverage:**
    - Check header magic, version
    - Validate checksums
    - Detect corruption
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Format spec
  - **Validation:** Validator catches corrupt files
  - **Deliverable:** `tools/hydra_validate.cpp`

- TODO [P3]: Add format fuzzer
  - **Coverage:**
    - Fuzz file loaders to find crashes
    - Test malformed .hydra, .vox files
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Fuzzing framework (AFL, libFuzzer)
  - **Validation:** Fuzz finds issues, no crashes after fixes
  - **Deliverable:** Fuzz harness in `tests/fuzz/`

---

## Documentation

### Format Specifications

- TODO [P2]: Document .hydra binary format
  - **Coverage:**
    - Byte-level layout
    - All field descriptions
    - Version history
    - Example files
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Format finalized
  - **Validation:** Third-party implementations possible
  - **Deliverable:** `docs/hydra_format_spec.md`

- TODO [P3]: Create format compatibility matrix
  - **Coverage:**
    - Which formats support which features
    - Import/export capabilities per format
    - Lossiness warnings
  - **Effort:** Small (4 hours)
  - **Dependencies:** All importers/exporters
  - **Validation:** Matrix is accurate
  - **Deliverable:** Table in `docs/formats.md`

### Usage Guides

- TODO [P2]: Write file I/O tutorial
  - **Coverage:**
    - How to save/load scenes
    - Using import/export tools
    - Best practices for file organization
  - **Effort:** Medium (1 day)
  - **Dependencies:** File I/O implemented
  - **Validation:** Tutorial is clear
  - **Deliverable:** `docs/file_io_tutorial.md`

- TODO [P3]: Create format migration guide
  - **Coverage:**
    - Upgrading from old .hydra versions
    - Converting from other voxel tools
  - **Effort:** Small (4 hours)
  - **Dependencies:** Multiple format versions exist
  - **Validation:** Migration successful
  - **Deliverable:** `docs/format_migration.md`

---

## Cross-References

- **Scene management:** `todo_simulation_viewer.md` P2 (scene save/load)
- **Voxel editing:** `todo_simulation_viewer.md` P2 (edit tools need I/O)
- **Examples:** `todo_examples_demos.md` (format converter example)
- **Testing:** `todo_testing_ci.md` (format validation tests)

---

## Estimated Effort (Data Formats & File I/O)

| Priority | Items | Effort (days) |
|----------|-------|---------------|
| **P1**   | 0     | 0             |
| **P2**   | 13    | 35-60         |
| **P3**   | 17    | 120-200       |
| **Total**| **30**| **155-260**   |

**Note:** No P1 items; format work is polish after core functionality. P2 items (native format, MagicaVoxel import/export) improve usability in 0.0.8. P3 items (advanced formats, compression) are long-term.

**Recommendation:** Define P2 .hydra format spec in 0.0.8. Implement import/export in 0.0.9. P3 advanced features as needed.

---

**Document Version:** 1.0
**Created:** 2025-11-25
**Target Release:** P2 in 0.0.8+, P3 long-term
**Owner:** Formats team (TBD)
