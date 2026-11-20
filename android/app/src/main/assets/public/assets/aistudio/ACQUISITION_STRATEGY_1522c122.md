# Affiliate Autopilot — Estratégia de Aquisição

> **Revisão 3.1 — 12/11/2026 (consolidação da especificação de autorização de publicação):** ajuste pontual na pendência 17 (seção 17): a aprovação individual é regra da fase inicial e vale para todo envio, inclusive privado; a evolução por política segue `AUTONOMY_AND_AGENTS.md` seção 4.3. Nenhuma outra regra deste documento foi alterada.

> **Revisão 3 — 06/11/2026 (proposta para aprovação):** explicita o destino multicanal, internacional e multiplataforma de afiliados; inclui blog/site e monetização direta de canais como frentes futuras; preserva YouTube como primeiro canal operacional e validação sequencial.

> **O que este documento é:** define **como** a audiência encontra o conteúdo, **por quais** canais, **como** ela passa da descoberta à conversão e **como** medir e otimizar esse caminho.
> **O que ele não é:** não define o que produzir nem como escrever (isso está em `CONTENT_STRATEGY.md`). Não descreve a arquitetura técnica (`ARCHITECTURE.md`); quando uma regra daqui depende de tecnologia, isso aparece como dependência, não como decisão técnica nem como funcionalidade existente.
>
> **Situação:** **[Proposta]** — versão 2.5 (harmonização com as decisões L1 e L2 de 04/11/2026 e com as decisões de 05/11/2026), aguarda revisão e aprovação do responsável. Nada aqui é decisão aprovada, exceto o que está marcado como **[Acordado]**. As mudanças entre versões estão na seção 18.
> **Pesquisa de fontes externas:** 04/11/2026 (OAuth do YouTube: 05/11/2026, em `ARCHITECTURE.md` seção 7.1). Regras e recursos de plataformas mudam; conferir a página oficial antes de depender delas.
>
> **Legenda:** **[Acordado]**, **[Proposta]**, **[Hipótese]**, **[A definir]**, **[A verificar]**, **[Fato verificado]** — mesmas definições de `CONTENT_STRATEGY.md` e `PROJECT_VISION.md`. **[Em investigação]**: capacidade que pode existir, mas cujo funcionamento ainda não foi comprovado com dados do projeto.

---

## 1. Filosofia de aquisição

### 1.1 Princípios **[Acordado]**

- Aquisição orgânica primeiro; nenhum orçamento para anúncios, ferramentas ou APIs pagas é pressuposto.
- Começar com investimento financeiro zero. Nenhuma despesa sem autorização explícita.
- Reinvestimento somente com dinheiro efetivamente recebido, **nunca com comissões pendentes**.
- Visualizações não são resultado comercial.
- Expansão baseada em resultados medidos.
- **Dois indicadores financeiros independentes [Acordado — L1, 04/11/2026]:** resultado comercial confirmado (comissões confirmadas menos custos atribuíveis) e resultado realizado em caixa (dinheiro efetivamente recebido menos despesas efetivamente pagas). Reinvestimentos só podem usar dinheiro efetivamente recebido; comissões pendentes ou apenas confirmadas não constituem orçamento disponível (seção 12).
- **YouTube como canal inicial prioritário e arquitetura multicanal [Acordado — L2]:** a distribuição pode chegar a outros canais (por exemplo, Instagram, TikTok, Pinterest e Google), conforme viabilidade.
- **Ordem dos canais [Acordado — 05/11/2026]:** o YouTube é o primeiro canal operacional. Instagram, TikTok e Pinterest só entram na integração operacional depois que o fluxo do YouTube estiver validado; pesquisa e preparação técnica podem ocorrer antes. O Google representa tráfego orgânico por site próprio e SEO.
- **Fases de publicação [Acordado]:** Fase A = validação controlada e não pública, incluindo publicação privada ou não pública em pelo menos um canal. Fase B = operação pública controlada, só depois de autorização explícita do proprietário, respeitando limites, permissões e kill switch. **Cada peça pública exige aprovação humana individual da versão exata**; políticas podem autorizar apenas tarefas internas/preparatórias e operações delimitadas que não substituam a revisão editorial.
- **Automação operacional como objetivo [Acordado — L2]:** pesquisa, produção, adaptação, agendamento, publicação e análise devem ser automatizadas. O proprietário supervisiona, define diretrizes e aprova decisões relevantes. Trabalho manual (inclusive importação e publicação manuais) só como contingência ou etapa temporária de validação **[Acordado — 05/11/2026]**. A automação respeita as APIs e políticas de cada plataforma.

### 1.2 Princípios operacionais **[Proposta]**

1. **Audiência certa antes de audiência grande.** Uma pessoa interessada no pilar vale mais do que mil visualizações fora do tema.
2. **Um canal por vez na validação.** A Fase B prevê "uma marca, um nicho e um canal de aquisição orgânica" (`PROJECT_VISION.md` seção 3), e o canal inicial é o YouTube **[Acordado — L2]**. Só se **valida** um novo canal depois que o anterior tem dados suficientes para uma decisão. Essa regra trata da validação comercial, não da arquitetura, que é multicanal (L2). Canais secundários (Instagram, TikTok, Pinterest) só entram na integração operacional depois que o fluxo do YouTube estiver validado **[Acordado — 05/11/2026]**; antes disso, só pesquisa e preparação técnica.
3. **Alcance alugado, relacionamento próprio.** Plataformas trazem alcance, mas podem mudar regras a qualquer momento. A operação busca, **quando houver necessidade concreta**, uma audiência própria (seção 7).
4. **Respeito às regras das plataformas** como condição de existência do canal, não como detalhe.
5. **Medir o caminho inteiro**: da impressão ao dinheiro recebido, sem confundir etapas intermediárias com o resultado (seção 12).
6. **Coletar só o necessário**: nenhum dado pessoal sem finalidade concreta (seção 16).

---

## 2. Estratégias de aquisição orgânica

### 2.1 Três motores de descoberta

| Motor | Como funciona | Intenção da audiência | Tempo até resultado |
|---|---|---|---|
| **Busca** (Google, busca do YouTube) | A pessoa procura uma resposta | Alta, especialmente em guias e comparativos | **[Hipótese]** lento; prazo desconhecido |
| **Recomendação** (feeds de vídeos curtos, página inicial e sugeridos do YouTube) | A plataforma oferece o conteúdo | Baixa a média; curiosidade | **[Hipótese]** pode ser mais rápido, mas instável |
| **Comunidade e indicação** (fóruns, grupos, compartilhamento) | Pessoas indicam o conteúdo | Variável; alta confiança | Lento e manual |

O tempo necessário para obter resultados orgânicos continua **[Hipótese]** em todos os motores. Nenhum prazo é prometido (`PROJECT_VISION.md` seção 3).

### 2.2 Relação com as categorias de conteúdo

Ver `CONTENT_STRATEGY.md` seção 3. Em resumo: recomendação serve à descoberta, busca serve à conexão e ao conteúdo comercial, comunidade serve à confiança.

### 2.3 Participação em comunidades **[Proposta]**

- **[Fato verificado]** O Google recomenda divulgar o site e participar de comunidades onde o público já está ([Google Search Essentials](https://developers.google.com/search/docs/essentials)).
- **[Fato verificado]** A Hotmart considera spam, entre outros, repetir links em comentários, enviar links em mensagens diretas sem consentimento e enviar e-mails em massa sem consentimento ([Hotmart — Manual de boas práticas](https://hotmart.com/pt-br/blog/melhores-praticas)).
- **Regra:** em comunidades, contribuir com respostas úteis, seguir as regras de cada espaço e **não colocar links de afiliado**, salvo quando a comunidade permitir expressamente.

---

## 3. Canais de distribuição

### 3.1 Avaliação dos canais candidatos **[Proposta]**

| Canal | Papel provável | Link clicável para afiliado? | Custo financeiro inicial | Riscos e observações |
|---|---|---|---|---|
| **YouTube (vídeos longos)** | Conexão, confiança e conteúdo comercial | Sim, na descrição, **somente com recursos avançados** ([YouTube — Sharing links](https://www.support.google.com/youtube/answer/13748639)) | Zero | Recursos avançados exigem verificação (seção 3.3). Políticas de conteúdo inautêntico e reutilizado (`CONTENT_STRATEGY.md` 5.4 e 12.3) |
| **YouTube Shorts** | Descoberta | **Não**: URLs em descrição e comentários de Shorts não são clicáveis. O "vídeo relacionado" aponta para conteúdo do próprio canal e também exige recursos avançados ([YouTube — Add a related video](https://support.google.com/youtube/answer/14075157?hl=en)) | Zero | Não é canal de conversão direta |
| **Google: tráfego orgânico por site próprio e SEO** (site/blog, por exemplo WordPress) | Centro do conteúdo comercial escrito e do SEO | Sim | Domínio e hospedagem (exigem autorização de gasto) | Previsto em `ARCHITECTURE.md` seção 4.7 como adaptador de publicação (só rascunho). Resultado em busca tende a ser lento **[Hipótese]** |
| **Pinterest** | Descoberta por busca visual **[Hipótese]** | **[A verificar]** | Zero | Uso da API depende de conta empresarial e de solicitação revisada pelo Pinterest ([Pinterest Developers](https://developers.pinterest.com/docs/getting-started/set-up-app/)) |
| **TikTok** | Descoberta | **[A verificar]** regras atuais de link no perfil para contas de marca no Brasil | Zero | Divulgação comercial obrigatória ao promover produtos ([TikTok](https://ads.tiktok.com/resources/help/article/how-to-turn-on-the-commercial-content-disclosure-setting-in-tiktok)) |
| **Instagram (Reels e carrosséis)** | Descoberta e conteúdo visual | **[A verificar]** recursos atuais de link | Zero | Conteúdo com link de afiliado deve usar "Parceria paga" ([Instagram](https://help.instagram.com/616901995832907/)) |
| **E-mail (lista própria)** | Relacionamento e retorno | Sim | **[A verificar]** | Adiado; ver seções 7 e 16 |
| **Comunidades** | Confiança e pesquisa de audiência | Geralmente não (seção 2.3) | Zero | Alto custo de tempo; risco de parecer spam |

**Automação por API [Fato verificado em 04/11/2026]** (relevante para o objetivo de automação, L2):
- **YouTube:** envio por API com cota padrão de 10.000 unidades por dia ([Google](https://developers.google.com/youtube/v3/getting-started)); o vídeo fica público se o estado de privacidade não for informado ([Google](https://developers.google.com/youtube/v3/docs/videos/insert)).
- **TikTok:** conteúdo publicado por clientes não auditados fica restrito à visualização privada ([TikTok Developers](https://developers.tiktok.com/doc/content-posting-api-get-started)).
- **Instagram:** publicação por API só em contas profissionais, com mídia hospedada em servidor público ([Meta](https://developers.facebook.com/docs/instagram-platform/content-publishing/)).
- Cada canal só é automatizado depois de conferir esses requisitos e os termos vigentes (`ARCHITECTURE.md` seção 7; a referência anterior a `FUTURE_ARCHITECTURE.md` apontava para um documento que nunca foi criado).

### 3.2 Canal inicial prioritário: YouTube (vídeos longos + Shorts) **[Acordado — L2: canal inicial prioritário]**

> **Decisão de 04/11/2026:** o YouTube é o canal inicial prioritário. Os detalhes de execução desta seção (formatos, sequência, momento do site) continuam **[Proposta]** e podem ser reavaliados pelos critérios da seção 3.2.7.

#### 3.2.1 Por que o YouTube é a alternativa preferencial

| Critério | YouTube (longo + Shorts) | Site + busca |
|---|---|---|
| Custo financeiro para começar | Zero | Domínio e hospedagem (despesa que exige autorização) |
| Descoberta e conversão no mesmo lugar | Sim: Shorts descobrem, vídeos longos aprofundam e convertem | Descoberta depende quase só da busca |
| Construção de confiança | Alta em vídeos longos (voz, explicação, demonstração) | Alta em guias bem fundamentados |
| Coerência com o princípio de investimento zero | Total | Parcial |
| Coerência com a arquitetura atual | Prevista como adaptador de publicação em `ARCHITECTURE.md` revisão 2 (seção 4.7); ainda não implementada | Alta: WordPress já previsto |

#### 3.2.2 Vantagens

- Começa sem despesa financeira.
- Cobre as três categorias numa só plataforma: Shorts para descoberta, vídeos longos para conexão e conteúdo comercial (`CONTENT_STRATEGY.md` seções 3 e 7).
- A busca do YouTube também atende intenção alta (guias, comparativos), não só recomendação.
- O YouTube Analytics oferece retenção, origem do tráfego e termos de busca sem custo ([YouTube — Audience retention](https://support.google.com/youtube/answer/9314415)).

#### 3.2.3 Limitações

- **Links clicáveis não são imediatos.** **[Fato verificado]** Links clicáveis em descrições de vídeos longos e o vídeo relacionado nos Shorts exigem recursos avançados. O acesso requer verificação por telefone e, depois, histórico suficiente do canal **ou** verificação por documento ou vídeo, e esta última não está disponível para todos os criadores ([YouTube — Feature access](https://support.google.com/youtube/answer/9890437?hl=en); [YouTube — Unlock advanced features](http://support.google.com/youtube/answer/9891124)). Só o proprietário principal do canal pode fazer a verificação de identidade. Isso precisa ser considerado no modelo Ghost Commerce: a marca é pública e independente, mas a verificação é feita pela pessoa responsável.
- **Dependência de uma única plataforma**, sujeita a mudanças de regra e de algoritmo.
- **Risco de conta "só de afiliado"**: o YouTube avisa que publicar conteúdo de afiliado em excesso em contas dedicadas pode violar a política de spam ([YouTube — External links policy](https://support.google.com/youtube/answer/9054257)).
- **Produção mais trabalhosa** que texto (seção 3.2.4).
- **A automação de vídeo ainda não existe no código.** A `ARCHITECTURE.md` (revisão 2) prevê publicação multicanal com o YouTube como primeiro adaptador, mas nada foi implementado. Produção ou publicação manual só é aceitável como solução **temporária** de validação ou contingência técnica **[Acordado — L2]**; o destino é a automação.

#### 3.2.4 Esforço operacional e sustentabilidade

| Etapa | Vídeo longo | Short |
|---|---|---|
| Pesquisa e dossiê (`CONTENT_STRATEGY.md` 9.2) | Alta | Reaproveitada da peça-mãe |
| Roteiro | Alta | Média |
| Produção (narração, visual, edição) | Alta | Média |
| Revisão humana e divulgação | Média | Baixa a média |
| Publicação e metadados | Baixa | Baixa |

**[Hipótese]** O modelo peça-mãe (`CONTENT_STRATEGY.md` seção 8) torna a produção sustentável: um vídeo longo de conexão por ciclo gera alguns Shorts derivados. A cadência real será definida pelo registro de tempo humano (`CONTENT_STRATEGY.md` seção 8.4). Nenhum volume é fixado antes desse registro.

**Automação [Acordado — L2]:** a tabela descreve o trabalho de cada etapa, não quem o faz. O objetivo é que o sistema execute pesquisa, roteiro, produção, adaptação e publicação, e que o tempo humano se reduza à supervisão, à revisão e às aprovações. Que partes podem ser automatizadas sem custo, e com qualidade aceitável, é **[A verificar]**.

#### 3.2.5 Relação entre descoberta, conexão e conversão no YouTube

```
Shorts (descoberta)
  └─ vídeo relacionado* / perfil / playlist ─> Vídeo longo de conexão
        └─ telas finais / playlist / descrição ─> Vídeo longo comercial
              └─ link na descrição* com divulgação ─> Página do produto (Hotmart)
* exige recursos avançados
```

#### 3.2.6 Como evitar depender só de Shorts **[Proposta]**

1. **O vídeo longo é o centro do canal.** Shorts existem para levar pessoas aos vídeos longos, não para substituí-los.
2. **Todo Short deriva de ou aponta para um vídeo longo** do mesmo pilar.
3. **Medir a passagem Shorts → vídeo longo** (seção 12.3). Muitas visualizações de Shorts sem passagem para vídeos longos são um sinal de alerta, não de sucesso.
4. **Não julgar o canal pelas visualizações de Shorts.** O julgamento usa as dimensões da seção 12.
5. **Preservar o material de pesquisa** (dossiês e roteiros) em formato reutilizável, para alimentar outro canal no futuro.

#### 3.2.7 Incorporação posterior de um site próprio **[Proposta]**

O site não é descartado; ele é **adiado**. Gatilhos para reavaliar:

- Existe dinheiro efetivamente recebido para pagar domínio e hospedagem, com autorização do proprietário.
- Há vídeos longos com bom desempenho que justificam uma versão escrita (guias, comparativos com tabelas, páginas de política de afiliados).
- Há necessidade de um destino próprio de links que não dependa do YouTube.
- Há necessidade de uma página de política de privacidade e, futuramente, de lista própria (seções 7 e 16).

Como incorporar sem duplicar:

1. Converter vídeos longos de conexão e comerciais em artigos **reescritos para texto** (`CONTENT_STRATEGY.md` seção 8.2), não em transcrições.
2. Usar o WordPress já previsto em `ARCHITECTURE.md` seção 4.7.
3. O site entra como **segundo canal**, seguindo a regra de "um canal por vez" (seção 1.2) e o processo de validação da seção 13.

**Critérios para reverter a proposta** (voltar a priorizar o site): impossibilidade prática de obter os recursos avançados, restrição de política do YouTube que afete o modelo, ou capacidade de produção de vídeo insustentável segundo o registro de tempo.

**Observação:** a proposta trata Shorts e vídeos longos como **um único canal** (mesma plataforma, conta e audiência). Essa interpretação da regra da Fase B precisa ser confirmada pelo proprietário.

### 3.3 Regra contra contas "só de afiliado"

Ver seção 3.2.3 e a proporção de categorias de `CONTENT_STRATEGY.md` seção 3.4.

---

## 4. Descoberta de público

### 4.1 Objetivo

Descobrir **quem** é a audiência, **o que** ela pergunta e **qual** problema tenta resolver, com dados e não com suposição. A demanda real de cada nicho continua **[Hipótese]** até ser medida.

### 4.2 Métodos sem custo **[Proposta]**

| Método | O que revela | Observação |
|---|---|---|
| Sugestões de busca do Google e do YouTube | Como as pessoas formulam perguntas | Consulta manual |
| "As pessoas também perguntam" e buscas relacionadas | Dúvidas vizinhas ao tema | Consulta manual |
| YouTube Analytics (depois que o canal existir) | Origem do tráfego, termos de busca, retenção | Gratuito; dados agregados |
| Google Search Console (se o site existir) | Buscas que já trazem impressões e cliques | Gratuito |
| Comentários nos próprios conteúdos | Perguntas reais, objeções, novas pautas | Ler para gerar pautas; não exportar dados pessoais de quem comenta |
| Leitura de comunidades públicas | Problemas e linguagem do público | Sem coleta automatizada; respeitar as regras de cada espaço |
| Páginas públicas dos produtos | Para quem o produto foi feito | Leitura manual. **[Fato verificado]** A Hotmart restringe automação e o uso de dados da plataforma para treinar IA ([Termos de Uso da Hotmart](https://hotmart.com/pt-br/legal/termos-de-uso)) |

### 4.3 Hipóteses de audiência

Cada marca registra suas hipóteses de audiência no guia da marca (`CONTENT_STRATEGY.md` seção 11.1) e as revisa com dados. **Nenhuma hipótese de audiência vira decisão sem evidência.**

### 4.4 Sinais de que a audiência está errada

- Muitas visualizações, pouca retenção e nenhum avanço para conteúdo de conexão.
- Comentários fora do tema do pilar.
- Visitas a conteúdo comercial com quase nenhum clique, ou cliques sem vendas.

---

## 5. Distribuição de vídeos curtos e longos

### 5.1 Papéis

Ver `CONTENT_STRATEGY.md` seção 7.1. Aqui ficam só as regras de distribuição.

### 5.2 Vídeos curtos **[Proposta]**

- Publicar com regularidade sustentável. **[Hipótese]** Constância importa mais do que volume; a frequência ideal é desconhecida.
- Com recursos avançados: usar o vídeo relacionado apontando para o vídeo longo do mesmo pilar ([YouTube — Add a related video](https://support.google.com/youtube/answer/14075157?hl=en)). Sem recursos avançados: mencionar o título do vídeo longo e usar playlists.
- Nunca usar vídeos curtos para empurrar produto.
- Reaproveitar o mesmo vídeo curto em outras plataformas só depois de verificar as regras de cada uma (conteúdo reutilizado, marcas d'água). Isso fica para quando houver um segundo canal (seção 1.2).

### 5.3 Vídeos longos **[Proposta]**

- Títulos e descrições com os termos que a audiência usa (busca do YouTube).
- Capítulos para facilitar a navegação.
- Telas finais e playlists ligando a descoberta à conexão e a conexão ao conteúdo comercial.
- Links de afiliado só em vídeos comerciais (ou de conexão em que o produto faça parte da solução), com divulgação (`CONTENT_STRATEGY.md` seção 13).
- Enquanto o canal não tiver recursos avançados, priorizar descoberta e conexão; o conteúdo comercial em vídeo só converte quando os links forem clicáveis.

### 5.4 Sequência entre formatos

Ver o diagrama da seção 3.2.5.

---

## 6. Artigos, guias e SEO

### 6.1 Papel do site

Se e quando o site for incorporado (seção 3.2.7), ele será o lugar natural do conteúdo comercial escrito: comparativos, guias de compra e análises, com links clicáveis, política de afiliados e controle total sobre a divulgação.

### 6.2 Regras de aquisição por busca **[Proposta]**

- Regras editoriais de SEO: `CONTENT_STRATEGY.md` seção 10.
- Cadastrar o site no Google Search Console e enviar o sitemap (gratuito).
- Links internos entre descoberta, conexão e conteúdo comercial dentro do cluster.
- Links de afiliado com `rel="sponsored"` ([Google — Qualify outbound links](https://developers.google.com/search/docs/crawling-indexing/qualify-outbound-links)).
- Páginas "Sobre", política de afiliados e política de privacidade. **[Fato verificado]** O Google cita página "Sobre" e informações sobre autoria como sinais de confiança ([Google — Creating helpful content](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)).

### 6.3 O que evitar

- Publicar muitas páginas parecidas só para cobrir variações de palavras-chave.
- Páginas comerciais sem conteúdo próprio, que apenas repetem a descrição do produto.
- Atualizar a data sem mudança real.

---

## 7. Construção de audiência própria

### 7.1 O que é **[Proposta]**

Audiência própria é a que a marca consegue alcançar **sem depender do algoritmo** de uma plataforma. A forma mais comum é uma lista de e-mail com consentimento.

### 7.2 Quando começar **[Proposta]**

**Não implementar agora.** Lista de e-mail, formulários e qualquer coleta de dados pessoais só devem existir quando houver, **ao mesmo tempo**:

1. **Necessidade operacional concreta**: por exemplo, conteúdo de conexão recorrente que a audiência pediu para receber, ou risco demonstrado de depender de uma única plataforma.
2. **Definição adequada de consentimento e privacidade**, conforme a seção 16: finalidade, base legal, política de privacidade publicada, forma de revogação e local seguro de armazenamento.
3. **Decisão técnica e autorização** do proprietário, porque a arquitetura atual não prevê esse recurso.

Até lá, a "audiência própria" fica limitada ao que as plataformas já oferecem: inscritos no canal e notificações.

### 7.3 Regras para quando existir

1. **Consentimento explícito, para finalidade determinada, com prova de obtenção** (seção 16).
2. **Descadastro fácil** em todo e-mail.
3. **Nenhuma compra, aluguel ou troca de listas.**
4. **Iscas honestas:** o material oferecido precisa ser útil por si só, sem promessa de "dinheiro fácil". **[Fato verificado]** Os termos da Hotmart proíbem divulgar produtos sugerindo ganho de dinheiro fácil ([Termos de Uso da Hotmart](https://hotmart.com/pt-br/legal/termos-de-uso)).
5. **Proporção:** o e-mail segue a mesma lógica de categorias de `CONTENT_STRATEGY.md` seção 3. A lista não é um canal de ofertas.

---

## 8. Caminho entre descoberta, interesse e conversão

### 8.1 Mapa do caminho

| Estágio (ver `CONTENT_STRATEGY.md` seção 4) | Pontos de contato | Mecanismo de avanço | Indicador de passagem |
|---|---|---|---|
| Curiosidade | Short, conteúdo visual, sugerido do YouTube | Vídeo relacionado, perfil, playlist | Passagem para vídeo longo |
| Interesse | Vídeo longo de conexão | Playlist, telas finais | Retenção e retorno |
| Relevância | Vídeo-guia prático | Tela final ou descrição apontando para comparativo ou análise | Visitas ao conteúdo comercial |
| Avaliação | Comparativo, análise | Link de afiliado com divulgação | Cliques qualificados |
| Decisão | Página do produto (fora da marca) | — | Venda confirmada |
| Relacionamento | Novos conteúdos, inscrição no canal | Inscrição, retorno | Inscritos e recorrência |

### 8.2 Regras **[Proposta]**

- Toda peça tem **um** próximo passo principal.
- A chamada para o próximo passo é editorial ("veja o guia completo"), nunca pressão de compra ("últimas vagas"), salvo se for verdade e estiver documentado pelo criador do produto.
- O caminho pode parar em qualquer estágio. Quem não compra, mas volta, ainda é audiência valiosa.

---

## 9. Integração dos links afiliados

### 9.1 Onde os links aparecem **[Proposta]**

| Local | Permitido? |
|---|---|
| Descrição de vídeo longo comercial | Sim, com divulgação no vídeo e junto ao link (exige recursos avançados) |
| Descrição de vídeo longo de conexão | Só se o produto fizer parte da solução tratada (`CONTENT_STRATEGY.md` seção 6.2) |
| Shorts | Não (links não clicáveis e categoria de descoberta) |
| Conteúdo comercial no site (futuro) | Sim, junto à análise e com divulgação |
| Comentários de terceiros, mensagens diretas, grupos | Não (spam segundo a Hotmart) |
| E-mail (futuro) | Sim, em conteúdo comercial para assinantes, com divulgação |

### 9.2 Regras de link

1. **Divulgação próxima ao link** (`CONTENT_STRATEGY.md` seção 13).
2. **Destino honesto:** o link leva ao que foi anunciado. Nenhum redirecionamento enganoso.
3. **Usar o link de divulgação oficial do afiliado.** **[Fato verificado]** A Hotmart avisa que compartilhar o endereço da página de vendas em vez do link de divulgação impede o recebimento da comissão ([Hotmart — Rastreamento dos links](https://help.hotmart.com/en/article/209119037/how-does-the-tracking-process-of-promotional-links-hotlinks-work-)).
4. **Parâmetro de origem** para identificar a peça (seção 11), com a ressalva de que a atribuição está em investigação.
5. **Proibido comprar pelo próprio link** ([Termos de Uso da Hotmart](https://hotmart.com/pt-br/legal/termos-de-uso)).
6. **Respeitar as formas de divulgação definidas por cada criador.** Na Hotmart, o criador do produto define as formas e limitações de divulgação ([Termos de Uso da Hotmart](https://hotmart.com/pt-br/legal/termos-de-uso)).
7. **Links mantidos:** links quebrados ou produtos desativados são removidos ou atualizados.

### 9.3 Relação com a arquitetura

`ARCHITECTURE.md` seção 4.8 prevê três opções de rastreamento de cliques: (a) Google Analytics, (b) redirecionador próprio (exige hospedagem) e (c) parâmetros da plataforma. A escolha é técnica e cabe ao proprietário e ao desenvolvimento.

Do ponto de vista desta estratégia: com o YouTube como canal inicial, os cliques nos links da descrição **não passam por nenhum sistema próprio**. A opção (c), com o parâmetro de origem da Hotmart, é a única que não exige gasto, mas sua confiabilidade está **[Em investigação]** (seção 11). Nenhuma das opções deve ser tratada como solução confirmada.

---

## 10. Estratégias de tráfego qualificado

### 10.1 O que é tráfego qualificado **[Proposta]**

Pessoas que chegam ao conteúdo ou ao produto **com uma necessidade compatível** com o que encontram. Indicadores: tempo de exibição, avanço para o próximo passo, cliques que resultam em venda confirmada e baixo reembolso.

### 10.2 Práticas

1. **Alinhar intenção e conteúdo:** busca com intenção de compra leva a comparativos; curiosidade leva a descoberta.
2. **Pré-qualificar antes do link:** dizer para quem o produto serve e para quem não serve (`CONTENT_STRATEGY.md` seção 6.2). Menos cliques, mais vendas.
3. **Não incentivar cliques artificiais:** nada de sorteios, "clique para ver" ou chamadas enganosas.
4. **Não trazer tráfego de fora do tema:** viralização sem relação com o pilar distorce as métricas.

### 10.3 Sinal de alerta

Muitos cliques com poucas vendas, ou reembolso alto, indicam desalinhamento entre conteúdo e produto. A resposta é revisar o conteúdo ou o produto, não aumentar o volume.

---

## 11. Rastreamento de cliques e atribuição de vendas

### 11.1 Situação **[Em investigação]**

A atribuição de vendas a canais e peças **ainda não está validada**. Nenhuma métrica, relatório ou decisão deve tratá-la como funcionalidade confirmada até a conclusão do protocolo da seção 11.4.

### 11.2 O que as fontes oficiais confirmam **[Fato verificado em 04/11/2026]**

| Ponto | O que a Hotmart informa | Fonte |
|---|---|---|
| Como a venda é atribuída ao afiliado | Por cookie gravado no navegador quando a pessoa clica no link de divulgação | [Hotmart — Rastreamento dos links](https://help.hotmart.com/en/article/209119037/how-does-the-tracking-process-of-promotional-links-hotlinks-work-) |
| Mesmo navegador e dispositivo | A compra precisa acontecer no mesmo navegador e dispositivo do clique | [Hotmart — Quero ser afiliado](https://help.hotmart.com/pt-br/article/208424898/quero-ser-afiliado-o-que-preciso-saber-para-comecar-) |
| Duração do cookie | 60, 90, 180 dias ou indefinida, conforme a configuração do **criador do produto** | Mesma fonte |
| Regra entre afiliados | Último clique, primeiro clique ou multiclique, definida pelo **criador do produto** | [Hotmart — Programa de afiliados](https://help.hotmart.com/en/article/210874788/how-do-i-set-up-and-manage-my-affiliate-program-) |
| Parâmetro de origem do afiliado | O afiliado pode usar `src` no link para identificar a campanha; o resultado aparece no painel de origem de vendas | [Hotmart — Origem das vendas](https://help.hotmart.com/en/article/216441797/how-can-i-track-the-source-of-my-sales-on-hotmart-) |
| `sck` | Descrito como parâmetro usado por **criadores** para campanhas que levam direto ao checkout | Mesma fonte |
| Campos na API | A documentação do histórico de vendas descreve o filtro `sales_source`/`src` como "código SRC utilizado no link da página de pagamento" para identificar a origem; o exemplo de resposta também traz um objeto `tracking` e o campo `source_sck`, sem descrição. O campo `commission_as` indica se o usuário foi comissionado como `AFFILIATE`. A página **não diz** se contas de afiliado podem usar o endpoint. Dados do comprador também aparecem | [Hotmart — Sales history](https://developers.hotmart.com/docs/pt-BR/v1/sales/sales-history/) |
| Ambiente de testes | Existe um sandbox com todos os endpoints, mas **os dados são fictícios** | [Hotmart — Sandbox](https://developers.hotmart.com/docs/en/start/sandbox/) |
| Uso das APIs | Não usar as APIs para consultas recorrentes longas; webhooks são recomendados | [Hotmart — Good usage practices](https://developers.hotmart.com/docs/en/tutorials/learn-good-usage-practices/) |

### 11.3 O que **não** está confirmado **[A verificar]**

1. Se a API, com credenciais de **conta de afiliado**, devolve as vendas do afiliado com a origem `src` preenchida. A documentação descreve `src` com exemplo de link de checkout do produto, não de link de afiliado, e não detalha o conteúdo do objeto `tracking`.
2. Se o valor de `src` é preservado quando a pessoa volta dias depois e compra sem clicar de novo.
3. Como `src` se comporta quando a pessoa clica em links de duas peças diferentes.
4. Se o painel de origem de vendas e a API mostram os mesmos números.
5. O que acontece com a atribuição quando a pessoa clica num aparelho e compra em outro (pelo funcionamento descrito, a venda tende a **não** ser atribuída ao afiliado).

### 11.4 Protocolo de validação **[Proposta]**

| Etapa | O que fazer | O que ela prova | Custo |
|---|---|---|---|
| V1. Documentação | Confirmar na documentação oficial quais campos de origem existem para afiliados e em quais endpoints | Que o dado **pode** existir | Zero |
| V2. Sandbox | Conferir a estrutura das respostas | Só o **formato** dos campos. Como os dados são fictícios, não prova comportamento real | Zero |
| V3. Painel da Hotmart | Depois das primeiras vendas reais, comparar o painel de origem de vendas com os links usados | Que o `src` aparece em vendas reais | Zero |
| V4. Consistência | Por período, comparar cliques registrados (quando houver), vendas no painel e comissões no extrato | O tamanho da diferença entre as fontes | Zero |
| V5. Registro de limitações | Documentar o que não pode ser atribuído (outro dispositivo, cookie expirado, regra de clique do criador) | Os limites conhecidos | Zero |

**Restrições do protocolo:**

- Nenhuma compra de teste pelo próprio link: é proibido pelos termos da Hotmart (seção 9.2).
- Nenhum teste automatizado em produção sem decisão técnica e revisão dos termos.
- A integração por API ou webhook é decisão técnica, fora do escopo deste documento.

**Critério de saída [A definir]:** o proprietário define qual nível de consistência entre as fontes é suficiente para usar a atribuição em decisões. Até lá, a atribuição só serve como **indicação**, nunca como base única para encerrar ou ampliar um pilar.

### 11.5 O que fazer enquanto a atribuição está em investigação

- Usar um valor de `src` diferente por canal e por peça, com uma convenção estável (exemplo: `yt-c042`). Essa convenção não depende de nenhum sistema novo.
- Tomar decisões com base em **indicadores de conteúdo** (retenção, passagem entre estágios) e em **resultados por marca e período** (seção 12.1), que não dependem de atribuição.
- Tratar o número de vendas por peça como aproximado.

### 11.6 Convenção de UTM (para quando houver site ou ferramenta de análise)

- **[Fato verificado]** No GA4, `utm_source`, `utm_medium` e `utm_campaign` devem estar sempre presentes; `utm_content` distingue links dentro da mesma peça; os valores diferenciam maiúsculas e minúsculas ([Google Analytics — URL builders](https://support.google.com/analytics/answer/10917952)).
- Convenção sugerida, sempre em minúsculas: `utm_source` = plataforma, `utm_medium` = tipo, `utm_campaign` = marca e pilar, `utm_content` = peça e posição do link.
- **[Fato verificado]** O Google proíbe enviar dados pessoais identificáveis ao Analytics, incluindo em parâmetros de campanha ([Google Analytics — Avoid sending PII](https://www.support.google.com/analytics/answer/6366371)).

---

## 12. Métricas de aquisição e resultado financeiro

### 12.1 Dimensão 1 — Resultado realizado em caixa **[Acordado — L1]**

> **Resultado realizado em caixa = dinheiro efetivamente recebido − despesas efetivamente pagas**, por marca e por período.
> Nas versões anteriores, este indicador se chamava "resultado financeiro realizado". Os dois nomes designam o mesmo indicador; neste documento, "resultado financeiro realizado" continua significando o resultado em caixa.

**Definições dos estados financeiros** (para não confundir):

| Estado | O que é | Entra no resultado realizado? |
|---|---|---|
| Valor da venda (faturamento do produto) | Preço pago pelo comprador. Pertence ao criador e à plataforma, **não** à operação | Não |
| Comissão pendente | Comissão registrada, ainda dentro do prazo de liberação | Não |
| Comissão aprovada ou liberada | Comissão que passou pelo prazo de liberação e está disponível para saque | Não (ainda está na plataforma) |
| **Dinheiro recebido** | Valor que chegou à conta bancária da operação | **Sim** |
| Comissão reembolsada ou cancelada | Comissão que não será paga | Não; já não aparece no dinheiro recebido |

**[Fato verificado]** Na Hotmart, as comissões ficam disponíveis de forma progressiva, considerando prazos de garantia, reembolsos e cancelamentos. Vendas em reais por cartão ficam disponíveis a partir de 30 dias corridos; por PIX ou boleto, após 2 dias corridos; em outras moedas, a partir de 15 dias. Saques em reais são manuais ([Hotmart — Quando posso sacar](https://help.hotmart.com/pt-br/article/360028608652/quando-posso-realizar-o-saque-das-minhas-comiss-es-); [Hotmart — Transferência automática](https://help.hotmart.com/en/article/22224013803149/how-does-the-automatic-transfer-of-commissions-work-)).

**Regras de cálculo:**

1. **Regime de caixa:** conta-se o valor na data em que entrou na conta bancária.
2. **Sem dupla contagem de reembolsos e cancelamentos:** como o dinheiro recebido já reflete o que foi reembolsado ou cancelado antes da liberação, eles **não são subtraídos de novo**. Eles aparecem só como indicador auxiliar (12.3).
3. **[A verificar]** Se a plataforma pode descontar do saldo, depois da liberação, valores de reembolsos ou contestações tardias. Se puder, esse desconto aparece naturalmente como valor menor nos saques seguintes e, de novo, não é subtraído uma segunda vez.
4. **Taxa de saque:** **[Fato verificado em 04/11/2026]** o artigo da Central de Ajuda "Como sacar a minha comissão?" informa que o valor mínimo para saque em reais é R$ 2,00, "acrescido da taxa de saque de R$ 1,99" ([Hotmart — Como sacar a minha comissão?](https://help.hotmart.com/pt-br/article/216440207/como-sacar-a-minha-comissao-)). O artigo de taxas da Hotmart acrescenta que a taxa de saque é descontada do saldo no momento da solicitação e "pode variar conforme o valor a ser sacado" ([Hotmart — Quais são as taxas cobradas](https://help.hotmart.com/pt-br/article/208298448/quais-sao-as-taxas-cobradas-pela-hotmart-)). Portanto, o valor de R$ 1,99 está confirmado para o caso descrito, mas **[A verificar]** se ele se mantém para qualquer valor sacado. Escolher **um** dos registros: (a) contar o valor líquido creditado, sem lançar a taxa como despesa; ou (b) contar o valor bruto do saque e lançar a taxa como despesa. **Recomendação: (a)**, por ser o valor que realmente chegou.
5. **Despesas financeiras efetivamente pagas:** domínio, hospedagem, ferramentas, APIs, anúncios ou qualquer outro gasto **pago** e atribuído à marca. Despesas autorizadas mas ainda não pagas não entram.
6. **Defasagem:** o resultado realizado chega semanas depois das vendas. Um período sem dinheiro recebido não significa, por si só, ausência de vendas.
7. **Base do reinvestimento [Acordado]:** só esta dimensão autoriza reinvestimento. Comissões pendentes ou liberadas e ainda não sacadas não contam.
8. **Aspectos fiscais** (tributos sobre comissões): **[A verificar com profissional qualificado]**. Quando definidos, serão tratados como despesa paga.

#### 12.1.1 Indicador complementar — Resultado comercial confirmado **[Acordado — L1]**

> **Resultado comercial confirmado = comissões confirmadas − custos atribuíveis**, por marca e por período.

- **É independente da Dimensão 1.** Os dois são sempre apresentados lado a lado, nunca somados e nunca substituídos um pelo outro.
- **Para que serve:** sinal antecipado do desempenho comercial, sem esperar a defasagem entre venda e saque (item 6).
- **Não autoriza gasto.** Comissões confirmadas não constituem orçamento disponível **[Acordado — L1]**.
- **Comissão confirmada [Acordado — 05/11/2026]:** só é confirmada depois da aprovação efetiva pela plataforma, inclusive depois do período de garantia, quando aplicável. Comissões ainda no prazo de garantia não contam como confirmadas. Reembolsos e cancelamentos conhecidos na data da apuração são descontados **[Proposta]**. O uso desse indicador em algum estágio continua **[A definir]** (seção 17).
- **Custos atribuíveis [Proposta]:** custos da marca referentes ao período, pagos ou não. Diferem das despesas efetivamente pagas da Dimensão 1.
- **Reembolsos posteriores:** quando uma comissão confirmada for reembolsada depois, o indicador do período é recalculado e a correção fica registrada.
- **Uso nos estágios de validação:** os critérios dos estágios 4 e 5 continuam baseados no resultado em caixa (seção 13.2). Usar este indicador como critério de algum estágio é **[A definir]**.

### 12.2 Dimensão 2 — Eficiência operacional **[Proposta]**

> **Eficiência operacional = resultado financeiro realizado do período ÷ horas humanas dedicadas à operação no mesmo período.**

- **Horas humanas** incluem pesquisa, produção, revisão, publicação, análise e manutenção (registro descrito em `CONTENT_STRATEGY.md` seção 8.4). Com o objetivo de automação (L2), espera-se que essas horas se concentrem em supervisão, revisão e aprovação; o indicador também mostra quanto a automação reduz o tempo humano.
- **Leitura:** é o valor obtido por hora de trabalho. No início, tende a ser zero ou negativa, por causa da defasagem e do tempo de construção de audiência. Isso é esperado e não deve ser lido isoladamente.
- **Uso:** comparar períodos da mesma marca e, no futuro, marcas diferentes. É o principal indicador de **sustentabilidade**.
- **Sem valor monetário da hora por enquanto:** o projeto não define um valor por hora. Se o proprietário quiser um "custo de oportunidade", isso é uma decisão **[A definir]**.

### 12.3 Dimensão 3 — Indicadores auxiliares **[Proposta]**

Explicam o resultado, mas **não são o resultado**.

| Grupo | Indicadores |
|---|---|
| Atenção | Impressões, taxa de cliques em miniaturas, retenção, visualizações engajadas, duração média ([YouTube — Content performance](https://support.google.com/youtube/answer/12220281)) |
| Engajamento e relacionamento | Comentários, compartilhamentos, inscritos, espectadores recorrentes, passagem Shorts → vídeo longo |
| Intenção | Cliques qualificados em links de afiliado (quando mensuráveis) |
| Vendas | Vendas confirmadas, conversões, taxa de conversão (vendas confirmadas ÷ cliques qualificados) |
| Comissões | Comissões pendentes, comissões liberadas e ainda não sacadas |
| Perdas | Reembolsos e cancelamentos (quantidade e valor); **apenas informativo**, sem nova subtração no resultado |
| Custos | Custos operacionais por natureza, inclusive autorizados e ainda não pagos (para planejamento) |

### 12.4 Granularidade: o que pode ser medido em cada nível **[Proposta]**

As três dimensões não têm a mesma granularidade. Misturá-las é o erro mais provável na leitura dos dados.

| Tipo de informação | Nível de apuração | Natureza | Pode ser chamado de resultado financeiro? |
|---|---|---|---|
| **Resultado financeiro realizado** (Dimensão 1) e **eficiência operacional** (Dimensão 2) | **Marca e período** | Fato, apurado pelo dinheiro que chegou à conta bancária e pelas despesas pagas | **Sim**, e somente ele |
| **Resultado comercial confirmado** (12.1.1) | **Marca e período** | Fato segundo os registros da plataforma, sujeito a correção por reembolsos posteriores | Não é resultado em caixa. É resultado comercial e não autoriza gasto |
| **Métricas de conteúdo** (retenção, engajamento, visualizações, passagem entre estágios) | Canal, categoria de conteúdo e peça | Fato, segundo os painéis das plataformas | Não |
| **Atribuição comercial** (vendas, comissões e cliques associados a um canal, categoria ou peça) | Canal, categoria e peça | **Estimativa** enquanto a atribuição estiver em investigação (seção 11) | **Não**. É indicação |

**Regras:**

1. **Nenhuma receita atribuída a um vídeo, canal ou conteúdo é apresentada como resultado financeiro confirmado.** Em relatórios, ela aparece com o rótulo "estimativa" e com o método de atribuição usado.
2. **A atribuição não cria uma Dimensão 1 por peça.** Mesmo depois de validada, a soma das estimativas por peça não substitui o resultado realizado da marca, porque parte das vendas sempre ficará sem atribuição (seção 11.3).
3. **Os estados financeiros não se misturam em nenhum nível.** Vendas confirmadas, comissões pendentes, comissões liberadas e dinheiro recebido são sempre colunas separadas (seção 12.1). Uma estimativa por peça, quando existir, refere-se a vendas ou comissões, nunca a dinheiro recebido.
4. **Evidência suficiente** para usar a atribuição de um canal em decisões é o critério de saída do protocolo da seção 11.4 **[A definir]**. Até lá, **nenhuma das fontes abaixo, isoladamente, comprova que uma venda veio de determinado vídeo, canal ou conteúdo**:
   - a tendência do resultado financeiro da marca;
   - as métricas de conteúdo;
   - o painel de origem de vendas da Hotmart.

   Esses dados podem apoiar a análise e a triangulação de evidências, mas não são tratados como confirmação de atribuição individual.
5. Métricas sempre separadas por marca, e dados de teste separados (`ARCHITECTURE.md` seção 4.3).
6. Nenhuma meta numérica fixada aqui (`PROJECT_VISION.md` seção 7).
7. Nenhuma decisão de ampliar ou encerrar depende só de indicadores de atenção.

---

## 13. Experimentos e validação de canais

### 13.1 Formato de experimento **[Proposta]**

Cada experimento é registrado **antes** de começar:

| Campo | Exemplo (ilustrativo) |
|---|---|
| Hipótese | "Shorts com pergunta no início levam mais pessoas ao vídeo longo" |
| Variável testada | Uma só (por exemplo, o tipo de gancho) |
| Métrica principal | Passagem Shorts → vídeo longo |
| Amostra ou período mínimo | **[A definir]** pelo proprietário antes do início |
| Critério de decisão | Continuar, ajustar ou parar, definido antes |
| Resultado e decisão | Preenchido no fim, com data |

### 13.2 Estágios de validação de um canal **[Proposta]**

Cada estágio é avaliado **só** pelos critérios da sua maturidade. Um estágio não exige o que pertence aos seguintes, e o que ele mostra não vale como prova dos seguintes.

| Estágio | Pergunta | Critérios de avaliação | Não exigido neste estágio | O que este estágio **não** prova |
|---|---|---|---|---|
| 1. Exploração | A audiência reage ao conteúdo? | Retenção, engajamento, sinais de interesse no pilar (perguntas nos comentários, retorno) e qualidade editorial (`CONTENT_STRATEGY.md` 12.1 e 14.2) | Vendas, comissões, lucro | Viabilidade comercial |
| 2. Interesse | A audiência avança para conexão e conteúdo comercial? | Passagem entre estágios, visitas a conteúdo comercial, cliques qualificados recorrentes | Vendas, lucro | Que há vendas |
| 3. Validação de conversão | Há vendas confirmadas? | Cliques qualificados, sinais de intenção, vendas confirmadas **na marca** com reembolso baixo. A associação dessas vendas ao canal é **estimada** até a validação da atribuição (seção 12.4) | Dinheiro recebido | Que o dinheiro chega ou cobre custos |
| 4. Resultado financeiro | O dinheiro chega? | Resultado financeiro realizado positivo por período (Dimensão 1) | Eficiência demonstrada | Que a operação é sustentável |
| 5. Sustentabilidade operacional | O resultado compensa o esforço? | Eficiência operacional estável ou crescente por períodos consecutivos (Dimensão 2) | — | — |

**Regras:**

1. **Conteúdo e canais em exploração não precisam demonstrar lucro.** Encerrar um pilar no estágio 1 por falta de vendas é um erro de leitura.
2. **Visualizações e engajamento nunca são prova de viabilidade comercial.** Eles só autorizam passar ao estágio seguinte, não ampliar investimento.
   - **Ressalva para canais novos:** cliques qualificados só são exigidos quando o canal permite links clicáveis. Em canais novos, especialmente no YouTube antes dos recursos avançados (seção 3.2.3), o estágio 2 usa indicadores alternativos de progressão, como a passagem de Shorts para vídeos longos, espectadores recorrentes e visitas a conteúdo comercial. O canal não é penalizado pela falta de uma funcionalidade ainda indisponível.
3. **Cada estágio tem um período máximo [A definir].** Se os critérios não forem atingidos nesse período, a ação é ajustar ou encerrar (seção 14.2), e não permanecer indefinidamente no mesmo estágio.
4. **Os estágios 4 e 5 são apurados por marca** (seção 12.4). Com um único canal na Fase B, o resultado da marca coincide com o do canal. Com mais de um canal, a parte de cada um é estimativa.
5. As três dimensões financeiras (seção 12) continuam valendo em todos os estágios: o que muda é qual delas decide o avanço.

Os valores concretos de cada critério são **[A definir]**, conforme `PROJECT_VISION.md` seção 3 (critérios definidos antes de começar).

### 13.3 Cuidados

- Um experimento por vez, por canal, quando possível.
- Não concluir a partir de um único conteúdo viral ou de um mês fraco.
- Considerar a defasagem entre venda e dinheiro recebido (12.1) ao definir os períodos.
- Experimentos nunca violam as regras de conteúdo, transparência e privacidade.

---

## 14. Otimização baseada em resultados

### 14.1 Ciclo de revisão **[Proposta]**

Periodicidade **[A definir]** (sugestão: mensal na Fase B).

1. Coletar as três dimensões da seção 12.
2. Identificar o que trouxe resultado, o que trouxe audiência qualificada e o que não trouxe nada.
3. Na primeira implementação, gerar recomendações; o sistema não aplica alterações automaticamente.
4. Em uma evolução futura, ajustes operacionais reversíveis poderão ser aplicados automaticamente somente quando estiverem cobertos por política previamente autorizada, dentro de seus limites e condições (`ARCHITECTURE.md` seção 4.10; `AUTONOMY_AND_AGENTS.md` seções 3 e 4).
5. Ações fora da política exigem aprovação humana. Otimizações com gasto, compras ou compromissos financeiros seguem a regra específica da seção 15 e não são autorizadas por esta seção.

### 14.2 Ações possíveis

| Situação | Ação sugerida |
|---|---|
| Vídeo de conexão com boa retenção e boa passagem para o comercial | Produzir mais sobre o mesmo pilar; criar derivadas |
| Conteúdo comercial com cliques e sem vendas | Revisar a adequação produto-audiência e a pré-qualificação |
| Conteúdo comercial com reembolso alto | Revisar o produto; avaliar retirá-lo |
| Muitas visualizações de Shorts sem passagem para vídeos longos | Revisar a ponte e o alinhamento com o pilar (3.2.6) |
| Pilar sem tração depois do período definido | Ajustar ou encerrar o pilar |
| Canal sem sinais depois do período definido | Ajustar ou encerrar o canal; reavaliar a seção 3.2.7 |

### 14.3 O que não otimizar

Não otimizar para visualizações, seguidores ou cliques isolados. A régua depende do estágio (seção 13.2):

- **Estágios 1 e 2:** otimizar retenção, engajamento, interesse e passagem entre estágios, sempre com a qualidade de `CONTENT_STRATEGY.md` seção 14. Esses indicadores orientam o conteúdo, mas não justificam ampliar investimento.
- **Estágio 3:** otimizar a qualidade dos cliques e as vendas confirmadas na marca, lendo a associação ao canal ou à peça como estimativa (seção 12.4).
- **Estágio 4:** o avanço se baseia no resultado financeiro realizado (Dimensão 1). Eficiência operacional positiva (Dimensão 2) não é exigida neste estágio.
- **Estágio 5:** resultado financeiro realizado e eficiência operacional são avaliados em conjunto (Dimensões 1 e 2).
- **Escala:** só depois de atendidos os critérios do estágio 5 (seção 15.2.2).
- **Continuar, ajustar ou encerrar:** segue os critérios e o período máximo do estágio em que o canal está (seção 13.2).

---

## 15. Mídia paga futura

### 15.1 Situação **[Acordado]**

Fora do escopo atual. Nenhum gasto sem autorização explícita. A arquitetura prevê, para o futuro, a tabela `ad_spend`, limites de gasto e kill switch (`ARCHITECTURE.md` seção 4.11).

### 15.2 Condições prévias **[Proposta]**

A mídia paga se divide em dois níveis, com exigências diferentes.

- **Por que a Etapa 4 não basta para escalar:** resultado positivo mostra que o dinheiro chega, mas não que a operação aguenta mais volume. Escalar anúncios aumenta revisão, conformidade e acompanhamento; sem eficiência por hora demonstrada, o esforço pode crescer mais que o resultado. A Etapa 5 é essa evidência.
- **Por que admitir testes antes da Etapa 5 [Hipótese]:** um teste pequeno mede algo que nenhum dado orgânico responde (se a mídia paga funciona para um conteúdo que já vende), com risco limitado por orçamento fechado e critério de parada. Se o proprietário preferir, os testes também podem ficar para depois da Etapa 5.

#### 15.2.1 Teste controlado e limitado

Todas as condições precisam ser verdadeiras:

1. O canal orgânico chegou ao **estágio 4** (seção 13.2): resultado financeiro realizado positivo.
2. Há vendas e resultado financeiro confirmados **no nível da marca e do período**. O conteúdo escolhido para o teste tem **sinais comerciais estimados** (cliques qualificados, vendas associadas por estimativa), sem que se afirme que ele gerou uma venda confirmada enquanto a atribuição não estiver validada (seção 12.4).
3. O orçamento vem de **dinheiro efetivamente recebido**, nunca de comissões pendentes ou liberadas e não sacadas (**[Acordado]**).
4. O orçamento é **fechado**, com prazo, teto de gasto e critério de parada definidos antes; o valor é **[A definir]** pelo proprietário a cada teste (este documento não fixa valores).
5. **Regra atual:** gasto e campanhas ficam fora das políticas por padrão; portanto, cada teste exige aprovação individual do proprietário. Uma política futura poderá autorizar execuções dentro de limites específicos somente se for aprovada expressamente, com marca, plataforma, finalidade, período, teto de gasto e critério de parada definidos (`AUTONOMY_AND_AGENTS.md` seções 3 e 4). Essa possibilidade não autoriza gastos agora.
6. As regras do criador do produto permitem anúncios (**[A verificar]** por produto; [Termos de Uso da Hotmart](https://hotmart.com/pt-br/legal/termos-de-uso)), e as políticas de anúncios da plataforma foram verificadas para o tipo de produto.
7. O teste não se renova automaticamente nem amplia seu orçamento; repetir exige nova aprovação ou deve estar expressamente coberto por política ainda válida.

#### 15.2.2 Expansão ou escala de investimento

Além das condições 3 a 6 do teste:

1. O canal chegou ao **estágio 5** (seção 13.2): resultado financeiro positivo **e** eficiência operacional demonstrada por períodos consecutivos.
2. Pelo menos um teste controlado foi concluído e avaliado pelas Dimensões 1 e 2.
3. A capacidade de revisão humana comporta o volume adicional (`CONTENT_STRATEGY.md` seção 8.4).
4. Orçamento, teto e critérios de parada aprovados pelo proprietário; nenhum valor é fixado neste documento.

### 15.3 Ordem sugerida, se um dia for aprovada **[Hipótese]**

1. Teste controlado (15.2.1): impulsionar um conteúdo orgânico com sinais comerciais estimados, numa marca com vendas confirmadas, com orçamento fechado e prazo fixo.
2. Medir pela Dimensão 1 e acompanhar a Dimensão 2 (seção 12). No estágio 4, a Dimensão 2 é registrada, mas não é exigência para aprovar ou concluir o teste (seção 14.3).
3. Só depois do estágio 5, avaliar expansão (15.2.2) ou campanhas próprias.

### 15.4 Regras permanentes

- Anúncios seguem as mesmas regras de transparência, de não enganar e de não prometer resultado.
- O kill switch e os limites de gasto são obrigatórios antes do primeiro centavo.

---

## 16. Privacidade e coleta de dados

### 16.1 Alcance

Aplica-se a qualquer integração futura de análise e aquisição: Google Analytics 4 e outras ferramentas de análise de tráfego, formulários e listas de e-mail, rastreamento de cliques e dados de conversão e vendas. **Nada disso existe hoje nem é recomendado agora**; esta seção define os princípios para quando houver necessidade.

### 16.2 Base legal **[Fato verificado]**

A LGPD exige que o tratamento de dados pessoais observe a boa-fé e princípios como **finalidade**, **adequação**, **necessidade** (mínimo necessário), **transparência**, **segurança**, **prevenção** e **responsabilização** ([LGPD, art. 6º](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm)). Quando a base for o consentimento, ele deve ter finalidade determinada, autorizações genéricas são nulas, cabe ao controlador provar que o obteve e ele pode ser revogado de forma gratuita e facilitada ([LGPD, art. 8º](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm)). O titular tem direitos de acesso, correção, eliminação e revogação, entre outros ([LGPD, art. 18](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm)).

### 16.3 Princípios do projeto **[Proposta]**

1. **Finalidade antes da ferramenta:** nenhuma coleta começa sem uma pergunta de negócio concreta que ela responda.
2. **Necessidade:** preferir dados agregados das próprias plataformas (YouTube Analytics, painel da Hotmart) a coletar dados próprios.
3. **Nenhum dado pessoal em links, parâmetros ou ferramentas de análise.** **[Fato verificado]** O Google proíbe enviar ao Analytics dados que permitam identificar pessoas, inclusive em URLs e parâmetros de campanha ([Google Analytics — Avoid sending PII](https://www.support.google.com/analytics/answer/6366371)), e exige informar os usuários sobre cookies e obter consentimento quando a lei exigir ([Google Analytics — Safeguarding your data](https://support.google.com/analytics/answer/6004245?hl=en)).
4. **Transparência:** política de privacidade publicada **antes** de qualquer coleta, explicando o que é coletado, para quê, por quanto tempo e como revogar.
5. **Dados de compradores:** o histórico de vendas da Hotmart contém dados pessoais de compradores ([Hotmart — Sales history](https://developers.hotmart.com/docs/pt-BR/v1/sales/sales-history/)). Para métricas, basta o agregado (quantidade, valor, status, origem). **Não armazenar nome, e-mail ou documento de compradores** sem finalidade concreta e definição jurídica (`PROJECT_VISION.md` seção 8).
6. **Segurança:** dados e credenciais separados por marca, com privilégio mínimo (`ARCHITECTURE.md` seção 10).
7. **Retenção limitada:** definir prazo de guarda e eliminação para cada tipo de dado antes de coletá-lo.
8. **Sem coleta para treinar IA** a partir de dados da Hotmart ([Termos de Uso da Hotmart](https://hotmart.com/pt-br/legal/termos-de-uso)).
9. **Revisão jurídica:** bases legais, papéis de controlador e operador e uso de cookies **[A verificar com profissional qualificado]**.

### 16.4 Ordem de adoção recomendada

1. **Agora:** apenas dados agregados das plataformas e parâmetro `src` sem dado pessoal.
2. **Com site:** ferramenta de análise configurada sem dados pessoais, com política de privacidade e aviso de cookies conforme a lei.
3. **Com necessidade comprovada:** lista de e-mail com consentimento (seção 7).

---

## 17. Decisões pendentes e hipóteses abertas

| # | Item | Tipo | Responsável ou fonte |
|---|---|---|---|
| 1 | ~~Aprovar ou não o YouTube como canal da Fase B~~ **Resolvido em 04/11/2026 (L2):** YouTube é o canal inicial prioritário | Decisão | Proprietário |
| 2 | Confirmar se Shorts e vídeos longos contam como um único canal | Decisão | Proprietário |
| 3 | Como obter os recursos avançados do YouTube numa marca Ghost Commerce (histórico do canal ou verificação do proprietário principal) | Decisão após verificação | [YouTube — Feature access](https://support.google.com/youtube/answer/9890437?hl=en), consultado em 04/11/2026 |
| 4 | Gatilhos e momento de incorporar um site próprio (seção 3.2.7) | Decisão futura | Proprietário |
| 5 | Executar o protocolo de validação da atribuição (seção 11.4) e definir o critério de saída | Verificação e decisão | Documentação Hotmart (04/11/2026); dados reais |
| 6 | Método técnico de rastreamento de cliques (`ARCHITECTURE.md` 4.8) | Decisão técnica | Proprietário e desenvolvimento |
| 7 | Registro da taxa de saque: valor líquido (recomendado) ou bruto com despesa; confirmar se a taxa varia conforme o valor (seção 12.1) | Decisão e verificação | Proprietário; [Hotmart — Taxas](https://help.hotmart.com/pt-br/article/208298448/quais-sao-as-taxas-cobradas-pela-hotmart-), consultado em 04/11/2026 |
| 8 | Possibilidade de descontos tardios de reembolso após a liberação | Verificação externa | Hotmart |
| 9 | Tratamento fiscal das comissões | Verificação externa | Profissional qualificado |
| 10 | Critérios numéricos e período máximo de cada estágio de validação (seção 13.2) | Decisão | Proprietário, antes do início |
| 10a | Critério de evidência suficiente para usar a atribuição em decisões (seções 11.4 e 12.4) | Decisão | Proprietário, após o protocolo de validação |
| 10b | Permitir testes controlados de mídia paga no estágio 4 ou só no 5; valor e prazo de cada teste (seção 15.2) | Decisão futura | Proprietário |
| 11 | Tempo para resultados orgânicos; demanda real do nicho | Hipótese | Dados próprios |
| 12 | Regras de link e divulgação no TikTok e no Instagram, e da "promoção paga" do YouTube para afiliados | Verificação externa | Páginas oficiais, antes de usar cada canal |
| 13 | Momento de iniciar lista de e-mail e coleta de dados (seções 7 e 16) | Decisão futura | Proprietário, com revisão jurídica |
| 14 | Aprovação formal deste documento | Decisão | Proprietário |
| 15 | ~~Distribuir peças em canais secundários antes da validação do YouTube~~ **Resolvido em 05/11/2026:** só depois da validação do YouTube; pesquisa e preparação podem ocorrer antes (seção 1.2, regra 2) | — | — |
| 16 | ~~Definição de "comissão confirmada"~~ **resolvida em 05/11/2026** (seção 12.1.1). Continua aberto: uso do resultado comercial confirmado em algum estágio | Decisão | Proprietário |
| 17 | ~~Granularidade geral da aprovação operacional~~ **Resolvido em 05/11/2026:** políticas autorizam tarefas delimitadas. Salvaguarda editorial de 06/11/2026: cada peça pública exige aprovação individual; nichos/produtos/ofertas também exigem decisão do proprietário (`AUTONOMY_AND_AGENTS.md` seção 4). **Em 12/11/2026 (decisão conceitual):** a aprovação individual é regra da fase inicial e vale para todo envio, inclusive privado; a evolução para publicação por política segue `AUTONOMY_AND_AGENTS.md` seção 4.3 e depende de decisão expressa do proprietário | — | — |
| 18 | Requisitos de API, auditoria e termos de automação de cada canal antes de automatizá-lo (seção 3.1) | Verificação externa | Páginas oficiais |

---


### 17.1 Validacao comercial sem metas arbitrarias **[Proposta]**

- Nao adotar taxas universais de retencao, CTR, conversao, cliques ou vendas como regra automatica de sucesso/fracasso. O desempenho depende do formato, origem do trafego, nicho, oferta, amostra e periodo.
- Definir previamente a pergunta de cada experimento, a metrica principal, o periodo de observacao e a evidencia minima necessaria. Registrar volume e contexto; amostras pequenas devem ser tratadas como inconclusivas, nao como prova.
- Separar alcance (impressoes/visualizacoes), interesse (retencao, visitas ao canal e cliques em recursos permitidos), intencao comercial (cliques qualificados) e resultado (vendas, comissoes confirmadas e dinheiro recebido).
- Nao interromper um produto ou nicho por um unico indicador isolado. Investigar primeiro se houve exposicao suficiente, se o link estava acessivel, se a atribuicao funcionou e se a oferta era pertinente.
- Metas numericas e prazos continuam **[A definir]** pelo responsavel antes de cada fase. Projecoes de 30/60/90 dias sao hipoteses de planejamento, nao previsoes de receita.

### 17.2 Shorts, links e limites de plataforma **[Proposta]**

- Nao presumir que links em descricoes ou comentarios de Shorts sejam clicaveis. Recursos de links, videos relacionados e links em videos longos dependem das regras e da elegibilidade vigentes da conta.
- Antes de desenhar o funil, verificar a documentacao oficial atual do YouTube para cada superficie de link e recurso de canal. Registrar data e requisito de elegibilidade; oferecer caminho alternativo permitido quando o link direto nao estiver disponivel.
- A estrategia nao deve depender de um unico recurso de plataforma nem prometer conversao direta a partir de todo formato.

### 17.3 Qualificacao de audiencia e expansao **[Proposta]**

- Conteudo de curiosidade ampla e uma hipotese de descoberta, nao evidencia automatica de audiencia compradora. Medir a passagem entre descoberta, conexao, cliques qualificados e vendas.
- Nichos como produtividade/neurociencia, ergonomia/saude fisica, tecnologia audiovisual e culinaria cientifica sao hipoteses a testar, nao nichos validados ou recomendacoes definitivas.
- A segunda marca e novos canais operacionais devem esperar evidencia de processo repetivel: qualidade editorial consistente, aquisicao relevante, atribuicao suficientemente confiavel, comissoes e caixa acompanhados, e esforco operacional conhecido.
- Preservar roteiros, fontes, arquivos finais, dados agregados e registros de campanha fora de uma unica plataforma. Uma suspensao ou restricao deve ser tratada pelos canais oficiais de recurso; nao presumir que criar outra conta/canal contorna a restricao ou e permitido.


## 17.1 Visão multicanal e internacional **[Acordado como destino]**

O negócio não será limitado ao YouTube nem a uma única rede de afiliados. A visão de destino inclui:
- YouTube (vídeos longos e curtos);
- Instagram, TikTok, Pinterest e outros canais adequados, com conteúdo adaptado;
- site/blog próprio, artigos, guias e SEO;
- mecanismos de busca e, quando viável, ativos próprios de audiência;
- mercados nacionais e internacionais, com conteúdos, ofertas e páginas localizados.

A ordem operacional permanece deliberada: validar o fluxo do YouTube primeiro; só então ativar canais adicionais um por vez, com critérios próprios de qualidade, atribuição, conformidade e esforço. Preparação e pesquisa dos canais futuros podem ocorrer antes, sem abrir integrações operacionais simultâneas.

## 17.2 Diversificação de redes e programas de afiliados **[Acordado como destino]**

Hotmart é uma possível integração inicial, não a única fonte de ofertas. A camada de aquisição e produtos deve poder trabalhar com diferentes redes/programas, incluindo candidatos como Amazon Brasil e internacional, Monetizze, Kiwify, ClickBank e outras redes pertinentes.

Cada rede deve ser avaliada separadamente quanto a:
- disponibilidade para o país e tipo de conta do proprietário;
- termos de uso, regras de tráfego, conteúdo e divulgação;
- API oficial, feeds ou métodos permitidos de importação;
- rastreamento e atribuição (cookies, parâmetros, janelas e relatórios);
- comissões, aprovação, reembolso, pagamento, moeda e tributação;
- qualidade e adequação dos produtos ao público da marca.
- janela de cookies, EPC, CPA e conversão, quando houver dados próprios ou fonte verificável;
- reputação e confiabilidade da rede e dos anunciantes;
- estabilidade e disponibilidade das APIs;
- condições contratuais e restrições de divulgação.

Além de redes, a visão inclui programas diretos de marcas e fabricantes, marketplaces com programa de afiliados e plataformas especializadas por nicho (`PROJECT_VISION.md` seção 14.1). Integrações são adicionadas, substituídas ou desativadas por adaptadores, sem reconstruir o núcleo.

Não presumir que todos os programas oferecem API de descoberta, dados equivalentes ou acesso automatizável. CSV/JSON e operação manual controlada continuam como contingência enquanto os meios oficiais não forem validados.

## 17.3 Internacionalização e aquisição localizada **[Acordado como destino]**

A expansão internacional exige mais do que traduzir conteúdo. Para cada mercado, validar idioma e variante regional, demanda, intenção de busca, cultura, oferta disponível, moeda, formas de pagamento, termos da rede, divulgações publicitárias, privacidade e obrigações legais/fiscais.

O Brasil é o primeiro mercado; a França é o primeiro mercado internacional, com pesquisa e preparação em paralelo e piloto só quando a operação específica estiver preparada e autorizada. Cada país tem estratégia, parceiros e canais próprios; exemplos e critérios em `PROJECT_VISION.md` seção 15.

Os dados de aquisição devem preservar país/mercado, idioma, moeda original, rede, produto, marca, canal e campanha quando disponíveis. Relatórios consolidados podem converter moedas, mas devem preservar valor original, taxa, fonte e data da conversão.

## 17.4 Blog/site próprio como canal de aquisição **[Acordado como destino]**

O site/blog próprio integra a estratégia futura de aquisição e monetização:
- artigos originais e aprofundados baseados em pesquisa documentada;
- guias e comparativos com intenção de busca;
- páginas de apoio aos vídeos e conteúdos de redes sociais;
- links de afiliados contextualizados e divulgados;
- SEO e, quando justificado, ferramentas de análise e Search Console.

O site não deve ser apenas uma coleção de textos gerados em massa. A publicação depende de valor editorial, revisão factual, atualização e aprovação humana. Sua ativação será faseada conforme orçamento, capacidade e evidência de que agrega um canal de aquisição independente.

## 17.5 Monetização complementar **[Acordado como destino; elegibilidade a verificar]**

Além das comissões de afiliados, podem ser avaliadas receitas de anúncios e programas de criadores (por exemplo, AdSense e mecanismos equivalentes), de acordo com requisitos de elegibilidade, país, canal e políticas vigentes.

Essas receitas devem ser medidas separadamente das comissões. Não presumir aprovação, monetização imediata ou valores mínimos de receita. A prioridade é construir audiência qualificada e conteúdo útil; monetização complementar não deve incentivar volume sem qualidade.

## 17.6 Operação inicial como pessoa física **[Intenção; validação obrigatória]**

A intenção do proprietário é começar como pessoa física, utilizando CPF, evitando custos fixos de pessoa jurídica enquanto a operação for pequena e isso for legalmente adequado. Não presumir isenção tributária, dispensa de declaração ou enquadramento específico. Antes de operar em escala, receber pagamentos internacionais ou ampliar fontes de receita, validar com contador/profissional qualificado as obrigações tributárias, cadastrais, cambiais e de consumo aplicáveis no Brasil e nos mercados atendidos.

## 18. Histórico de revisões

| Versão | Data | Mudanças |
|---|---|---|
| 3.1 | 08/11/2026 | Critérios adicionais de avaliação de redes e programas (cookies, EPC/CPA, reputação, APIs, contrato) e programas diretos de marcas (17.2); Brasil e França como primeiros mercados, com remissão à visão (17.3). |
| 3.1 | 12/11/2026 | Pendência 17 (seção 17): registrada a decisão conceitual de 12/11/2026 (aprovação individual como regra da fase inicial, válida para todo envio; evolução por política em `AUTONOMY_AND_AGENTS.md` seção 4.3). Nenhuma outra alteração. |
| 3 | 06/11/2026 | Formaliza a visão de destino multicanal/global, diversificação de redes de afiliados, blog/site e SEO, monetização complementar e intenção inicial de pessoa física sujeita a validação; mantém YouTube como primeiro canal operacional. |
| 1 | 04/11/2026 | Versão inicial |
| 2 | 04/11/2026 | YouTube (longo + Shorts) como canal preferencial **proposto**, com análise completa e caminho para o site (3.2); recursos avançados do YouTube (3.1, 3.2.3, 5); atribuição reclassificada como capacidade em investigação, com protocolo de validação (11); métrica financeira dividida em três dimensões, sem dupla contagem de reembolsos (12); estágios de validação ajustados (13.2); lista de e-mail adiada (7); nova seção de privacidade e coleta de dados (16); pendências atualizadas (17) |
| 2.1 | 04/11/2026 | Revisão pontual: fonte específica da taxa de saque e ressalva de variação (12.1, item 4); granularidade entre resultado realizado, métricas de conteúdo e atribuição estimada (12.4); critérios por maturidade em cada estágio (13.2) e régua de otimização por estágio (14.3); separação entre teste controlado (estágio 4) e expansão (estágio 5) na mídia paga (15.2, 15.3); pendências 7, 10, 10a e 10b (17). Estrutura: 18 seções (1 a 15 temáticas; 16 Privacidade; 17 Pendências; 18 Histórico) |
| 2.2 | 04/11/2026 | Ajustes pontuais: nenhuma fonte isolada comprova atribuição individual (12.4, regra 4); ressalva de cliques qualificados para canais sem links clicáveis (13.2, sob a regra 2); relação entre as Dimensões 1 e 2 e os estágios 4, 5 e escala (14.3); teste de mídia paga baseado em vendas confirmadas na marca e sinais estimados no conteúdo (15.2.1, condição 2; 15.3, passo 1, por coerência). Nenhuma seção renumerada |
| 2.3 | 04/11/2026 | Ajustes pontuais: vendas do estágio 3 confirmadas na marca, com associação ao canal estimada (13.2, linha do estágio 3; 14.3, item do estágio 3); Dimensão 2 acompanhada, mas não exigida, em teste no estágio 4 (15.3, passo 2). Nenhuma seção renumerada |
| 2.4 | 04/11/2026 | Harmonização com as decisões L1 e L2: princípios acordados (1.1); regra "um canal por vez" restrita à validação (1.2); Pinterest e Google na avaliação de canais, com fatos de automação por API (3.1); YouTube acordado como canal inicial (3.2); trabalho manual só temporário (3.2.3, 3.2.4); Dimensão 1 renomeada "resultado realizado em caixa" e marcada como acordada (12.1); novo indicador complementar "resultado comercial confirmado" (12.1.1, 12.4); horas humanas como supervisão (12.2); pendências 1 resolvida e 15 a 18 novas (17). Nenhuma seção renumerada; nova subseção 12.1.1 |
| 2.5 | 05/11/2026 | Harmonização com as decisões de 05/11/2026: ordem dos canais, fases A e B, aprovação por política e operação manual só como contingência (1.1); canais secundários só depois da validação do YouTube (1.2, regra 2); Google como tráfego orgânico por site próprio e SEO (3.1); comissão confirmada acordada (12.1.1); referência de aprovação do teste de mídia paga corrigida (15.2.1, item 5); itens 15, 16 (parcial) e 17 resolvidos (17). Nenhuma seção renumerada |
| 2.6 | 05/11/2026 | Secao 14: separada a implementacao inicial baseada em recomendacoes da evolucao futura de ajustes dentro de politicas autorizadas. Secao 15.2.1: confirmada a regra atual de aprovacao individual para gasto/campanhas fora de politica; eventual politica futura exige autorizacao expressa e limites. Nenhum gasto autorizado. |
