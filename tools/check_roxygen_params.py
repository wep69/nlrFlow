#!/usr/bin/env python3
from pathlib import Path
import re, sys
root=Path(__file__).resolve().parents[1]
exports=re.findall(r'export\(([^)]+)\)',(root/'NAMESPACE').read_text())
text='\n'.join(p.read_text(errors='ignore') for p in sorted((root/'R').glob('*.R')))
problems=[]
for fn in exports:
    m=re.search(r'(?m)^'+re.escape(fn)+r'\s*<-\s*function\s*\(', text)
    if not m: continue
    i=m.end(); depth=1; in_s=in_d=False; esc=False
    while i < len(text) and depth:
        c=text[i]
        if esc: esc=False
        elif c=='\\' and (in_s or in_d): esc=True
        elif c=="'" and not in_d: in_s=not in_s
        elif c=='"' and not in_s: in_d=not in_d
        elif not in_s and not in_d:
            if c=='(': depth+=1
            elif c==')': depth-=1
        i+=1
    sig=text[m.end():i-1]
    # top-level comma split
    args=[]; buf=''; dep=0; in_s=in_d=False; esc=False
    for c in sig+',':
        if esc: buf+=c; esc=False; continue
        if c=='\\' and (in_s or in_d): buf+=c; esc=True; continue
        if c=="'" and not in_d: in_s=not in_s; buf+=c; continue
        if c=='"' and not in_s: in_d=not in_d; buf+=c; continue
        if not in_s and not in_d:
            if c in '([{': dep+=1
            elif c in ')]}': dep-=1
            elif c==',' and dep==0:
                a=buf.strip(); buf=''
                if a:
                    name=a.split('=',1)[0].strip()
                    if name and name!='...': args.append(name)
                continue
        buf+=c
    before=text[:m.start()]
    lines=before.splitlines()
    block_lines=[]
    for line in reversed(lines):
        if line.startswith("#'"):
            block_lines.append(line)
        elif block_lines:
            break
    block='\n'.join(reversed(block_lines))
    params=set(re.findall(r"#'\s*@param\s+([A-Za-z0-9_.]+)",block))
    missing=[a for a in args if a not in params]
    if missing: problems.append(f"{fn}: undocumented formals {', '.join(missing)}")
if problems:
    print('ROXYGEN PARAM CHECK FAIL')
    print('\n'.join('- '+p for p in problems)); sys.exit(1)
print(f'ROXYGEN PARAM CHECK PASS: {len(exports)}/{len(exports)} exported functions have documented formals.')
