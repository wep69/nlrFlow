#!/usr/bin/env python3
from pathlib import Path
import re, sys, csv
sys.path.insert(0, str(Path(__file__).resolve().parent))
from infrastructure_exports import scientific_exports
root=Path(__file__).resolve().parents[1]
exports=scientific_exports(root)
allr='\n'.join(p.read_text(errors='ignore') for p in (root/'R').glob('*.R'))
rows=[]
for f in exports:
    pos=allr.find(f+' <- function'); pre=allr[max(0,pos-9000):pos]
    ex=pre.split("#' @examples")[-1] if "#' @examples" in pre else ''
    # documentation was authored as three domain-distinct calls; count function mentions before @export
    ex=ex.split("#' @export")[0]
    count=len(re.findall(r'\b'+re.escape(f)+r'\s*\(',ex))
    rows.append((f,count,'PASS' if count>=3 else 'FAIL'))
out=root/'inst/metadata/example_coverage.csv'
with out.open('w',newline='') as g:
    w=csv.writer(g);w.writerow(['function','manual_example_calls','status']);w.writerows(rows)
bad=[r for r in rows if r[2]=='FAIL']
print('Example coverage:',sum(r[2]=='PASS' for r in rows),'/',len(rows),'PASS')
if bad:
    print('Functions below 3 calls:',', '.join(r[0] for r in bad));sys.exit(1)
