    except Exception as e:
        results.append((sby, f'ERROR: {e}'))
#!/usr/bin/env python3

#!/usr/bin/env python3
"""
Automate running all SBY formal proofs and logging results for Hydra RTL modules.
"""
import os
import subprocess

FORMAL_DIR = 'formal'
SBY_SUFFIX = '.sby'
LOG_FILE = 'sby_results.log'

sby_files = [f for f in os.listdir(FORMAL_DIR) if f.endswith(SBY_SUFFIX)]
results = []

for sby in sby_files:
    sby_path = os.path.join(FORMAL_DIR, sby)
    print(f'Running: {sby_path}')
    try:
        proc = subprocess.run(['sby', sby_path], capture_output=True, text=True, timeout=600)
        out = proc.stdout + proc.stderr
        status = 'PASS' if 'Status: PASSED' in out else 'FAIL' if 'Status: FAILED' in out else 'UNKNOWN'
        results.append((sby, status))
        with open(os.path.join(FORMAL_DIR, LOG_FILE), 'a') as log:
            log.write(f'==== {sby} ====\n{out}\n')
    except Exception as e:
        results.append((sby, f'ERROR: {e}'))

print('\nSummary:')
for sby, status in results:
    print(f'{sby}: {status}')
