# Refactor viewer code architecture

## Current State
- live_sdl_main.cpp is ~2500+ lines monolithic file
- Contains main simulation loop, input handling, rendering, backend selection
- Hard to maintain and navigate

## Proposed Structure
- viewer_main.cpp: Entry point and high-level orchestration
- viewer_simulation.cpp/h: Core simulation logic and Verilator harness
- viewer_input.cpp/h: Input handling (keyboard, mouse, SDL events)
- viewer_rendering.cpp/h: Framebuffer management and HUD rendering
- viewer_backend.cpp/h: Platform backend selection and management
- viewer_config.cpp/h: Configuration parsing and environment variables

## Benefits
- Improved maintainability and code navigation
- Easier testing of individual components
- Better separation of concerns
- Reduced merge conflicts

## Implementation Steps
1. Extract input handling into viewer_input.*
2. Extract rendering/HUD logic into viewer_rendering.*
3. Extract backend management into viewer_backend.*
4. Extract configuration into viewer_config.*
5. Extract core simulation into viewer_simulation.*
6. Update Makefile to compile all new files
7. Test all backends and modes work correctly

## Priority
P3 - Code quality improvement, not blocking functionality
