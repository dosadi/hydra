#!/usr/bin/env python3
"""
Automated SystemVerilog property generator for Hydra RTL modules.
Scans for key signals and emits assertion templates for formal verification.
"""
import re
import os

RTL_DIR = '../rtl'
OUT_FILE = os.path.join(os.path.dirname(__file__), 'generated_properties.sv')

# Signal patterns to look for
SIGNALS = [
    ('frame start', r'start_frame_ext|start_frame_pulse'),
    ('frame done', r'frame_done'),
    ('pixel write enable', r'pixel_write_en'),
    ('pixel address', r'pixel_addr'),
]

# Property templates
TEMPLATES = {
    'frame start': '''property frame_start_to_done; @(posedge clk) disable iff (!rst_n) start_frame_ext |-> ##[1:$] frame_done; endproperty\nframe_start_to_done_sva: assert property (frame_start_to_done);\n''',
    'pixel address monotonicity': '''property pixel_addr_monotonic; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr >= $past(pixel_addr); endproperty\npixel_addr_monotonic_sva: assert property (pixel_addr_monotonic);\n''',
    'pixel write no overlap': '''property pixel_write_no_overlap; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr != $past(pixel_addr); endproperty\npixel_write_no_overlap_sva: assert property (pixel_write_no_overlap);\n''',
}

def scan_signals(rtl_path):
    signals_found = set()
    with open(rtl_path, 'r') as f:
        text = f.read()
        for label, pattern in SIGNALS:
            if re.search(pattern, text):
                signals_found.add(label)
    return signals_found

def main():
    props = []
    for fname in os.listdir(RTL_DIR):
        if fname.endswith('.sv'):
            path = os.path.join(RTL_DIR, fname)
            signals = scan_signals(path)
            if 'frame start' in signals and 'frame done' in signals:
                props.append(TEMPLATES['frame start'])
            if 'pixel write enable' in signals and 'pixel address' in signals:
                props.append(TEMPLATES['pixel address monotonicity'])
                props.append(TEMPLATES['pixel write no overlap'])
    with open(OUT_FILE, 'w') as f:
        f.write('// Auto-generated SystemVerilog properties\n')
        for p in props:
            f.write(p + '\n')
    print(f'Generated {len(props)} properties in {OUT_FILE}')

if __name__ == '__main__':
    main()
