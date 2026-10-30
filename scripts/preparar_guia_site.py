#!/usr/bin/env python3
"""Gera a versão de site do Guia sem alterar sua fonte canônica.

- V01–V03: substituem marcadores explícitos já presentes no Guia.
- V04–V06: slots adicionais em posições definidas pelo Pilot 01.
- V07: opcional e desabilitado por padrão, conforme seu brief editorial.

Se o SVG final existir, ele é incorporado; caso contrário, a posição é ocupada
por um placeholder visível. Assim, o layout pode ser testado antes da conclusão
dos visuais.
"""

from pathlib import Path
import re
import os

ROOT = Path(__file__).resolve().parents[1]
GUIDE = ROOT / "guia" / "guia-execucao-reprodutibilidade-r.md"
OUT = ROOT / "site" / "conteudo" / "guia-site.md"
VISUAL_DIR = ROOT / "site" / "assets" / "visuais"
PATTERN = re.compile(r"^\*\*\[VISUAL (V\d{2}) — (.+)\]\*\*\s*$")

EXTRA = [
    ("V04", "Construção da participação de combustíveis fósseis (FFS)",
     "A participação fóssil é calculada a partir da soma das séries de consumo de gás, petróleo e carvão", True),
    ("V05", "Linhagem das variáveis, preparação e estimação",
     "O script principal encadeia as etapas necessárias para transformar os arquivos distribuídos nos resultados da reprodução", True),
    ("V06", "Diagnósticos, aplicabilidade e limites de interpretação",
     "Os diagnósticos qualificam a interpretação das estimações sem constituir novas especificações ou hipóteses", True),
    ("V07", "Sensibilidades predefinidas e alcance das conclusões",
     "Com a inclusão de LULUCF, H1 e H2a continuam sem suporte", os.getenv("TCC_INCLUDE_V07", "0") == "1"),
]


def render_slot(code: str, description: str) -> str:
    svg = VISUAL_DIR / f"{code}.svg"
    if svg.exists():
        return (
            f'<div class="visual-slot" id="{code.lower()}">\n'
            f'  <img src="assets/visuais/{code}.svg" alt="{description}" class="visual-svg">\n'
            f'  <p class="visual-caption"><strong>{code}</strong> — {description}</p>\n'
            f'</div>'
        )
    return (
        f'<div class="visual-placeholder" id="{code.lower()}">\n'
        f'  <strong>{code}</strong><br>\n'
        f'  {description}<br>\n'
        f'  <small>Placeholder do Pilot 01 — o arquivo final será inserido sem alterar esta posição.</small>\n'
        f'</div>'
    )


def main() -> None:
    text = GUIDE.read_text(encoding="utf-8")
    out = []
    inserted = set()
    for line in text.splitlines():
        match = PATTERN.match(line.strip())
        if match:
            code, desc = match.group(1), match.group(2)
            out.append(render_slot(code, desc))
            inserted.add(code)
            continue
        out.append(line)
        for code, desc, anchor, enabled in EXTRA:
            if enabled and code not in inserted and anchor in line:
                out.append("")
                out.append(render_slot(code, desc))
                inserted.add(code)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(out) + "\n", encoding="utf-8")
    print("Visuais inseridos/placeholder:", ", ".join(sorted(inserted)))
    print(f"Guia de site gerado: {OUT}")


if __name__ == "__main__":
    main()
