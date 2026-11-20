# Affiliate Autopilot — Estratégia de Conteúdo

> **Revisão 3.2 — 12/11/2026 (consolidação da especificação de autorização de publicação):** a aprovação individual de cada peça passa a ser descrita como **regra da fase inicial**, não como limitação definitiva; as regras normativas estão em `AUTONOMY_AND_AGENTS.md` seção 4 e este documento apenas as referencia e reflete suas consequências editoriais (seções 2, 3, 12.1, 12.2, 13.2, 15, 15.1 e 16.3). Trechos marcados como **[Decisão conceitual — 12/11/2026]** registram decisões do proprietário; nada disto está implementado e nenhuma política de publicação está ativa. A revisão 3, de 06/11/2026, tinha cabeçalho de proposta e corpo marcado como **[Acordado]**: o status histórico é ambíguo e não equivale à aprovação definitiva de todo o seu conteúdo.

> **Revisão 3.1 — 08/11/2026 (proposta para aprovação):** frequência por marca, referências por tipo de marca e funil editorial (seções 16.2, 16.6 e 16.7).

> **Revisão 3 — 06/11/2026 (proposta para aprovação):** explicita a estratégia de peça-mãe multiformato, artigo aprofundado, cadência editorial inicial como hipótese e aprovação humana obrigatória da versão exata antes de publicação pública. A expansão de formatos/canais é visão de destino; não altera a prioridade operacional atual do YouTube.

> **O que este documento é:** define **o que** produzir, **por que** produzir, **como** estruturar o conteúdo e **como** integrar produtos de forma natural.
> **O que ele não é:** não define canais, distribuição, rastreamento nem aquisição de audiência (isso está em `ACQUISITION_STRATEGY.md`). Não descreve a arquitetura técnica (`ARCHITECTURE.md`) nem a visão de negócio (`PROJECT_VISION.md`), e não registra o que já foi implementado (`PROJECT_STATUS.md`).
>
> **Situação:** **[Proposta]** — versão 2.3 (harmonização com a decisão L2 de 04/11/2026 e com as decisões de 05/11/2026 sobre aprovação), aguarda revisão e aprovação do responsável. Nada aqui é decisão aprovada, exceto o que está marcado como **[Acordado]**. As mudanças entre versões estão na seção 17.
> **Pesquisa de fontes externas:** 04/11/2026 (pontos revisados na versão 2 foram verificados novamente na mesma data). Regras de plataformas mudam com frequência; conferir a página oficial antes de depender de qualquer regra citada.
>
> **Legenda** (a mesma de `PROJECT_VISION.md`):
> - **[Acordado]**: decisão do responsável pelo projeto.
> - **[Proposta]**: sugestão para revisão, ainda não aprovada.
> - **[Hipótese]**: acreditamos nisso, mas não foi validado com dados reais.
> - **[A definir]**: depende de uma decisão ou de um dado que ainda não existe.
> - **[Fato verificado]**: regra ou informação confirmada em fonte oficial na data da pesquisa.

---

## 1. Filosofia editorial

### 1.1 Princípio central **[Acordado]**

> **O conteúdo é o protagonista. O produto é uma consequência contextual e natural.**

Uma peça de conteúdo só existe porque é útil, interessante ou informativa para uma audiência real. O produto aparece quando, e somente quando, ajuda essa audiência a resolver um problema ou a avançar num interesse que o próprio conteúdo já tratou.

### 1.2 Consequências práticas **[Proposta]**

1. **Teste do conteúdo sem link:** toda peça precisa continuar valendo a pena se o link de afiliado for removido. Se não valer, a peça não é publicada.
2. **A maioria das peças não terá produto.** Conteúdo de descoberta e boa parte do conteúdo de conexão existem para construir audiência e confiança, não para vender.
3. **Nunca inventar:** nenhuma avaliação, depoimento, experiência de uso, resultado ou dado é inventado. Isso já é um princípio do projeto (`README.md`, `PROJECT_VISION.md` seção 8).
4. **Honestidade sobre o método:** quando uma análise se baseia em informações públicas e não em uso próprio, isso é dito claramente (ver seção 6.4).
5. **Qualidade antes de volume:** publicar menos e melhor. O volume nunca é meta em si.

### 1.3 Por que essa filosofia também é a mais segura

As regras das plataformas e dos buscadores apontam na mesma direção:

- **[Fato verificado]** O Google define *scaled content abuse* (abuso de conteúdo em escala) como gerar muitas páginas "para manipular rankings e não para ajudar usuários", "não importa como" o conteúdo foi criado. Entre os exemplos estão usar IA para gerar muitas páginas sem valor e criar vários sites para esconder a natureza em escala do conteúdo ([Google Search Central — Spam policies](https://developers.google.com/search/docs/essentials/spam-policies)).
- **[Fato verificado]** O Google recomenda conteúdo *people-first* e lista como sinal de alerta usar "automação extensa para produzir conteúdo sobre muitos assuntos" e entrar num nicho "sem expertise real, só porque achou que teria tráfego" ([Google — Creating helpful content](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)).
- **[Fato verificado]** O YouTube não monetiza conteúdo "produzido em massa, genérico, repetitivo ou manipulador", nem conteúdo gerado por IA "com modelos genéricos" sem a perspectiva original do criador ([YouTube — Monetization policies](https://support.google.com/youtubecreatorstudio/answer/1311392?hl=en)).
- **[Fato verificado]** Os termos da Hotmart proíbem divulgação "massiva, repetitiva, fora de contexto, enganosa" e consideram conduta inadequada do afiliado prestar informações "falsas, incompletas ou imprecisas" sobre o produto ([Termos de Uso da Hotmart](https://hotmart.com/pt-br/legal/termos-de-uso)).

Conteúdo artificial feito só para inserir links é, ao mesmo tempo, ruim para a audiência, arriscado para as contas e contrário às regras.

---

## 2. Pilares de conteúdo

### 2.1 O que é um pilar **[Proposta]**

Um pilar é um **grande tema** da marca, estável no tempo, que conecta a curiosidade da audiência a necessidades reais. Cada marca terá de 3 a 5 pilares. Os pilares são definidos **por marca** e registrados no guia da marca (seção 11).

### 2.2 Estrutura de um pilar

| Elemento | Descrição |
|---|---|
| Tema | O grande assunto (por exemplo, "como o cérebro aprende") |
| Promessa à audiência | O que a pessoa ganha ao acompanhar esse tema |
| Perguntas da audiência | Dúvidas reais, coletadas com os métodos de `ACQUISITION_STRATEGY.md` seção 4 |
| Necessidades e problemas | O que a audiência tenta resolver ou alcançar |
| Ganchos de descoberta | Fatos, histórias e fenômenos que despertam interesse |
| Temas de conexão | Guias e explicações práticas ligados às necessidades |
| Categorias de produto possíveis | Tipos de produto que poderiam ajudar (nunca o ponto de partida) |
| Limites | O que a marca não trata nesse pilar (por exemplo, aconselhamento médico) |

### 2.3 Critérios para aprovar um pilar **[Proposta]**

1. Existe interesse real e recorrente (verificado com dados, não suposto).
2. O tema permite conteúdo de descoberta interessante **e** conteúdo prático útil.
3. Existe pelo menos uma necessidade concreta à qual produtos verificados poderiam atender, mesmo que só no futuro.
4. A marca consegue tratar o tema com rigor (fontes confiáveis, sem depender de opinião não fundamentada).
5. O tema não está em segmento restrito ou sensível sem uma decisão explícita do responsável (saúde e alegações médicas, finanças e investimentos, apostas e jogos de azar, público infantil, segurança de produtos e pessoas; a lista é aberta e está definida em `AUTONOMY_AND_AGENTS.md` seção 4.4). Peças sobre temas sensíveis exigem sempre aprovação individual, e um risco relevante ainda não classificado bloqueia a peça até a classificação pelo proprietário. O guia do CONAR de 2026 trata segmentos restritos e público infantil com regras reforçadas ([CONAR — Guia de Publicidade por Influenciadores Digitais](https://www.conar.org.br/noticias/guia-de-marketing-e-publicidade-por-influenciadores-digitais)).

**[A definir]**: o nicho e os pilares da primeira marca. Este documento não os escolhe.

### 2.4 Exemplo ilustrativo (não é decisão)

Para tornar a estratégia concreta, este documento usa um exemplo **fictício**: uma marca sobre **aprendizado e memória**.

| Pilar | Gancho de descoberta | Conexão | Comercial contextual possível |
|---|---|---|---|
| Como a memória funciona | "Por que esquecemos 70% de algo em poucos dias?" (curva do esquecimento) | Guia de revisão espaçada | Comparativo de métodos e cursos de estudo |
| Aprender idiomas | "Por que crianças parecem aprender idiomas mais rápido?" | Rotina realista de 20 minutos por dia | Análise de cursos de idioma disponíveis |

O exemplo serve apenas para ilustrar. Os dados citados nele precisariam de verificação antes de qualquer uso real.

---

## 3. Categorias de conteúdo e seus objetivos

As três categorias são **[Acordado]**. As regras de cada uma são **[Proposta]**.

### 3.1 Descoberta

| Item | Definição |
|---|---|
| Objetivo | Atrair pessoas que ainda não conhecem a marca ou não estão procurando produtos |
| Exemplos | Curiosidades científicas, fatos interessantes, histórias surpreendentes, explicações educativas, fenômenos, descobertas, entretenimento informativo |
| Formatos típicos | Vídeos curtos, conteúdos visuais, vídeos longos narrativos |
| Produto | **Não aparece.** Nenhum link de afiliado |
| Sucesso significa | Retenção, compartilhamento, novos seguidores, visitas ao conteúdo de conexão |
| Obrigação | Toda peça de descoberta pertence a um pilar e tem uma "ponte" para pelo menos um conteúdo de conexão (seção 4.3) |
| Risco | Atrair audiência sem nenhuma relação com as necessidades do pilar. Viralizar fora do tema não é sucesso |

### 3.2 Conexão

| Item | Definição |
|---|---|
| Objetivo | Aprofundar o interesse e relacioná-lo a necessidades, problemas ou interesses reais |
| Exemplos | Explicações aprofundadas, guias práticos, aplicações no cotidiano, soluções para problemas específicos, comparação de métodos e alternativas |
| Formatos típicos | Vídeos longos, artigos, guias |
| Produto | **Raramente, e só quando faz parte da solução.** Prioridade para soluções gratuitas ou que não dependam de compra |
| Sucesso significa | Tempo de leitura ou de exibição, retorno da audiência, inscrição em lista própria, visitas a conteúdo comercial relacionado |
| Obrigação | Resolver o problema prometido com o próprio conteúdo, não só "apontar para um produto" |

### 3.3 Comercial contextual

| Item | Definição |
|---|---|
| Objetivo | Apresentar produtos quando realmente fizerem sentido para o assunto e a audiência |
| Exemplos | Comparativos, análises, recomendações, guias de compra, demonstrações de utilidade, avaliações baseadas em informações verificáveis |
| Formatos típicos | Artigos, vídeos longos, guias |
| Produto | **Central, mas com análise honesta**: prós, contras, para quem serve, para quem não serve e alternativas |
| Sucesso significa | Cliques qualificados, vendas confirmadas, baixo reembolso, confiança mantida e, no fim do ciclo, dinheiro efetivamente recebido (definições em `ACQUISITION_STRATEGY.md` seção 12) |
| Obrigação | Passar no teste de relevância (seção 6.2) e na divulgação (seção 13). Na fase inicial, autorização humana individual do responsável sobre a versão exata antes de qualquer envio, público ou privado (`AUTONOMY_AND_AGENTS.md` seções 4.2 e 4.6) |

### 3.4 Equilíbrio entre categorias **[Hipótese]**

Não há proporção fixa aprovada, e a proporção ideal continua desconhecida. Hipótese inicial a testar: **a maior parte das publicações deve ser de descoberta e conexão**, e o conteúdo comercial deve ser uma minoria, ligada a temas que a audiência já demonstrou valorizar. A proporção real será ajustada com dados (ver `ACQUISITION_STRATEGY.md` seção 13).

**Regra fixa [Proposta]:** nenhum canal da marca pode ficar com aparência de vitrine. Se a audiência percebe a marca como "um canal de anúncios", a estratégia falhou, mesmo que gere vendas no curto prazo.

---

## 4. Jornada da audiência

### 4.1 Estágios

| Estágio | Estado da pessoa | Categoria predominante | Pergunta que a peça responde |
|---|---|---|---|
| 1. Curiosidade | Não conhece a marca nem tem uma necessidade declarada | Descoberta | "Isso é interessante?" |
| 2. Interesse | Quer entender melhor | Descoberta e conexão | "Como isso funciona?" |
| 3. Relevância | Percebe que o tema se aplica à própria vida | Conexão | "Como isso me ajuda?" |
| 4. Avaliação | Procura uma solução e compara caminhos | Conexão e comercial | "Qual é a melhor opção para mim?" |
| 5. Decisão | Está pronta para escolher | Comercial contextual | "Vale a pena para o meu caso?" |
| 6. Relacionamento | Já consumiu, comprou ou não comprou, e continua acompanhando | Todas | "O que mais posso aprender aqui?" |

### 4.2 Regras da jornada **[Proposta]**

1. **Não pular estágios à força.** Uma peça de descoberta não empurra a pessoa direto para a compra.
2. **Toda peça tem um próximo passo natural**: outra peça, uma série, um guia ou, só no estágio 4 ou 5, uma oferta.
3. **Não comprar continua sendo um bom resultado** quando o produto não serve para a pessoa. Uma recomendação honesta de "não compre se..." aumenta a confiança.

### 4.3 Pontes entre categorias

A transição natural depende de **pontes editoriais**, não de chamadas de venda:

| De | Para | Exemplo de ponte (do caso ilustrativo) |
|---|---|---|
| Descoberta | Conexão | "Esquecemos rápido, mas existe um jeito simples de evitar isso. Explico no vídeo completo." |
| Conexão | Comercial | "Se você prefere um método guiado em vez de montar o próprio, comparei as opções neste guia." |
| Comercial | Conexão | "Se nenhuma dessas opções serve para você, este guia gratuito mostra como fazer sozinho." |

Os mecanismos de distribuição de cada ponte (links, playlists, links internos) estão em `ACQUISITION_STRATEGY.md` seção 8.

---

## 5. Storytelling e retenção

### 5.1 Estrutura narrativa base **[Proposta]**

1. **Gancho honesto:** uma pergunta, um contraste ou um fato surpreendente que o conteúdo **de fato** responde.
2. **Tensão:** por que isso é intrigante ou importante.
3. **Desenvolvimento:** explicação clara, com exemplos e fontes.
4. **Recompensa:** a resposta prometida no gancho, sem enrolação.
5. **Ponte:** o próximo passo natural (seção 4.3).

### 5.2 Gancho sem clickbait

- **[Fato verificado]** O Google recomenda evitar *clickbait*, detalhes enganosos ou exagerados em títulos e imagens, e sensacionalismo que explore curiosidade mórbida ou indignação ([Google — Get on Discover](https://developers.google.com/search/docs/appearance/google-discover)).
- **Regra [Proposta]:** o título, a miniatura e os primeiros segundos prometem exatamente o que o conteúdo entrega. Promessa falsa gera abandono e destrói a confiança.

### 5.3 Retenção como medida de qualidade

- **[Fato verificado]** O YouTube Analytics mostra a retenção ao longo do vídeo, o percentual que continua assistindo após os primeiros 30 segundos ("intro") e os momentos de queda e de pico ([YouTube — Audience retention](https://support.google.com/youtube/answer/9314415)). Esses dados indicam onde o conteúdo perde ou prende a atenção.
- Quedas no início costumam indicar desalinhamento entre título ou miniatura e conteúdo. Quedas no meio indicam trechos lentos ou confusos.
- **Regra [Proposta]:** retenção é lida **junto** com a qualidade e o resultado comercial (seção 14), nunca sozinha.

### 5.4 Séries e recorrência

Séries temáticas (por exemplo, "mitos sobre memória") facilitam o retorno da audiência e criam pontes naturais. **Cuidado:** o YouTube permite séries com estrutura semelhante, desde que cada episódio tenha "história, foco ou conceito distintos"; conteúdo "intercambiável de vídeo para vídeo" não é monetizável ([YouTube — Monetization policies](https://support.google.com/youtubecreatorstudio/answer/1311392?hl=en)).

---

## 6. Integração contextual de produtos

### 6.1 Ordem de decisão **[Proposta]**

O produto **nunca** é o ponto de partida da pauta.

1. Existe uma necessidade real da audiência? (dados de `ACQUISITION_STRATEGY.md` seção 4)
2. O conteúdo resolve ou esclarece essa necessidade por si só?
3. Existe algum produto que ajude de forma concreta?
4. O produto tem dados verificados (preço, condições, conteúdo, garantia, data da coleta)?
5. Só então o produto entra no conteúdo, com divulgação.

### 6.2 Teste de relevância (obrigatório para conteúdo comercial) **[Proposta]**

O produto só entra se **todas** as respostas forem "sim":

| # | Pergunta |
|---|---|
| 1 | O conteúdo continua útil sem o link? |
| 2 | O produto se relaciona diretamente com o problema tratado? |
| 3 | As informações sobre o produto vêm de fonte verificável e estão datadas? |
| 4 | O conteúdo diz para quem o produto **não** serve? |
| 5 | Alternativas (inclusive gratuitas, quando existirem) foram mencionadas? |
| 6 | Nenhuma promessa vai além do que o produto e o criador conseguem cumprir? |
| 7 | A divulgação do vínculo de afiliado está clara e visível (seção 13)? |

### 6.3 Regras de apresentação

- **Reproduzir corretamente as condições do produto.** **[Fato verificado]** Pelos termos da Hotmart, o afiliado é responsável por reproduzir ao público todas as características e condições de venda do produto e responde **solidariamente** com o criador pelo cumprimento dessas condições ([Termos de Uso da Hotmart](https://hotmart.com/pt-br/legal/termos-de-uso)).
- **Sem promessas de resultado.** O manual da Hotmart desaconselha associar a compra a resultados imediatos que o produto não garante ([Hotmart — Manual de boas práticas](https://hotmart.com/pt-br/blog/melhores-praticas)). O Código de Defesa do Consumidor proíbe publicidade enganosa, inclusive por omissão de dado essencial ([CDC, art. 37](http://www.planalto.gov.br/ccivil_03/leis/l8078.htm)).
- **Sem uso de nomes de terceiros** (marcas, pessoas) para reforçar benefícios sem autorização ([Hotmart — Manual de boas práticas](https://hotmart.com/pt-br/blog/melhores-praticas)).
- **Sem sugerir vínculo com a Hotmart** nem com o criador do produto além do de afiliado ([Termos de Uso da Hotmart](https://hotmart.com/pt-br/legal/termos-de-uso)).
- **Preço e condições sempre datados** ("consultado em DD/MM/AAAA"), porque mudam.

### 6.4 Tipos de análise e como identificá-los

Este ponto é crítico para uma operação com marcas que não são pessoas reais (Ghost Commerce):

| Tipo | Quando usar | Como identificar ao público |
|---|---|---|
| **Teste próprio** | Só quando alguém da operação realmente usou o produto | "Testamos o produto por X dias. Veja como foi o teste." Com evidências (capturas, registros) |
| **Análise documental** | Quando a análise se baseia em informações públicas (página do produto, ementa, condições, políticas) | "Esta análise se baseia nas informações públicas do produto, consultadas em DD/MM/AAAA. Não testamos o produto." |
| **Comparativo de critérios** | Quando compara opções por critérios objetivos | Mostrar critérios, fontes e data da coleta |

- **[Fato verificado]** O Google recomenda que avaliações tragam evidências da experiência própria e expliquem prós e contras com base em pesquisa original ([Google — Write high quality reviews](https://developers.google.com/search/docs/specialty/ecommerce/write-high-quality-reviews)). Uma análise documental bem feita é útil, mas **não pode se apresentar como teste**.
- **[Fato verificado]** O guia da FTC (EUA) afirma que não se pode falar da experiência com um produto que não foi testado ([FTC — Disclosures 101](https://www.ftc.gov/business-guidance/resources/disclosures-101-social-media-influencers)). Relevante para a futura expansão internacional.
- **[Hipótese]** A falta de experiência própria pode limitar o desempenho de conteúdo comercial em buscadores. Mitigação possível: testar de fato alguns produtos, com custo aprovado individualmente pelo responsável (gasto fica fora das políticas de aprovação enquanto não houver decisão em contrário, `AUTONOMY_AND_AGENTS.md` seção 3).

---

## 7. Estratégia de vídeos curtos e longos

### 7.1 Papéis **[Proposta]**

| Formato | Papel principal | Categoria predominante | Produto |
|---|---|---|---|
| Vídeo curto | Descoberta e alcance | Descoberta | Não. No máximo uma ponte para conteúdo completo |
| Vídeo longo | Conexão e confiança | Conexão; comercial ocasional | Somente em peças comerciais que passem no teste da seção 6.2 |

**[Fato verificado]** No YouTube, URLs em descrições e comentários de Shorts **não são clicáveis**. Links em descrições de vídeos longos são clicáveis para canais com recursos avançados, e o Shorts pode apontar para um vídeo relacionado do próprio canal ([YouTube — Sharing links](https://www.support.google.com/youtube/answer/13748639)). Isso reforça o papel do vídeo curto como descoberta, não como venda.

**[Fato verificado]** Links clicáveis na descrição de vídeos longos e o recurso de vídeo relacionado nos Shorts exigem acesso aos **recursos avançados** do canal. Esse acesso requer verificação por telefone e histórico suficiente do canal ou verificação por documento ou vídeo, e a verificação por documento ou vídeo não está disponível para todos os criadores ([YouTube — Feature access](https://support.google.com/youtube/answer/9890437?hl=en); [YouTube — Add a related video](https://support.google.com/youtube/answer/14075157?hl=en)). Consequência: um canal novo pode passar um período inicial **sem** links clicáveis. Nesse período, o conteúdo comercial em vídeo não converte diretamente, e o foco natural é descoberta e conexão.

### 7.2 Vídeos curtos

- Uma ideia por vídeo, com gancho nos primeiros segundos e recompensa clara.
- Cada vídeo curto aponta para um vídeo longo, um artigo ou uma série (detalhes de distribuição em `ACQUISITION_STRATEGY.md` seção 5). O link de vídeo relacionado depende dos recursos avançados (seção 7.1).
- Variar a substância de cada vídeo: modelos visuais podem se repetir, o conteúdo não (seção 5.4).

### 7.3 Vídeos longos

- Estrutura em capítulos, com resposta à pergunta principal sem enrolação.
- Em peças comerciais, a divulgação aparece **no próprio vídeo**, não só na descrição (seção 13).
- Fontes citadas na descrição.

### 7.4 Produção de marca sem rosto (Ghost Commerce)

- Formatos viáveis sem apresentador: narração com recursos visuais, animação explicativa, tela com demonstração, infográfico animado.
- **[Fato verificado]** O YouTube exige divulgar conteúdo gerado ou alterado por IA que pareça realista: uma pessoa real dizendo algo que não disse, cenas realistas que não aconteceram, imagens alteradas de eventos reais. Conteúdo claramente não realista e edições menores não exigem divulgação ([YouTube — Disclosing GenAI content](https://support.google.com/youtube/answer/14328491?hl=en)).
- **[Fato verificado]** O TikTok exige rotular conteúdo inteiramente gerado ou significativamente editado por IA, incluindo vozes e rostos sintéticos ([TikTok — Creator Trust Guide](https://ads.tiktok.com/business/library/Creator_Trust_Guide_Responsible_Media.pdf)).
- **Regra [Proposta]:** na dúvida, divulgar o uso de IA. Narrações com voz sintética: **[A verificar]** o enquadramento em cada plataforma antes de adotar.
- O guia do CONAR de 2026 também trata de avatares e conteúdo produzido com IA na publicidade ([CONAR](https://www.conar.org.br/noticias/guia-de-marketing-e-publicidade-por-influenciadores-digitais)).

---

## 8. Reaproveitamento de conteúdo

### 8.1 Modelo "peça-mãe" **[Proposta]**

Cada ciclo de produção parte de **uma peça-mãe** bem pesquisada (vídeo longo ou artigo aprofundado). Dela derivam versões menores.

```
             Pesquisa e dossiê de fontes (seção 9)
                           |
                     PEÇA-MÃE (conexão)
             vídeo longo  ou  artigo/guia aprofundado
                           |
     +-----------+---------+---------+-----------+
     |           |                   |           |
 vídeos curtos  artigo ou     conteúdo visual   e-mail
 (descoberta)   roteiro       (carrossel,       (lista
                derivado      infográfico)      própria)
```

### 8.2 Regras de qualidade das derivadas

1. **Cada derivada funciona sozinha.** Um corte de vídeo longo precisa de gancho e recompensa próprios.
2. **Adaptar ao formato, não só recortar.** Texto lido em voz alta não é roteiro de vídeo, e transcrição não é artigo.
3. **Não duplicar conteúdo no site.** Versões de texto quase idênticas da mesma peça não agregam valor e se aproximam do conteúdo em escala que o Google desaconselha.
4. **Derivadas comerciais seguem as regras comerciais** (seções 6 e 13), mesmo quando derivam de uma peça de conexão.

### 8.3 Matriz de derivação

| Peça-mãe | Derivadas possíveis | Atenção |
|---|---|---|
| Vídeo longo de conexão | 2 a 4 vídeos curtos de descoberta; artigo; conteúdo visual | Cada curto com gancho próprio |
| Artigo-guia | Roteiro de vídeo longo; carrossel; e-mail | Reescrever para o formato |
| Comparativo comercial | Vídeo longo comercial; e-mail para quem se inscreveu no tema | Divulgação em cada formato |

### 8.4 Capacidade sustentável de produção **[Hipótese]**

A quantidade de peças que uma pessoa consegue produzir com qualidade, sem queda de rigor, é **desconhecida**. Regras até existir dado real:

1. **Registrar o tempo humano por peça** (pesquisa, roteiro ou texto, produção, revisão, publicação). Esse registro alimenta a métrica de eficiência de `ACQUISITION_STRATEGY.md` seção 12.2.
2. **A cadência é definida pela capacidade de revisão**, não pelo que a plataforma "recompensaria". Se a revisão humana não acompanha, o volume diminui.
3. **Começar com um ciclo pequeno e repetível**: por exemplo, uma peça-mãe e poucas derivadas por ciclo. Os números concretos ficam **[A definir]** após as primeiras semanas de registro.
4. **Sinais de cadência insustentável:** checklist da seção 12.1 pulado, aumento de correções, fontes ausentes no dossiê.
5. **Automação como objetivo [Acordado — L2]:** a produção manual é uma solução temporária de validação. O objetivo é que pesquisa, produção, adaptação e publicação sejam automatizadas, e que o tempo humano registrado se concentre em supervisão, revisão e aprovação. A automação nunca dispensa o checklist da seção 12.1 nem as regras de transparência e de uso de IA (seções 12.2 e 13).

### 8.5 Ferramentas

Ferramentas específicas **não são requisito** nesta fase. O critério de escolha futura será: gratuita ou de código aberto, sem prender a operação a um fornecedor, e com custo aprovado se houver (`ARCHITECTURE.md` seção 1).

---

## 9. Pesquisa e verificação de informações

### 9.1 Hierarquia de fontes **[Proposta]**

| Nível | Tipo de fonte | Uso |
|---|---|---|
| 1 | Artigos científicos revisados por pares, órgãos oficiais, documentação oficial | Base para afirmações factuais |
| 2 | Instituições reconhecidas, livros técnicos, imprensa de referência | Contexto e confirmação |
| 3 | Divulgação científica de qualidade | Inspiração; confirmar no nível 1 ou 2 |
| 4 | Blogs, redes sociais, fóruns | Só para entender perguntas da audiência, nunca como prova |

### 9.2 Dossiê de fontes por peça

Cada peça tem um **dossiê**: a lista das afirmações factuais, a fonte de cada uma e a data da consulta.

- **[Fato verificado]** O CDC determina que o fornecedor mantenha "os dados fáticos, técnicos e científicos" que sustentam a mensagem publicitária ([CDC, art. 36, parágrafo único](http://www.planalto.gov.br/ccivil_03/leis/l8078.htm)). O dossiê cumpre essa função para o conteúdo comercial e é uma boa prática para os demais.
- O dossiê se conecta ao princípio "dados reais ou dados de teste identificados" (`ARCHITECTURE.md` seção 1, item 7).

### 9.3 Regras de verificação

1. Curiosidades "surpreendentes" exigem verificação **reforçada**, porque costumam circular distorcidas.
2. Números são citados com fonte, data e contexto.
3. Quando a ciência não tem consenso, o conteúdo diz isso.
4. Conteúdo gerado ou resumido por IA é sempre conferido por uma pessoa nas fontes originais. **[Fato verificado]** O Google recomenda verificar manualmente fatos de todo conteúdo gerado por IA antes de publicar ([Google — Generative AI content](https://developers.google.com/search/docs/fundamentals/using-gen-ai-content)).

### 9.4 Política de correções

Erros encontrados depois da publicação são corrigidos de forma visível, com nota de correção e data. Isso vale para todos os formatos que permitem edição.

---

## 10. SEO e conteúdo evergreen

### 10.1 Princípios **[Proposta]**

- **SEO a serviço de conteúdo útil**, nunca o contrário. **[Fato verificado]** O Google orienta criar conteúdo *people-first*, e não conteúdo feito para manipular rankings ([Google — Creating helpful content](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)).
- **Conteúdo não-commodity:** o Google diferencia conteúdo "de conhecimento comum, que qualquer um poderia escrever" de conteúdo com perspectiva ou experiência única ([Google — AI optimization guide](https://developers.google.com/search/docs/fundamentals/ai-optimization-guide/)). A estratégia busca o segundo tipo: ângulo próprio, síntese bem fundamentada, exemplos originais.
- **Usar as palavras que as pessoas usam** em títulos, cabeçalhos e textos de link ([Google Search Essentials](https://developers.google.com/search/docs/essentials)).

### 10.2 Organização por clusters

Cada pilar vira um **cluster** no site:

- Uma página-pilar (guia completo do tema).
- Páginas de conexão que aprofundam subtemas.
- Páginas comerciais ligadas às necessidades do cluster.
- Links internos entre elas, para facilitar a navegação da pessoa e a descoberta pelo buscador.

### 10.3 Evergreen e atualização

- Prioridade para temas que continuam úteis por muito tempo.
- Revisão periódica de páginas importantes, principalmente as comerciais (preços e condições mudam).
- **[Fato verificado]** O Google lista como sinal de alerta mudar a data de páginas para parecerem recentes sem alterar o conteúdo ([Google — Creating helpful content](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)). **Regra:** só atualizar a data quando houver atualização real.

### 10.4 Links de afiliado e SEO

- **[Fato verificado]** O Google pede que links de afiliado sejam qualificados com `rel="sponsored"` (ou `nofollow`), e pode aplicar ações manuais ou algorítmicas a sites que não fazem isso ([Google — Link tagging and link spam update](https://developers.google.com/search/blog/2021/07/link-tagging-and-link-spam-update)).
- **[Fato verificado]** Usar links de afiliado numa página, "com os links tratados de forma apropriada", é citado pelo Google como prática que não viola a política ([Google — Spam policies](https://developers.google.com/search/docs/essentials/spam-policies)).
- A implementação técnica (atributo nos links publicados) é assunto de arquitetura; aqui fica a regra editorial.

---

## 11. Identidade e diferenciação das marcas

### 11.1 Guia da marca **[Proposta]**

Cada marca terá um guia próprio, de uma ou duas páginas:

| Seção | Conteúdo |
|---|---|
| Propósito | Por que a marca existe para a audiência |
| Audiência | Quem é, o que busca, o que não busca (hipóteses, depois dados) |
| Pilares | Seção 2 |
| Tom de voz | Por exemplo: curioso, claro, sem exageros |
| Identidade visual | Cores, tipografia, estilo de imagens e vídeos |
| Limites | Temas, produtos e abordagens que a marca não usa |
| Política comercial | Tipos de produto aceitos e recusados |
| Transparência | Quem opera a marca, como divulga o vínculo de afiliado e o uso de IA |

### 11.2 Independência sem esconder quem opera

- **[Acordado]** As marcas são independentes e compartilham infraestrutura (`PROJECT_VISION.md` seção 5).
- **[Acordado]** Independência não autoriza ocultar quem opera quando lei ou plataforma exigirem identificação (`PROJECT_VISION.md` seção 5).
- **[Fato verificado]** O Google cita "criar vários sites com a intenção de esconder a natureza em escala do conteúdo" como abuso ([Google — Spam policies](https://developers.google.com/search/docs/essentials/spam-policies)).
- **Regra [Proposta]:** uma nova marca só existe se tiver audiência, pilares e proposta **genuinamente diferentes**. Não criar marcas para replicar o mesmo conteúdo em mais lugares.

### 11.3 Diferenciação

Cada marca precisa responder: "por que alguém acompanharia esta marca e não outra sobre o mesmo tema?". Possíveis fontes de diferença: ângulo editorial, profundidade, formato, recorte de audiência, qualidade visual, rigor nas fontes.

---

## 12. Qualidade editorial e originalidade

### 12.1 Checklist antes da aprovação **[Proposta]**

| # | Critério |
|---|---|
| 1 | A peça pertence a um pilar e tem um objetivo de categoria claro |
| 2 | O gancho é honesto e o conteúdo entrega o que promete |
| 3 | As afirmações factuais estão no dossiê, com fontes |
| 4 | A peça traz algo além de um resumo do que já existe |
| 5 | Texto, áudio e imagens são originais ou licenciados (`PROJECT_VISION.md` seção 8) |
| 6 | Uso de IA revisado por uma pessoa e divulgado quando exigido |
| 7 | Se for comercial: passou no teste de relevância (6.2) e tem divulgação (13) |
| 8 | Linguagem clara, sem erros, adequada ao tom da marca |
| 9 | Próximo passo (ponte) definido |

**[Decisão conceitual — 12/11/2026]** Este checklist integra as verificações obrigatórias de `AUTONOMY_AND_AGENTS.md` seção 4.5. As regras de verificação são versionadas: ficam registradas a versão usada na aprovação e a usada imediatamente antes do envio. Uma falha bloqueia o envio; não há exceção, e a aprovação do responsável não serve para contornar uma falha de conformidade.

### 12.2 Política de uso de IA

- IA pode apoiar a pesquisa, a estrutura, o rascunho, a revisão e a produção visual.
- Toda peça passa pelo checklist da seção 12.1 antes da publicação. **Na fase inicial, cada envio, público ou privado, exige autorização humana individual da versão exata pelo responsável**; nesta fase, políticas não substituem essa autorização (`AUTONOMY_AND_AGENTS.md` seção 4.2). Publicação pública só na Fase B, depois de autorização explícita (`ARCHITECTURE.md` seções 4.6 e 4.7).
- IA nunca inventa experiência, depoimento ou dado.
- Divulgação de IA conforme cada plataforma (seção 7.4).

### 12.3 Direitos autorais

Imagens, músicas, trechos de vídeo e textos de terceiros só com licença ou permissão. **[Fato verificado]** O YouTube trata como "conteúdo reutilizado" o material de terceiros sem comentário ou transformação significativa, o que pode impedir a monetização ([YouTube — Reused content FAQ](https://support.google.com/youtube/community-guide/271248162/faq-reused-content-youtube%E2%80%99s-partner-program?hl=en)).

---

## 13. Transparência na divulgação de links de afiliado

### 13.1 Base legal e de autorregulação (Brasil)

- **[Fato verificado]** O CDC exige que a publicidade seja identificável "fácil e imediatamente" pelo consumidor ([CDC, art. 36](http://www.planalto.gov.br/ccivil_03/leis/l8078.htm)).
- **[Fato verificado]** O novo Guia do CONAR para influenciadores (publicado em maio de 2026, com efeitos a partir de 1º de junho de 2026) amplia o conceito de publicidade. Segundo análises jurídicas, remuneração por desempenho, como comissão de afiliado, caracteriza publicidade, e a identificação deve ser ostensiva, visível em primeiro plano, sem depender de "ver mais" ([CONAR](https://www.conar.org.br/noticias/guia-de-marketing-e-publicidade-por-influenciadores-digitais); [TozziniFreire](https://tozzinifreire.com.br/publicacoes/boletins/novo-guia-do-conar-o-que-muda-para-campanhas-com-influenciadores-digitais/); [Migalhas](https://www.migalhas.com.br/depeso/456195/campanha-segura-comeca-antes-do-post-o-novo-guia-do-conar); [Legal500](https://www.legal500.com/intelligence/brazil/media-telecoms-it-entertainment/conar-atualiza-guia-de-publicidade-com-influenciadores)).
- **[Fato verificado]** O guia recomenda usar as ferramentas nativas das plataformas para identificar conteúdo pago ([Legal500](https://www.legal500.com/intelligence/brazil/media-telecoms-it-entertainment/conar-atualiza-guia-de-publicidade-com-influenciadores)).
- **[A verificar com profissional qualificado]** O enquadramento de marcas sem rosto (perfis de marca, não de pessoa) no guia do CONAR. O guia menciona perfis virtuais e avatares, mas a aplicação concreta deve ser confirmada. Este documento não é aconselhamento jurídico.

### 13.2 Regras de divulgação **[Proposta]**

1. **Clara:** linguagem simples que diga que há ganho de comissão. Exemplo: "Se você comprar por este link, recebemos uma comissão, sem custo extra para você." **[Fato verificado]** A FTC considera que "link de afiliado" sozinho ou um botão "compre agora" podem não ser compreendidos como divulgação ([FTC — Endorsement Guides FAQ](https://www.ftc.gov/business-guidance/resources/ftcs-endorsement-guides-what-people-are-asking)).
2. **Próxima:** perto da recomendação e do link, não só no rodapé ou na página "Sobre".
3. **Visível:** antes de qualquer "ver mais"; em vídeo, falada ou escrita **no próprio vídeo**, além da descrição.
4. **No idioma da peça.**
5. **Ferramentas nativas mais divulgação própria:** usar o recurso da plataforma **e** a frase de divulgação.
6. **Bloqueio [Decisão conceitual — 12/11/2026]:** quando a divulgação for obrigatória, sua ausência, incompletude ou posição inadequada bloqueia o envio. Um campo de divulgação vazio não dispensa a verificação (`AUTONOMY_AND_AGENTS.md` seção 4.5, item 11).

### 13.3 Aplicação por formato

| Formato | Divulgação |
|---|---|
| Artigo no site | Aviso no início da página e junto a cada link ou bloco de links; política de afiliados acessível; links com `rel="sponsored"` (seção 10.4) |
| Vídeo longo no YouTube | Aviso falado ou na tela no momento da recomendação; frase na descrição junto ao link. **[A verificar]** Se o recurso "contém promoção paga" se aplica a links de afiliado sem acordo direto com o criador do produto. A política de conteúdo de marca do YouTube cita relações "em troca de algo de valor" ([YouTube — Branded content policies](https://support.google.com/youtube/answer/17596007?hl=en)) |
| Instagram | **[Fato verificado]** O Instagram indica que conteúdo com link de afiliado deve usar o rótulo "Parceria paga", sem precisar marcar um parceiro ([Instagram — About branded content](https://help.instagram.com/616901995832907/)) |
| TikTok | **[Fato verificado]** Conteúdo que promove marca, produto ou serviço exige ativar a divulgação de conteúdo comercial ([TikTok — Commercial content disclosure](https://ads.tiktok.com/resources/help/article/how-to-turn-on-the-commercial-content-disclosure-setting-in-tiktok)) |
| E-mail | Aviso junto a cada recomendação com link |
| Mercados internacionais (futuro) | Seguir a regra local. Nos EUA, ver o guia da FTC, que pede a divulgação no vídeo e perto do link ([FTC — Endorsement Guides FAQ](https://www.ftc.gov/business-guidance/resources/ftcs-endorsement-guides-what-people-are-asking)) |

### 13.4 Divulgação de IA

Ver seção 7.4. A divulgação de IA é independente da divulgação comercial; uma não substitui a outra.

---

## 14. Métricas de qualidade e desempenho

### 14.1 Princípio **[Acordado]**

Visualizações não são resultado comercial. Prioridade para retenção, engajamento, cliques qualificados e conversões.

### 14.2 Métricas de qualidade do conteúdo (este documento)

| Métrica | O que indica | Categoria |
|---|---|---|
| Retenção e retenção nos primeiros 30 s | Se o gancho e o desenvolvimento prendem | Vídeo, todas |
| Visualizações engajadas e "ficou para assistir" (Shorts) | Se o curto foi assistido ou pulado | Descoberta |
| Duração média de exibição; percentual médio assistido | Profundidade do interesse | Conexão |
| Compartilhamentos e salvamentos | Valor percebido | Descoberta e conexão |
| Comentários com perguntas ou relatos | Relevância e novas pautas | Todas |
| Visitas à peça de conexão a partir da descoberta | Se a ponte funciona | Descoberta |
| Retorno da audiência (espectadores e leitores recorrentes) | Construção de relacionamento | Conexão |
| Taxa de correções e reclamações | Qualidade factual | Todas |
| Proporção de peças aprovadas na primeira revisão | Qualidade do processo | Todas |

Definições oficiais das métricas do YouTube: [YouTube — Content performance](https://support.google.com/youtube/answer/12220281?hl=en-IN).

### 14.3 Métricas comerciais do conteúdo

As métricas financeiras seguem as três dimensões definidas em `ACQUISITION_STRATEGY.md` seção 12 (resultado financeiro realizado, eficiência operacional e indicadores auxiliares). Este documento não cria definições próprias para evitar divergência.

- **No nível da peça**, só existem métricas de conteúdo (fatos) e atribuição comercial (estimativa): cliques qualificados e vendas, reembolsos e cancelamentos associados à peça. Ver a tabela de granularidade em `ACQUISITION_STRATEGY.md` seção 12.4.
- **A atribuição de vendas a peças é uma capacidade em investigação** (`ACQUISITION_STRATEGY.md` seção 11). Até ser validada, nenhuma peça é declarada "lucrativa" ou "não lucrativa" com base em atribuição.
- **O resultado financeiro realizado é medido por marca e por período**, não por peça. Nenhuma receita atribuída a uma peça é apresentada como resultado confirmado.
- **Peças em exploração não precisam demonstrar venda**, e bons indicadores de atenção não provam viabilidade comercial (`ACQUISITION_STRATEGY.md` seção 13.2).

### 14.4 Regras de leitura **[Proposta]**

1. Cada categoria tem metas diferentes: comparar descoberta com comercial pelo mesmo indicador é um erro.
2. Nenhuma meta numérica é fixada aqui. Metas serão definidas pelo responsável e registradas com data (`PROJECT_VISION.md` seção 7).
3. Dados de teste sempre separados (`is_test`, `ARCHITECTURE.md` seção 4.3).
4. O tempo humano por peça (seção 8.4) é registrado junto com as métricas, porque faz parte do custo operacional.

---

## 15. Possibilidades futuras de automação e IA

Tudo nesta seção é **possibilidade futura**, não requisito. A automação segue os níveis de autorização de `PROJECT_VISION.md` seção 6.

**Atualização de 04/11/2026 (L2):** a automação operacional passou a ser **objetivo acordado** do projeto (`PROJECT_VISION.md` seção 1). As atividades abaixo continuam **não implementadas**; a ordem e o momento de cada uma seguem a sequência de lotes registrada em `PROJECT_STATUS.md` (o `PRODUCT_ROADMAP.md` antes citado nunca foi criado), e os agentes e níveis de autonomia, `AUTONOMY_AND_AGENTS.md`.

| Atividade | Nível sugerido | Situação |
|---|---|---|
| Coleta de perguntas da audiência a partir de dados de canais próprios | 1 (somente leitura) | Futuro |
| Briefing por modelo (palavras-chave, fatos do banco, estrutura, aviso de afiliado) | 2 | Previsto em `ARCHITECTURE.md` seção 4.6 (Jinja2) |
| Rascunho de roteiro ou artigo com IA | 2 | Futuro. Hoje: `NullProvider`, sem IA por API (`ARCHITECTURE.md` seção 4.6) |
| Checagem automática do checklist (fontes ausentes, falta de divulgação) | 2 | Futuro |
| Sugestão de derivadas a partir da peça-mãe | 2 | Futuro |
| Envio ou publicação de qualquer peça, em modo público ou privado | 3 na fase inicial (autorização humana individual da versão exata). Conteúdo editorial comum poderá futuramente operar por política, por decisão expressa do proprietário (`AUTONOMY_AND_AGENTS.md` seções 4.2 a 4.4) | Regra da fase inicial, não limitação definitiva da arquitetura; painel móvel e registro auditável. Não implementado |
| Decisão de nicho, marca, produto ou oferta | 0 (decisão do proprietário) | Requisito de governança comercial; não automatizar a decisão final |
| Upload privado/não público dentro de fluxo de teste | 3 no MVP (autorização individual vinculada ao hash, com a visibilidade exata no manifesto). 4 somente no futuro, se uma política específica for ativada | Automação por política adiada em 12/11/2026 (`AUTONOMY_AND_AGENTS.md` seção 4); sujeito a teste e limites |

Políticas podem autorizar tarefas internas, pesquisa e rascunhos. Na fase inicial, não substituem a autorização individual de nenhum envio, público ou privado. Temas sensíveis, alterações materiais e decisões de nicho, marca, produto e oferta permanecem sempre com o proprietário, mesmo que uma política venha a ser ativada (`AUTONOMY_AND_AGENTS.md` seção 4.4).

**Limites permanentes [Proposta]:**

- Nenhuma automação aumenta o volume além da capacidade de revisão humana com qualidade.
- **[Fato verificado]** Os termos da Hotmart proíbem coletar ou usar informações extraídas da plataforma para treinar modelos de IA e usar sistemas automatizados de forma contrária aos termos ([Termos de Uso da Hotmart](https://hotmart.com/pt-br/legal/termos-de-uso)). Qualquer automação que use dados da Hotmart precisa ser revisada contra os termos antes de existir.
- Toda IA por API exige orçamento aprovado e limite de gasto (`ARCHITECTURE.md` seção 4.6).
- Nenhuma automação coleta ou processa dados pessoais sem cumprir os princípios de privacidade de `ACQUISITION_STRATEGY.md` seção 16.
- Automação não reduz nenhuma exigência deste documento: checklist de relevância, dossiê de fontes, divulgação e revisão humana continuam obrigatórios.

---


### 15.1 Controle de qualidade factual e uso de IA **[Proposta]**

- Cada afirmacao factual relevante deve ter fonte identificavel, data de consulta e trecho/evidencia que a sustenta. Registrar se a peca e uma explicacao documental, uma analise comparativa ou um teste proprio.
- Nao afirmar que a marca testou, usou ou comprovou um produto quando a avaliacao foi feita apenas com base em documentacao, especificacoes ou relatos de terceiros.
- IA pode apoiar pesquisa, estrutura, roteiro e variacoes, mas nao substitui verificacao de fontes, julgamento editorial nem contribuicao original. Evitar producao em massa de pecas repetitivas, superficiais ou sem valor adicional.
- Conteudo sintetico ou alterado de forma realista deve receber a divulgacao exigida pela plataforma quando aplicavel. Isso nao significa que todo uso de IA precise da mesma rotulagem; verificar a regra especifica para o caso.
- A autorização é vinculada ao hash exato da versão da peça. Qualquer mudança, inclusive de formatação ou ortografia, gera nova versão e exige nova verificação e nova aprovação individual; no MVP não há herança entre versões (`AUTONOMY_AND_AGENTS.md` seção 4.6). Preço, oferta, disponibilidade, garantia e prazos citados são conferidos de novo para a data de publicação; dado vencido, não verificável ou alterado bloqueia o envio (seção 4.5 do mesmo documento).

### 15.2 Integridade comercial e limites de alegacoes **[Proposta]**

- Conteudo de descoberta pode priorizar alcance, mas a estrategia precisa medir se atrai audiencia que tambem demonstra interesse nos temas de conexao e nas necessidades que os produtos atendem.
- A transicao para recomendacao comercial deve explicar a necessidade, os criterios de escolha e a pertinencia do produto; nao inserir produto apenas para monetizar um tema sem relacao.
- Comparativos devem declarar criterios, limitacoes, data das informacoes e se houve teste proprio. Nao inventar notas, depoimentos, experiencia ou resultados.
- Em temas de saude, financas ou seguranca, exigir fontes de maior autoridade, linguagem proporcional a evidencia e revisao reforcada; evitar diagnosticos, promessas de resultado ou recomendacoes que extrapolem a competencia editorial.

## 16. Decisões pendentes e hipóteses abertas

| # | Item | Tipo | Responsável ou fonte |
|---|---|---|---|
| 1 | Nicho e pilares da primeira marca | Decisão | Responsável pelo projeto |
| 2 | Formato da primeira peça-mãe: vídeo longo, já que o YouTube foi aprovado como canal inicial prioritário em 04/11/2026 (L2; `ACQUISITION_STRATEGY.md` seção 3.2) | Decisão | Responsável pelo projeto |
| 3 | Uso de narração com voz sintética e como divulgá-la | Decisão após verificação | Políticas de IA do YouTube e do TikTok, verificadas em 04/11/2026 (seção 7.4); reconferir antes de adotar |
| 4 | Testar produtos de fato (custo com aprovação individual) ou trabalhar só com análise documental no início | Decisão | Responsável pelo projeto |
| 5 | Enquadramento de marcas sem rosto no guia do CONAR | Verificação externa | Profissional qualificado; guia do CONAR de 2026 |
| 6 | Uso do recurso de "promoção paga" do YouTube para links de afiliado | Verificação externa | Política de conteúdo de marca do YouTube, consultada em 04/11/2026, sem resposta conclusiva |
| 7 | Proporção entre descoberta, conexão e conteúdo comercial | Hipótese | Dados próprios após a Fase B começar |
| 8 | Capacidade sustentável de produção (seção 8.4) | Hipótese | Registro de tempo humano |
| 9 | Desempenho de análises documentais (sem teste próprio) em buscadores | Hipótese | Dados próprios |
| 10 | Aprovação formal deste documento | Decisão | Responsável pelo projeto |

---


## 16.1 Ecossistema editorial e formatos de destino **[Acordado como visão]**

A estratégia editorial não se limita a vídeos do YouTube. O sistema deverá preparar um acervo reutilizável de pesquisa e conteúdo que possa originar formatos diferentes, adaptados a cada canal:

- **Vídeo longo:** peça aprofundada, com narrativa, fontes verificáveis e edição de qualidade.
- **Conteúdo curto:** cortes ou peças derivadas, reeditadas e contextualizadas para Shorts, Reels, TikTok e formatos equivalentes quando esses canais forem ativados.
- **Artigo ou guia:** pesquisa aprofundada em texto, reescrita para leitura e busca orgânica; não publicar mera transcrição automática do vídeo.
- **Materiais auxiliares:** comparativos, tabelas, páginas de referência e atualizações, quando acrescentarem valor real.

A peça-mãe é uma fonte de pesquisa e narrativa, não um molde para replicação mecânica. Cada derivação deve ter propósito editorial, contexto e adequação à plataforma. Conteúdo curto não deve ser publicado apenas para cumprir uma quota.

## 16.2 Cadência inicial de produção **[Hipótese de planejamento]**

Como ponto de partida para estimar capacidade, considerar:
- aproximadamente um vídeo longo a cada duas semanas;
- cerca de 4 a 8 cortes derivados por ciclo quinzenal, somente se houver trechos realmente úteis;
- um artigo aprofundado relacionado quando a pesquisa permitir produzir uma versão escrita original e útil.

Esta é a referência inicial da **primeira marca**. Não existe frequência universal: cada marca e canal define a sua conforme identidade, público, mercado, canal e desempenho (seção 16.6).

A cadência não é compromisso fixo, meta algorítmica nem obrigação de volume. O responsável poderá reduzir, aumentar ou suspender formatos conforme qualidade, tempo, capacidade de revisão, custo, desempenho e sustentabilidade. Não publicar material fraco apenas para manter frequência.

## 16.3 Aprovação editorial individual (regra da fase inicial) **[Acordado; Decisão conceitual — 12/11/2026]**

Na fase inicial, antes de qualquer envio, público ou privado, o proprietário deverá aprovar no painel móvel a versão exata do material. É regra desta fase, não limitação definitiva: o conteúdo editorial comum poderá futuramente operar por política, por decisão expressa do proprietário (`AUTONOMY_AND_AGENTS.md` seções 4.2 e 4.3). A revisão deve permitir consultar, conforme o formato:
- roteiro ou texto integral;
- título, descrição, thumbnail/capa e demais metadados;
- fontes e alegações factuais relevantes;
- produto, oferta e link de afiliado;
- divulgação clara da relação comercial;
- formato/canal de destino e configuração de visibilidade;
- legendas e elementos visuais incorporados;
- destino comercial verificado de cada link, condições comerciais confirmadas e fim de cada oferta citada;
- vencimento da autorização, apresentado separadamente do fim da oferta.

A seleção de nichos, produtos e ofertas comerciais também deve ser apresentada ao proprietário para decisão antes de orientar uma campanha ou peça comercial. O sistema pode pesquisar, comparar, pontuar e recomendar, mas não transforma uma recomendação em decisão comercial automaticamente.

A aprovação fica associada ao hash exato da versão e às evidências analisadas (links, destinos e ofertas). Qualquer alteração gera nova versão e exige nova aprovação; no MVP não há herança de autorização entre versões (`AUTONOMY_AND_AGENTS.md` seção 4.6). Temas sensíveis e alterações materiais de preço, oferta, promessa comercial, links, divulgação ou mídia exigem sempre aprovação individual (seção 4.4 do mesmo documento). Na fase inicial, uma aprovação genérica de política não substitui a aprovação individual de cada envio.

## 16.4 Blog/site próprio e SEO **[Acordado como destino; execução faseada]**

O blog/site próprio é um ativo previsto na visão do negócio, não uma alternativa descartada. Seu papel inclui:
- publicar artigos de pesquisa documentada, guias e comparativos originais;
- captar tráfego orgânico de buscas informacionais e comerciais;
- oferecer contexto e divulgação transparente de links de afiliado;
- construir ativos próprios de conteúdo e, futuramente, audiência, respeitando privacidade e consentimento.

A entrada operacional do site ocorrerá em fase própria, após avaliação de hospedagem, domínio, manutenção, segurança, privacidade, SEO e capacidade editorial. Preparar a arquitetura para WordPress ou outra solução compatível não significa contratar serviço ou ativar o site agora.

## 16.5 Monetização e integridade editorial

A monetização pode combinar comissões de afiliados com receitas diretas de plataformas (por exemplo, programas de anúncios ou criadores), quando houver elegibilidade e autorização. A existência de monetização não deve degradar a independência editorial nem justificar recomendações inadequadas.

A divulgação de afiliados deve ser clara e próxima do link/recomendação. Receitas de anúncios, fundos de criadores, comissões confirmadas e dinheiro recebido devem permanecer em categorias e indicadores distintos, conforme a origem e o estado real do pagamento.

## 16.6 Estratégias de publicação por tipo de marca **[Acordado como princípio — 08/11/2026; referências são hipóteses]**

O projeto administrará várias marcas independentes, cada uma com identidade, posicionamento, público, nicho, personalidade, reputação, histórico, estratégia editorial e comercial e mercados prioritários próprios (seção 11.1). O objetivo são marcas que construam audiência, credibilidade e presença comercial, **não uma fazenda de canais genéricos** que publica conteúdo padronizado diariamente.

| Tipo de marca | Foco | Referência de frequência **[Hipótese]** |
|---|---|---|
| Descoberta, autoridade e compra sutil | Educação, curiosidade, descoberta, confiança e construção de audiência | Um vídeo longo por semana e dois Shorts durante a semana |
| Pesquisa e intenção de compra | Guias de compra, comparações, avaliações documentais, páginas de produtos e categorias, informações comerciais | Publicações, atualizações e páginas comerciais diárias **quando houver demanda e utilidade** |
| Híbrida | Combinação das duas | Definida por marca |

- As referências servem para estimar capacidade; não são metas nem obrigações. A primeira marca parte da referência da seção 16.2 até decisão do proprietário.
- Não publicar apenas para preencher calendário. Qualidade, capacidade de revisão (aprovação individual, seção 16.3) e desempenho medido prevalecem sobre a frequência.

## 16.7 Funil editorial **[Proposta]**

O funil detalha as três categorias da seção 3, sem substituí-las:

| Etapa | Conteúdo | Categoria (seção 3) |
|---|---|---|
| 1. Descoberta | Ciência, educação, curiosidades e temas de interesse | Descoberta |
| 2. Construção de autoridade | Aprofundamento, explicações e contexto | Conexão |
| 3. Identificação de necessidades | Problemas e oportunidades | Conexão |
| 4. Orientação | Guias e comparações | Conexão ou comercial contextual |
| 5. Comercial | Recomendações e ofertas, quando pertinentes | Comercial contextual |

- Conteúdo sem link comercial é **normal**, não exceção (seção 3.4).
- Não inventar testes pessoais ou experiências que não aconteceram. Sem teste próprio, apresentar análise documental com fontes e limitações explícitas (seção 6.4).
- Transparência sobre relações comerciais e afiliações em todas as marcas (seção 13).

## 17. Histórico de revisões

| Versão | Data | Mudanças |
|---|---|---|
| 3.2 | 12/11/2026 | Consolidação da especificação de autorização de publicação (decisões conceituais de 12/11/2026; regras em `AUTONOMY_AND_AGENTS.md` seção 4). Aprovação individual descrita como regra da fase inicial, válida para todo envio, inclusive privado (3, 12.2, 15, 16.3); temas sensíveis por referência à lista aberta (2); checklist versionado e sem exceção (12.1); ausência ou posição inadequada da divulgação bloqueia o envio (13.2); nova versão a cada mudança e conferência das condições comerciais antes do envio (15.1); itens exibidos na revisão (16.3). Nenhuma regra editorial removida; nada implementado. |
| 3.1 | 08/11/2026 | Frequência definida por marca, sem frequência universal (16.2); estratégias de publicação por tipo de marca com referências como hipóteses (16.6); funil editorial em cinco etapas ligado às três categorias (16.7). Nenhuma regra anterior removida. |
| 3 | 06/11/2026 | Proposta de visão editorial multiformato: peça-mãe, vídeos longos, cortes adaptados e artigos; cadência quinzenal como hipótese; aprovação humana individual pelo painel móvel; blog/SEO e monetização complementar como destino faseado. |
| 1 | 04/11/2026 | Versão inicial |
| 2 | 04/11/2026 | Métricas comerciais alinhadas às três dimensões financeiras de `ACQUISITION_STRATEGY.md` 12 (14.3); atribuição tratada como capacidade em investigação; requisito de recursos avançados do YouTube (7.1, 7.2); nova seção de capacidade de produção (8.4); registro de tempo humano (14.4); limites de privacidade na automação (15); pendências reorganizadas (16) |
| 2.1 | 04/11/2026 | Revisão pontual: 14.3 alinhada à granularidade (`ACQUISITION_STRATEGY.md` 12.4) e aos critérios por estágio (13.2). Estrutura: 17 seções (1 a 15 temáticas; 16 Pendências; 17 Histórico) |
| 2.2 | 04/11/2026 | Harmonização mínima com a decisão L2: produção manual como solução temporária e tempo humano como supervisão (8.4, item 5); publicação por adaptadores multicanal (15, tabela); pendência 2 atualizada com o YouTube aprovado (16); nota de objetivo acordado no início da seção 15. A aprovação humana por peça continua como está até a decisão sobre a granularidade de aprovação. Nenhuma seção renumerada |
| 2.3 | 05/11/2026 | Harmonização mínima com as decisões de 05/11/2026: aprovação individual ou por política (3, tabela; 12.2, item; 15, tabela); referências ao antigo "nível 4" de custo corrigidas (6, hipótese; 16, item 4). Nenhuma seção renumerada |
| 2.4 | 05/11/2026 | Secao 15: conteudo comercial permanece com aprovacao individual por padrao enquanto nao houver politica especifica validada; possibilidade futura de nivel 4 dentro de politica expressamente autorizada, sem transformar a salvaguarda provisoria em regra definitiva. |
