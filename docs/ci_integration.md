# Hydra CI Integration Guide

This guide shows how to integrate Hydra into various CI/CD systems for automated testing and validation.

## Table of Contents

- [Quick Start](#quick-start)
- [GitHub Actions](#github-actions)
- [GitLab CI](#gitlab-ci)
- [Jenkins](#jenkins)
- [CircleCI](#circleci)
- [Travis CI](#travis-ci)
- [Docker-based CI](#docker-based-ci)
- [Best Practices](#best-practices)

---

## Quick Start

### Minimal Headless Test

The simplest CI integration uses the headless backend:

```bash
# Build simulator
make -C sim

# Run headless smoke test
HYDRA_BACKEND=headless \
FRAME_DUMP=/tmp/test.ppm \
AUTO_EXIT=1 \
./sim/sim_voxel

# Verify frame was generated
test -f /tmp/test.ppm
test $(stat -c%s /tmp/test.ppm) -gt 1000
```

### With Backend Validation

For more thorough testing:

```bash
# Run backend smoke test suite
./sim/tests/backend_smoke.sh --quick

# Or run full backend selection tests
./sim/tests/test_backend_selection.sh
```

---

## GitHub Actions

### Basic Workflow

`.github/workflows/hydra-ci.yml`:

```yaml
name: Hydra CI

on: [push, pull_request]

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y \
            build-essential \
            libsdl2-dev \
            libsdl2-ttf-dev \
            verilator \
            python3 \
            python3-pip

      - name: Build simulator
        run: make -C sim

      - name: Run headless backend test
        run: |
          HYDRA_BACKEND=headless \
          FRAME_DUMP=/tmp/test_frame.ppm \
          AUTO_EXIT=1 \
          ./sim/sim_voxel

      - name: Verify frame output
        run: |
          test -f /tmp/test_frame.ppm
          size=$(stat -c%s /tmp/test_frame.ppm)
          echo "Frame size: $size bytes"
          test $size -gt 1000

      - name: Run backend smoke tests
        run: ./sim/tests/backend_smoke.sh --quick

      - name: Upload frame as artifact
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-frame
          path: /tmp/test_frame.ppm
```

### Multi-Platform Matrix

Test across multiple platforms:

```yaml
name: Multi-Platform CI

on: [push, pull_request]

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        backend: [headless, sdl]
    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - name: Install Linux dependencies
        if: runner.os == 'Linux'
        run: |
          sudo apt-get update
          sudo apt-get install -y \
            libsdl2-dev libsdl2-ttf-dev verilator

      - name: Install macOS dependencies
        if: runner.os == 'macOS'
        run: |
          brew update
          brew install sdl2 sdl2_ttf verilator

      - name: Build
        run: make -C sim

      - name: Test backend
        env:
          HYDRA_BACKEND: ${{ matrix.backend }}
          SDL_VIDEODRIVER: dummy
        run: |
          FRAME_DUMP=/tmp/test.ppm AUTO_EXIT=1 ./sim/sim_voxel
          test -f /tmp/test.ppm
```

### With OpenGL (Xvfb)

For testing GL backend on Linux:

```yaml
      - name: Install Xvfb for GL testing
        run: |
          sudo apt-get install -y xvfb mesa-utils

      - name: Test OpenGL backend
        run: |
          xvfb-run -a ./sim/tests/backend_smoke.sh
```

---

## GitLab CI

`.gitlab-ci.yml`:

```yaml
image: ubuntu:22.04

variables:
  DEBIAN_FRONTEND: noninteractive

stages:
  - build
  - test
  - validate

before_script:
  - apt-get update
  - apt-get install -y build-essential libsdl2-dev libsdl2-ttf-dev verilator python3

build:
  stage: build
  script:
    - make -C sim
  artifacts:
    paths:
      - sim/sim_voxel
      - sim/obj_dir/
    expire_in: 1 hour

test_headless:
  stage: test
  dependencies:
    - build
  script:
    - HYDRA_BACKEND=headless FRAME_DUMP=/tmp/test.ppm AUTO_EXIT=1 ./sim/sim_voxel
    - test -f /tmp/test.ppm
    - test $(stat -c%s /tmp/test.ppm) -gt 1000
  artifacts:
    when: always
    paths:
      - /tmp/test.ppm
    expire_in: 1 week

test_backends:
  stage: test
  dependencies:
    - build
  script:
    - ./sim/tests/backend_smoke.sh --quick

platform_capabilities:
  stage: validate
  dependencies:
    - build
  script:
    - ./scripts/probe_platform.sh --json > platform_caps.json
    - ./sim/sim_voxel --show-capabilities
  artifacts:
    reports:
      dotenv: platform_caps.json
```

---

## Jenkins

`Jenkinsfile`:

```groovy
pipeline {
    agent any

    stages {
        stage('Setup') {
            steps {
                sh '''
                    sudo apt-get update
                    sudo apt-get install -y libsdl2-dev libsdl2-ttf-dev verilator
                '''
            }
        }

        stage('Build') {
            steps {
                sh 'make -C sim'
            }
        }

        stage('Test') {
            parallel {
                stage('Headless Test') {
                    steps {
                        sh '''
                            HYDRA_BACKEND=headless \
                            FRAME_DUMP=${WORKSPACE}/test_frame.ppm \
                            AUTO_EXIT=1 \
                            ./sim/sim_voxel
                        '''
                    }
                }

                stage('Backend Smoke') {
                    steps {
                        sh './sim/tests/backend_smoke.sh --quick'
                    }
                }
            }
        }

        stage('Validate') {
            steps {
                sh '''
                    test -f ${WORKSPACE}/test_frame.ppm
                    SIZE=$(stat -c%s ${WORKSPACE}/test_frame.ppm)
                    echo "Frame size: ${SIZE} bytes"
                    test ${SIZE} -gt 1000
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'test_frame.ppm', allowEmptyArchive: true
            cleanWs()
        }
    }
}
```

---

## CircleCI

`.circleci/config.yml`:

```yaml
version: 2.1

jobs:
  build-and-test:
    docker:
      - image: ubuntu:22.04

    steps:
      - checkout

      - run:
          name: Install dependencies
          command: |
            apt-get update
            apt-get install -y build-essential libsdl2-dev libsdl2-ttf-dev verilator python3

      - run:
          name: Build simulator
          command: make -C sim

      - run:
          name: Headless test
          command: |
            HYDRA_BACKEND=headless FRAME_DUMP=/tmp/test.ppm AUTO_EXIT=1 ./sim/sim_voxel
            test -f /tmp/test.ppm

      - run:
          name: Backend smoke tests
          command: ./sim/tests/backend_smoke.sh --quick

      - store_artifacts:
          path: /tmp/test.ppm
          destination: test-frame.ppm

workflows:
  version: 2
  build-test:
    jobs:
      - build-and-test
```

---

## Travis CI

`.travis.yml`:

```yaml
language: c

os:
  - linux
  - osx

dist: jammy

addons:
  apt:
    packages:
      - build-essential
      - libsdl2-dev
      - libsdl2-ttf-dev
      - verilator

before_install:
  - if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then brew update; fi
  - if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then brew install sdl2 sdl2_ttf verilator; fi

script:
  - make -C sim
  - HYDRA_BACKEND=headless FRAME_DUMP=/tmp/test.ppm AUTO_EXIT=1 ./sim/sim_voxel
  - test -f /tmp/test.ppm
  - ./sim/tests/backend_smoke.sh --quick

after_success:
  - ls -lh /tmp/test.ppm
```

---

## Docker-based CI

### Dockerfile for CI

`docker/Dockerfile.ci`:

```dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libsdl2-dev \
    libsdl2-ttf-dev \
    verilator \
    python3 \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /hydra

# Copy source
COPY . .

# Build simulator
RUN make -C sim

# Set entrypoint for testing
ENTRYPOINT ["/hydra/sim/sim_voxel"]
```

### Build and Test with Docker

```bash
# Build CI image
docker build -f docker/Dockerfile.ci -t hydra-ci .

# Run headless test
docker run --rm \
  -e HYDRA_BACKEND=headless \
  -e FRAME_DUMP=/tmp/test.ppm \
  -e AUTO_EXIT=1 \
  -v $(pwd)/output:/output \
  hydra-ci

# Run backend smoke
docker run --rm \
  --entrypoint /hydra/sim/tests/backend_smoke.sh \
  hydra-ci \
  --quick
```

### Docker Compose for CI

`docker-compose.ci.yml`:

```yaml
version: '3.8'

services:
  hydra-test:
    build:
      context: .
      dockerfile: docker/Dockerfile.ci
    environment:
      - HYDRA_BACKEND=headless
      - FRAME_DUMP=/output/test.ppm
      - AUTO_EXIT=1
    volumes:
      - ./ci-output:/output
```

Run with:

```bash
docker-compose -f docker-compose.ci.yml up --abort-on-container-exit
```

---

## Best Practices

### 1. Always Use Headless in CI

Unless testing specific backends, use headless mode:

```bash
export HYDRA_BACKEND=headless
export SDL_VIDEODRIVER=dummy  # For SDL fallback
```

### 2. Capture Artifacts

Always save generated frames for debugging:

```yaml
- name: Upload artifacts
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: test-outputs
    path: |
      /tmp/*.ppm
      sim/build/*.log
```

### 3. Log Platform Capabilities

Include platform info in CI logs:

```bash
./scripts/probe_platform.sh
./sim/sim_voxel --show-capabilities
```

### 4. Use Quick Mode for PR Checks

For fast feedback on pull requests:

```bash
./sim/tests/backend_smoke.sh --quick
```

### 5. Run Full Tests on Main Branch

For merge to main, run comprehensive tests:

```bash
./sim/tests/backend_smoke.sh           # Full backend tests
./sim/tests/test_backend_selection.sh  # Backend selection tests
```

### 6. Deterministic Frame Testing

Use fixed seeds for reproducibility:

```bash
HYDRA_WORLD_SEED=42 \
FRAME_DUMP=frame1.ppm \
AUTO_EXIT=1 \
./sim/sim_voxel

HYDRA_WORLD_SEED=42 \
FRAME_DUMP=frame2.ppm \
AUTO_EXIT=1 \
./sim/sim_voxel

cmp frame1.ppm frame2.ppm || exit 1
```

### 7. Timeout Protection

Set reasonable timeouts to prevent hung builds:

```yaml
- name: Run simulation
  timeout-minutes: 5
  run: ./sim/sim_voxel
```

### 8. Cache Build Artifacts

Speed up CI by caching Verilator output:

```yaml
- name: Cache Verilator objects
  uses: actions/cache@v3
  with:
    path: sim/obj_dir
    key: ${{ runner.os }}-verilator-${{ hashFiles('rtl/**/*.sv') }}
```

---

## Troubleshooting CI

### Common Issues

#### 1. No DISPLAY in CI

**Error:** `can't open display`

**Solution:**
```bash
# Use headless backend
export HYDRA_BACKEND=headless

# Or use SDL dummy driver
export SDL_VIDEODRIVER=dummy
```

#### 2. Missing Libraries

**Error:** `libSDL2.so: cannot open shared object file`

**Solution:** Install runtime libraries, not just -dev packages:
```bash
sudo apt-get install libsdl2-2.0-0 libsdl2-ttf-2.0-0
```

#### 3. Verilator Compilation Slow

**Solution:** Use ccache and cache obj_dir:
```bash
sudo apt-get install ccache
export OBJCACHE=ccache
```

#### 4. Frame Not Generated

**Solution:** Check AUTO_EXIT and FRAME_DUMP are set:
```bash
if [ ! -f "$FRAME_DUMP" ]; then
    echo "ERROR: Frame not generated"
    echo "Logs:"
    cat sim/build/*.log
    exit 1
fi
```

---

## Performance Benchmarking

### Benchmark in CI

Track performance over time:

```bash
#!/bin/bash
# scripts/ci_benchmark.sh

ITERATIONS=10
TOTAL_TIME=0

for i in $(seq 1 $ITERATIONS); do
    START=$(date +%s%N)
    HYDRA_BACKEND=headless FRAME_DUMP=/tmp/bench_$i.ppm AUTO_EXIT=1 ./sim/sim_voxel
    END=$(date +%s%N)
    ELAPSED=$(( ($END - $START) / 1000000 ))  # Convert to ms
    TOTAL_TIME=$(( $TOTAL_TIME + $ELAPSED ))
    echo "Iteration $i: ${ELAPSED}ms"
done

AVG_TIME=$(( $TOTAL_TIME / $ITERATIONS ))
echo "Average frame time: ${AVG_TIME}ms"

# Fail if performance regression
if [ $AVG_TIME -gt 5000 ]; then
    echo "ERROR: Performance regression detected (${AVG_TIME}ms > 5000ms threshold)"
    exit 1
fi
```

---

## See Also

- [Backend Support Matrix](backend_support_matrix.md) - Platform compatibility
- [Testing Overview](testing_overview.md) - Complete test suite
- [Backend Smoke Tests](../sim/tests/backend_smoke.sh) - Quick validation script
- [Platform Probe](../scripts/probe_platform.sh) - Capabilities detection
