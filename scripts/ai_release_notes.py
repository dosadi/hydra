#!/usr/bin/env python3
"""
AI-assisted release notes generation.
Analyzes git history and generates comprehensive release notes.
"""

import argparse
import subprocess
import re
from datetime import datetime
from collections import defaultdict

def get_git_commits(since_tag=None):
    """Get commits since the last tag or all commits."""
    cmd = ['git', 'log', '--oneline', '--pretty=format:%s']
    if since_tag:
        cmd.extend(['HEAD', f'^{since_tag}'])
    else:
        # Get commits since last tag
        try:
            last_tag = subprocess.check_output(['git', 'describe', '--tags', '--abbrev=0'], text=True).strip()
            cmd.extend([f'{last_tag}..HEAD'])
        except:
            cmd.extend(['--all'])

    try:
        result = subprocess.check_output(cmd, text=True)
        return result.split('\n') if result else []
    except:
        return []

def categorize_commits(commits):
    """Categorize commits by type."""
    categories = defaultdict(list)

    for commit in commits:
        commit = commit.strip()
        if not commit:
            continue

        lower_commit = commit.lower()

        if any(word in lower_commit for word in ['fix', 'bug', 'issue', 'error', 'crash']):
            categories['bug_fixes'].append(commit)
        elif any(word in lower_commit for word in ['add', 'new', 'feature', 'implement']):
            categories['features'].append(commit)
        elif any(word in lower_commit for word in ['perf', 'performance', 'speed', 'optimize']):
            categories['performance'].append(commit)
        elif any(word in lower_commit for word in ['refactor', 'cleanup', 'style']):
            categories['refactoring'].append(commit)
        elif any(word in lower_commit for word in ['doc', 'documentation', 'readme']):
            categories['documentation'].append(commit)
        elif any(word in lower_commit for word in ['test', 'testing', 'ci']):
            categories['testing'].append(commit)
        elif any(word in lower_commit for word in ['build', 'makefile', 'cmake', 'ci']):
            categories['build_system'].append(commit)
        else:
            categories['other'].append(commit)

    return categories

def generate_release_notes(version, categories):
    """Generate formatted release notes."""

    notes = [f"# Release {version}", ""]
    notes.append(f"**Released:** {datetime.now().strftime('%Y-%m-%d')}")
    notes.append("")

    # Summary
    total_commits = sum(len(commits) for commits in categories.values())
    notes.append(f"**Total Changes:** {total_commits} commits")
    notes.append("")

    # Features
    if categories['features']:
        notes.append("## 🚀 New Features")
        notes.append("")
        for commit in categories['features'][:10]:  # Limit to 10
            notes.append(f"- {commit}")
        if len(categories['features']) > 10:
            notes.append(f"- ... and {len(categories['features']) - 10} more features")
        notes.append("")

    # Bug Fixes
    if categories['bug_fixes']:
        notes.append("## 🐛 Bug Fixes")
        notes.append("")
        for commit in categories['bug_fixes'][:10]:
            notes.append(f"- {commit}")
        if len(categories['bug_fixes']) > 10:
            notes.append(f"- ... and {len(categories['bug_fixes']) - 10} more bug fixes")
        notes.append("")

    # Performance
    if categories['performance']:
        notes.append("## ⚡ Performance Improvements")
        notes.append("")
        for commit in categories['performance']:
            notes.append(f"- {commit}")
        notes.append("")

    # Other categories
    other_sections = [
        ('refactoring', '🔧 Refactoring', '♻️'),
        ('testing', '🧪 Testing', '✅'),
        ('documentation', '📚 Documentation', '📖'),
        ('build_system', '🔨 Build System', '⚙️'),
    ]

    for key, title, icon in other_sections:
        if categories[key]:
            notes.append(f"## {icon} {title}")
            notes.append("")
            for commit in categories[key][:5]:
                notes.append(f"- {commit}")
            if len(categories[key]) > 5:
                notes.append(f"- ... and {len(categories[key]) - 5} more {key.replace('_', ' ')} changes")
            notes.append("")

    # Other changes
    if categories['other']:
        notes.append("## 📝 Other Changes")
        notes.append("")
        for commit in categories['other'][:5]:
            notes.append(f"- {commit}")
        if len(categories['other']) > 5:
            notes.append(f"- ... and {len(categories['other']) - 5} more changes")
        notes.append("")

    # Installation notes
    notes.append("## 📦 Installation")
    notes.append("")
    notes.append("Download the package from the assets below and extract:")
    notes.append("```bash")
    notes.append("tar xzf hydra-package.tar.gz")
    notes.append("cd hydra-package")
    notes.append("./sim_voxel")
    notes.append("```")
    notes.append("")

    # Requirements
    notes.append("## 🔧 Requirements")
    notes.append("")
    notes.append("- Verilator 5.x")
    notes.append("- SDL2 libraries")
    notes.append("- C++17 compiler")
    notes.append("")

    notes.append("---")
    notes.append("*This release notes was automatically generated by AI analysis of git commits.*")

    return "\n".join(notes)

def main():
    parser = argparse.ArgumentParser(description='Generate AI-enhanced release notes')
    parser.add_argument('--version', required=True, help='Release version')
    parser.add_argument('--output', required=True, help='Output markdown file')

    args = parser.parse_args()

    # Get commits
    commits = get_git_commits()

    if not commits:
        # Fallback content
        content = f"""# Release {args.version}

**Released:** {datetime.now().strftime('%Y-%m-%d')}

## Changes
- See commit history for details

## Installation
Download the package from the assets below and extract:
```bash
tar xzf hydra-package.tar.gz
cd hydra-package
./sim_voxel
```

## Requirements
- Verilator 5.x
- SDL2 libraries
- C++17 compiler

---
*Release notes generated automatically - no commits found for analysis.*"""
    else:
        # Categorize and generate notes
        categories = categorize_commits(commits)
        content = generate_release_notes(args.version, categories)

    # Write output
    with open(args.output, 'w') as f:
        f.write(content)

    print(f"Generated AI-enhanced release notes for {args.version}")

if __name__ == '__main__':
    main()