#!/usr/bin/env python3
"""
AI-assisted documentation generation for code.
Scans code and suggests documentation improvements.
"""

import argparse
import os
import re
from pathlib import Path

def scan_cpp_files():
    """Scan C++ files for documentation opportunities."""
    suggestions = []

    cpp_files = Path('sim').rglob('*.cpp') + Path('sim').rglob('*.cc') + Path('sim').rglob('*.h')

    for cpp_file in cpp_files:
        try:
            with open(cpp_file, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()

            lines = content.split('\n')

            # Check for functions without documentation
            for i, line in enumerate(lines):
                if re.match(r'^\s*(?:static\s+)?(?:\w+\s+)+\w+\s*\(', line):
                    # Found a function definition
                    # Check if previous lines have comments
                    has_docs = False
                    for j in range(max(0, i-5), i):
                        if lines[j].strip().startswith('//') or '/*' in lines[j]:
                            has_docs = True
                            break

                    if not has_docs:
                        suggestions.append(f"📝 Add documentation to function in {cpp_file.name}: {line.strip()}")

            # Check for classes without documentation
            class_matches = re.findall(r'^\s*class\s+\w+', content, re.MULTILINE)
            for match in class_matches:
                class_name = match.split()[-1]
                # Check if class has documentation
                class_start = content.find(match)
                before_class = content[max(0, class_start-200):class_start]
                if not ('/**' in before_class or '///' in before_class):
                    suggestions.append(f"📚 Add class documentation for {class_name} in {cpp_file.name}")

        except Exception as e:
            suggestions.append(f"❌ Error scanning {cpp_file}: {e}")

    return suggestions

def scan_systemverilog_files():
    """Scan SystemVerilog files for documentation opportunities."""
    suggestions = []

    sv_files = Path('rtl').rglob('*.sv') + Path('rtl').rglob('*.v')

    for sv_file in sv_files:
        try:
            with open(sv_file, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()

            # Check for modules without documentation
            module_matches = re.findall(r'^\s*module\s+\w+', content, re.MULTILINE)
            for match in module_matches:
                module_name = match.split()[-1]
                # Check if module has documentation
                module_start = content.find(match)
                before_module = content[max(0, module_start-300):module_start]
                if not ('/**' in before_module or '/*' in before_module):
                    suggestions.append(f"📦 Add module documentation for {module_name} in {sv_file.name}")

            # Check for parameters without comments
            param_matches = re.findall(r'^\s*parameter\s+\w+', content, re.MULTILINE)
            for match in param_matches:
                param_name = match.split()[-1]
                param_line = content.find(match)
                line_content = content[param_line:param_line+100]
                if not ('//' in line_content or '/*' in line_content):
                    suggestions.append(f"🔧 Add parameter documentation for {param_name} in {sv_file.name}")

        except Exception as e:
            suggestions.append(f"❌ Error scanning {sv_file}: {e}")

    return suggestions

def generate_doc_suggestions():
    """Generate documentation improvement suggestions."""
    suggestions = []

    suggestions.extend(scan_cpp_files())
    suggestions.extend(scan_systemverilog_files())

    # Limit suggestions to avoid overwhelming
    if len(suggestions) > 20:
        suggestions = suggestions[:20]
        suggestions.append(f"... and {len(suggestions) - 20} more suggestions")

    return suggestions

def main():
    parser = argparse.ArgumentParser(description='AI documentation generator')
    parser.add_argument('--scan-code', action='store_true', help='Scan code for documentation opportunities')
    parser.add_argument('--output', required=True, help='Output markdown file')

    args = parser.parse_args()

    suggestions = []

    if args.scan_code:
        suggestions = generate_doc_suggestions()

    # Write output
    with open(args.output, 'w') as f:
        f.write("# 🤖 AI Documentation Enhancement Suggestions\n\n")

        if suggestions:
            f.write("Based on code analysis, here are suggested documentation improvements:\n\n")
            for suggestion in suggestions:
                f.write(f"- {suggestion}\n")
            f.write("\nThese suggestions can help improve code maintainability and understanding.\n")
        else:
            f.write("✅ Code appears to be well-documented!\n")
            f.write("No significant documentation improvements suggested.\n")

        f.write("\n---\n*Generated automatically by AI documentation analysis.*\n")

if __name__ == '__main__':
    main()