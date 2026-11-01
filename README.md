# TCC — Reprodutibilidade e Guia de Execução

Repositório público da análise empírica do TCC **Determinantes Econômicas da Emissão de Gases de Efeito Estufa: Análise dos Membros Ativos do Mercosul**.

Esta distribuição reúne o site Quarto/webR, o Guia de Execução e Reprodutibilidade e o pacote público para reprodução local em R.

<!-- PERSONAL-METADATA:START -->
**Site de reprodução:** https://ambiente-de-teste-mm.github.io/tcc-reprodutibilidade/  
**Repositório:** https://github.com/Ambiente-de-teste-MM/tcc-reprodutibilidade  
**Autor:** MATHEUS MOSER
<!-- PERSONAL-METADATA:END -->

## Conteúdo

- `guia/` — fonte estática do Guia de Execução e Reprodutibilidade em R;
- `site/` — fonte do site Quarto/webR e da execução analítica no navegador;
- `reproducibilidade/` — pacote público de reprodução local a partir do painel analítico canônico;
- `downloads/` — orientação sobre arquivos compactados associados às versões publicadas.

## Fronteira dos dados públicos

O repositório distribui o painel analítico canônico de 170 observações e o código necessário para reproduzir E1–E4, diagnósticos, sensibilidades, tabelas e figuras. Os cinco snapshots preservados de provedores terceiros e os extratos intermediários permanecem fora da distribuição pública; sua reconstrução foi certificada separadamente na camada canônica privada do projeto.

Consulte `reproducibilidade/documentacao/fontes-e-licencas.md` para proveniência e tratamento de redistribuição.

## Execução

A página **Execução no navegador** permite executar o núcleo analítico com R via webR. Para reprodução local, consulte `reproducibilidade/README.md`.

Os visuais editoriais do Guia são incorporados como SVGs navegáveis por pan/zoom. O slot V03 permanece temporariamente como placeholder até o render final de sua fonte Mermaid corrigida.
