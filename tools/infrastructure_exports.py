#!/usr/bin/env python3
"""Shared export bookkeeping for the nlrFlow static release gates.

`NAMESPACE` exports 83 scientific functions plus six infrastructure entry
points added with the Phase-5 UX work (the pipe re-export and the cache, engine
registry and wizard helpers). The scientific-count gates below are defined over
the 83 scientific functions only; the infrastructure exports are reported
separately so that the documented "83 exported functions" claim stays exact.
"""
from pathlib import Path
import re

INFRASTRUCTURE_EXPORTS = frozenset({
    '%>%',
    'nl_cache_clear',
    'nl_cache_info',
    'nl_list_engines',
    'nl_register_engine',
    'nl_wizard',
})

SCIENTIFIC_EXPORT_COUNT = 83


def all_exports(root):
    """Every name exported by NAMESPACE, in file order (quotes stripped)."""
    ns = (Path(root) / 'NAMESPACE').read_text(encoding='utf-8')
    return [name.strip().strip('"').strip("'")
            for name in re.findall(r'export\(([^)]+)\)', ns)]


def scientific_exports(root):
    """Exports excluding the infrastructure entry points."""
    return [e for e in all_exports(root) if e not in INFRASTRUCTURE_EXPORTS]


def count_summary(root):
    """(scientific, infrastructure) export counts."""
    exports = all_exports(root)
    sci = [e for e in exports if e not in INFRASTRUCTURE_EXPORTS]
    return len(sci), len(exports) - len(sci)
