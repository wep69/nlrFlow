#!/usr/bin/env python3
"""Static cross-file integrity checks for nlrFlow Phase E (blocks 68-74)."""
from pathlib import Path
import csv, re, sys
ROOT = Path(__file__).resolve().parents[1]
errors=[]

def fail(msg): errors.append(msg)

def rows(path):
    with open(ROOT/path, newline='', encoding='utf-8') as f:
        return list(csv.DictReader(f))

# Authoritative block map.
b = rows('inst/metadata/74_BLOCKS_IMPLEMENTATION.csv')
if len(b)!=74: fail(f'Expected 74 blocks, found {len(b)}')
nums=[]
for r in b:
    key = next((k for k in r if k.lower() in {'block','block_id','id'}), None)
    if key:
        try: nums.append(int(r[key]))
        except Exception: pass
if nums and nums != list(range(1,75)): fail('Block numbers are not exactly 1:74')

# Public API and Phase-E function names.
ns=(ROOT/'NAMESPACE').read_text(encoding='utf-8')
exports=re.findall(r'^export\(([^)]+)\)',ns,re.M)
if len(exports)!=83: fail(f'Expected 83 exports, found {len(exports)}')
phase_e={'nl_sciml_available','nl_sciml_info','nl_sciml_setup','nl_neural_ode','nl_ude','nl_pinn','nl_missing_physics','nl_ude_discover','nl_sciml_diagnose','nl_dynamic_design','nl_control'}
missing=phase_e-set(exports)
if missing: fail('Missing Phase-E exports: '+', '.join(sorted(missing)))

# Documentation counts.
vigs=list((ROOT/'vignettes').glob('*.Rmd'))
if len(vigs)!=41: fail(f'Expected 41 Rmd vignettes, found {len(vigs)}')
for i in range(31,42):
    if not any(p.name.startswith(f'{i:02d}-') for p in vigs): fail(f'Missing vignette {i:02d}')

# Teaching datasets and provenance.
ext=list((ROOT/'inst/extdata').glob('*.csv'))
if len(ext)!=14: fail(f'Expected 14 extdata CSV files, found {len(ext)}')
dm=rows('inst/metadata/dataset_manifest.csv')
if len(dm)!=14: fail(f'Expected 14 dataset-manifest rows, found {len(dm)}')

# Reference synchronization.
bib=(ROOT/'references/references.bib').read_text(encoding='utf-8')
bkeys=set(re.findall(r'^@\w+\{([^,]+),',bib,re.M))
vbib=(ROOT/'vignettes/references.bib').read_text(encoding='utf-8')
vkeys=set(re.findall(r'^@\w+\{([^,]+),',vbib,re.M))
ris=(ROOT/'references/references.ris').read_text(encoding='utf-8')
ris_n=len(re.findall(r'^TY  -',ris,re.M))
meta=rows('inst/metadata/reference_metadata.csv')
if not (len(bkeys)==len(vkeys)==ris_n==len(meta)==28):
    fail(f'Reference counts differ: bib={len(bkeys)}, vignette_bib={len(vkeys)}, RIS={ris_n}, metadata={len(meta)}')
if bkeys!=vkeys: fail('Package and vignette BibTeX keys differ')
text='\n'.join(p.read_text(encoding='utf-8',errors='ignore') for p in vigs)
cited=set(re.findall(r'@([A-Za-z0-9_:.\-]+)',text))
cited={x.rstrip('.,;:') for x in cited}
uncited=bkeys-cited
if uncited: fail('Uncited bibliography keys: '+', '.join(sorted(uncited)))

# Julia bridge files and reproducibility safeguards.
runner=(ROOT/'inst/julia/nlrflow_sciml_runner.jl').read_text(encoding='utf-8')
for token in ['Random.seed!','parallelism=parmode','deterministic=deterministic','WeightedIntervalTraining','integrated_control']:
    if token not in runner: fail(f'Julia runner missing safeguard/token: {token}')
setup=(ROOT/'inst/julia/setup_sciml.jl').read_text(encoding='utf-8')
for pkg in ['OrdinaryDiffEq','SciMLSensitivity','Lux','NeuralPDE','SymbolicRegression','Optimization']:
    if pkg not in setup: fail(f'Julia setup missing {pkg}')

# Version.
desc=(ROOT/'DESCRIPTION').read_text(encoding='utf-8')
if 'Version: 0.3.0.9000' not in desc: fail('DESCRIPTION version is not 0.3.0.9000')

if errors:
    print('PHASE-E INTEGRITY: FAIL')
    for e in errors: print(' -',e)
    sys.exit(1)
print(f'PHASE-E INTEGRITY: PASS | blocks={len(b)} exports={len(exports)} vignettes={len(vigs)} datasets={len(ext)} references={len(bkeys)}')
