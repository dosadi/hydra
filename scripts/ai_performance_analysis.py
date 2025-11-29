#!/usr/bin/env python3
"""
AI-assisted performance analysis for benchmark results.
"""

import argparse
import csv
import os
from datetime import datetime

def analyze_performance(benchmark_file, output_file):
    """Analyze performance benchmark data and provide insights."""

    if not os.path.exists(benchmark_file):
        with open(output_file, 'w') as f:
            f.write("# 🤖 AI Performance Analysis\n\n")
            f.write("❌ Benchmark data not found - cannot perform analysis.\n")
        return

    insights = []

    try:
        with open(benchmark_file, 'r') as f:
            # Assuming CSV format with columns: test_name, value, unit
            reader = csv.DictReader(f)
            data = list(reader)

        if not data:
            insights.append("❌ No benchmark data available")
        else:
            # Analyze frame rates
            frame_tests = [row for row in data if 'fps' in row.get('unit', '').lower() or 'frame' in row.get('name', '').lower()]

            if frame_tests:
                fps_values = []
                for test in frame_tests:
                    try:
                        value = float(test.get('value', 0))
                        fps_values.append(value)
                    except (ValueError, TypeError):
                        continue

                if fps_values:
                    avg_fps = sum(fps_values) / len(fps_values)
                    min_fps = min(fps_values)
                    max_fps = max(fps_values)

                    insights.append(f"📊 Average FPS: {avg_fps:.1f}")
                    insights.append(f"⚡ Peak FPS: {max_fps:.1f}")
                    insights.append(f"🐌 Minimum FPS: {min_fps:.1f}")

                    if avg_fps < 30:
                        insights.append("⚠️  Average FPS below 30 - potential performance issue")
                    elif avg_fps > 60:
                        insights.append("🚀 Excellent performance - FPS above 60")

            # Analyze memory usage
            mem_tests = [row for row in data if 'mb' in row.get('unit', '').lower() or 'memory' in row.get('name', '').lower()]

            if mem_tests:
                mem_values = []
                for test in mem_tests:
                    try:
                        value = float(test.get('value', 0))
                        mem_values.append(value)
                    except (ValueError, TypeError):
                        continue

                if mem_values:
                    avg_mem = sum(mem_values) / len(mem_values)
                    max_mem = max(mem_values)
                    insights.append(f"💾 Average Memory: {avg_mem:.1f} MB")
                    insights.append(f"📈 Peak Memory: {max_mem:.1f} MB")

                    if max_mem > 1000:  # 1GB
                        insights.append("⚠️  High memory usage detected - consider optimization")

            # General insights
            total_tests = len(data)
            insights.append(f"🧪 Total benchmark tests run: {total_tests}")

            if total_tests > 10:
                insights.append("📈 Comprehensive benchmark suite - good coverage")
            elif total_tests < 3:
                insights.append("📉 Limited benchmark coverage - consider adding more tests")

    except Exception as e:
        insights.append(f"❌ Error analyzing performance data: {e}")

    # Write analysis
    with open(output_file, 'w') as f:
        f.write("# 🤖 AI Performance Analysis\n\n")
        f.write(f"Analysis performed on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

        if insights:
            for insight in insights:
                f.write(f"- {insight}\n")
        else:
            f.write("✅ Performance analysis completed - no significant issues detected.\n")

        f.write("\n---\n*This analysis was automatically generated from benchmark data.*\n")

def main():
    parser = argparse.ArgumentParser(description='AI performance analysis')
    parser.add_argument('--benchmark', required=True, help='Benchmark CSV file')
    parser.add_argument('--output', required=True, help='Output markdown file')

    args = parser.parse_args()
    analyze_performance(args.benchmark, args.output)

if __name__ == '__main__':
    main()