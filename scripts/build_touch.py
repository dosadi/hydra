#!/usr/bin/env python3
"""
Build Tree Touch System - Makefile on Steroids

Extends the doc touch system concept to the entire build tree:
- RTL/HDL files → Verilated C++
- C/C++ source → Object files → Binaries
- Config files → Generated Makefiles
- Tests → Test results
- Scripts → Generated artifacts

Like Make, but:
- Tracks implicit dependencies automatically
- Understands build tool outputs
- Integrates with existing build systems
- Provides AI-assisted build repair
- Works across Make, CMake, Verilator, etc.

Usage:
  # Scan build tree and track dependencies
  python3 scripts/build_touch.py --scan

  # Check what's stale
  python3 scripts/build_touch.py --check

  # Show what needs rebuilding
  python3 scripts/build_touch.py --needs-rebuild

  # Touch a source file and show impact
  python3 scripts/build_touch.py --touch rtl/voxel_raycaster_core.sv

  # Visualize build dependency tree
  python3 scripts/build_touch.py --tree
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from argparse import ArgumentParser
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any

@dataclass
class BuildNode:
    """Represents a file in the build tree."""
    path: Path
    node_type: str  # source, object, binary, generated, config, test_result
    mtime: float
    depends_on: list[str] = field(default_factory=list)  # What this depends on
    generates: list[str] = field(default_factory=list)   # What this generates
    built_by: str | None = None  # Make target, CMake target, etc.
    needs_rebuild: bool = False
    reason: str = ""

    @property
    def is_stale(self) -> bool:
        """Check if this needs rebuilding."""
        return self.needs_rebuild


class BuildScanner:
    """Scans build tree and extracts dependencies."""

    def __init__(self, root: Path):
        self.root = root
        self.nodes: dict[str, BuildNode] = {}

    def scan(self) -> dict[str, BuildNode]:
        """Scan entire build tree."""
        print("🔍 Scanning build tree...")

        # Scan different types of files
        self._scan_rtl_files()
        self._scan_c_cpp_files()
        self._scan_makefiles()
        self._scan_cmake_files()
        self._scan_build_artifacts()
        self._scan_test_results()

        print(f"✓ Scanned {len(self.nodes)} build nodes")
        return self.nodes

    def _scan_rtl_files(self):
        """Scan RTL/HDL files and extract dependencies."""
        rtl_files = list(self.root.glob("rtl/**/*.sv")) + \
                   list(self.root.glob("rtl/**/*.v"))

        for rtl_file in rtl_files:
            rel_path = str(rtl_file.relative_to(self.root))

            # Extract module dependencies from includes and instantiations
            deps = self._extract_rtl_deps(rtl_file)

            node = BuildNode(
                path=rtl_file,
                node_type="rtl_source",
                mtime=rtl_file.stat().st_mtime,
                depends_on=deps,
                generates=self._infer_generated_from_rtl(rtl_file),
                built_by="verilator"
            )

            self.nodes[rel_path] = node

    def _extract_rtl_deps(self, rtl_file: Path) -> list[str]:
        """Extract dependencies from RTL file."""
        deps = []
        try:
            content = rtl_file.read_text(encoding="utf-8", errors="ignore")

            # Find includes
            for match in re.finditer(r'`include\s+"([^"]+)"', content):
                inc_file = match.group(1)
                # Try to resolve relative to rtl_file
                inc_path = (rtl_file.parent / inc_file).relative_to(self.root)
                deps.append(str(inc_path))

            # Find module instantiations (simplified)
            for match in re.finditer(r'(\w+)\s+\w+\s*\(', content):
                module_name = match.group(1)
                # Look for corresponding .sv file
                possible_file = rtl_file.parent / f"{module_name}.sv"
                if possible_file.exists():
                    deps.append(str(possible_file.relative_to(self.root)))

        except Exception as e:
            print(f"Warning: Failed to scan {rtl_file}: {e}")

        return deps

    def _infer_generated_from_rtl(self, rtl_file: Path) -> list[str]:
        """Infer what gets generated from RTL file (Verilated C++)."""
        # Verilator generates V{ModuleName}.cpp and .h
        module_name = self._extract_module_name(rtl_file)
        if module_name:
            return [
                f"sim/obj_dir/V{module_name}.cpp",
                f"sim/obj_dir/V{module_name}.h",
                f"sim/obj_dir/V{module_name}__Syms.cpp",
            ]
        return []

    def _extract_module_name(self, rtl_file: Path) -> str | None:
        """Extract module name from RTL file."""
        try:
            content = rtl_file.read_text(encoding="utf-8", errors="ignore")
            match = re.search(r'module\s+(\w+)', content)
            if match:
                return match.group(1)
        except Exception:
            pass
        return None

    def _scan_c_cpp_files(self):
        """Scan C/C++ files and extract dependencies."""
        c_files = list(self.root.glob("**/*.c")) + \
                 list(self.root.glob("**/*.cpp")) + \
                 list(self.root.glob("**/*.cc"))

        for c_file in c_files:
            if "third_party" in str(c_file) or "obj_dir" in str(c_file):
                continue  # Skip third-party and generated

            rel_path = str(c_file.relative_to(self.root))

            deps = self._extract_c_deps(c_file)

            node = BuildNode(
                path=c_file,
                node_type="c_source",
                mtime=c_file.stat().st_mtime,
                depends_on=deps,
                generates=[rel_path.replace(".cpp", ".o").replace(".c", ".o")],
                built_by="gcc/g++"
            )

            self.nodes[rel_path] = node

    def _extract_c_deps(self, c_file: Path) -> list[str]:
        """Extract #include dependencies from C/C++ file."""
        deps = []
        try:
            content = c_file.read_text(encoding="utf-8", errors="ignore")

            # Find local includes (not system includes)
            for match in re.finditer(r'#include\s+"([^"]+)"', content):
                inc_file = match.group(1)
                # Try to resolve
                inc_path = (c_file.parent / inc_file)
                if inc_path.exists():
                    deps.append(str(inc_path.relative_to(self.root)))

        except Exception as e:
            print(f"Warning: Failed to scan {c_file}: {e}")

        return deps

    def _scan_makefiles(self):
        """Scan Makefiles and extract targets."""
        makefiles = list(self.root.glob("**/Makefile")) + \
                   list(self.root.glob("**/makefile"))

        for makefile in makefiles:
            rel_path = str(makefile.relative_to(self.root))

            targets = self._extract_make_targets(makefile)

            node = BuildNode(
                path=makefile,
                node_type="makefile",
                mtime=makefile.stat().st_mtime,
                depends_on=[],
                generates=targets,
                built_by="make"
            )

            self.nodes[rel_path] = node

    def _extract_make_targets(self, makefile: Path) -> list[str]:
        """Extract targets from Makefile."""
        targets = []
        try:
            content = makefile.read_text(encoding="utf-8", errors="ignore")

            # Find target definitions (simplified)
            for match in re.finditer(r'^([a-zA-Z0-9_\-\.]+):', content, re.MULTILINE):
                target = match.group(1)
                if target not in ['.PHONY', '.DEFAULT', '.SUFFIXES']:
                    targets.append(target)

        except Exception as e:
            print(f"Warning: Failed to scan {makefile}: {e}")

        return targets

    def _scan_cmake_files(self):
        """Scan CMakeLists.txt files."""
        cmake_files = list(self.root.glob("**/CMakeLists.txt"))

        for cmake_file in cmake_files:
            rel_path = str(cmake_file.relative_to(self.root))

            node = BuildNode(
                path=cmake_file,
                node_type="cmake",
                mtime=cmake_file.stat().st_mtime,
                depends_on=[],
                generates=["build/Makefile"],  # Simplified
                built_by="cmake"
            )

            self.nodes[rel_path] = node

    def _scan_build_artifacts(self):
        """Scan build artifacts (binaries, .o files, etc.)."""
        # Object files
        obj_files = list(self.root.glob("**/*.o"))
        for obj_file in obj_files:
            if obj_file.exists():
                rel_path = str(obj_file.relative_to(self.root))
                node = BuildNode(
                    path=obj_file,
                    node_type="object_file",
                    mtime=obj_file.stat().st_mtime,
                    depends_on=[],  # Would be filled by build system analysis
                )
                self.nodes[rel_path] = node

        # Binaries
        bin_dirs = ["sim", "build", "out"]
        for bin_dir in bin_dirs:
            bin_path = self.root / bin_dir
            if bin_path.exists():
                for item in bin_path.iterdir():
                    if item.is_file() and os.access(item, os.X_OK):
                        rel_path = str(item.relative_to(self.root))
                        node = BuildNode(
                            path=item,
                            node_type="binary",
                            mtime=item.stat().st_mtime,
                            depends_on=[],
                        )
                        self.nodes[rel_path] = node

    def _scan_test_results(self):
        """Scan test result files."""
        test_dirs = ["sim/tests", "out", "build"]
        for test_dir in test_dirs:
            test_path = self.root / test_dir
            if not test_path.exists():
                continue

            # Look for test result files
            for result_file in test_path.glob("**/*.log"):
                rel_path = str(result_file.relative_to(self.root))
                node = BuildNode(
                    path=result_file,
                    node_type="test_result",
                    mtime=result_file.stat().st_mtime,
                    depends_on=[],
                )
                self.nodes[rel_path] = node


class BuildAnalyzer:
    """Analyzes build dependencies and staleness."""

    def __init__(self, nodes: dict[str, BuildNode]):
        self.nodes = nodes
        self.reverse_deps: dict[str, list[str]] = defaultdict(list)
        self._build_reverse_deps()

    def _build_reverse_deps(self):
        """Build reverse dependency map."""
        for path, node in self.nodes.items():
            for dep in node.depends_on:
                self.reverse_deps[dep].append(path)

    def check_staleness(self) -> dict[str, list[str]]:
        """Check for stale build artifacts."""
        stale: dict[str, list[str]] = defaultdict(list)

        for path, node in self.nodes.items():
            # Check if dependencies are newer
            for dep in node.depends_on:
                if dep not in self.nodes:
                    stale[path].append(f"Missing dependency: {dep}")
                    continue

                dep_node = self.nodes[dep]
                if dep_node.mtime > node.mtime:
                    age_diff = int((dep_node.mtime - node.mtime) / 60)
                    stale[path].append(
                        f"{dep} is {age_diff}min newer than this"
                    )

        return stale

    def mark_stale_from_touch(self, touched_path: str) -> list[str]:
        """Mark all artifacts that depend on touched file as needing rebuild."""
        affected = []
        to_process = [touched_path]
        visited = set()

        while to_process:
            current = to_process.pop(0)
            if current in visited:
                continue
            visited.add(current)

            # Mark all reverse dependencies as stale
            for dependent in self.reverse_deps.get(current, []):
                if dependent not in self.nodes:
                    continue
                dep_node = self.nodes[dependent]
                if not dep_node.needs_rebuild:
                    dep_node.needs_rebuild = True
                    dep_node.reason = f"Depends on {current} which was updated"
                    affected.append(dependent)
                    to_process.append(dependent)

        return affected


def save_metadata(nodes: dict[str, BuildNode], output_path: Path):
    """Save build dependency metadata."""
    metadata: dict[str, Any] = {
        "generated": datetime.now().isoformat(),
        "nodes": {},
    }

    for path, node in sorted(nodes.items()):
        metadata["nodes"][path] = {
            "type": node.node_type,
            "mtime": node.mtime,
            "mtime_iso": datetime.fromtimestamp(node.mtime).isoformat(),
            "depends_on": node.depends_on,
            "generates": node.generates,
            "built_by": node.built_by,
            "needs_rebuild": node.needs_rebuild,
            "reason": node.reason,
        }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(metadata, indent=2, sort_keys=True))
    print(f"✓ Saved build metadata to {output_path}")


def main() -> int:
    parser = ArgumentParser(description="Build tree touch system")
    parser.add_argument("--scan", action="store_true",
                        help="Scan build tree and extract dependencies")
    parser.add_argument("--check", action="store_true",
                        help="Check for stale build artifacts")
    parser.add_argument("--needs-rebuild", action="store_true",
                        help="Show what needs rebuilding")
    parser.add_argument("--touch", metavar="FILE",
                        help="Touch a file and show rebuild impact")
    parser.add_argument("--tree", action="store_true",
                        help="Show build dependency tree")
    parser.add_argument("--output", default="build/build_dependencies.json",
                        help="Output path for metadata")
    parser.add_argument("--root", type=Path, default=Path.cwd(),
                        help="Repository root")

    args = parser.parse_args()

    root = args.root.resolve()

    # Scan or load metadata
    if args.scan:
        scanner = BuildScanner(root)
        nodes = scanner.scan()
        save_metadata(nodes, root / args.output)
        return 0

    # Load existing metadata
    metadata_path = root / args.output
    if not metadata_path.exists():
        print("Run with --scan first to build metadata")
        return 1

    metadata = json.loads(metadata_path.read_text())
    nodes = {}
    for path, info in metadata["nodes"].items():
        nodes[path] = BuildNode(
            path=root / path,
            node_type=info["type"],
            mtime=info["mtime"],
            depends_on=info.get("depends_on", []),
            generates=info.get("generates", []),
            built_by=info.get("built_by"),
            needs_rebuild=info.get("needs_rebuild", False),
            reason=info.get("reason", ""),
        )

    analyzer = BuildAnalyzer(nodes)

    if args.check:
        stale = analyzer.check_staleness()
        if stale:
            print("Stale build artifacts:\n")
            for artifact, reasons in sorted(stale.items()):
                print(f"  {artifact}:")
                for reason in reasons:
                    print(f"    - {reason}")
            return 1
        else:
            print("✓ All build artifacts up to date!")
            return 0

    if args.touch:
        touch_path = Path(args.touch)
        if not touch_path.is_absolute():
            touch_path = root / touch_path
        touch_rel = str(touch_path.relative_to(root))
        affected = analyzer.mark_stale_from_touch(touch_rel)
        print(f"Touched: {touch_rel}")
        if affected:
            print(f"\nMarked {len(affected)} artifacts as needing rebuild:")
            for artifact in sorted(affected):
                print(f"  - {artifact}")
        save_metadata(nodes, root / args.output)
        return 0

    if args.needs_rebuild:
        needs_rebuild = [
            path for path, node in nodes.items()
            if node.needs_rebuild
        ]
        if needs_rebuild:
            print(f"Build artifacts needing rebuild ({len(needs_rebuild)}):")
            for artifact in sorted(needs_rebuild):
                node = nodes[artifact]
                print(f"  {artifact}")
                print(f"    Reason: {node.reason}")
            return 1
        else:
            print("✓ No artifacts need rebuilding!")
            return 0

    if args.tree:
        print("Build dependency tree:")
        # Simplified tree view
        for path, node in sorted(nodes.items())[:20]:
            print(f"\n{path} ({node.node_type})")
            if node.depends_on:
                print(f"  Depends on:")
                for dep in node.depends_on[:5]:
                    print(f"    - {dep}")
            if node.generates:
                print(f"  Generates:")
                for gen in node.generates[:5]:
                    print(f"    - {gen}")
        return 0

    # Default: show summary
    print(f"Build tree summary:")
    print(f"  Total nodes: {len(nodes)}")

    by_type = defaultdict(int)
    for node in nodes.values():
        by_type[node.node_type] += 1

    print(f"\n  By type:")
    for node_type, count in sorted(by_type.items()):
        print(f"    {node_type}: {count}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
