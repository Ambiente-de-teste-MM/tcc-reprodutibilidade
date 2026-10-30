<!--
Publication mirror derived from Google Doc: tcc_stage-viii_guia-execucao-reprodutibilidade-r_draft_2026-10-29_v13
Drive ID: 1httY8nO8TQuPFFxx3qO7Q0svKYLLBGzJq7OIXhcWS54
Source revision after browser/local scope conformity repair: AHj4eMTRBoeFpBnOiUNfg6A7gw47rkPE4X0FZQQF1NKFNWbmb7Hocw-GY8wbcT-SpOnzvcSQyrrKMgUgLRZfnl_Qw2OD4hsJ_mfgFoitNg
Status at synchronization: Pass 05 candidate; not a new substantive version.
Normalization: removed Google Docs export escaping only.
-->

# Guia de Execução e Reprodutibilidade em R

**Trabalho:** *DETERMINANTES ECONÔMICAS DA EMISSÃO DE GASES DO EFEITO ESTUFA: ANÁLISE DOS MEMBROS ATIVOS DO MERCOSUL*    
**Autor:** `[preencher a partir da identificação oficial do TCC]`    
**Curso / Instituição:** `[preencher a partir da identificação oficial do TCC]`

**Este guia permite compreender, inspecionar e reproduzir a análise empírica do TCC em diferentes níveis de detalhe.**

**O guia avança da estrutura da pesquisa até a validação da reprodução.** O percurso começa pelo desenho analítico, passa pela construção dos dados e pelas estimações e termina nos resultados, diagnósticos e verificações de reprodução.

**A execução no navegador e a reprodução local percorrem o mesmo fluxo analítico.** A versão web permite executar a reprodução diretamente no navegador, sem instalação local de R, enquanto o Pacote de Reprodutibilidade em R oferece acesso direto ao código, aos arquivos gerados e ao ambiente de execução para inspeção e validação mais controladas.

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

**No navegador, a análise pode ser reproduzida sem uma instalação local de R.** A versão web executa o mesmo fluxo analítico da reprodução, da reconstrução dos dados às transformações, estimações, diagnósticos e sensibilidades, com uma apresentação mais guiada dos resultados.

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

<small>Os diagnósticos preliminares de estacionariedade, integração e dependência transversal foram empregados durante o desenvolvimento metodológico como instrumentos de reconhecimento das propriedades dos dados e de apoio às decisões que culminaram na arquitetura econométrica adotada. Esses procedimentos não constituem etapas necessárias à execução das estimações finais: as decisões por eles informadas foram posteriormente incorporadas à especificação e ao procedimento econométrico validados. Por essa razão, integram o registro técnico do desenvolvimento metodológico, enquanto o pacote de reprodutibilidade concentra-se na execução da arquitetura empírica já estabelecida e em seus diagnósticos, inferências e análises de sensibilidade correspondentes.</small>

<small>A preparação das variáveis, a centralização local, a transformação dos coeficientes para o centro comum e a agregação são detalhadas na seção seguinte e implementadas diretamente nos módulos R distribuídos com a reprodução.</small>

---

# 2. Das fontes aos dados estimáveis

**A reprodução começa nas cópias preservadas das fontes efetivamente utilizadas no TCC.** Esses arquivos constituem o ponto de partida para reconstruir o painel da análise. Assim, a execução utiliza as mesmas versões das bases empregadas no trabalho, em vez de consultar novamente os provedores e eventualmente receber dados que tenham sido revisados depois da realização da pesquisa.

| Provedor | Conteúdo utilizado | Papel na análise |  
| :---- | :---- | :---- |  
| World Development Indicators (WDI) | PIB real per capita, intensidade energética, agricultura e indústria | Renda, energia e composição produtiva |  
| World Development Indicators (WDI) | População | Conversão das emissões para valores per capita |  
| Climate Watch | GEE incluindo e excluindo LULUCF | Variável dependente principal e alternativa |  
| Our World in Data (OWID) | Gás, petróleo e carvão | Componentes da participação fóssil |  
| Our World in Data (OWID) | Oferta total de energia | Denominador da participação fóssil |

<small>A documentação do pacote identifica os arquivos preservados, sua proveniência, integridade e condições de redistribuição.</small>

---

## Da fonte preservada aos extratos normalizados

**As diferentes bases são reduzidas ao mesmo recorte de países, anos e séries antes de serem combinadas.** O código seleciona Argentina, Bolívia, Brasil, Paraguai e Uruguai no período de 1990 a 2023 e converte as fontes para uma estrutura comum de observações país-ano.

**A reconstrução produz cinco extratos normalizados.** Eles correspondem a economia e composição produtiva, população, emissões, componentes fósseis e oferta total de energia.

**A preparação preserva as observações disponíveis nas fontes, sem preencher lacunas com valores estimados ou criar observações intermediárias.** Em outras palavras, o código não interpola valores entre dois anos nem substitui uma eventual ausência de dado por uma estimativa. Nas planilhas do WDI, por exemplo, a estrutura original em formato largo é convertida para país-ano sem alterar os valores selecionados.

<small>Antes da extração, o código verifica a identidade dos arquivos preservados e a presença das séries, países e anos esperados.</small>

---

## Construção do painel

**Os cinco extratos são combinados pela chave `iso3 + year`, formando um painel balanceado com 170 observações.** O resultado contém 34 anos para cada um dos cinco países e mantém uma única observação para cada combinação país-ano.

**Algumas séries utilizadas na análise são construídas durante essa etapa.** As emissões totais do Climate Watch são convertidas para toneladas de CO₂ equivalente per capita utilizando a população do WDI. A participação fóssil é calculada a partir da soma das séries de consumo de gás, petróleo e carvão em relação à oferta total de energia.

**O painel reconstruído é comparado com o painel analítico certificado antes da continuidade da reprodução.** A reconstrução parte sempre das fontes preservadas e refaz o processo de preparação dos dados. O painel certificado é utilizado somente como referência para verificar se esse processo chegou novamente aos mesmos dados empregados na análise original; ele não substitui as fontes nem funciona como um atalho para evitar sua reconstrução.

---

## Transformações usadas nas estimações

**As variáveis são transformadas no código antes de serem encaminhadas às especificações econométricas.** As emissões de GEE per capita, o PIB real per capita e a intensidade energética entram em logaritmo. Participação fóssil, agricultura e indústria permanecem expressas em pontos percentuais.

| Variável analítica | Construção |  
| :---- | :---- |  
| Emissões — principal | log de GEE per capita excluindo LULUCF |  
| Emissões — sensibilidade | log de GEE per capita incluindo LULUCF |  
| Renda | log do PIB real per capita |  
| Intensidade energética | log da intensidade energética |  
| Participação fóssil | percentual da oferta total de energia |  
| Agricultura | participação percentual no PIB |  
| Indústria | participação percentual no PIB |

**O termo quadrático da CAK é construído a partir da renda em logaritmo, após sua centralização.** Por isso, um eventual campo contendo o PIB per capita elevado ao quadrado em nível não corresponde ao regressor quadrático utilizado nas estimações.

---

## Centralização por país e centro comum

**A estimação utiliza uma centralização local temporária da renda e posteriormente reexpressa os resultados em uma referência comum.** Para cada país, o logaritmo do PIB per capita é inicialmente expresso em relação à média daquele próprio país, e a estimação FM-OLS é realizada nessa referência local. Essa reparametrização é reversível e não altera a relação econômica estimada.

**Os coeficientes associados à renda são então transformados para um centro comum calculado a partir do painel completo.** Essa reexpressão coloca os resultados dos cinco países em uma mesma referência de renda antes da comparação e da formação da média do grupo. O centro comum permanece fixo nas sensibilidades predefinidas, mantendo a mesma referência entre as estimações.

**[VISUAL V02 — fontes preservadas → extratos normalizados → painel reconstruído → transformações → centralização local → estimação por país → reexpressão no centro comum → média do grupo]**

<small>O centro comum corresponde à média do logaritmo do PIB real per capita nas 170 observações do painel. Seu valor é calculado e verificado automaticamente durante a execução.</small>

---

## Integridade da reconstrução

**A preparação dos dados inclui verificações automáticas antes que o painel seja utilizado nas estimações.** O código verifica, entre outros pontos, a identidade dos arquivos-fonte, o número esperado de observações, os países e anos presentes, a unicidade das chaves país-ano e a validade das variáveis necessárias.

**As séries derivadas também são verificadas contra suas próprias fórmulas de construção.** Isso inclui as emissões per capita, a participação fóssil e outras variáveis produzidas durante a reconstrução.

**A etapa termina com a comparação entre o painel reconstruído e a referência certificada.** Somente depois dessas verificações o painel segue para as transformações e estimações executadas pelos módulos seguintes.

<small>As verificações de integridade utilizam hashes dos arquivos, identidades algébricas e tolerâncias numéricas definidas no próprio pacote.</small>

---

# 3. Como a reprodução funciona

**A análise pode ser reproduzida no navegador ou localmente em R.** As duas formas executam o mesmo fluxo analítico, da reconstrução dos dados às estimações, diagnósticos e sensibilidades, mas servem a usos diferentes: a versão web prioriza a execução guiada e a inspeção dos resultados na interface, enquanto a execução local dá acesso direto ao código, aos arquivos gerados e ao ambiente de execução.

| Forma de execução | Execução | Apresentação |  
| :---- | :---- | :---- |  
| Navegador | Fluxo analítico da reprodução | Seleção guiada dos principais resultados, diagnósticos e etapas |  
| Local em R | Fluxo analítico da reprodução | Acesso direto ao código, às etapas e ao conjunto de arquivos produzidos |

<small>A execução local também permite maior aproximação ao ambiente utilizado na reprodução de referência, especialmente quando são observadas as versões de R, pacotes e parâmetros documentados no Pacote de Reprodutibilidade em R.</small>

---

## Execução no navegador

**A versão web executa a análise em R diretamente no navegador.** Isso permite acompanhar a preparação dos dados, as estimações e as etapas posteriores sem configurar previamente uma instalação local de R.

**A versão web destaca apenas o que é mais útil para acompanhar a reprodução.** As especificações E1–E4, seus principais coeficientes e os diagnósticos centrais aparecem com maior destaque; resultados auxiliares continuam disponíveis, mas não ocupam o fluxo principal do guia. Assim, a reprodução permanece inspecionável sem virar uma sequência extensa de tabelas e saídas técnicas.

**A diferença está na apresentação, não em uma análise econometricamente reduzida.** O procedimento continua sendo tratado como um processo único; a versão web apenas organiza o que recebe maior ou menor destaque.

<small>A execução no navegador utiliza R por meio de webR. A compatibilidade de E1–E4 já foi verificada numericamente contra os resultados de referência; o alcance final do fluxo executável na versão publicada ainda depende da verificação direta da implementação web.</small>

---

## Execução local do pacote

**A reprodução local utiliza diretamente os arquivos do Pacote de Reprodutibilidade em R e oferece acesso integral ao código e às saídas produzidas.** O ponto de entrada é o arquivo `executar_analise.R`, localizado na raiz do pacote, que coordena os módulos responsáveis pela preparação dos dados, estimações, diagnósticos, sensibilidades, tabelas e figuras.

**Em RStudio, a forma mais simples é abrir a pasta do pacote e executar `executar_analise.R`.** A partir daí, é possível acompanhar o código, inspecionar os objetos e arquivos gerados e abrir os módulos individuais quando uma etapa exigir mais detalhe.

**A mesma reprodução também pode ser iniciada pela linha de comando.** A partir da pasta principal do pacote:

```bash  
Rscript --vanilla executar_analise.R  
```

**As dependências necessárias devem estar disponíveis no ambiente antes da execução.** O pacote não instala automaticamente as bibliotecas utilizadas; os requisitos e as versões de referência são documentados junto aos arquivos distribuídos.

<small>Para maior proximidade com a implementação publicada, recomenda-se utilizar as versões de R e dos pacotes registradas na documentação da versão de referência. Outras versões compatíveis podem introduzir pequenas diferenças numéricas ou de comportamento entre ambientes.</small>

---

## Organização do código

**O código é dividido em sete módulos coordenados pelo script principal.** A separação mantém cada etapa fácil de localizar sem concentrar toda a análise em um único arquivo.

| Arquivo | Função |  
| :---- | :---- |  
| `executar_analise.R` | Coordena a reprodução completa |  
| `R/01_configuracao.R` | Define parâmetros, caminhos e funções auxiliares |  
| `R/02_preparacao_dados.R` | Reconstrói as fontes, forma o painel e prepara as variáveis |  
| `R/03_diagnosticos.R` | Executa os diagnósticos definidos para a análise |  
| `R/04_estimacao_principal.R` | Estima as especificações E1–E4 |  
| `R/05_sensibilidades.R` | Executa as análises de sensibilidade |  
| `R/06_tabelas.R` | Produz as tabelas e saídas tabulares |  
| `R/07_figuras.R` | Produz as figuras da reprodução |

**[VISUAL V03 — duas rotas para o mesmo fluxo analítico: navegador (Quarto/webR → execução guiada e seleção de saídas) / pacote local (`executar_analise.R` → módulos R/01–07 → inspeção direta dos arquivos e saídas), com referência separada]**

<small>A numeração organiza os arquivos para leitura e manutenção. A sequência efetiva das operações é controlada pelo script `executar_analise.R`.</small>

---

## Da execução aos resultados

**O script principal encadeia as etapas necessárias para transformar os arquivos distribuídos nos resultados da reprodução.** O fluxo começa com a configuração do ambiente e a verificação das entradas, passa pela reconstrução e preparação dos dados e segue para estimações, diagnósticos e sensibilidades.

**Ao final, os resultados da análise são gravados em arquivos que podem ser consultados fora do R.** Isso inclui tabelas, figuras, arquivos consolidados e outras saídas usadas para conferir os resultados e registrar a execução.

**As verificações incorporadas ao pacote interrompem a execução quando uma condição necessária não é atendida.** Assim, problemas como arquivos inesperados, estruturas incompatíveis ou falhas nas verificações de integridade são identificados antes que a sequência restante seja executada.

<small>Os arquivos de entrada permanecem separados das saídas geradas, de modo que os materiais necessários para iniciar a reprodução não se confundam com os arquivos produzidos durante a execução.</small>

---

# 4. O que a execução produz

**A execução produz as estimações, diagnósticos, sensibilidades, tabelas, figuras e registros necessários para conferir a reprodução.** O guia apresenta primeiro E1–E4, depois os resultados que qualificam sua interpretação e, por fim, a síntese das hipóteses e das trajetórias das emissões.

<small>O conjunto completo de arquivos permanece disponível no Pacote de Reprodutibilidade em R, mesmo quando determinado resultado não é exibido diretamente nesta apresentação.</small>

---

## Resultados principais E1–E4

**A tabela principal coloca E1–E4 lado a lado.** Para cada termo relevante, ela apresenta a estimativa do coeficiente e os elementos usados em sua avaliação estatística, permitindo observar o que muda quando os blocos de energia e composição produtiva são acrescentados ao núcleo de renda.

**[TABELA — resultados principais E1–E4, gerada a partir da execução atual]**

<small>A tabela exibida é construída a partir dos resultados gerados pela execução, com `inferencia_principal.csv` como fonte principal. Os arquivos completos de coeficientes permanecem disponíveis para inspeção mais detalhada.</small>

---

## Forma estimada da relação renda–emissões

**No intervalo de renda observado na amostra, aumentos de renda permanecem associados a aumentos de emissões.** A Figura 1 apresenta a elasticidade marginal associada à renda, mostrando como essa relação varia ao longo dos níveis de PIB per capita observados nos cinco países.

Para que a forma de U invertido prevista pela hipótese da Curva Ambiental de Kuznets aparecesse dentro da amostra, essa elasticidade deveria atingir zero e tornar-se negativa em algum ponto. **A inversão não ocorre dentro da faixa de renda observada**, de modo que E1 não fornece suporte à H1 nessa faixa.

**[FIGURA 1A — elasticidade marginal da renda: resultado de referência]**

**[FIGURA 1B — elasticidade marginal da renda: resultado desta execução]**

<small>As duas figuras representam a mesma saída substantiva. A primeira acompanha a reprodução de referência; a segunda é gerada pela execução atual e permite uma comparação visual direta entre as duas reproduções.</small>

---

## Diagnósticos pós-estimação

**Os diagnósticos qualificam a interpretação das estimações sem constituir novas especificações ou hipóteses.** A reprodução verifica padrões dos resíduos, incluindo autocorrelação, heterocedasticidade, tendência e dependência entre os países, e organiza esses resultados de forma compacta para identificar onde a interpretação exige maior cautela.

**[QUADRO — síntese dos diagnósticos residuais e de dependência transversal, gerado a partir da execução atual]**

**A interpretação de longo prazo de E1 recebe uma verificação complementar específica.** Os testes adicionais de cointegração não fornecem evidência suficiente para confirmar essa propriedade de E1. Esse resultado limita uma interpretação forte de longo prazo da especificação, sem alterar o fato de que ela permanece informativa para caracterizar a relação estimada na amostra.

<small>Os resultados apresentados nesta seção são lidos das saídas produzidas pela própria execução; os testes não são refeitos separadamente pelo guia.</small>

---

## Sensibilidade a quebras predefinidas

**As exclusões predefinidas de períodos da amostra mostram que algumas relações são mais estáveis do que outras.** Participação fóssil e indústria apresentam maior estabilidade direcional, enquanto intensidade energética, termo quadrático da renda e agricultura mostram maior sensibilidade em exercícios selecionados.

Essas comparações ajudam a identificar resultados mais dependentes de períodos específicos da amostra. **Elas são tratadas como análises de sensibilidade das estimativas pontuais**, e não como uma nova rodada de inferência formal para cada amostra reduzida.

**[QUADRO — sensibilidade às exclusões predefinidas, gerado a partir da execução atual]**

---

## Sensibilidade à inclusão das emissões de uso da terra e florestas

**Parte das conclusões depende da fronteira utilizada para contabilizar as emissões de gases de efeito estufa.** O resultado principal utiliza emissões per capita excluindo uso da terra, mudança no uso da terra e silvicultura (LULUCF, do inglês *Land Use, Land-Use Change and Forestry*). A reprodução também repete a análise utilizando a medida alternativa que inclui esse componente.

**Com a inclusão de LULUCF, H1 e H2a continuam sem suporte, enquanto o suporte observado para H2b e H3 deixa de se manter.** A sensibilidade mostra que as conclusões associadas à participação fóssil e à composição produtiva dependem, em parte, da fronteira de contabilização das emissões adotada.

---

## Síntese das hipóteses

**A evidência principal não sustenta H1 nem H2a; H2b e H3 recebem suporte no resultado principal, com uma qualificação importante associada a LULUCF.**

| Hipótese | Resultado principal | Qualificação |  
| :---- | :---- | :---- |  
| H1 | Não sustentada | A forma de U invertido não aparece na faixa de renda observada; a cointegração de E1 também não é confirmada pela verificação complementar |  
| H2a | Não sustentada | O resultado permanece sem suporte na sensibilidade com LULUCF |  
| H2b | Sustentada | O suporte não se mantém quando LULUCF é incluído |  
| H3 | Sustentada | O suporte não se mantém quando LULUCF é incluído |

**E4 funciona como verificação conjunta das relações examinadas nas especificações anteriores, e não como uma hipótese adicional.** Sua leitura permite observar como os coeficientes se comportam quando os blocos energético e de composição produtiva são incluídos simultaneamente.

<small>A síntese final é produzida a partir das estimações, diagnósticos e sensibilidades anteriores, evitando interpretar isoladamente apenas um coeficiente ou uma especificação.</small>

---

## Trajetórias das emissões

**As trajetórias das emissões ajudam a visualizar tanto a heterogeneidade entre os cinco países quanto o efeito da fronteira de contabilização adotada.** As Figuras 2 e 3 apresentam a evolução das emissões per capita entre 1990 e 2023, respectivamente excluindo e incluindo LULUCF.

**[FIGURA 2 — emissões de GEE per capita excluindo LULUCF, gerada nesta execução]**

**[FIGURA 3 — emissões de GEE per capita incluindo LULUCF, gerada nesta execução]**

Essas figuras têm função descritiva e contextual. **As diferenças visuais entre países e entre as duas medidas de emissões complementam, mas não substituem, os resultados das estimações e das análises de sensibilidade.**

---

## Arquivos produzidos pela reprodução

**A execução gera mais arquivos do que os exibidos diretamente no guia.** O diretório de resultados reúne tabelas reutilizáveis, figuras, resultados detalhados dos diagnósticos e sensibilidades, registros do ambiente e informações sobre a própria execução.

| Grupo | Conteúdo |  
| :---- | :---- |  
| Estimações | Coeficientes e resultados das especificações E1–E4 |  
| Diagnósticos | Resultados por país e sínteses das verificações aplicadas |  
| Sensibilidades | Quebras predefinidas e alternativa incluindo LULUCF |  
| Tabelas | Arquivos tabulares utilizados na apresentação e na inspeção |  
| Figuras | Figuras substantivas e seus formatos distribuídos |  
| Registros | Ambiente R, versões de pacotes e informações da execução |

**O inventário completo permite sair da síntese do guia e conferir diretamente o que foi produzido pelo código.** Quando um diagnóstico, coeficiente ou exercício de sensibilidade exigir mais detalhe, a saída correspondente pode ser consultada sem que todo esse material precise aparecer no corpo principal.

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

