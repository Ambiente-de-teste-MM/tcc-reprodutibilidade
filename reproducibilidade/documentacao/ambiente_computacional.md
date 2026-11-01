# Registro do ambiente computacional

Este arquivo documenta a camada de registro de ambiente do Pacote de Reprodutibilidade em R.

## Referência pública

A referência computacional pública **não deriva dos gates internos R0–R6**. Ela será criada exclusivamente a partir da implementação publicável depois que essa implementação passar pela validação limpa final.

Até esse congelamento, não existe um `ambiente_execucao_referencia.csv` público autorizado.

## Execução atual

`executar_analise.R` grava em `resultados/logs/ambiente_execucao.csv` um registro estruturado `campo,valor`, incluindo:

- versão do R;
- plataforma e arquitetura;
- sistema operacional detectável pelo R;
- versão do RStudio quando exposta pelo ambiente;
- locale;
- fuso horário;
- BLAS e LAPACK quando reportados por `extSoftVersion()`;
- versões das dependências do pacote;
- identificação da entrada canônica.

Quando `referencia/ambiente_execucao_referencia.csv` existir, a execução também grava `resultados/logs/comparacao_ambiente.csv`, alinhando os campos da implementação publicada e da sessão atual. Diferenças nesse arquivo não constituem automaticamente falha analítica; servem para tornar diferenças de ambiente explícitas e auditáveis.

`package_versions.csv` e `sessionInfo.txt` permanecem como registros complementares mais detalhados.

## Promoção da referência

Após a validação final da implementação que será publicada:

1. o registro `resultados/logs/ambiente_execucao.csv` da execução validada é promovido para `referencia/ambiente_execucao_referencia.csv`;
2. os demais artefatos de referência são promovidos do mesmo run validado;
3. hashes e metadados públicos são congelados contra essa mesma implementação.

Os registros R0–R6 permanecem apenas na documentação histórica interna do projeto.
