#!/usr/bin/env python3
"""
AI-assisted performance baseline management.
Stores and compares performance baselines.
"""

import argparse
import csv
import json
import os
from datetime import datetime
from pathlib import Path

BASELINE_FILE = 'scripts/performance_baseline.json'

def store_baseline(data_file):
    """Store current performance data as baseline."""

    if not os.path.exists(data_file):
        print(f"Benchmark data file {data_file} not found")
        return

    baseline_data = {
        'timestamp': datetime.now().isoformat(),
        'commit': os.environ.get('GITHUB_SHA', 'unknown'),
        'data': {}
    }

    try:
        with open(data_file, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                key = row.get('name', 'unknown')
                try:
                    value = float(row.get('value', 0))
                    unit = row.get('unit', '')
                    baseline_data['data'][key] = {'value': value, 'unit': unit}
                except (ValueError, TypeError):
                    continue

        # Ensure directory exists
        os.makedirs(os.path.dirname(BASELINE_FILE), exist_ok=True)

        # Load existing baseline if present
        existing_data = {}
        if os.path.exists(BASELINE_FILE):
            try:
                with open(BASELINE_FILE, 'r') as f:
                    existing_data = json.load(f)
            except:
                pass

        # Update with new data
        existing_data.update({k: v for k, v in baseline_data.items() if k != 'data'})
        existing_data['data'].update(baseline_data['data'])

        with open(BASELINE_FILE, 'w') as f:
            json.dump(existing_data, f, indent=2)

        print(f"✅ Stored performance baseline with {len(baseline_data['data'])} metrics")

    except Exception as e:
        print(f"❌ Error storing baseline: {e}")

def compare_with_baseline(data_file, output_file):
    """Compare current performance with baseline."""

    if not os.path.exists(BASELINE_FILE):
        with open(output_file, 'w') as f:
            f.write("# 🤖 Performance Regression Analysis\n\n")
            f.write("❌ No baseline data available for comparison.\n")
        return

    if not os.path.exists(data_file):
        with open(output_file, 'w') as f:
            f.write("# 🤖 Performance Regression Analysis\n\n")
            f.write("❌ Current performance data not found.\n")
        return

    try:
        # Load baseline
        with open(BASELINE_FILE, 'r') as f:
            baseline = json.load(f)

        # Load current data
        current_data = {}
        with open(data_file, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                key = row.get('name', 'unknown')
                try:
                    value = float(row.get('value', 0))
                    unit = row.get('unit', '')
                    current_data[key] = {'value': value, 'unit': unit}
                except (ValueError, TypeError):
                    continue

        # Compare
        regressions = []
        improvements = []

        for key, current in current_data.items():
            if key in baseline.get('data', {}):
                baseline_val = baseline['data'][key]['value']
                current_val = current['value']
                unit = current.get('unit', '')

                # For FPS, higher is better
                if 'fps' in unit.lower() or 'frame' in key.lower():
                    change_pct = ((current_val - baseline_val) / baseline_val) * 100
                    if change_pct < -10:  # 10% regression
                        regressions.append(f"🐌 {key}: {baseline_val:.1f} → {current_val:.1f} {unit} ({change_pct:.1f}% regression)")
                    elif change_pct > 10:  # 10% improvement
                        improvements.append(f"🚀 {key}: {baseline_val:.1f} → {current_val:.1f} {unit} (+{change_pct:.1f}% improvement)")
                # For time-based metrics, lower is better
                elif 'ms' in unit.lower() or 'time' in key.lower():
                    change_pct = ((current_val - baseline_val) / baseline_val) * 100
                    if change_pct > 10:  # 10% slower
                        regressions.append(f"🐌 {key}: {baseline_val:.1f} → {current_val:.1f} {unit} ({change_pct:.1f}% slower)")
                    elif change_pct < -10:  # 10% faster
                        improvements.append(f"🚀 {key}: {baseline_val:.1f} → {current_val:.1f} {unit} (+{abs(change_pct):.1f}% faster)")

        # Write analysis
        with open(output_file, 'w') as f:
            f.write("# 🤖 Performance Regression Analysis\n\n")
            f.write(f"Compared against baseline from: {baseline.get('timestamp', 'unknown')}\n\n")

            if regressions:
                f.write("## ⚠️ Performance Regressions Detected\n\n")
                for regression in regressions:
                    f.write(f"- {regression}\n")
                f.write("\n")
            else:
                f.write("## ✅ No Performance Regressions\n\n")

            if improvements:
                f.write("## 🎉 Performance Improvements\n\n")
                for improvement in improvements:
                    f.write(f"- {improvement}\n")
                f.write("\n")

            if not regressions and not improvements:
                f.write("## 📊 Performance Stable\n\n")
                f.write("No significant performance changes detected.\n\n")

            f.write("---\n")
            f.write("*This analysis compares current performance against stored baseline.*\n")

        print(f"✅ Generated performance regression analysis")

    except Exception as e:
        with open(output_file, 'w') as f:
            f.write("# 🤖 Performance Regression Analysis\n\n")
            f.write(f"❌ Error during analysis: {e}\n")
        print(f"❌ Error in performance comparison: {e}")

def main():
    parser = argparse.ArgumentParser(description='AI performance baseline management')
    parser.add_argument('--store', action='store_true', help='Store current data as baseline')
    parser.add_argument('--compare', action='store_true', help='Compare with baseline')
    parser.add_argument('--data', required=True, help='Performance data CSV file')
    parser.add_argument('--output', help='Output file for comparison results')

    args = parser.parse_args()

    if args.store:
        store_baseline(args.data)
    elif args.compare:
        if not args.output:
            parser.error("--output required for --compare")
        compare_with_baseline(args.data, args.output)
    else:
        parser.error("Must specify --store or --compare")

if __name__ == '__main__':
    main()