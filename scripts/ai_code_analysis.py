#!/usr/bin/env python3
"""
AI-assisted code analysis for pull request reviews.
Analyzes changed files and provides suggestions for improvements.
"""

import argparse
import os
import re
import subprocess
from pathlib import Path

def analyze_cpp_file(filepath):
    """Analyze C++ file for common issues and improvements."""
    suggestions = []

    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

        lines = content.split('\n')

        # Check for common C++ issues
        if 'using namespace std;' in content:
            suggestions.append("⚠️  Consider avoiding 'using namespace std;' - prefer explicit std:: qualification")

        # Check for raw pointers without smart pointers
        raw_pointers = len(re.findall(r'\b\w+\s*\*\s*\w+', content))
        if raw_pointers > 5:
            suggestions.append(f"💡 Found {raw_pointers} raw pointers - consider using smart pointers (unique_ptr, shared_ptr)")

        # Check for TODO comments
        todos = len(re.findall(r'//.*TODO|/\*.*TODO', content, re.IGNORECASE))
        if todos > 0:
            suggestions.append(f"📝 Found {todos} TODO comment(s) - ensure they are tracked")

        # Check for long functions
        in_function = False
        brace_count = 0
        function_lines = 0
        for line in lines:
            stripped = line.strip()
            if stripped.startswith('//') or stripped.startswith('/*') or not stripped:
                continue

            brace_count += line.count('{') - line.count('}')
            if brace_count > 0:
                function_lines += 1
                if function_lines > 50:
                    suggestions.append("🔧 Function exceeds 50 lines - consider breaking it down")
                    break

        # Check for magic numbers
        magic_numbers = len(re.findall(r'\b\d{2,}\b', content))
        if magic_numbers > 10:
            suggestions.append("🔢 Found multiple magic numbers - consider using named constants")

        # Check for exception safety
        try_blocks = len(re.findall(r'\btry\s*\{', content))
        catch_blocks = len(re.findall(r'\bcatch\s*\(', content))
        if try_blocks > catch_blocks:
            suggestions.append("⚠️  Unbalanced try/catch blocks - ensure proper exception handling")

        # Check for memory leaks (basic heuristic)
        news = len(re.findall(r'\bnew\s+', content))
        deletes = len(re.findall(r'\bdelete\s+', content))
        if news > deletes + 2:  # Allow some margin
            suggestions.append("💧 Potential memory leaks - ensure all 'new' calls have matching 'delete'")

        # Check for const correctness
        non_const_params = len(re.findall(r'\w+\s+\w+\s*\(', content))  # Simple heuristic
        if non_const_params > 10:
            suggestions.append("🔒 Consider using 'const' for parameters that aren't modified")

        # Check for include guards in headers
        if filepath.endswith('.h') or filepath.endswith('.hpp'):
            if not re.search(r'#ifndef\s+\w+\s*#define\s+\w+', content, re.IGNORECASE):
                suggestions.append("🛡️  Missing include guards in header file")

    except Exception as e:
        suggestions.append(f"❌ Error analyzing {filepath}: {e}")

    return suggestions

def analyze_systemverilog_file(filepath):
    """Analyze SystemVerilog file for common issues."""
    suggestions = []

    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

        # Check for blocking assignments in sequential logic
        blocking_assigns = len(re.findall(r'always\s*\([^)]*\)\s*begin[^}]*=', content))
        if blocking_assigns > 0:
            suggestions.append("⚠️  Found blocking assignments (=) in sequential always blocks - use non-blocking (<=)")

        # Check for missing reset logic
        always_ff_blocks = len(re.findall(r'always_ff\s*\(', content))
        if always_ff_blocks > 0 and 'rst' not in content.lower():
            suggestions.append("🔍 Consider adding reset logic to always_ff blocks")

        # Check for large modules
        lines = content.split('\n')
        if len(lines) > 500:
            suggestions.append("📏 Module is quite large - consider splitting into smaller modules")

        # Check for parameter usage
        params = len(re.findall(r'\bparameter\b', content))
        param_usage = len(re.findall(r'\b\w+\s*\[.*\]', content))
        if params > 0 and param_usage < params:
            suggestions.append("🔧 Parameters defined but not fully utilized - review parameter usage")

        # Check for clock domain crossings without proper synchronization
        if 'always_ff' in content and 'posedge' in content:
            clock_signals = re.findall(r'posedge\s+(\w+)', content)
            if len(set(clock_signals)) > 1:
                suggestions.append("⚠️  Multiple clock domains detected - ensure proper CDC synchronization")

        # Check for combinational loops
        always_comb_blocks = re.findall(r'always_comb\s*begin(.*?)\bend', content, re.DOTALL)
        for block in always_comb_blocks:
            if '=' in block and '<=' not in block:
                suggestions.append("🔄 Potential combinational loop - review always_comb assignments")

        # Check for unused signals (basic heuristic)
        assignments = set(re.findall(r'(\w+)\s*[<=]=', content))
        usages = set(re.findall(r'\b(\w+)\b', content))
        potentially_unused = assignments - usages
        if len(potentially_unused) > 5:
            suggestions.append(f"📝 Found {len(potentially_unused)} potentially unused signals - review assignments")

    except Exception as e:
        suggestions.append(f"❌ Error analyzing {filepath}: {e}")

    return suggestions

def analyze_python_file(filepath):
    """Analyze Python file for common issues."""
    suggestions = []

    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

        lines = content.split('\n')

        # Check for long functions
        in_function = False
        function_lines = 0
        for line in lines:
            stripped = line.strip()
            if stripped.startswith('#') or not stripped:
                continue

            if stripped.startswith('def ') or stripped.startswith('async def '):
                in_function = True
                function_lines = 0
            elif in_function and stripped and not stripped.startswith(' ') and not stripped.startswith('\t'):
                in_function = False
            elif in_function:
                function_lines += 1

            if function_lines > 30:
                suggestions.append("🔧 Function exceeds 30 lines - consider refactoring")
                break

        # Check for bare except clauses
        bare_excepts = len(re.findall(r'except\s*:', content))
        if bare_excepts > 0:
            suggestions.append("⚠️  Found bare 'except:' clauses - specify exception types")

        # Check for print statements (in production code)
        prints = len(re.findall(r'\bprint\s*\(', content))
        if prints > 5:
            suggestions.append("📝 Multiple print statements found - consider using logging")

    except Exception as e:
        suggestions.append(f"❌ Error analyzing {filepath}: {e}")

    return suggestions

def main():
    parser = argparse.ArgumentParser(description='AI-assisted code analysis')
    parser.add_argument('--files', required=True, help='Space-separated list of files to analyze')
    parser.add_argument('--output', required=True, help='Output markdown file')

    args = parser.parse_args()
    files = args.files.split()

    all_suggestions = []

    for filepath in files:
        if not os.path.exists(filepath):
            continue

        file_ext = Path(filepath).suffix.lower()
        filename = os.path.basename(filepath)

        suggestions = []
        if file_ext in ['.cpp', '.cc', '.cxx', '.c++', '.c']:
            suggestions = analyze_cpp_file(filepath)
        elif file_ext in ['.sv', '.v']:
            suggestions = analyze_systemverilog_file(filepath)
        elif file_ext == '.py':
            suggestions = analyze_python_file(filepath)

        if suggestions:
            all_suggestions.append(f"## {filename}\n")
            for suggestion in suggestions:
                all_suggestions.append(f"- {suggestion}")
            all_suggestions.append("")

    # Write output
    with open(args.output, 'w') as f:
        if all_suggestions:
            f.write("# 🤖 AI Code Analysis Suggestions\n\n")
            f.write("This analysis provides automated suggestions for code improvements.\n")
            f.write("Please review these suggestions and apply them where appropriate.\n\n")
            f.write("\n".join(all_suggestions))
        else:
            f.write("# 🤖 AI Code Analysis\n\n")
            f.write("✅ No significant issues found in the analyzed code.\n")
            f.write("The code appears to follow good practices!\n")

if __name__ == '__main__':
    main()