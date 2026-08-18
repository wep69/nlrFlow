#!/usr/bin/env python3
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
exports=re.findall(r'export\(([^)]+)\)',(root/'NAMESPACE').read_text())

def find_block(fn):
    for p in (root/'R').glob('*.R'):
        s=p.read_text(errors='ignore')
        m=re.search(r'(?m)^'+re.escape(fn)+r'\s*<-\s*function\s*\(',s)
        if not m: continue
        # collect contiguous roxygen lines before definition
        prefix=s[:m.start()].splitlines()
        i=len(prefix)-1; block=[]
        while i>=0 and prefix[i].startswith("#'"):
            block.append(prefix[i][2:].lstrip()); i-=1
        block=block[::-1]
        # signature balancing
        pos=m.end()-1; lev=0; end=None
        for j,ch in enumerate(s[pos:],start=pos):
            if ch=='(': lev+=1
            elif ch==')':
                lev-=1
                if lev==0: end=j+1; break
        sig=s[m.start():end]
        sig=re.sub(r'^'+re.escape(fn)+r'\s*<-\s*function\s*',fn,sig)
        sig=' '.join(sig.split())
        return block,sig
    raise KeyError(fn)

def esc_text(x):
    # Conservative Rd escaping outside examples
    return x.replace('%','\\%')

for fn in exports:
    block,sig=find_block(fn)
    title=block[0] if block else fn
    desc=[]; params=[]; ret='An R object.'; examples=[]; mode='desc'
    for line in block[1:]:
        if line.startswith('@param '):
            mode='meta'; rest=line[len('@param '):]; parts=rest.split(None,1); params.append((parts[0],parts[1] if len(parts)>1 else ''))
        elif line.startswith('@return '): ret=line[len('@return '):]; mode='meta'
        elif line.startswith('@examples'): mode='examples'
        elif line.startswith('@export'): mode='meta'
        elif line.startswith('@'):
            mode='meta'
        elif mode=='desc':
            if line: desc.append(line)
        elif mode=='examples': examples.append(line)
    if not desc: desc=[title]
    out=[f'\\name{{{fn}}}',f'\\alias{{{fn}}}',f'\\title{{{esc_text(title)}}}',f'\\description{{{esc_text(" ".join(desc))}}}',f'\\usage{{{sig}}}']
    if params:
        out.append('\\arguments{')
        for n,d in params: out.append(f'  \\item{{{n}}}{{{esc_text(d)}}}')
        out.append('}')
    out.append(f'\\value{{{esc_text(ret)}}}')
    if examples:
        out.append('\\examples{')
        out.extend(examples)
        out.append('}')
    (root/'man'/f'{fn}.Rd').write_text('\n'.join(out)+'\n')
print(f'Materialized {len(exports)} conservative Rd topics. Regenerate with roxygen2 before release.')
