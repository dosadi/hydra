# Simulation Viewer TODO Tracker

**Last Updated:** 2025-11-25 (Expanded)
**Owner:** Viewer/Simulation Team
**Related Trackers:** `todo_platform_backends.md`, `todo_rendering.md`, `todo_debugging_tools.md`

---

## Overview

Tracks simulation viewer features, HUD improvements, user controls, batch/headless modes, debugging aids, and user experience enhancements. Focus areas: usability, accessibility, debugging, automation, world editing.

**Priority Distribution:**
- **P0:** 0 items - No viewer blockers for 0.0.7
- **P1:** 10 items (~12 days) - High-value UX improvements
- **P2:** 20 items (~25 days) - Extended features
- **P3:** 14 items (~18 days) - Future enhancements

**Total:** 44 items, ~55 engineer-days

---

## P1 - High Priority UX and Debugging (Recommended for 0.0.7)

### HUD and Visual Feedback
- **TODO [P1]:** Add HUD toggle to flash when selection write fails (cursor miss)
  - **Effort:** 1 day
  - **Priority:** P1 - User feedback
  - **Dependencies:** Selection logic stable
  - **Validation:** Warning appears when F pressed without hit
  - **Deliverable:** Selection miss warning in HUD
  - **Status:** Partially done - improve visibility

- **TODO [P1]:** Add on-screen FPS graph (rolling average, min/max)
  - **Effort:** 2 days
  - **Priority:** P1 - Performance visibility
  - **Dependencies:** None
  - **Validation:** Graph shows FPS trends
  - **Deliverable:** FPS graph in HUD

- **TODO [P1]:** Add performance overlay (frame time breakdown, busy %)
  - **Effort:** 2 days
  - **Priority:** P1 - Performance profiling
  - **Dependencies:** Timestamp infrastructure
  - **Validation:** Overlay shows eval/render/display time
  - **Deliverable:** Performance overlay toggle

- **TODO [P1]:** Improve HUD readability (configurable font size, colors, background)
  - **Effort:** 1 day
  - **Priority:** P1 - Accessibility
  - **Dependencies:** None
  - **Validation:** HUD readable on all backgrounds
  - **Deliverable:** HUD configuration options
  - **Status:** Font scale exists - add colors/background

### Controls and Input
- **TODO [P1]:** Add joystick/gamepad support (SDL game controller API)
  - **Effort:** 3 days
  - **Priority:** P1 - Input accessibility
  - **Dependencies:** SDL2 gamepad support
  - **Validation:** Controller can navigate and edit
  - **Deliverable:** Gamepad input handling

- **TODO [P1]:** Add mouse smoothing/acceleration toggle (raw vs. filtered)
  - **Effort:** 1 day
  - **Priority:** P1 - Input precision
  - **Dependencies:** None
  - **Validation:** Smoothing toggle affects mouse feel
  - **Deliverable:** HYDRA_MOUSE_SMOOTH env var

- **TODO [P1]:** Add per-axis camera sensitivity (separate X/Y/pitch/yaw)
  - **Effort:** 1 day
  - **Priority:** P1 - Fine camera control
  - **Dependencies:** None
  - **Validation:** Sensitivity configurable per axis
  - **Deliverable:** HYDRA_SENS_X/Y/PITCH/YAW env vars
  - **Status:** Mentioned in tracker - implement

### Batch and Headless Modes
- **TODO [P1]:** Add scripted camera path playback (JSON/CSV camera sequence)
  - **Effort:** 3 days
  - **Priority:** P1 - Automated captures
  - **Dependencies:** Camera path format defined
  - **Validation:** Playback produces deterministic output
  - **Deliverable:** Camera path player

- **TODO [P1]:** Add multi-frame batch render mode (output numbered frames)
  - **Effort:** 2 days
  - **Priority:** P1 - Video generation
  - **Dependencies:** Frame numbering infrastructure
  - **Validation:** Batch render outputs frame sequence
  - **Deliverable:** HYDRA_FRAME_RANGE env var
  - **Status:** HYDRA_MAX_FRAME_DUMPS exists - extend

- **TODO [P1]:** Document all viewer modes (interactive, headless, batch, safe capture)
  - **Effort:** 1 day
  - **Priority:** P1 - User documentation
  - **Dependencies:** Modes implemented
  - **Validation:** Users can run all modes from docs
  - **Deliverable:** Section in sim_controls.md or viewer_modes.md

---

## P2 - Medium Priority Extended Features (Nice-to-Have)

### Advanced HUD Features
- **TODO [P2]:** Add minimap (top-down 2D view of voxel volume)
  - **Effort:** 4 days
  - **Priority:** P2 - Navigation aid
  - **Dependencies:** None
  - **Validation:** Minimap shows camera position and orientation
  - **Deliverable:** Minimap toggle (M key)

- **TODO [P2]:** Add compass/orientation indicator (N/S/E/W directions)
  - **Effort:** 1 day
  - **Priority:** P2 - Orientation aid
  - **Dependencies:** None
  - **Validation:** Compass shows current heading
  - **Deliverable:** Compass in HUD

- **TODO [P2]:** Add crosshair customization (style, color, size)
  - **Effort:** 1 day
  - **Priority:** P2 - Personalization
  - **Dependencies:** None
  - **Validation:** Crosshair configurable
  - **Deliverable:** HYDRA_CROSSHAIR_* env vars

- **TODO [P2]:** Add voxel type/color info display (show voxel under cursor)
  - **Effort:** 2 days
  - **Priority:** P2 - Inspection tool
  - **Dependencies:** Voxel data accessible
  - **Validation:** HUD shows voxel type at cursor
  - **Deliverable:** Voxel inspector in HUD

- **TODO [P2]:** Add screenshot hotkey with customizable format (PNG, PPM, BMP)
  - **Effort:** 2 days
  - **Priority:** P2 - Capture flexibility
  - **Dependencies:** Image encoding libs
  - **Validation:** Screenshots in multiple formats
  - **Deliverable:** Format selection env var
  - **Status:** PPM exists - add PNG/BMP

### World Editing and Interaction
- **TODO [P2]:** Add voxel painting mode (brush, palette, undo/redo)
  - **Effort:** 5 days
  - **Priority:** P2 - Creative tool
  - **Dependencies:** Voxel write API
  - **Validation:** Can paint and undo edits
  - **Deliverable:** Paint mode toggle (P key)

- **TODO [P2]:** Add voxel copy/paste (select region, copy, paste elsewhere)
  - **Effort:** 4 days
  - **Priority:** P2 - Editing productivity
  - **Dependencies:** Selection region
  - **Validation:** Copy/paste works correctly
  - **Deliverable:** Copy/paste hotkeys (Ctrl+C/V)

- **TODO [P2]:** Add voxel fill tool (flood fill, box fill)
  - **Effort:** 3 days
  - **Priority:** P2 - Bulk editing
  - **Dependencies:** Voxel write API
  - **Validation:** Fill operations work
  - **Deliverable:** Fill tool (F key in edit mode)

- **TODO [P2]:** Add undo/redo stack for voxel edits
  - **Effort:** 3 days
  - **Priority:** P2 - Edit safety
  - **Dependencies:** Edit history tracking
  - **Validation:** Undo/redo works correctly
  - **Deliverable:** Ctrl+Z/Y hotkeys

- **TODO [P2]:** Add world save/load (export/import voxel data)
  - **Effort:** 4 days
  - **Priority:** P2 - Persistence
  - **Dependencies:** Voxel file format defined
  - **Validation:** Save/load preserves world
  - **Deliverable:** Save/load hotkeys and CLI
  - **Notes:** See todo_data_formats.md

### Camera and Navigation
- **TODO [P2]:** Add bookmarked camera positions (save/recall viewpoints)
  - **Effort:** 2 days
  - **Priority:** P2 - Navigation productivity
  - **Dependencies:** None
  - **Validation:** Bookmarks save/recall correctly
  - **Deliverable:** Bookmark hotkeys (Ctrl+1-9, 1-9)

- **TODO [P2]:** Add smooth camera transitions (interpolated movement)
  - **Effort:** 3 days
  - **Priority:** P2 - Visual polish
  - **Dependencies:** None
  - **Validation:** Camera moves smoothly between points
  - **Deliverable:** Smooth transition toggle

- **TODO [P2]:** Add orbit camera mode (rotate around point)
  - **Effort:** 3 days
  - **Priority:** P2 - Inspection mode
  - **Dependencies:** Orbit math
  - **Validation:** Camera orbits around target
  - **Deliverable:** Orbit mode toggle (O key)

## P3 - Automation & Dashboard Integration

- **TODO [P3]:** Log viewer telemetry (FPS, camera path, HUD state) into `out/viewer_health.json` and have `scripts/ai_health_dashboard.py` consume it so viewer regressions show up in the dashboard summary.
- **TODO [P3]:** Create a viewer regression harness that runs multiple backend combos via `scripts/ai_health_dashboard.py` and captures frame diffs per backend in `out/viewer_regression/`.
- **TODO [P3]:** Maintain a viewer feature backlog section (list of quick fixes vs product-level rewrites) that references this tracker so contributors can span bugfixes through new feature initiatives without assuming a fixed size.

- **TODO [P2]:** Add camera FOV (field of view) adjustment
  - **Effort:** 2 days
  - **Priority:** P2 - Viewing flexibility
  - **Dependencies:** RTL FOV parameter
  - **Validation:** FOV adjusts via hotkey
  - **Deliverable:** FOV adjust (,/. keys)

### Debug and Visualization
- **TODO [P2]:** Add ray visualization (show ray path through voxels)
  - **Effort:** 3 days
  - **Priority:** P2 - Debug aid
  - **Dependencies:** Ray trace data export
  - **Validation:** Ray path visible in viewer
  - **Deliverable:** Ray visualization toggle
  - **Notes:** See todo_debugging_tools.md

- **TODO [P2]:** Add grid overlay (show voxel grid lines)
  - **Effort:** 2 days
  - **Priority:** P2 - Orientation aid
  - **Dependencies:** None
  - **Validation:** Grid visible at toggle
  - **Deliverable:** Grid toggle (G key)

- **TODO [P2]:** Add axis indicator (X/Y/Z axes at origin)
  - **Effort:** 1 day
  - **Priority:** P2 - Orientation aid
  - **Dependencies:** None
  - **Validation:** Axes visible at toggle
  - **Deliverable:** Axis toggle (A key)

- **TODO [P2]:** Add HUD layer group toggles (inputs/memory/ray stats) so users can mix/hide specific sections without editing code.
- **TODO [P2]:** Add performance profiler visualization (heat map, bottlenecks)
  - **Effort:** 4 days
  - **Priority:** P2 - Performance analysis
  - **Dependencies:** Profiler data
  - **Validation:** Heat map shows slow areas
  - **Deliverable:** Profiler visualization
  - **Notes:** See todo_performance.md

### Automation and Scripting
- **TODO [P2]:** Add demo mode (automated camera path, flag toggles, narration)
  - **Effort:** 4 days
  - **Priority:** P2 - Marketing/demos
  - **Dependencies:** Camera path, script format
  - **Validation:** Demo runs automatically
  - **Deliverable:** Demo script player
  - **Status:** Mentioned in tracker - implement

- **TODO [P2]:** Add input recording/playback (record mouse/keyboard, replay)
  - **Effort:** 3 days
  - **Priority:** P2 - Reproducible demos
  - **Dependencies:** Input event logging
  - **Validation:** Playback reproduces input
  - **Deliverable:** Record/playback mode
  - **Status:** Mentioned in todo_master - implement

- **TODO [P2]:** Add scripting interface (Lua or Python for automation)
  - **Effort:** 5 days
  - **Priority:** P2 - Advanced automation
  - **Dependencies:** Scripting language embedding
  - **Validation:** Scripts can control viewer
  - **Deliverable:** Scripting API

---

## P3 - Low Priority Future Enhancements (Future Work)

### Advanced Visualization
- **TODO [P3]:** Add stereoscopic 3D rendering (side-by-side, anaglyph)
  - **Effort:** 5 days
  - **Priority:** P3 - VR/3D prep
  - **Dependencies:** Dual camera rendering
  - **Validation:** Stereo output works
  - **Deliverable:** Stereo mode toggle

- **TODO [P3]:** Add VR headset support (OpenVR, Oculus SDK)
  - **Effort:** 10 days
  - **Priority:** P3 - Immersive experience
  - **Dependencies:** VR SDK integration
  - **Validation:** VR headset works
  - **Deliverable:** VR mode

- **TODO [P3]:** Add augmented reality (AR) overlay mode
  - **Effort:** 7 days
  - **Priority:** P3 - Advanced visualization
  - **Dependencies:** AR framework
  - **Validation:** AR overlay works
  - **Deliverable:** AR mode

### Advanced Editing
- **TODO [P3]:** Add procedural voxel generation tools (noise, fractals, L-systems)
  - **Effort:** 7 days
  - **Priority:** P3 - Content creation
  - **Dependencies:** Procedural algorithms
  - **Validation:** Procedural tools work
  - **Deliverable:** Procedural toolset

- **TODO [P3]:** Add voxel sculpting (smooth, carve, extrude)
  - **Effort:** 8 days
  - **Priority:** P3 - Artistic tools
  - **Dependencies:** Voxel manipulation
  - **Validation:** Sculpting tools work
  - **Deliverable:** Sculpting mode

- **TODO [P3]:** Add parametric object insertion (sphere, cube, cylinder)
  - **Effort:** 4 days
  - **Priority:** P3 - Modeling tools
  - **Dependencies:** Parametric algorithms
  - **Validation:** Objects insert correctly
  - **Deliverable:** Object insertion menu

### Multiplayer and Collaboration
- **TODO [P3]:** Add networked multi-viewer (multiple users in same world)
  - **Effort:** 10 days
  - **Priority:** P3 - Collaboration
  - **Dependencies:** Network protocol
  - **Validation:** Multi-user works
  - **Deliverable:** Networked mode

- **TODO [P3]:** Add collaborative editing (real-time multi-user editing)
  - **Effort:** 8 days
  - **Priority:** P3 - Collaboration
  - **Dependencies:** Conflict resolution
  - **Validation:** Collaborative edits work
  - **Deliverable:** Collaborative mode

### Performance and Quality
- **TODO [P3]:** Add level-of-detail (LOD) system for distant voxels
  - **Effort:** 5 days
  - **Priority:** P3 - Performance
  - **Dependencies:** LOD rendering
  - **Validation:** LOD improves FPS
  - **Deliverable:** LOD system

- **TODO [P3]:** Add temporal anti-aliasing (TAA)
  - **Effort:** 6 days
  - **Priority:** P3 - Visual quality
  - **Dependencies:** Multi-frame history
  - **Validation:** TAA reduces aliasing
  - **Deliverable:** TAA toggle

- **TODO [P3]:** Add super-sampling anti-aliasing (SSAA)
  - **Effort:** 3 days
  - **Priority:** P3 - Visual quality
  - **Dependencies:** Higher resolution rendering
  - **Validation:** SSAA improves quality
  - **Deliverable:** SSAA factor control

### Accessibility
- **TODO [P3]:** Add colorblind modes (deuteranopia, protanopia, tritanopia)
  - **Effort:** 3 days
  - **Priority:** P3 - Accessibility
  - **Dependencies:** Color remapping
  - **Validation:** Colorblind modes work
  - **Deliverable:** Colorblind mode selection

- **TODO [P3]:** Add screen reader support for HUD text
  - **Effort:** 4 days
  - **Priority:** P3 - Accessibility
  - **Dependencies:** Screen reader API
  - **Validation:** Screen reader narrates HUD
  - **Deliverable:** Screen reader integration

- **TODO [P3]:** Add high-contrast mode for visibility
  - **Effort:** 2 days
  - **Priority:** P3 - Accessibility
  - **Dependencies:** None
  - **Validation:** High contrast improves visibility
  - **Deliverable:** High contrast toggle

---

## Feature Completion Status

### Implemented (DONE)
- ✅ Safe capture mode (HYDRA_SAFE_CAPTURE, F3)
- ✅ World seed override (HYDRA_WORLD_SEED)
- ✅ Mouse capture indicator and toggle
- ✅ Keybindings overlay (F1 sticky, / timed)
- ✅ Safe defaults preset (HYDRA_SAFE_DEFAULTS, F2)
- ✅ Camera pos/angle env vars (HYDRA_CAM_POS, HYDRA_CAM_ANG)
- ✅ Backend selection (HYDRA_BACKEND, --backend)
- ✅ Screenshot to PPM (S key)
- ✅ Camera reset (R key)
- ✅ HUD toggle (H key)
- ✅ Theme toggle (T key)
- ✅ Invert Y mouse (HYDRA_INVERT_Y)
- ✅ Font size scaling (HYDRA_FONT_SCALE)
- ✅ Autosave/autoload config (HYDRA_AUTOSAVE_CFG)

### In Progress
- 🟡 Config file parser (autosave exists, extend to seed/backend)
- 🟡 Selection miss warning (basic implementation, improve)

### Planned (TODO)
- ❌ Audio feedback on selection/edit
- ❌ Seed randomize hotkey
- ❌ Demo mode (scripted camera paths)
- ❌ Per-axis sensitivity
- ❌ Cursor ray visualization
- ❌ Many more (see P1/P2/P3 lists above)

---

## Control Scheme Reference

### Current Hotkeys
- **WASD:** Camera movement (forward/left/back/right)
- **Q/E:** Camera up/down
- **Mouse:** Look around (pitch/yaw)
- **F:** Select voxel at screen center
- **0-9:** Toggle render flags
- **C/X/Z/B:** Voxel edit operations (when selection active)
- **O:** Toggle diagnostic slice renderer
- **S:** Screenshot (timestamped PPM)
- **R:** Reset camera and flags
- **H:** Toggle HUD
- **T:** Toggle HUD theme (light/dark)
- **V:** Cycle pixel view mode (color/word0/word2/sideband)
- **F1:** Toggle keybindings overlay (sticky)
- **/:** Show keybindings popup (timed)
- **F2:** Toggle safe defaults
- **F3:** Toggle safe capture mode
- **P:** Dump camera state to stdout

### Proposed Hotkeys (not yet implemented)
- **M:** Toggle minimap
- **G:** Toggle grid overlay
- **A:** Toggle axis indicator
- **P (in edit mode):** Paint mode
- **Ctrl+C/V:** Copy/paste voxels
- **Ctrl+Z/Y:** Undo/redo edits
- **Ctrl+1-9:** Save camera bookmark
- **1-9 (in bookmark mode):** Recall camera bookmark
- **,/.:** Adjust FOV
- **O (alt):** Orbit camera mode

---

## Environment Variables Reference

### Implemented
- `HYDRA_BACKEND` - Backend selection (SDL, GL, etc.)
- `HYDRA_CAM_POS` - Initial camera position (x,y,z)
- `HYDRA_CAM_ANG` - Initial camera angles (yaw,pitch)
- `HYDRA_MOVE_SPEED` - Camera movement speed
- `HYDRA_MOUSE_SENS` - Mouse sensitivity
- `HYDRA_INVERT_Y` - Invert Y-axis mouse
- `HYDRA_FONT` - Font path override
- `HYDRA_FONT_SCALE` - Font size scaling
- `HYDRA_WORLD_SEED` - Procedural world seed
- `HYDRA_SAFE_DEFAULTS` - Enable safe defaults
- `HYDRA_SAFE_CAPTURE` - Enable safe capture mode
- `HYDRA_AUTOSAVE_CFG` - Autosave config file path
- `HYDRA_MOUSE_CAPTURE` - Enable/disable mouse capture
- `HYDRA_CAM_CLAMP` - Clamp camera to bounds
- `HYDRA_CAM_BOUNDS` - Camera boundary limits
- `HYDRA_FPS_TARGET` - Target FPS for frame pacing
- `HYDRA_CLEAR_EACH_FRAME` - Clear framebuffer each frame
- `HYDRA_CLEAR_COLOR` - Framebuffer clear color
- `HYDRA_PIXEL_VIEW` - Initial pixel view mode
- `FRAME_DUMP` - Frame dump path
- `AUTO_EXIT` - Auto-exit after capture
- `HYDRA_MAX_FRAME_DUMPS` - Max frames to dump
- `HYDRA_FRAME_BASE` - Frame dump basename
- `LOG_FRAMES` - Enable frame logging
- `LOG_KEYS` - Enable key logging

### Proposed (not yet implemented)
- `HYDRA_MOUSE_SMOOTH` - Mouse smoothing toggle
- `HYDRA_SENS_X/Y/PITCH/YAW` - Per-axis sensitivity
- `HYDRA_CROSSHAIR_*` - Crosshair customization
- `HYDRA_FRAME_RANGE` - Batch render frame range
- Many more (see P1/P2/P3 lists)

---

## Cross-References

**Related Work:**
- See `todo_platform_backends.md` for backend implementation
- See `todo_rendering.md` for visual quality improvements
- See `todo_debugging_tools.md` for profiling and visualization
- See `todo_data_formats.md` for world save/load formats
- See `todo_examples_demos.md` for demo content

**Blocking Items:**
- No P0 viewer items - all features are enhancements
- P1 items improve UX significantly for demos and testing

---

## Notes

- **Viewer is feature-rich** with extensive DONE list
- **P1 items enhance testing/demos** - valuable for 0.0.7
- **P2 items are creative tools** - defer to post-0.0.7
- **P3 items are long-term vision** - VR, multiplayer, advanced editing

**Viewer Philosophy:**
1. **Usability first** - make common tasks easy
2. **Accessibility** - support diverse users
3. **Automation** - enable scripting and batch operations
4. **Debugging** - expose internals for development
5. **Extensibility** - scripting and plugin support (future)

**Next Actions:**
1. Add FPS graph (P1, quick win)
2. Implement gamepad support (P1, accessibility)
3. Add camera path playback (P1, automation)
4. Document viewer modes (P1, documentation)

---

**Document Version:** 2.0 (Expanded)
**Created:** 2025-11-25
**Status:** Active tracker for simulation viewer features
