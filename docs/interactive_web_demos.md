# Interactive Web Demos Guide

This guide covers the implementation of interactive web-based demos for Hydra, enabling browser-based visualization and experimentation with the graphics system.

## Overview

Interactive web demos provide an accessible way for users to experience Hydra's capabilities without requiring local installation. These demos run in web browsers using WebAssembly (WASM) compilation of the C++ viewer.

## Architecture

### WebAssembly Port

#### Emscripten Build System
Hydra uses Emscripten to compile the C++ SDL viewer to WebAssembly:

```makefile
# WebAssembly build configuration
EMCC = emscripten/emcc
EMAR = emscripten/emar

# WebAssembly flags
EMCC_FLAGS = \
    -s USE_SDL=2 \
    -s USE_SDL_TTF=2 \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s EXPORTED_RUNTIME_METHODS='["ccall","cwrap"]' \
    -s EXPORTED_FUNCTIONS='["_main","_set_canvas_size","_get_frame_time"]' \
    -s MINIFY_HTML=0 \
    --preload-file assets/ \
    --shell-file shell.html

# Build WebAssembly version
web/sim_voxel.js web/sim_voxel.wasm: $(SOURCES)
    $(EMCC) $(SOURCES) $(EMCC_FLAGS) -o web/sim_voxel.html
```

#### File Structure
```
web/
├── sim_voxel.js          # Emscripten-generated JavaScript
├── sim_voxel.wasm        # WebAssembly binary
├── sim_voxel.html        # Generated HTML shell
├── assets/               # Preloaded assets (fonts, textures)
│   ├── fonts/
│   └── textures/
├── demo.html             # Custom demo page
├── demo.js               # Demo-specific JavaScript
└── styles.css            # Demo styling
```

### JavaScript API

#### Viewer Control Interface
```javascript
// Initialize WebAssembly viewer
const Module = {
    canvas: document.getElementById('hydra-canvas'),
    onRuntimeInitialized: function() {
        // Viewer is ready
        console.log('Hydra WebAssembly viewer initialized');
    }
};

// Control functions
function setCameraPosition(x, y, z) {
    Module.ccall('set_camera_pos', 'void', ['number', 'number', 'number'], [x, y, z]);
}

function getFrameTime() {
    return Module.ccall('get_frame_time', 'number', [], []);
}

function loadVoxelScene(data) {
    // Load scene data into WebAssembly memory
    const buffer = Module._malloc(data.length);
    Module.HEAPU8.set(data, buffer);
    Module.ccall('load_scene', 'void', ['number', 'number'], [buffer, data.length]);
    Module._free(buffer);
}
```

#### Event Handling
```javascript
// Mouse controls
const canvas = document.getElementById('hydra-canvas');
canvas.addEventListener('mousedown', (e) => {
    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    Module.ccall('handle_mouse_down', 'void', ['number', 'number', 'number'], [e.button, x, y]);
});

// Keyboard controls
document.addEventListener('keydown', (e) => {
    Module.ccall('handle_key_down', 'void', ['string'], [e.key]);
});
```

## Demo Implementation

### Basic Viewer Demo

#### HTML Structure
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hydra Graphics Demo</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <div class="demo-container">
        <header>
            <h1>Hydra Graphics System Demo</h1>
            <p>Interactive 3D voxel graphics in your browser</p>
        </header>

        <div class="viewer-section">
            <canvas id="hydra-canvas" width="800" height="600"></canvas>
        </div>

        <div class="controls">
            <div class="control-group">
                <label>Camera:</label>
                <button onclick="resetCamera()">Reset</button>
                <button onclick="topView()">Top</button>
                <button onclick="sideView()">Side</button>
            </div>

            <div class="control-group">
                <label>Render Mode:</label>
                <select id="render-mode">
                    <option value="solid">Solid</option>
                    <option value="wireframe">Wireframe</option>
                    <option value="points">Points</option>
                </select>
            </div>

            <div class="control-group">
                <label>Voxel Scene:</label>
                <select id="scene-select">
                    <option value="cube">Cube</option>
                    <option value="sphere">Sphere</option>
                    <option value="terrain">Terrain</option>
                </select>
            </div>
        </div>

        <div class="info-panel">
            <div id="fps-display">FPS: --</div>
            <div id="status">Initializing...</div>
        </div>
    </div>

    <script src="sim_voxel.js"></script>
    <script src="demo.js"></script>
</body>
</html>
```

#### JavaScript Controls
```javascript
// demo.js
let viewerReady = false;

const Module = {
    canvas: document.getElementById('hydra-canvas'),
    onRuntimeInitialized: function() {
        viewerReady = true;
        document.getElementById('status').textContent = 'Ready';
        initControls();
        startRenderLoop();
    }
};

function initControls() {
    // Camera controls
    document.getElementById('render-mode').addEventListener('change', (e) => {
        Module.ccall('set_render_mode', 'void', ['string'], [e.target.value]);
    });

    document.getElementById('scene-select').addEventListener('change', (e) => {
        loadScene(e.target.value);
    });
}

function resetCamera() {
    Module.ccall('reset_camera', 'void', [], []);
}

function topView() {
    Module.ccall('set_camera_top_view', 'void', [], []);
}

function sideView() {
    Module.ccall('set_camera_side_view', 'void', [], []);
}

function loadScene(sceneName) {
    fetch(`scenes/${sceneName}.bin`)
        .then(response => response.arrayBuffer())
        .then(data => {
            const buffer = Module._malloc(data.byteLength);
            Module.HEAPU8.set(new Uint8Array(data), buffer);
            Module.ccall('load_scene', 'void', ['number', 'number'], [buffer, data.byteLength]);
            Module._free(buffer);
        });
}

function startRenderLoop() {
    function render() {
        if (viewerReady) {
            Module.ccall('render_frame', 'void', [], []);
            updateFPS();
        }
        requestAnimationFrame(render);
    }
    render();
}

function updateFPS() {
    const fps = Module.ccall('get_fps', 'number', [], []);
    document.getElementById('fps-display').textContent = `FPS: ${fps.toFixed(1)}`;
}
```

#### CSS Styling
```css
/* styles.css */
.demo-container {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

.viewer-section {
    text-align: center;
    margin: 20px 0;
    border: 2px solid #333;
    border-radius: 8px;
    overflow: hidden;
    background: #000;
}

#hydra-canvas {
    display: block;
    background: #111;
}

.controls {
    display: flex;
    flex-wrap: wrap;
    gap: 20px;
    margin: 20px 0;
    padding: 20px;
    background: #f5f5f5;
    border-radius: 8px;
}

.control-group {
    display: flex;
    align-items: center;
    gap: 10px;
}

.control-group label {
    font-weight: bold;
    min-width: 100px;
}

button, select {
    padding: 8px 16px;
    border: 1px solid #ccc;
    border-radius: 4px;
    background: white;
    cursor: pointer;
}

button:hover {
    background: #e0e0e0;
}

.info-panel {
    display: flex;
    justify-content: space-between;
    padding: 10px;
    background: #333;
    color: white;
    border-radius: 4px;
    font-family: monospace;
}
```

### Advanced Demo Features

#### Scene Editor Demo
```javascript
// Scene editor functionality
class SceneEditor {
    constructor() {
        this.selectedVoxel = null;
        this.brushSize = 1;
        this.brushColor = 0xFFFFFF;
        this.init();
    }

    init() {
        this.setupToolbar();
        this.setupMouseHandlers();
        this.setupKeyboardHandlers();
    }

    setupToolbar() {
        // Color picker
        const colorPicker = document.createElement('input');
        colorPicker.type = 'color';
        colorPicker.value = '#ffffff';
        colorPicker.addEventListener('change', (e) => {
            this.brushColor = parseInt(e.target.value.slice(1), 16);
        });
        document.getElementById('toolbar').appendChild(colorPicker);

        // Brush size
        const sizeSlider = document.createElement('input');
        sizeSlider.type = 'range';
        sizeSlider.min = 1;
        sizeSlider.max = 10;
        sizeSlider.value = 1;
        sizeSlider.addEventListener('input', (e) => {
            this.brushSize = parseInt(e.target.value);
        });
        document.getElementById('toolbar').appendChild(sizeSlider);
    }

    setupMouseHandlers() {
        const canvas = document.getElementById('hydra-canvas');

        canvas.addEventListener('click', (e) => {
            const worldPos = this.screenToWorld(e.offsetX, e.offsetY);
            if (e.ctrlKey) {
                this.eraseVoxel(worldPos);
            } else {
                this.placeVoxel(worldPos);
            }
        });

        canvas.addEventListener('mousemove', (e) => {
            if (e.buttons & 1) { // Left mouse button
                const worldPos = this.screenToWorld(e.offsetX, e.offsetY);
                this.placeVoxel(worldPos);
            }
        });
    }

    screenToWorld(screenX, screenY) {
        // Convert screen coordinates to world coordinates
        const worldX = Module.ccall('screen_to_world_x', 'number', ['number', 'number'], [screenX, screenY]);
        const worldY = Module.ccall('screen_to_world_y', 'number', ['number', 'number'], [screenX, screenY]);
        const worldZ = Module.ccall('screen_to_world_z', 'number', ['number', 'number'], [screenX, screenY]);
        return { x: worldX, y: worldY, z: worldZ };
    }

    placeVoxel(pos) {
        Module.ccall('place_voxel', 'void', ['number', 'number', 'number', 'number', 'number'],
                    [pos.x, pos.y, pos.z, this.brushColor, this.brushSize]);
    }

    eraseVoxel(pos) {
        Module.ccall('erase_voxel', 'void', ['number', 'number', 'number', 'number'],
                    [pos.x, pos.y, pos.z, this.brushSize]);
    }
}

// Initialize editor when viewer is ready
const sceneEditor = new SceneEditor();
```

#### Performance Demo
```javascript
// Performance monitoring and visualization
class PerformanceMonitor {
    constructor() {
        this.frameTimes = [];
        this.maxSamples = 100;
        this.chart = null;
        this.init();
    }

    init() {
        this.createChart();
        this.startMonitoring();
    }

    createChart() {
        const ctx = document.getElementById('performance-chart').getContext('2d');
        this.chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: 'Frame Time (ms)',
                    data: [],
                    borderColor: 'rgb(75, 192, 192)',
                    tension: 0.1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Frame Time (ms)'
                        }
                    }
                }
            }
        });
    }

    startMonitoring() {
        setInterval(() => {
            const frameTime = Module.ccall('get_frame_time', 'number', [], []);
            this.addSample(frameTime);
            this.updateChart();
            this.updateStats();
        }, 100); // Update 10 times per second
    }

    addSample(frameTime) {
        this.frameTimes.push(frameTime);
        if (this.frameTimes.length > this.maxSamples) {
            this.frameTimes.shift();
        }
    }

    updateChart() {
        this.chart.data.labels = this.frameTimes.map((_, i) => i.toString());
        this.chart.data.datasets[0].data = this.frameTimes;
        this.chart.update();
    }

    updateStats() {
        const avgFrameTime = this.frameTimes.reduce((a, b) => a + b, 0) / this.frameTimes.length;
        const fps = 1000 / avgFrameTime;
        const minFrameTime = Math.min(...this.frameTimes);
        const maxFrameTime = Math.max(...this.frameTimes);

        document.getElementById('avg-fps').textContent = fps.toFixed(1);
        document.getElementById('avg-frame-time').textContent = avgFrameTime.toFixed(2);
        document.getElementById('min-frame-time').textContent = minFrameTime.toFixed(2);
        document.getElementById('max-frame-time').textContent = maxFrameTime.toFixed(2);
    }
}
```

## Build and Deployment

### Emscripten Setup

#### Installation
```bash
# Install Emscripten SDK
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
```

#### Build Configuration
```makefile
# web/Makefile
EMSDK_PATH ?= /path/to/emsdk
SHELL := /bin/bash

.PHONY: all clean web

all: web

web: sim_voxel.js sim_voxel.wasm sim_voxel.html

sim_voxel.js sim_voxel.wasm sim_voxel.html: $(SOURCES) shell.html
	source $(EMSDK_PATH)/emsdk_env.sh && \
	emcc $(SOURCES) \
		-s USE_SDL=2 \
		-s USE_SDL_TTF=2 \
		-s ALLOW_MEMORY_GROWTH=1 \
		-s EXPORTED_RUNTIME_METHODS='["ccall","cwrap","HEAPU8","HEAPF32","_malloc","_free"]' \
		-s EXPORTED_FUNCTIONS='["_main","_render_frame","_get_fps","_get_frame_time","_set_camera_pos","_reset_camera","_set_render_mode","_load_scene","_place_voxel","_erase_voxel","_screen_to_world_x","_screen_to_world_y","_screen_to_world_z"]' \
		-s MINIFY_HTML=0 \
		--preload-file ../sim/assets@/assets \
		--shell-file shell.html \
		-O3 \
		-o sim_voxel.html

clean:
	rm -f sim_voxel.js sim_voxel.wasm sim_voxel.html
	rm -rf assets/
```

#### Custom HTML Shell
```html
<!-- shell.html -->
<!doctype html>
<html lang="en-us">
<head>
    <meta charset="utf-8">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>{{{ PROJECT_NAME }}}</title>
    <style>
        body {
            margin: 0;
            background: #000;
        }
        #canvas {
            display: block;
            margin: 0 auto;
        }
        #output {
            position: absolute;
            top: 10px;
            left: 10px;
            color: white;
            font-family: monospace;
            background: rgba(0,0,0,0.7);
            padding: 5px;
            border-radius: 3px;
        }
    </style>
</head>
<body>
    <canvas id="canvas" width="800" height="600"></canvas>
    <div id="output">Loading...</div>

    <script type='text/javascript'>
        var Module = {
            canvas: document.getElementById('canvas'),
            print: function(text) {
                console.log(text);
                document.getElementById('output').innerHTML = text;
            },
            printErr: function(text) {
                console.error(text);
            }
        };
    </script>
    {{{ SCRIPT }}}
</body>
</html>
```

### Deployment Options

#### GitHub Pages
```yaml
# .github/workflows/deploy-web.yml
name: Deploy Web Demo
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2

    - name: Setup Emscripten
      run: |
        git clone https://github.com/emscripten-core/emsdk.git
        cd emsdk
        ./emsdk install latest
        ./emsdk activate latest

    - name: Build WebAssembly
      run: |
        source emsdk/emsdk_env.sh
        cd web
        make

    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      if: github.ref == 'refs/heads/main'
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./web
```

#### CDN Hosting
```bash
# Upload to CDN
aws s3 sync web/ s3://hydra-demos/ --acl public-read

# Cloudflare Pages
npx wrangler pages deploy web/
```

## Performance Optimization

### WebAssembly Optimizations

#### Compilation Flags
```makefile
# Optimized build flags
EMCC_OPTIMIZED_FLAGS = \
    -O3 \
    -flto \
    -s ASSERTIONS=0 \
    -s DISABLE_EXCEPTION_CATCHING=1 \
    -s EVAL_CTORS=1 \
    -s MINIMAL_RUNTIME=1 \
    -s SINGLE_FILE=1 \
    -s WASM_BIGINT \
    --closure 1 \
    --llvm-lto 3
```

#### Memory Management
```javascript
// Pre-allocate memory pools
const voxelBuffer = Module._malloc(1024 * 1024); // 1MB voxel data
const tempBuffer = Module._malloc(64 * 1024);   // 64KB temp space

// Use typed arrays for bulk data transfer
const voxelData = new Uint8Array(Module.HEAPU8.buffer, voxelBuffer, 1024 * 1024);

// Cleanup
Module._free(voxelBuffer);
Module._free(tempBuffer);
```

### Rendering Optimizations

#### Frame Rate Management
```javascript
class FrameRateManager {
    constructor(targetFPS = 60) {
        this.targetFPS = targetFPS;
        this.frameInterval = 1000 / targetFPS;
        this.lastFrameTime = 0;
        this.frameCount = 0;
        this.fps = 0;
    }

    shouldRender() {
        const now = performance.now();
        if (now - this.lastFrameTime >= this.frameInterval) {
            this.lastFrameTime = now;
            this.frameCount++;
            return true;
        }
        return false;
    }

    updateFPS() {
        const now = performance.now();
        if (now - this.fpsUpdateTime >= 1000) {
            this.fps = this.frameCount;
            this.frameCount = 0;
            this.fpsUpdateTime = now;
        }
    }
}
```

#### Level of Detail (LOD)
```javascript
// Implement LOD system
function updateLOD(cameraDistance) {
    let lodLevel;
    if (cameraDistance < 10) {
        lodLevel = 3; // High detail
    } else if (cameraDistance < 50) {
        lodLevel = 2; // Medium detail
    } else {
        lodLevel = 1; // Low detail
    }

    Module.ccall('set_lod_level', 'void', ['number'], [lodLevel]);
}
```

## Browser Compatibility

### Supported Browsers
- **Chrome:** 57+ (WebAssembly support)
- **Firefox:** 52+ (WebAssembly support)
- **Safari:** 11+ (WebAssembly support)
- **Edge:** 16+ (WebAssembly support)

### Feature Detection
```javascript
// Check WebAssembly support
function checkWebAssemblySupport() {
    try {
        if (typeof WebAssembly === 'object' &&
            typeof WebAssembly.instantiate === 'function') {
            const module = new WebAssembly.Module(Uint8Array.of(0x0, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00));
            if (module instanceof WebAssembly.Module) {
                return new WebAssembly.Instance(module) instanceof WebAssembly.Instance;
            }
        }
    } catch (e) {}
    return false;
}

// Check WebGL support (fallback for WebAssembly)
function checkWebGLSupport() {
    try {
        const canvas = document.createElement('canvas');
        return !!(window.WebGLRenderingContext &&
                 canvas.getContext('webgl'));
    } catch (e) {
        return false;
    }
}
```

### Fallback Handling
```javascript
// Progressive enhancement
async function initializeViewer() {
    if (checkWebAssemblySupport()) {
        // Load WebAssembly version
        await loadWebAssemblyViewer();
    } else if (checkWebGLSupport()) {
        // Fallback to JavaScript/WebGL version
        await loadWebGLViewer();
    } else {
        // Show static demo or error message
        showFallbackContent();
    }
}
```

## Security Considerations

### Content Security Policy
```html
<!-- CSP headers for WebAssembly -->
<meta http-equiv="Content-Security-Policy" content="
    default-src 'self';
    script-src 'self' 'unsafe-eval';
    style-src 'self' 'unsafe-inline';
    wasm-unsafe-eval;
">
```

### Memory Limits
```javascript
// Monitor memory usage
function checkMemoryUsage() {
    if (performance.memory) {
        const used = performance.memory.usedJSHeapSize;
        const limit = performance.memory.jsHeapSizeLimit;

        if (used > limit * 0.8) {
            console.warn('High memory usage detected');
            // Trigger garbage collection or reduce quality
            Module.ccall('reduce_quality', 'void', [], []);
        }
    }
}
```

## Testing and Validation

### Automated Testing
```javascript
// Web demo test suite
describe('Hydra Web Demo', () => {
    beforeAll(async () => {
        await initializeViewer();
    });

    test('viewer initializes correctly', () => {
        expect(viewerReady).toBe(true);
    });

    test('camera controls work', () => {
        resetCamera();
        const pos = getCameraPosition();
        expect(pos.x).toBeCloseTo(0);
        expect(pos.y).toBeCloseTo(0);
        expect(pos.z).toBeCloseTo(0);
    });

    test('scene loading works', async () => {
        await loadScene('cube');
        const voxelCount = getVoxelCount();
        expect(voxelCount).toBeGreaterThan(0);
    });

    test('performance is acceptable', () => {
        const fps = getAverageFPS();
        expect(fps).toBeGreaterThan(30);
    });
});
```

### Cross-Browser Testing
```bash
# Test on multiple browsers
npx playwright test web-demo.spec.js --browser=all

# Headless testing
npx puppeteer test-demo.js
```

## Future Enhancements

### Advanced Features
- **Multiplayer:** Real-time collaborative editing
- **VR Support:** WebXR integration for VR headsets
- **Mobile Optimization:** Touch controls and responsive design
- **Offline Mode:** Service worker caching
- **Progressive Web App:** Installable web app

### Integration Options
- **API Endpoints:** REST API for scene management
- **WebSockets:** Real-time synchronization
- **File Upload:** Drag-and-drop scene loading
- **Sharing:** Social media integration

### Analytics and Monitoring
- **Usage Tracking:** Google Analytics integration
- **Performance Monitoring:** Real user monitoring
- **Error Reporting:** Sentry integration
- **A/B Testing:** Feature flag system

## Resources

### WebAssembly Tools
- **Emscripten:** https://emscripten.org/
- **WebAssembly.org:** https://webassembly.org/
- **WABT:** https://github.com/WebAssembly/wabt

### JavaScript Libraries
- **Chart.js:** https://www.chartjs.org/
- **Three.js:** https://threejs.org/ (WebGL fallback)
- **Playwright:** https://playwright.dev/

### Learning Resources
- **WebAssembly Guide:** https://developer.mozilla.org/en-US/docs/WebAssembly
- **Emscripten Tutorial:** https://emscripten.org/docs/getting_started/Tutorial.html
- **Web Performance:** https://web.dev/performance/

---

**Document Version:** 1.0
**Last Updated:** 2025-11-28
**Status:** Framework for WebAssembly demo implementation
**Next Steps:** Implement Emscripten build system and basic demo