#!/usr/bin/env python3
"""
Automate formal property insertion and SBY config generation for Hydra RTL modules.
"""
import re
import os

RTL_DIR = '../rtl'
FORMAL_GUARD = '`ifdef FORMAL'
SBY_TEMPLATE = '''[options]
mode prove

[engines]
smtbmc

[script]
read -formal ../rtl/{rtl_file}
prep -top {top_module}

[files]
../rtl/{rtl_file}
'''

# Property templates
PROPERTIES = {
    'frame_start_to_done': '''property frame_start_to_done; @(posedge clk) disable iff (!rst_n) start_frame_ext |-> ##[1:$] frame_done; endproperty\nframe_start_to_done_sva: assert property (frame_start_to_done);\n''',
    'pixel_addr_monotonic': '''property pixel_addr_monotonic; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr >= $past(pixel_addr); endproperty\npixel_addr_monotonic_sva: assert property (pixel_addr_monotonic);\n''',
    'pixel_write_no_overlap': '''property pixel_write_no_overlap; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr != $past(pixel_addr); endproperty\npixel_write_no_overlap_sva: assert property (pixel_write_no_overlap);\n''',
    'dma_done_after_busy': '''property dma_done_after_busy; @(posedge clk) disable iff (!rst_n) done |-> busy; endproperty\ndma_done_after_busy_sva: assert property (dma_done_after_busy);\n''',
    'done_only_on_enable': '''property done_only_on_enable; @(posedge clk) disable iff (!rst_n) done |-> enable; endproperty\ndone_only_on_enable_sva: assert property (done_only_on_enable);\n''',
    'output_bounds': '''property output_bounds; @(posedge clk) disable iff (!rst_n) (surface_normal_x <= 8'd255 && surface_normal_y <= 8'd255 && surface_normal_z <= 8'd255 && surface_curvature <= 8'd255 && surface_smoothness <= 8'd255); endproperty\noutput_bounds_sva: assert property (output_bounds);\n''',
}

SIGNALS = {
    'frame_start_to_done': ['start_frame_ext', 'frame_done'],
    'pixel_addr_monotonic': ['pixel_write_en', 'pixel_addr'],
    'pixel_write_no_overlap': ['pixel_write_en', 'pixel_addr'],
    'dma_done_after_busy': ['done', 'busy'],
    'done_only_on_enable': ['done', 'enable'],
    'output_bounds': ['surface_normal_x', 'surface_normal_y', 'surface_normal_z', 'surface_curvature', 'surface_smoothness'],
}

def scan_signals(rtl_path):
    signals_found = set()
    with open(rtl_path, 'r') as f:
        text = f.read()
        for prop, sigs in SIGNALS.items():
            if all(re.search(r'\\b' + s + r'\\b', text) for s in sigs):
                signals_found.add(prop)
    return signals_found

def insert_properties(rtl_path, props):
    with open(rtl_path, 'r') as f:
        lines = f.readlines()
    # Check if already present
    already_present = any(FORMAL_GUARD in l for l in lines)
    if already_present:
        return False
    # Insert after module header
    for i, l in enumerate(lines):
        if l.strip().startswith('module '):
            insert_idx = i + 1
            break
    else:
        insert_idx = 1
    prop_block = [FORMAL_GUARD + '\n']
    for p in props:
        prop_block.append(PROPERTIES[p])
    prop_block.append('`endif\n')
    lines[insert_idx:insert_idx] = prop_block
    with open(rtl_path, 'w') as f:
        f.writelines(lines)
    return True

def create_sby(rtl_file, top_module, props):
    sby_path = os.path.join('formal', f'{top_module}_auto.sby')
    with open(sby_path, 'w') as f:
        f.write(SBY_TEMPLATE.format(rtl_file=rtl_file, top_module=top_module))
        f.write('\n# Properties:\n')
        for p in props:
            f.write(f'#   {p}\n')
    print(f'Created {sby_path}')

def main():
    for fname in os.listdir(RTL_DIR):
        if fname.endswith('.sv'):
            path = os.path.join(RTL_DIR, fname)
            props = scan_signals(path)
            if props:
                inserted = insert_properties(path, props)
                top_module = fname.replace('.sv', '')
                create_sby(fname, top_module, props)
                print(f'Processed {fname}: {"Inserted" if inserted else "Already present"} properties: {props}')

if __name__ == '__main__':
    main()
