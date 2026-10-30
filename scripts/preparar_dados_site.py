#!/usr/bin/env python3
"""Stage the canonical processed panel into the Quarto site for browser execution.

The authoritative copy belongs to reproducibilidade/dados/processados/. The file
under site/data/ is a disposable build resource and must never be maintained by
hand.
"""
from __future__ import annotations

import csv
import hashlib
import shutil
from pathlib import Path

FILE_NAME = "tcc_data_panel-canonical-mercosur_1990-2023_2026-10-21_v01.csv"
EXPECTED_MD5 = "e71061bfdeb3ba8ea9f258905727718c"
EXPECTED_ROWS = 170
REQUIRED_COLUMNS = {
    "country",
    "iso3",
    "year",
    "ghgpc_tco2e_excl_lulucf",
    "gdp_pc_const2015_usd",
    "energy_intensity_kgoe_per_1000_2021ppp_gdp",
    "fossil_share_pct",
    "agri_va_pct_gdp",
    "industry_va_pct_gdp",
}

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "reproducibilidade" / "dados" / "processados" / FILE_NAME
TARGET = ROOT / "site" / "data" / FILE_NAME


def md5(path: Path) -> str:
    h = hashlib.md5()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


if not SOURCE.is_file():
    raise SystemExit(f"Painel canônico ausente: {SOURCE}")

source_md5 = md5(SOURCE)
if source_md5 != EXPECTED_MD5:
    raise SystemExit(
        f"MD5 inesperado para o painel canônico: {source_md5} != {EXPECTED_MD5}"
    )

with SOURCE.open("r", encoding="utf-8", newline="") as fh:
    reader = csv.DictReader(fh)
    columns = set(reader.fieldnames or [])
    missing = REQUIRED_COLUMNS - columns
    if missing:
        raise SystemExit(f"Colunas obrigatórias ausentes: {sorted(missing)}")
    rows = sum(1 for _ in reader)

if rows != EXPECTED_ROWS:
    raise SystemExit(f"Número de linhas inesperado: {rows} != {EXPECTED_ROWS}")

TARGET.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(SOURCE, TARGET)

if md5(TARGET) != source_md5:
    raise SystemExit("A cópia preparada para o site não é idêntica à fonte canônica.")

print(f"Painel do site derivado de: {SOURCE}")
print(f"Destino de build: {TARGET}")
print(f"linhas={rows}")
print(f"md5={source_md5}")
