# Determinantes Econômicas da Emissão de Gases de Efeito Estufa — Pacote Público de Reprodutibilidade

Este diretório contém a distribuição pública da análise empírica do TCC **“Determinantes Econômicas da Emissão de Gases de Efeito Estufa: análise dos membros ativos do Mercosul”**.

A análise cobre Argentina, Bolívia, Brasil, Paraguai e Uruguai entre 1990 e 2023, em um painel balanceado de 170 observações país-ano.

## Fronteira da distribuição pública

A implementação canônica privada preserva a cadeia completa `snapshots de origem → extratos normalizados → painel analítico → análise`. Para a distribuição pública, os cinco snapshots de terceiros e os extratos intermediários não são espelhados no GitHub. O pacote público parte do **painel analítico canônico derivado**, cuja reconstrução a partir das fontes preservadas foi validada separadamente.

Essa fronteira de publicação não altera as especificações, o estimador, as hipóteses, os diagnósticos ou as sensibilidades. Ela altera apenas qual camada de dados é distribuída diretamente.

Painel distribuído:

`tcc_data_panel-canonical-mercosur_1990-2023_2026-10-21_v01.csv`

- 170 observações;
- 5 países × 34 anos;
- 1990–2023;
- MD5 `e71061bfdeb3ba8ea9f258905727718c`;
- SHA-256 `27c6d756512756a7a2f98fd8391d8d3cbb4c4092f614ff2e56ec5bb5ae8a9342`.

## Execução local pública

A partir da raiz de `reproducibilidade/`:

```bash
Rscript --vanilla executar_analise.R
```

Ou abra `executar_analise.R` em R/RStudio e execute o script.

A rota pública:

1. valida a identidade do painel canônico distribuído;
2. prepara as transformações analíticas;
3. estima E1–E4;
4. executa os diagnósticos B07;
5. executa as sensibilidades B08 e B09;
6. gera tabelas e figuras;
7. registra ambiente, versões de pacotes, estado consolidado e manifestos da execução.

Os scripts não instalam automaticamente as dependências.

## Estrutura

```text
reproducibilidade/
├── README.md
├── executar_analise.R
├── R/
│   ├── 01_configuracao.R
│   ├── 02_preparacao_dados.R
│   ├── 03_diagnosticos.R
│   ├── 04_estimacao_principal.R
│   ├── 05_sensibilidades.R
│   ├── 06_tabelas.R
│   └── 07_figuras.R
├── dados/
│   └── processados/
├── documentacao/
├── referencia/
└── resultados/          # criado/preenchido pela execução
```

## Especificações

- **E1:** núcleo da Curva Ambiental de Kuznets — PIB real per capita e termo quadrático;
- **E2:** E1 + intensidade energética + participação fóssil;
- **E3:** E1 + participação da agricultura + participação da indústria;
- **E4:** especificação conjunta.

A interpretação é predominantemente associacional, não causal.

## Resultados substantivos de referência

- H1 não é sustentada no resultado principal;
- H2a não é sustentada;
- H2b e H3 são sustentadas para a variável dependente principal, que exclui LULUCF;
- a inclusão de LULUCF remove o suporte observado para H2b e H3;
- as exclusões predefinidas são tratadas como sensibilidades das estimativas pontuais;
- a verificação complementar não confirma a cointegração de E1.

## Proveniência e licenças

Os dados derivam de World Development Indicators / World Bank, Climate Watch / World Resources Institute e Our World in Data. A documentação em `documentacao/` registra proveniência, hashes e a decisão conservadora de não redistribuir os snapshots preservados de terceiros.

A reconstrução completa a partir dessas fontes permanece preservada na camada canônica do projeto e foi validada numericamente contra o painel distribuído.

## Execução no navegador

O site Quarto/webR utiliza o mesmo painel canônico e executa o núcleo analítico de E1–E4, diagnósticos e sensibilidades diretamente no navegador. A diferença entre as rotas pública local e web é de interface e de arquivos produzidos, não de especificação econométrica.

Os visuais editoriais do Guia podem permanecer como placeholders e ser substituídos posteriormente por arquivos Mermaid/draw.io renderizados sem alterar esta arquitetura de execução.
