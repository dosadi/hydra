# Hydra Game Engine Integration Design

This living design note describes how Hydra signals, APIs, and runtimes align with modern gaming engines (Unity, Unreal, Godot, custom) so we can provide higher-level retained APIs and meaningful integrations to the games community.

## Goals

- Define a Hydra-friendly `VoxelRenderer` abstraction that games can hook into as a plug-in renderer, complete with frame submission, selection edits, and feature toggles.
- Map Hydra inputs/outputs (camera/flags, HDR lighting, framebuffer) to the expected property sets used by game engines, specifying coordinate systems, data formats, and handshake semantics.
- Support both native `libhydra` and higher-level wrappers (C#, Blueprints, Godot GDExtension) for quick prototypes, plus optional Unreal Engine plugin that exposes Hydra-specific blueprints/events.

## Retained API Concepts

| Feature | Hydra Primitive | Game Engine Mapping |
|---------|------------------|---------------------|
| Frame Submissions | start_frame / pixel_word x3 | BeginFrame/EndFrame callbacks, custom frame buffers |
| Camera Control | CSR writes + env overrides | Camera component with controller input binding (C#, Blueprint) |
| Selection & Editing | voxel edits via CSRs + DMA | Exposed API functions (SetVoxel, Sweep) and in-editor UI |
| Rendering Flags | HYDRA_RENDER_FLAGS bitfields | Engine UI toggle (UI widget or artist console) |
| Emissive & PBR | pixel_reemissure sideband | Shader material pairings with emissive parameters |
| Debug Telemetry | frame_time, fps, HDR stats | Engine overlays (HUD, Stats) or streaming logs via `scripts/ai_health_dashboard.py` |

## Platform Integration Sketches

1. **Unity/C# plugin**
   - Expose `HydraRendererComponent` derived from `MonoBehaviour`.
   - Use `libhydra` via P/Invoke for CSRs and DMA, wrap selection edits, handle frame callbacks.
   - Provide shader wrappers that sample Hydra framebuffers via native textures or shared memory.

2. **Unreal/Blueprints**
   - Create a Hydra UE module with Blueprint nodes (StartFrame, SetCamera, ToggleFlag).
   - Provide optional Hydra viewport bridging to Unreal render target for mixed content.
   - Hook Hydra upgrade events to dispatcher so artists can create pixel effect materials.

3. **Godot GDExtension**
   - Implement a `HydraVoxelNode` that exposes signals for frame updates, selection events, keyboard inputs.
   - Scripted by GDScript or C++ plugin to read Hydra metadata and adjust camera transforms.

## Automation Hooks

- Document required dependencies, build steps, and test harnesses inside `docs/todo/todo_go_to_market.md` and `docs/todo/todo_content_creation.md`.
- Feed design note references into `docs/todo/todo_dependency_map.md` so automation knows this doc supports both rendering/demos and content pipelines.
- Keep this document updated as the Hydra APIs evolve to maintain compatibility with successive engine updates.
