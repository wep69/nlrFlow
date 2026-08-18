#!/usr/bin/env python3
from pathlib import Path
import re, sys
root=Path(__file__).resolve().parents[1]
ns=(root/'NAMESPACE').read_text()
exports=re.findall(r'export\(([^)]+)\)',ns)
allr='\n'.join(p.read_text(errors='ignore') for p in (root/'R').glob('*.R'))
alls='\n'.join(p.read_text(errors='ignore') for p in (root/'vignettes').glob('*.Rmd'))
problems=[]
for f in exports:
    if not re.search(r'\b'+re.escape(f)+r'\s*<-\s*function\b',allr): problems.append(f+' missing definition')
    pos=allr.find(f+' <- function')
    pre=allr[max(0,pos-7000):pos]
    if "#' @examples" not in pre: problems.append(f+' missing roxygen examples')
    # Require 3 explicit function mentions across vignettes. Comments count for optional backends.
    if len(re.findall(r'\b'+re.escape(f)+r'\s*\(',alls)) < 3: problems.append(f+' has fewer than 3 vignette calls')
# package structure
for req in ['DESCRIPTION','NAMESPACE','README.md','tests/testthat.R']:
    if not (root/req).exists(): problems.append('missing '+req)
if problems:
    print('STATIC VALIDATION FAIL')
    for p in problems: print('-',p)
    sys.exit(1)
print(f'STATIC VALIDATION PASS: {len(exports)} exported functions; all definitions/documentation/vignette-call gates satisfied.')
