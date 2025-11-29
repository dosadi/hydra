#!/usr/bin/env python3
# ============================================================================
# Hydra Synthesis Analysis Tool
# Analyze synthesis results and generate reports
# ============================================================================

import os
import re
import argparse
import json
from pathlib import Path
from typing import Dict, List, Optional

class SynthesisAnalyzer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.results = {}

    def analyze_vivado_results(self, vivado_dir: str) -> Dict:
        """Analyze Vivado synthesis and implementation results."""
        results = {
            'tool': 'vivado',
            'utilization': {},
            'timing': {},
            'power': {},
            'status': 'unknown'
        }

        vivado_path = self.project_root / 'synthesis' / 'vivado' / vivado_dir

        # Parse utilization report
        util_file = vivado_path / 'utilization.rpt'
        if util_file.exists():
            results['utilization'] = self._parse_vivado_utilization(util_file)

        # Parse timing report
        timing_file = vivado_path / 'timing.rpt'
        if timing_file.exists():
            results['timing'] = self._parse_vivado_timing(timing_file)

        # Parse power report
        power_file = vivado_path / 'power.rpt'
        if power_file.exists():
            results['power'] = self._parse_vivado_power(power_file)

        # Check implementation status
        if (vivado_path / 'hydra_synth.runs' / 'impl_1' / 'voxel_framebuffer_top.bit').exists():
            results['status'] = 'success'
        elif (vivado_path / 'hydra_synth.runs' / 'impl_1').exists():
            results['status'] = 'failed'

        return results

    def analyze_quartus_results(self, quartus_dir: str) -> Dict:
        """Analyze Quartus synthesis results."""
        results = {
            'tool': 'quartus',
            'utilization': {},
            'timing': {},
            'power': {},
            'status': 'unknown'
        }

        quartus_path = self.project_root / 'synthesis' / 'quartus' / quartus_dir

        # Parse timing report
        timing_file = quartus_path / 'timing.rpt'
        if timing_file.exists():
            results['timing'] = self._parse_quartus_timing(timing_file)

        # Check for bitstream
        if (quartus_path / 'output_files' / 'hydra_synth.sof').exists():
            results['status'] = 'success'

        return results

    def analyze_yosys_results(self, yosys_dir: str) -> Dict:
        """Analyze Yosys synthesis results."""
        results = {
            'tool': 'yosys',
            'utilization': {},
            'timing': {},
            'status': 'unknown'
        }

        yosys_path = self.project_root / 'synthesis' / 'yosys' / yosys_dir

        # Parse synthesis log
        log_file = yosys_path / 'synth.log'
        if log_file.exists():
            results['utilization'] = self._parse_yosys_stats(log_file)

        # Check for output files
        if (yosys_path / 'synth.json').exists():
            results['status'] = 'success'

        return results

    def _parse_vivado_utilization(self, util_file: Path) -> Dict:
        """Parse Vivado utilization report."""
        util = {}
        with open(util_file, 'r') as f:
            content = f.read()

        # Extract LUT utilization
        lut_match = re.search(r'LUTs*\s*\|\s*(\d+)/\s*(\d+)', content, re.MULTILINE)
        if lut_match:
            util['lut_used'] = int(lut_match.group(1))
            util['lut_total'] = int(lut_match.group(2))

        # Extract FF utilization
        ff_match = re.search(r'Registers\s*\|\s*(\d+)/\s*(\d+)', content, re.MULTILINE)
        if ff_match:
            util['ff_used'] = int(ff_match.group(1))
            util['ff_total'] = int(ff_match.group(2))

        # Extract BRAM utilization
        bram_match = re.search(r'Block RAM\s*\|\s*(\d+)/\s*(\d+)', content, re.MULTILINE)
        if bram_match:
            util['bram_used'] = int(bram_match.group(1))
            util['bram_total'] = int(bram_match.group(2))

        return util

    def _parse_vivado_timing(self, timing_file: Path) -> Dict:
        """Parse Vivado timing report."""
        timing = {}
        with open(timing_file, 'r') as f:
            content = f.read()

        # Extract worst negative slack
        wns_match = re.search(r'Worst Negative Slack\s*:\s*([-\d.]+)', content)
        if wns_match:
            timing['wns'] = float(wns_match.group(1))

        # Extract total negative slack
        tns_match = re.search(r'Total Negative Slack\s*:\s*([-\d.]+)', content)
        if tns_match:
            timing['tns'] = float(tns_match.group(1))

        return timing

    def _parse_vivado_power(self, power_file: Path) -> Dict:
        """Parse Vivado power report."""
        power = {}
        with open(power_file, 'r') as f:
            content = f.read()

        # Extract total power
        total_match = re.search(r'Total On-Chip Power\s*\(W\)\s*\|\s*([\d.]+)', content)
        if total_match:
            power['total_power'] = float(total_match.group(1))

        return power

    def _parse_quartus_timing(self, timing_file: Path) -> Dict:
        """Parse Quartus timing report."""
        timing = {}
        with open(timing_file, 'r') as f:
            content = f.read()

        # Extract setup slack
        slack_match = re.search(r'Setup Slack\s*:\s*([-\d.]+)', content)
        if slack_match:
            timing['setup_slack'] = float(slack_match.group(1))

        return timing

    def _parse_yosys_stats(self, log_file: Path) -> Dict:
        """Parse Yosys synthesis statistics."""
        util = {}
        with open(log_file, 'r') as f:
            content = f.read()

        # Extract cell counts
        cell_matches = re.findall(r'(\w+)\s+(\d+)', content)
        for cell_type, count in cell_matches:
            if cell_type in ['AND', 'OR', 'XOR', 'DFF', 'MUX']:
                util[cell_type.lower()] = int(count)

        return util

    def generate_report(self, results: Dict, output_file: str):
        """Generate a comprehensive synthesis report."""
        report = f"""
# Hydra Synthesis Analysis Report

## Summary
- **Design**: voxel_framebuffer_top
- **Status**: {results.get('status', 'unknown')}
- **Tool**: {results.get('tool', 'unknown')}

## Resource Utilization
"""

        util = results.get('utilization', {})
        if util:
            if 'lut_used' in util:
                report += f"- **LUTs**: {util['lut_used']}/{util['lut_total']} ({util['lut_used']/util['lut_total']*100:.1f}%)\n"
            if 'ff_used' in util:
                report += f"- **Flip-Flops**: {util['ff_used']}/{util['ff_total']} ({util['ff_used']/util['ff_total']*100:.1f}%)\n"
            if 'bram_used' in util:
                report += f"- **BRAM**: {util['bram_used']}/{util['bram_total']} ({util['bram_used']/util['bram_total']*100:.1f}%)\n"
        else:
            report += "- No utilization data available\n"

        report += "\n## Timing Analysis\n"
        timing = results.get('timing', {})
        if timing:
            if 'wns' in timing:
                report += f"- **Worst Negative Slack**: {timing['wns']:.3f} ns\n"
            if 'tns' in timing:
                report += f"- **Total Negative Slack**: {timing['tns']:.3f} ns\n"
            if 'setup_slack' in timing:
                report += f"- **Setup Slack**: {timing['setup_slack']:.3f} ns\n"
        else:
            report += "- No timing data available\n"

        report += "\n## Power Analysis\n"
        power = results.get('power', {})
        if power:
            if 'total_power' in power:
                report += f"- **Total Power**: {power['total_power']:.3f} W\n"
        else:
            report += "- No power data available\n"

        # Write report
        with open(output_file, 'w') as f:
            f.write(report)

        print(f"Analysis report written to: {output_file}")

def main():
    parser = argparse.ArgumentParser(description='Analyze FPGA synthesis results')
    parser.add_argument('--tool', choices=['vivado', 'quartus', 'yosys'], required=True,
                       help='Synthesis tool used')
    parser.add_argument('--project-dir', default='vivado_project',
                       help='Project directory name')
    parser.add_argument('--output', default='synthesis_report.md',
                       help='Output report file')

    args = parser.parse_args()

    analyzer = SynthesisAnalyzer('/workspaces/hydra')

    if args.tool == 'vivado':
        results = analyzer.analyze_vivado_results(args.project_dir)
    elif args.tool == 'quartus':
        results = analyzer.analyze_quartus_results(args.project_dir)
    elif args.tool == 'yosys':
        results = analyzer.analyze_yosys_results(args.project_dir)

    analyzer.generate_report(results, args.output)

if __name__ == '__main__':
    main()