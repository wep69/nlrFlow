#!/usr/bin/env python3
from pathlib import Path
import re,csv,sys
root=Path(__file__).resolve().parents[1]
exports=re.findall(r'export\(([^)]+)\)',(root/'NAMESPACE').read_text())
rows=[]
for fn in exports:
 p=root/'man'/f'{fn}.Rd'
 s=p.read_text(errors='ignore') if p.exists() else ''
 m=re.search(r'\\examples\{(.*)\}\s*$',s,re.S)
 ex=m.group(1) if m else ''
 n=len(re.findall(r'\b'+re.escape(fn)+r'\s*\(',ex))
 rows.append((fn,n,'PASS' if n>=3 else 'FAIL'))
out=root/'inst/metadata/generated_rd_example_coverage.csv'
with out.open('w',newline='') as f:
 w=csv.writer(f);w.writerow(['function','Rd_example_calls','status']);w.writerows(rows)
bad=[r for r in rows if r[2]=='FAIL']
print(f'Generated Rd example coverage: {len(rows)-len(bad)}/{len(rows)} PASS')
if bad:
 print('FAIL:',', '.join(x[0] for x in bad));sys.exit(1)
