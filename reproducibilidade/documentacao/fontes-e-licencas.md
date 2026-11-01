# Fontes preservadas e tratamento de redistribuição

Este arquivo documenta os inputs preservados utilizados pela implementação publicável do TCC e separa **proveniência/integridade** de **autorização de redistribuição**.

## Fontes preservadas

| Provedor | Arquivo preservado | Conteúdo utilizado | MD5 |
|---|---|---|---|
| World Development Indicators / World Bank | `tcc_data_source_wdi_economy-composition_2026-08-31_v01.xlsx` | PIB real per capita, intensidade energética, agricultura e indústria | `11cd7bb1eb11f83899625b09f1383c9f` |
| World Development Indicators / World Bank | `tcc_data_source_wdi_population-plus-fossil-share_2026-08-31_v01.xlsx` | população | `ffe14c2407a18794326f390650f6190b` |
| Climate Watch / World Resources Institute | `tcc_data_source_climate-watch_ghg-historical_2026-08-31_v01.csv` | GEE incluindo e excluindo LULUCF | `413f54f2016c82fb2f83c28f343bf211` |
| Our World in Data | `tcc_data_source_owid_fossil-consumption-by-fuel_2026-08-31_v01.csv` | gás, petróleo e carvão | `e1a46c8a03d96db5aa11aefcd6b40bbb` |
| Our World in Data | `tcc_data_source_owid_total-energy-supply_2026-08-31_v01.csv` | oferta total de energia | `1f1a5e4e0a1e3742607db37946235a65` |

Esses são os arquivos efetivamente utilizados pela reconstrução validada. A implementação privada verifica seus hashes antes de iniciar a preparação dos dados.

## Decisão de publicação — 2026-10-30

A presença dos arquivos no **repositório privado canônico** não constitui, por si só, decisão de redistribuição pública.

A fronteira pública adotada é deliberadamente conservadora:

- **não redistribuir os cinco snapshots preservados de origem** em `dados/fontes_originais/`;
- **não redistribuir os extratos intermediários** produzidos diretamente desses snapshots;
- distribuir o código analítico, a documentação de proveniência e o **painel analítico canônico derivado** necessário à reprodução das estimações e à execução no navegador;
- manter no repositório privado a cadeia integral `fontes preservadas → extratos → painel`, com hashes e validação numérica;
- indicar os provedores e as condições de reutilização aplicáveis, sem apresentar a retenção privada dos snapshots como restrição de acesso às fontes originais.

A decisão evita depender de uma interpretação extensiva de termos de terceiros para redistribuir cópias integrais dos arquivos baixados. Ela não altera os dados, as transformações ou a cadeia analítica canônica.

### Base documental consultada

- **World Development Indicators / World Bank:** o catálogo do WDI identifica o dataset como público sob **Creative Commons Attribution 4.0 (CC BY 4.0)**. Ver: `https://datacatalog.worldbank.org/search/dataset/0037712/world-development-indicators`.
- **Climate Watch / WRI:** a plataforma se apresenta como plataforma de dados abertos, oferece download do conjunto histórico de GEE e remete às suas regras de permissões/licenciamento; como o conjunto agrega dados de múltiplas fontes, a publicação não replica o snapshot integral preservado. Ver: `https://www.wri.org/data/climate-watch-historical-emissions-data-countries-us-states-unfccc` e `https://www.climatewatchdata.org/about/permissions`.
- **Our World in Data:** as séries energéticas utilizadas são apresentadas como dados com **major processing by Our World in Data** e com instruções explícitas de atribuição; a própria OWID também ressalta que dados de provedores terceiros permanecem sujeitos aos termos dos provedores originais. Por isso, a publicação utiliza os valores derivados no painel e não espelha os snapshots integrais preservados. Ver: `https://ourworldindata.org/grapher/energy-mix` e `https://catalog.ourworldindata.org/energy/owid_energy/`.

Esta é uma decisão de engenharia de publicação e proveniência para o pacote acadêmico; não pretende substituir avaliação jurídica dos termos de cada provedor.

## Painel analítico

O painel processado canônico utilizado como referência de comparação e distribuído na superfície pública é:

`tcc_data_panel-canonical-mercosur_1990-2023_2026-10-21_v01.csv`

MD5: `e71061bfdeb3ba8ea9f258905727718c`.

O painel reúne 170 observações país-ano e contém as variáveis necessárias à reprodução das especificações. Sua documentação deve preservar a atribuição aos provedores acima e indicar que há transformações próprias do TCC — entre elas conversões per capita, composição da participação fóssil e demais variáveis derivadas documentadas no código.

A reconstrução a partir das cinco fontes preservadas foi validada numericamente contra esse painel em ambiente limpo, com diferença escalada máxima igual a zero no gate de integração de 2026-10-30.

## Consequência para a execução web

A execução pública no navegador parte do painel analítico canônico distribuído. A reconstrução desde os snapshots preservados permanece disponível na implementação privada/local integral. Assim, a execução web reproduz transformações analíticas, E1–E4, diagnósticos e sensibilidades sem exigir que os cinco arquivos-fonte preservados cruzem a fronteira pública.
