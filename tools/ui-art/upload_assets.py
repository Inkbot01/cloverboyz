from pathlib import Path
import argparse
import json
import re
import subprocess
import sys

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--verbose', action='store_true')
args = parser.parse_args()
candidate = root / 'tmp/tungsten/UI.luau'
candidate.unlink(missing_ok=True)
command = ['tungsten', 'sync', 'cloud']
if args.verbose:
    command.append('--verbose')
result = subprocess.run(command, cwd=root, capture_output=True, text=True)
output = result.stdout + result.stderr
env_file = root / '.env'
if env_file.exists():
    for line in env_file.read_text().splitlines():
        name, separator, value = line.partition('=')
        if separator and any(part in name.upper() for part in ('KEY', 'TOKEN', 'SECRET')):
            secret = value.strip().strip('\"\'')
            if secret:
                output = output.replace(secret, '[REDACTED]')
print(output, end='')
if result.returncode:
    sys.exit(result.returncode)
if not candidate.is_file():
    sys.exit('Tungsten did not generate an asset map; existing runtime IDs were preserved.')
source = candidate.read_text()
entries = dict(re.findall(r'\["([^"]+)"\]\s*=\s*"(rbxassetid://[1-9][0-9]*)"', source))
expected = json.loads((root / 'assets/interface/manifest.json').read_text())['publishedAssets']
missing = sorted(set(expected) - entries.keys())
if missing:
    sys.exit('Upload incomplete; runtime IDs preserved. Missing: ' + ', '.join(missing))
lines = ['return table.freeze({']
lines.extend(f'\t["{name}"] = "{entries[name]}",' for name in sorted(expected))
lines.append('})')
destination = root / 'src/shared/Assets/UI.luau'
staged = destination.with_suffix('.luau.tmp')
staged.write_text('\n'.join(lines) + '\n')
staged.replace(destination)
print(f'Installed {len(expected)} published image IDs in {destination.relative_to(root)}.')
