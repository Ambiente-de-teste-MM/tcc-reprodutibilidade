<!--
Publication mirror derived from Google Doc: tcc_stage-viii_guia-execucao-reprodutibilidade-r_draft_2026-10-29_v13
Drive ID: 1httY8nO8TQuPFFxx3qO7Q0svKYLLBGzJq7OIXhcWS54
Status at integration: Pass 05 candidate; not a new substantive version.
Normalization: removed Google Docs export escaping only.
-->

# Guia de Execução e Reprodutibilidade em R

**Trabalho:** *DETERMINANTES ECONÔMICAS DA EMISSÃO DE GASES DO EFEITO ESTUFA: ANÁLISE DOS MEMBROS ATIVOS DO MERCOSUL*    
**Autor:** `[preencher a partir da identificação oficial do TCC]`    
**Curso / Instituição:** `[preencher a partir da identificação oficial do TCC]`

**Este guia permite compreender, inspecionar e reproduzir a análise empírica do TCC em diferentes níveis de detalhe.**

**O guia avança da estrutura da pesquisa até a validação da reprodução.** O percurso começa pelo desenho analítico, passa pela construção dos dados e pelas estimações e termina nos resultados, diagnósticos e verificações de reprodução.

**A execução no navegador complementa a reprodução local.** Partes centrais da análise podem ser executadas diretamente pela versão web, enquanto o Pacote de Reprodutibilidade em R preserva os arquivos, a documentação estática e as instruções necessárias para uma reprodução local completa.

---

## Como a informação é apresentada

**O guia separa a informação principal dos detalhes necessários à reprodução.** As frases em destaque apresentam o que é essencial para acompanhar a análise; o texto regular acrescenta contexto e qualificação, enquanto os detalhes de implementação permanecem em nível secundário.

**O texto regular desenvolve e qualifica a síntese inicial.** Nele ficam as explicações necessárias para entender o procedimento e interpretar os resultados sem recorrer imediatamente à documentação técnica.

<small>Informações de implementação, estrutura de arquivos, versões, verificações internas e outras especificações necessárias à auditoria ou à reprodução aparecem em nível visual secundário.</small>

> **Convenção de leitura**    
> **Negrito:** síntese principal    
> Texto regular: explicação e qualificação    
> <small>Texto em menor destaque: implementação, validação ou informação auxiliar</small>

---

## O que este guia reproduz

**A reprodução cobre Argentina, Bolívia, Brasil, Paraguai e Uruguai entre 1990 e 2023, totalizando 170 observações país-ano.**

| Elemento | Conteúdo |  
| :---- | :---- |  
| Países | Argentina, Bolívia, Brasil, Paraguai e Uruguai |  
| Período | 1990–2023 |  
| Unidade de observação | País-ano |  
| Observações | 170 |  
| Variável dependente principal | Emissões de gases de efeito estufa (GEE) per capita, excluindo uso da terra, mudança no uso da terra e silvicultura (LULUCF, do inglês *Land Use, Land-Use Change and Forestry*) |  
| Especificações | E1, E2, E3 e E4 |  
| Natureza | Associacional, não causal |

**A reprodução documenta a passagem das fontes preservadas ao painel analítico e às estimações.** Ela apresenta as transformações utilizadas, as quatro especificações principais, os diagnósticos e as análises de sensibilidade definidas no desenho empírico.

**A execução completa também gera os arquivos usados para conferir os resultados.** Entre eles estão tabelas, figuras e demais saídas produzidas ao longo da análise.

<small>A variável dependente alternativa incluindo LULUCF é utilizada em uma análise de sensibilidade. A reconstrução utiliza cópias preservadas das fontes efetivamente empregadas no trabalho, evitando que revisões posteriores dos provedores alterem os dados reproduzidos.</small>

---

## Formas de utilizar o guia

**O guia pode ser utilizado para leitura da implementação, execução no navegador ou reprodução local da análise.**

**A leitura sequencial acompanha a análise do desenho empírico aos resultados.** Ela passa pela construção dos dados, pela forma como a reprodução é executada e, ao final, pelos limites e verificações da análise.

**No navegador, partes centrais da análise podem ser executadas sem uma instalação local de R.** A versão web utiliza os mesmos dados e especificações da reprodução e sua compatibilidade numérica com os resultados de referência já foi verificada.

**A reprodução local utiliza o Pacote de Reprodutibilidade em R.** Nele estão o código, os dados necessários, a documentação e as instruções de execução.

**Uma versão estática em Markdown acompanha o pacote e preserva as orientações essenciais do guia.** Dessa forma, a documentação permanece disponível também para uso local.

<small>O ambiente computacional de referência é estabelecido pela execução local validada do autor e registrado em `documentacao/ambiente_referencia.csv`. A implementação pública passa posteriormente por uma validação própria contra essa referência.</small>

---

## Estrutura do guia

**O conteúdo está organizado em seis partes, da orientação inicial à validação e reutilização da reprodução.**

1. **Orientação**  
2. **Pesquisa e desenho analítico**  
3. **Das fontes aos dados estimáveis**  
4. **Como a reprodução funciona**  
5. **O que a execução produz**  
6. **Limites, validação e reutilização**

**A sequência completa pode ser seguida do início ao fim, mas o guia também funciona para consultas pontuais.** As seções de execução, resultados, documentação técnica e arquivos de reprodução podem ser acessadas diretamente quando necessário.

<small>A versão web oferece atalhos para as principais seções e para os arquivos de reprodução local.</small>

---

# 1. Pesquisa e desenho analítico

**A análise investiga como renda, energia e composição produtiva se associam às emissões de gases de efeito estufa per capita nos membros ativos do Mercosul.** O estudo organiza a investigação em quatro dimensões: emissões, renda, energia e composição produtiva. A variável dependente principal corresponde às emissões de GEE per capita, excluindo LULUCF. A renda é representada pelo PIB real per capita e por seu termo quadrático; o bloco energético inclui intensidade energética e participação fóssil; e a composição produtiva é representada pelas participações da agricultura e da indústria no PIB.

| Dimensão | Variável | Papel |  
| :---- | :---- | :---- |  
| Emissões | GEE per capita | Variável dependente |  
| Renda | PIB real per capita | Núcleo CAK |  
| Renda | Termo quadrático da renda | Não linearidade |  
| Energia | Intensidade energética | Uso de energia por unidade de produto |  
| Energia | Participação fóssil | Composição da matriz energética |  
| Composição produtiva | Agricultura | Participação setorial no PIB |  
| Composição produtiva | Indústria | Participação setorial no PIB |

<small>As fontes, unidades e transformações operacionais das variáveis são apresentadas na seção seguinte. Neste ponto, elas são introduzidas apenas por sua função na análise.</small>

---

## Especificações e hipóteses

**E1 estima o núcleo da Curva Ambiental de Kuznets (CAK); E2 e E3 acrescentam mecanismos distintos; e E4 reúne os dois blocos em uma especificação conjunta.**

| Especificação | Núcleo de renda | Energia | Composição produtiva |  
| :------------ | --------------: | ------: | -------------------: |  
| E1 | ✓ | | |  
| E2 | ✓ | ✓ | |  
| E3 | ✓ | | ✓ |  
| E4 | ✓ | ✓ | ✓ |

**E1 examina a relação entre renda e emissões.** E2 acrescenta intensidade energética e participação fóssil. E3 incorpora as participações da agricultura e da indústria. E4 combina o núcleo de renda com os blocos energético e de composição produtiva.

**As hipóteses acompanham essa estrutura.** H1 avalia a ocorrência de uma relação em U invertido entre renda e emissões; H2a, a associação positiva da intensidade energética; H2b, a associação positiva da participação dos combustíveis fósseis; e H3, a associação estatística conjunta da agricultura e da indústria com as emissões, sem impor sinal esperado a cada coeficiente individual. E4 não constitui uma hipótese independente: sua função é verificar se as relações observadas nas especificações anteriores permanecem estáveis quando os blocos são estimados conjuntamente.

**[VISUAL V01 — arquitetura das especificações E1 → E2 / E3 → E4]**

---

## Estratégia de estimação

**Cada país é estimado separadamente e os coeficientes são posteriormente expressos em uma referência comum para a construção das médias do grupo.** O procedimento central utiliza o estimador de mínimos quadrados ordinários totalmente modificados (FM-OLS, do inglês *Fully Modified Ordinary Least Squares*), empregado para obter as relações especificadas para cada país considerando as propriedades das séries utilizadas.

**A renda é centralizada antes da estimação.** Primeiro, cada país é estimado em relação ao seu próprio nível médio de renda. Em seguida, os coeficientes associados ao núcleo de renda são reexpressos em um centro comum calculado a partir do painel completo, permitindo comparar e agregar resultados obtidos para países com diferentes níveis médios de renda.

**As estimativas dos cinco países são agregadas por média simples.** Cada país recebe o mesmo peso na formação do resultado do grupo.

<small>A inferência da média de grupo incorpora a possível dependência transversal entre os países. Em E2–E4, os erros-padrão e testes decorrem de uma extensão operacional dessa rota de covariância para uma configuração com regressores de propriedades de integração distintas e são tratados como aproximações inferenciais condicionais.</small>

<small>A configuração reproduzida utiliza `cointReg::cointRegFM`, kernel de Bartlett (`"ba"`), bandwidth 3, intercepto explícito, `demeaning = FALSE` e `check = TRUE`.</small>

**Depois das estimações principais, a análise aplica diagnósticos e sensibilidades previamente definidos.** Essas etapas avaliam as condições de interpretação dos resultados e sua estabilidade diante de alterações específicas de amostra e mensuração.

<small>Os diagnósticos preliminares de estacionariedade, integração e dependência transversal foram empregados durante o desenvolvimento metodológico para definir e validar a estratégia de estimação. Eles permanecem como documentação de reconhecimento metodológico e não constituem etapas de execução do pacote final de reprodutibilidade.</small>

---

# 2. Das fontes aos dados estimáveis

## Fontes utilizadas

**A reconstrução parte de cópias preservadas das fontes utilizadas no trabalho, e não de consultas novas aos provedores.**

| Fonte | Conteúdo utilizado | Papel na análise |  
| :---- | :---- | :---- |  
| World Development Indicators (WDI) | População, PIB real per capita, agricultura, indústria | Renda, composição produtiva e conversão per capita |  
| Climate Watch | Emissões de GEE | Variável dependente |  
| Our World in Data (OWID) | Intensidade energética, gás, petróleo, carvão e oferta total de energia | Bloco energético |

**A reprodução começa pelos arquivos preservados porque as bases públicas podem ser revisadas posteriormente.** Dessa forma, uma atualização do provedor não altera retroativamente o conjunto de dados utilizado no TCC.

<small>O pacote inclui documentação de proveniência, identificação dos arquivos originais e as condições aplicáveis à sua redistribuição.</small>

---

## Reconstrução e painel analítico

**Os arquivos preservados são convertidos em cinco extratos normalizados, que depois são combinados em um painel país-ano.** A reconstrução padroniza nomes de países, anos, unidades e identificadores antes da combinação das fontes.

**O painel principal contém 170 observações, correspondentes aos cinco países entre 1990 e 2023.** A estrutura final é balanceada para o recorte principal da análise.

**Algumas séries utilizadas na análise são construídas durante essa etapa.** As emissões totais do Climate Watch são convertidas para toneladas de CO₂ equivalente per capita utilizando a população do WDI. A participação fóssil é calculada a partir da soma das séries de consumo de gás, petróleo e carvão em relação à oferta total de energia.

**O PIB real per capita é transformado em logaritmo e centralizado para as estimações.** A intensidade energética também é utilizada em logaritmo. As participações da agricultura, da indústria e dos combustíveis fósseis são mantidas em pontos percentuais.

<small>O painel reconstruído é conferido por identidades de linhas, chaves país-ano, cobertura temporal, presença de valores ausentes e consistência das variáveis derivadas antes de seguir para as estimações.</small>

**[VISUAL V02 — fontes preservadas → extratos normalizados → painel reconstruído → transformações → centralização local → estimação por país → reexpressão no centro comum → média do grupo]**

---

## Estrutura dos arquivos de dados

**Os arquivos de dados são separados entre fontes preservadas, extratos normalizados e dados processados.**

| Pasta | Conteúdo |  
| :---- | :---- |  
| `dados/fontes_originais/` | Cópias preservadas das fontes utilizadas |  
| `dados/extratos_csv/` | Cinco extratos normalizados |  
| `dados/processados/` | Painel e objetos derivados utilizados na reprodução |

**Essa separação permite distinguir o material obtido dos provedores das transformações realizadas pelo projeto.** Os extratos funcionam como uma etapa intermediária auditável entre as fontes preservadas e o painel analítico.

---

# 3. Como a reprodução funciona

## Duas formas de execução

**A análise pode ser reproduzida no navegador ou localmente em R.** As duas formas seguem o mesmo desenho econométrico geral, mas servem a usos diferentes: a versão web prioriza o acompanhamento das etapas e dos resultados principais, enquanto a execução local dá acesso direto ao código, aos arquivos gerados e ao ambiente de execução.

**A execução no navegador é a rota mais simples para acompanhar o núcleo da reprodução.** Ela utiliza R diretamente no navegador e não exige instalação local para as etapas disponibilizadas na versão web.

**A execução local é a rota completa.** Ela utiliza o Pacote de Reprodutibilidade em R e produz todos os arquivos previstos pela implementação pública, incluindo diagnósticos, sensibilidades, tabelas, figuras, logs e registros do ambiente computacional.

<small>A versão web não substitui a distribuição dos arquivos de reprodução. Ela oferece uma forma adicional de executar e inspecionar partes centrais da análise.</small>

**[VISUAL V03 — rotas distintas: navegador (Quarto/webR → execução guiada) / pacote local (`executar_analise.R` → módulos R/01–07 → resultados completos), com referência separada]**

---

## Organização do código

**O script principal encadeia as etapas necessárias para transformar os arquivos distribuídos nos resultados da reprodução.** O fluxo começa com a configuração do ambiente e a verificação das entradas, passa pela reconstrução e preparação dos dados e segue para estimações, diagnósticos e sensibilidades.

| Ordem | Arquivo | Função principal |  
| :---- | :---- | :---- |  
| 1 | `R/01_configuracao.R` | Configuração, constantes e caminhos |  
| 2 | `R/02_reconstrucao_fontes.R` | Reconstrução dos extratos a partir das fontes preservadas |  
| 3 | `R/03_preparacao_painel.R` | Construção e validação do painel analítico |  
| 4 | `R/04_estimacao_principal.R` | Estimação das especificações E1–E4 |  
| 5 | `R/05_sensibilidades.R` | Exercícios de sensibilidade definidos no desenho empírico |  
| 6 | `R/06_tabelas.R` | Tabelas e arquivos tabulares |  
| 7 | `R/07_figuras.R` | Figuras e dados de apoio aos gráficos |

**Cada etapa também produz informações úteis para verificar a reprodução.** Isso inclui logs, manifestos, resumos tabulares e arquivos intermediários destinados à auditoria do processo.

---

## Execução local

**A reprodução local começa em `executar_analise.R`.** O script verifica o ambiente e os arquivos de entrada, executa os módulos em sequência e grava os resultados nas pastas correspondentes.

**O ambiente computacional da execução também é registrado.** A execução atual gera `resultados/logs/ambiente_execucao.csv` e, quando existe uma referência computacional válida, produz também `resultados/logs/comparacao_ambiente.csv`.

<small>O registro do ambiente não exige identidade absoluta entre máquinas. Diferenças de sistema, arquitetura ou versão são tratadas como contexto diagnóstico e devem ser avaliadas em conjunto com a equivalência dos resultados.</small>

---

# 4. O que a execução produz

## Resultados principais

**A tabela principal coloca E1–E4 lado a lado.** Para cada termo relevante, ela apresenta a estimativa do coeficiente e os elementos usados em sua avaliação estatística, permitindo observar o que muda quando os blocos de energia e composição produtiva são acrescentados ao núcleo de renda.

**A interpretação das hipóteses é feita a partir do conjunto apropriado de resultados, e não apenas do sinal de um coeficiente isolado.** H1 exige a combinação da forma quadrática com o teste de U invertido e com a localização do ponto de reversão; H3 depende do teste conjunto das variáveis de composição produtiva.

**Os resultados principais não oferecem suporte a uma CAK em U invertido.** A hipótese H1 não é sustentada nas especificações principais.

**A intensidade energética não apresenta associação positiva estatisticamente sustentada nas especificações principais.** H2a não recebe suporte.

**A participação fóssil apresenta associação positiva nas especificações principais que incluem o bloco energético.** H2b recebe suporte em E2 e permanece sustentada em E4.

**A composição produtiva apresenta associação conjunta estatisticamente sustentada nas especificações que incluem agricultura e indústria.** H3 recebe suporte em E3 e permanece sustentada em E4.

<small>As estimativas de E2–E4 são interpretadas com a qualificação inferencial associada à extensão operacional da rota de covariância para uma configuração com regressores de propriedades de integração distintas.</small>

---

## Diagnósticos

**Os diagnósticos qualificam a interpretação das estimações sem constituir novas especificações ou hipóteses.** A reprodução verifica padrões dos resíduos, incluindo autocorrelação, heterocedasticidade, tendência e dependência entre os países, e organiza esses resultados de forma compacta para identificar onde a interpretação exige maior cautela.

**A dependência transversal dos resíduos difere entre as especificações.** Ela é detectada em E1–E3 no diagnóstico principal, mas não em E4.

**Os testes complementares de cointegração para E1 não fornecem uma conclusão convergente.** Por isso, a relação polinomial da especificação de renda não é tratada como uma relação de cointegração confirmada.

---

## Sensibilidades

**As análises de sensibilidade verificam se as conclusões dependem de episódios específicos ou da fronteira de contabilização das emissões.**

**A sensibilidade de amostra exclui períodos previamente identificados para Bolívia, Brasil e Uruguai.** Os resultados são utilizados como comparação de estabilidade dos sinais e magnitudes e não substituem as estimações principais.

**A sensibilidade de mensuração repete a análise utilizando emissões per capita incluindo LULUCF.** Essa alteração muda a fronteira contabilizada da variável dependente.

**Com a inclusão de LULUCF, H1 e H2a continuam sem suporte, enquanto o suporte observado para H2b e H3 deixa de se manter.** A sensibilidade mostra que as conclusões associadas à participação fóssil e à composição produtiva dependem, em parte, da fronteira de contabilização das emissões adotada.

---

## Arquivos gerados

**A execução produz saídas legíveis e arquivos destinados à verificação da reprodução.**

| Tipo | Exemplos |  
| :---- | :---- |  
| Resultados tabulares | `inferencia_principal.csv`, `tcc_resultados-empiricos.xlsx` |  
| Figuras | SVG, PNG e dados de apoio |  
| Logs | ambiente, versões de pacotes e `sessionInfo()` |  
| Manifestos | entradas e saídas da reprodução |  
| Referência analítica | arquivos congelados usados na comparação |

**Os arquivos tabulares permitem conferir os principais resultados sem depender da interface do site.** O arquivo `inferencia_principal.csv` concentra a inferência principal em formato simples, enquanto `tcc_resultados-empiricos.xlsx` organiza as saídas empíricas em uma planilha de consulta.

**As figuras são acompanhadas por arquivos de apoio quando isso melhora a verificabilidade.** Dessa forma, o gráfico pode ser conferido tanto visualmente quanto pelos dados que o produziram.

<small>Os nomes e caminhos finais dos arquivos distribuídos são definidos pelo pacote publicável e mantidos estáveis na publicação.</small>

---

# 5. Limites, validação e reutilização

## Limites da análise

**Os resultados descrevem associações observadas nos cinco países analisados entre 1990 e 2023 e não identificam efeitos causais.** As estimativas permitem examinar como renda, energia e composição produtiva se relacionam com as emissões dentro dessa amostra, mas não estabelecem que alterações em uma variável produzam necessariamente mudanças nas demais.

**O recorte possui uma dimensão transversal pequena e corresponde à composição atual dos Estados Partes ativos do Mercosul.** Os cinco países não compartilham uma trajetória histórica uniforme de participação no bloco ao longo de 1990–2023.

**A especificação E1 não apresenta a forma de U invertido da Curva Ambiental de Kuznets na faixa de renda observada.** Além disso, os testes complementares não fornecem evidência suficiente para confirmar uma relação de cointegração em E1.

**Algumas conclusões também dependem das escolhas de amostra e de mensuração das emissões.** Os exercícios de exclusão de períodos mostram diferentes graus de estabilidade entre os coeficientes, enquanto a inclusão das emissões associadas ao uso da terra, mudança no uso da terra e silvicultura altera as conclusões relacionadas a H2b e H3.

---

## Validação da reprodução

**A validação é feita em duas etapas.** Primeiro, uma execução local limpa no ambiente do autor estabelece a referência canônica da análise e registra o ambiente computacional correspondente. Depois, quando o repositório, o pacote e a versão web estiverem montados, a implementação pública será executada de ponta a ponta e comparada com essa referência.

A validação da implementação pública deverá confirmar a reconstrução dos cinco extratos normalizados, do painel balanceado com 170 observações, das especificações E1–E4, dos diagnósticos e das análises de sensibilidade, além da regeneração das tabelas, figuras e informações do ambiente de execução.

| Etapa a verificar | Critério de fechamento |  
| :---- | :---- |  
| Fontes → extratos normalizados | Reconstrução limpa confirmada |  
| Extratos → painel analítico | Reconstrução e identidade do painel confirmadas |  
| Especificações E1–E4 | Resultados da implementação publicável validados |  
| Diagnósticos | Regeneração e consistência confirmadas |  
| Sensibilidades | Regeneração e consistência confirmadas |  
| Tabelas e relatórios | Regenerados pela implementação publicável |  
| Figuras | Regeneradas pela implementação publicável |  
| Ambiente computacional | Registro da execução pública gerado e comparado à referência do autor |

**A execução local validada do autor estabelece a referência analítica e computacional usada nas comparações posteriores.** A implementação pública deverá reproduzir esses resultados dentro das tolerâncias definidas e passará por sua própria validação antes da publicação. Os registros internos R0–R6 não são usados como referência pública.

<small>Os registros R0–R6 permanecem apenas como documentação histórica do desenvolvimento da metodologia e da implementação.</small>

---

## Registro do ambiente computacional

**O ambiente computacional de referência é registrado a partir da execução local validada do autor, e cada nova execução gera um registro comparável.** Isso permite identificar diferenças de versão, plataforma ou configuração sem exigir que os ambientes sejam idênticos.

Depois da validação da execução canônica do autor, seu registro é preservado em `documentacao/ambiente_referencia.csv`. Em cada nova reprodução, o script coleta novamente as informações disponíveis e grava o ambiente corrente na pasta de resultados, permitindo a comparação entre os dois registros.

| Informação | Exemplo de registro |  
| :---- | :---- |  
| Versão do R | versão completa da sessão |  
| Plataforma e arquitetura | sistema e arquitetura informados pelo R |  
| Sistema operacional | nome e versão detectáveis |  
| Ambiente de desenvolvimento | versão do RStudio, quando utilizado |  
| Localidade | locale da sessão |  
| Fuso horário | configuração utilizada |  
| BLAS / LAPACK | implementação identificada pelo R |  
| Pacotes | versões efetivamente carregadas ou utilizadas |

**Os dois registros utilizam a mesma estrutura para facilitar a comparação entre execuções.** Em ambientes nos quais determinado campo não se aplica — como RStudio em uma execução diretamente pelo navegador — ele pode ser registrado como não aplicável.

<small>A referência computacional é preservada em `documentacao/ambiente_referencia.csv`; cada execução grava `resultados/logs/ambiente_execucao.csv` e, quando a referência está disponível, `resultados/logs/comparacao_ambiente.csv`, além das versões de pacotes e de `sessionInfo()`.</small>

---

## Validação da execução no navegador

**A viabilidade da reprodução em R diretamente no navegador também foi testada antes da construção da versão final do guia.** O ambiente web foi capaz de carregar `cointReg`, utilizar o painel analítico distribuído e reproduzir numericamente as quatro especificações principais.

Nos testes realizados com webR, E1–E4 permaneceram dentro da tolerância numérica adotada para a verificação da reprodução. A arquitetura de publicação com Quarto, GitHub Pages e execução R no navegador também foi testada com sucesso.

**Esses testes mostram que o núcleo econométrico é compatível com a execução no navegador, mas não substituem a validação da implementação pública completa.** Quando a versão final estiver montada, ela será testada contra a referência canônica estabelecida pela execução local do autor.

<small>A integração testada utilizou Quarto Live com webR e `cointReg` 0.2.0. Os testes de publicação também confirmaram o funcionamento de GitHub Pages e dos elementos interativos utilizados para a inspeção dos diagramas.</small>

---

## Resultado de referência e resultado da execução atual

**Os resultados congelados a partir da execução canônica do autor fornecem a referência para novas reproduções.** A comparação pode ser feita numericamente pelas verificações incorporadas ao código e, quando útil, também de forma visual entre um resultado de referência e o arquivo recém-produzido.

A Figura 1 é um exemplo desse uso: a versão congelada a partir da execução de referência mostra o resultado esperado, enquanto a figura gerada na execução atual mostra o arquivo reconstruído naquela sessão.

**A comparação visual funciona como uma verificação complementar, não como substituto das verificações numéricas.** A equivalência dos dados e resultados é avaliada pelo código a partir das identidades, benchmarks e tolerâncias definidos no pacote.

---

## Onde encontrar cada parte do pacote

**Os arquivos são organizados para que seja possível passar da visão geral aos detalhes da implementação quando necessário.**

| Interesse | Local no pacote |  
| :---- | :---- |  
| Visão geral e instruções | `README.md` |  
| Execução completa | `executar_analise.R` |  
| Código da análise | `R/` |  
| Fontes preservadas | `dados/fontes_originais/` |  
| Extratos normalizados | `dados/extratos_csv/` |  
| Painel e dados processados | `dados/processados/` |  
| Dicionário do código | `documentacao/dicionario_codigo.md` |  
| Fluxo da análise | `documentacao/fluxo_da_analise.md` |  
| Proveniência dos dados | `documentacao/proveniencia_dados.csv` |  
| Documentação do ambiente computacional | `documentacao/ambiente_computacional.md` |  
| Registro computacional de referência | `documentacao/ambiente_referencia.csv` |  
| Ambiente da execução atual | `resultados/logs/ambiente_execucao.csv` |  
| Fontes e licenças | `documentacao/fontes_e_licencas.md` |  
| Validação da reprodução | `documentacao/validacao_reprodutibilidade.md` |  
| Resultados produzidos | `resultados/` |  
| Arquivos de referência | `referencia/` |

**A versão estática deste guia acompanha o pacote de reprodução.** Ela preserva as instruções necessárias para localizar, executar e interpretar os arquivos mesmo quando a versão web não estiver sendo utilizada.

---

## Proveniência e reutilização

**Os dados preservados mantêm a atribuição aos seus provedores originais.** O pacote reúne materiais provenientes do World Development Indicators, Climate Watch e Our World in Data, e sua redistribuição ou reutilização deve respeitar as condições aplicáveis a cada fonte.

**A documentação de proveniência identifica a origem e o papel de cada arquivo utilizado na análise.** Antes de reutilizar externamente uma base preservada, o leitor deve consultar também a documentação de fontes e licenças distribuída com o pacote.

<small>Os arquivos de terceiros não constituem criação do autor. A documentação distingue esses materiais do código, da documentação e dos demais conteúdos autorais produzidos para a reprodução.</small>

---

## Como citar

**A publicação final do pacote deve ser citada pela versão efetivamente consultada.** A referência completa acompanhará a distribuição pública e identificará autoria, versão, endereço do repositório e identificador persistente quando aplicável.

| Elemento | Informação |  
| :---- | :---- |  
| Autor | `[preencher a partir da identificação oficial do TCC]` |  
| Título | *Pacote de Reprodutibilidade em R — Determinantes Econômicas da Emissão de Gases de Efeito Estufa: Análise dos Membros Ativos do Mercosul* |  
| Versão | `[preencher na publicação]` |  
| Repositório | `[preencher na publicação]` |  
| DOI / identificador persistente | `[preencher se atribuído]` |

---

## Encerramento

**O guia conecta a descrição da pesquisa aos arquivos usados para reproduzir e conferir sua análise empírica.** A versão web permite acompanhar a execução e os resultados principais; o pacote local mantém o código, os dados, as saídas e a documentação completa para uma inspeção mais detalhada.
