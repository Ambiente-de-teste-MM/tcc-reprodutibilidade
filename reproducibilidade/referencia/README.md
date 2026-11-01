# Artefatos de referência

Este diretório é reservado aos artefatos imutáveis da **implementação publicável validada**. Ele é separado de `resultados/`, que contém as saídas da execução atual.

## Regra

`executar_analise.R` não escreve neste diretório. A camada só deve ser atualizada quando a implementação destinada à publicação passar pela validação limpa final e for formalmente promovida como referência pública.

Os gates internos R0–R6 e seus resultados não são fontes de referência pública para este diretório.

## População prevista após a validação final

Preservar aqui, no mínimo:

- `ambiente_execucao_referencia.csv`;
- `inferencia_principal.csv`;
- `figura-01_elasticidade-marginal-e1.svg`;
- `figura-01_elasticidade-marginal-e1.png`;
- `figura-01_elasticidade-marginal-e1_plot-data.csv`;
- manifesto com hashes dos artefatos congelados.

Esses arquivos suportarão a comparação entre a implementação publicada e uma execução corrente sem permitir que uma nova execução sobrescreva a referência.

**Estado atual:** estrutura preparada; população dos artefatos aguarda a validação da implementação publicável.
