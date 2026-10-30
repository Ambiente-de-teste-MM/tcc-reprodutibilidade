#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GUIDE = ROOT / "guia" / "guia-execucao-reprodutibilidade-r.md"
OUT = ROOT / "site" / "conteudo" / "guia-site.md"

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(GUIDE.read_text(encoding="utf-8"), encoding="utf-8")
print(f"Guia de site gerado: {OUT}")
