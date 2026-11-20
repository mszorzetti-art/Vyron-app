# Affiliate Autopilot — Visão de longo prazo

> **O que este documento é:** a descrição do negócio que queremos construir. Ele **não** descreve o que já existe (isso está em `PROJECT_STATUS.md`) e **não** define metas financeiras, projeções de vendas, prazos obrigatórios nem garantias de receita.
>
> **Revisão 7.2 — 12/11/2026 (consolidação da especificação de autorização de publicação):** a aprovação individual de cada peça passa a ser descrita como regra da fase inicial, não como limitação definitiva da arquitetura; a publicação poderá evoluir para execução dentro de políticas previamente autorizadas, por decisão expressa do proprietário. Produtos, nichos, marcas, ofertas e decisões comerciais estratégicas permanecem sob decisão do proprietário. As regras estão em `AUTONOMY_AND_AGENTS.md` seção 4; este documento apenas as referencia (seções 1, 3, 6, 12 e 21). A revisão 5, de 06/11/2026, tinha cabeçalho de proposta e corpo marcado como **[Acordado]**: o status histórico é ambíguo e não equivale à aprovação definitiva de todo o seu conteúdo. Nada implementado; nenhuma política ativada.
>
> **Revisão 7.3 — 14/11/2026 (reconciliação documental):** só atualização de fatos, sem mudar a visão nem as decisões: a linha "Implementado" da seção 13 passa a refletir os Lotes 6 a 9, integrados à `main`; as notas sobre o `PRODUCT_ROADMAP.md` (que existe desde 14/11/2026) e a nota do critério A para B (seção 10) foram corrigidas; a seção 5 registra a situação real do `brand_id`.
>
> **Revisão 7 — 08/11/2026 (proposta para aprovação):** acrescenta a camada conceitual de Compliance Intelligence (seção 17.1), com referências regulatórias gerais da União Europeia e da França confirmadas pela pesquisa do responsável, pendências por categoria e enquadramento, estados conceituais de conformidade e responsabilidade por modelo comercial. Não implementado; não amplia o MVP.
>
> **Revisão 6 — 08/11/2026 (proposta para aprovação):** consolida a visão de longo prazo do proprietário: diversificação de modelos de negócio (afiliados em várias redes, dropshipping nacional e internacional, lojas próprias, marketplaces, monetização de conteúdo), Brasil como primeiro mercado e França como primeiro mercado internacional, central de inteligência com operações independentes, inteligência de produtos e fornecedores, aprendizado contínuo, inteligência financeira por modelo de negócio e horizontes de evolução (5 meses a 6+ anos). Mudanças nas seções 2, 4 e 11.4 e novas seções 13 a 21. **Nada disso altera a prioridade atual (concluir e validar a operação de afiliados) nem descreve funcionalidade existente**; o que existe está na seção 13 e em `PROJECT_STATUS.md`.
>
> **Revisão 5 — 06/11/2026 (proposta para aprovação):** explicita a visão completa do proprietário: operação privada (não SaaS), mídia multicanal e internacional, múltiplas redes de afiliados, monetização complementar, blog/site próprio e aprovação editorial humana pelo celular. O sequenciamento do MVP não reduz o escopo de destino. Mudanças nas seções 1, 2, 3, 4, 6, 8, 9 e 10.
>
> **Revisão 2 — 04/11/2026:** incorpora as decisões L1, L2, L6 e L7 aprovadas pelo responsável em 04/11/2026. Mudanças na seção 11. Documentos de longo prazo: `FUTURE_ARCHITECTURE.md`, `PRODUCT_ROADMAP.md` e `AUTONOMY_AND_AGENTS.md`. *(Nota de 07/11/2026, atualizada em 14/11/2026: o `FUTURE_ARCHITECTURE.md` nunca foi criado; a arquitetura de destino está em `ARCHITECTURE.md` seções 12.1 a 12.6. O `PRODUCT_ROADMAP.md` existe desde 14/11/2026 e traz a sequência de etapas; o estado verificado continua em `PROJECT_STATUS.md`.)*
>
> **Legenda:**
> - **[Acordado]**: decisão do responsável pelo projeto.
> - **[Proposta]**: sugestão para revisão; ainda não aprovada.
> - **[Hipótese]**: acreditamos, mas não foi validado com dados reais.
> - **[A definir]**: depende de uma decisão ou de um dado que ainda não existe.

## 1. Missão e objetivos

**Missão [Acordado]:** construir uma operação digital própria, sustentável, mensurável, escalável e progressivamente automatizada, que opere marcas e ativos de mídia do proprietário para gerar receita. **O Affiliate Autopilot é uma ferramenta privada de uso próprio: não será vendido como SaaS, licença, assinatura ou serviço para terceiros.**

**Objetivos [Acordado]:**
1. Começar por marketing de afiliados, priorizando aquisição orgânica e custos iniciais reduzidos.
2. Medir o desempenho de cada marca separadamente.
3. Automatizar aos poucos, mantendo aprovação humana nas ações importantes.
4. Evoluir, a longo prazo, para o modelo **Ghost Commerce**.

**Objetivo de automação operacional [Acordado — L2, 04/11/2026]:**
- O sistema deve ser projetado para automatizar pesquisa, produção, adaptação, agendamento, publicação e análise.
- O responsável **não deve depender de trabalho operacional manual recorrente**. Seu papel é principalmente supervisionar, definir diretrizes e aprovar decisões relevantes.
- Trabalho manual só existe como solução **temporária** de validação ou contingência técnica, nunca como modelo operacional definitivo.
- A automação respeita as APIs, as políticas e os limites de cada plataforma. Soluções gratuitas e de código aberto têm prioridade quando forem tecnicamente viáveis, **sem presumir** que toda automação será gratuita ou permitida.

**Distribuição multicanal e multiplataforma [Acordado]:** a visão de destino inclui YouTube, Instagram, TikTok, Pinterest, site/blog próprio, busca orgânica e outros canais que se mostrarem viáveis. O YouTube é apenas o primeiro canal operacional, não o limite do negócio. A expansão será sequencial, validando um fluxo por vez, sem desenvolver ou operar todos simultaneamente.

**Ordem dos canais [Acordado — 05/11/2026]:**
- O YouTube é o primeiro canal operacional.
- Instagram, TikTok e Pinterest só entram na integração operacional depois da validação do fluxo do YouTube; pesquisa e preparação técnica desses canais podem ocorrer antes.
- Google, na estratégia de aquisição, significa tráfego orgânico por site próprio e SEO.

**Central de controle móvel [Acordado como visão de destino]:** o proprietário deverá conseguir acompanhar a operação e tomar decisões pelo celular, por meio de painel/aplicativo móvel. A interface móvel é parte da experiência final pretendida; a implementação pode começar por uma interface web responsiva e evoluir, sem exigir aplicativo nativo para concluir o MVP.**

**Aprovação humana editorial [Acordado]:** antes de qualquer publicação pública, o proprietário deverá revisar e aprovar a versão exata do conteúdo, incluindo roteiro/peça, título, descrição, links e divulgações. A seleção de nichos, marcas, produtos e ofertas também deve ser submetida à decisão do proprietário antes de orientar uma campanha ou conteúdo comercial. A automação prepara e recomenda; não substitui essas decisões. **[Decisão conceitual — 12/11/2026]** A aprovação individual de cada peça é a regra da fase inicial e vale para todo envio a uma plataforma, público ou privado; não é uma limitação definitiva da arquitetura. A publicação de conteúdo editorial comum poderá evoluir para execução automática dentro de políticas previamente autorizadas, por decisão expressa do proprietário (`AUTONOMY_AND_AGENTS.md` seções 4.2 e 4.3). Nichos, marcas, produtos, ofertas e decisões comerciais estratégicas permanecem sempre sob decisão do proprietário, e o sistema nunca altera sozinho suas políticas, seus limites financeiros ou seu nível de autonomia (seção 4.1 do mesmo documento).

**Operação manual [Acordado — 05/11/2026]:** importação manual de métricas ou vendas e publicação manual podem existir como contingência ou etapa temporária de validação, nunca como solução operacional definitiva.

**Sobre o termo.** "Ghost Commerce" é o nome que o responsável adotou para o modelo de longo prazo. Aqui ele é descrito só pelas características acordadas: múltiplas marcas independentes, geridas por uma infraestrutura compartilhada, com automação híbrida. Uma definição mais detalhada é **[A definir]**.

## 2. Modelo de negócio e fontes potenciais de receita

| Fonte | Situação | O que precisa ser validado |
|---|---|---|
| Comissões de afiliados (ponto de partida) | **[Acordado]** | Comissões reais, reembolsos e prazos de pagamento; o que a plataforma permite automatizar |
| Outras redes de afiliados | Direção futura **[Acordado]** | Termos, comissões e disponibilidade de cada rede |
| Mercados internacionais | Direção futura **[Acordado]** | Idioma, regras locais, moeda, tributação |
| Produtos digitais próprios | Direção futura **[Acordado]** | Demanda, esforço de produção, suporte ao cliente |
| Monetização direta de canais (ex.: AdSense e programas de criadores) | Fonte complementar futura **[Acordado como objetivo; elegibilidade a verificar]** | Requisitos de elegibilidade, políticas, disponibilidade por país/canal e receita efetiva |
| Conteúdo editorial em site/blog próprio | Ativo de aquisição e monetização futuro **[Acordado]** | Domínio/hospedagem, SEO, privacidade, manutenção, tráfego e adequação dos links |
| Print on demand | Direção futura **[Acordado]** | Fornecedores, margens, qualidade, logística |
| Dropshipping nacional e internacional | Parte da visão de destino **[Acordado — 08/11/2026]**; ativação só **"se viável"** **[Acordado]** | Viabilidade logística, legal e de margem por mercado; qualidade e confiabilidade dos fornecedores; atendimento, devoluções e garantias (seção 14.2) |
| Lojas virtuais próprias e venda em marketplaces | Direção futura **[Acordado — 08/11/2026]** | Catálogo, pagamentos, frete, devoluções, atendimento, tributação e margem por mercado (seção 14.3) |

Os tipos de receita (monetização de conteúdo, comissão, receita bruta de loja, margem de dropshipping, lucro operacional e caixa recebido) nunca se confundem nos relatórios (seções 14.5 e 18).

**Custos a acompanhar:** hospedagem e domínios, ferramentas, anúncios (só no futuro e com aprovação), taxas de plataformas e o tempo de trabalho. Nenhum valor está definido aqui.

## 3. Estratégia inicial de validação comercial **[Proposta]**

Objetivo: descobrir, com dados reais e gasto mínimo, se o modelo funciona antes de ampliá-lo.

1. **Começar pequeno:** uma marca, um nicho e um canal de aquisição orgânica, sem anúncios pagos. O canal inicial prioritário é o **YouTube** **[Acordado — L2]**. Os demais canais entram na integração operacional só depois da validação do fluxo do YouTube (seção 1; `ACQUISITION_STRATEGY.md` seção 1.2).
2. **Produtos reais verificados:** escolher produtos com dados confirmados na plataforma, nunca valores inventados. A operação não ficará vinculada à Hotmart: outras redes e programas de afiliados nacionais e internacionais serão avaliados e integrados gradualmente, conforme termos, APIs, rastreamento, pagamentos e viabilidade.
3. **Conteúdo com aprovação individual na fase inicial:** o sistema prepara rascunhos e materiais; nesta fase, nenhuma peça é enviada a uma plataforma, em modo público ou privado, sem autorização individual do responsável sobre a versão exata. Políticas podem autorizar tarefas internas e preparatórias; na fase inicial, não substituem a autorização individual de cada envio (`AUTONOMY_AND_AGENTS.md` seção 4.2). A evolução por política segue a seção 4.3 do mesmo documento.
4. **Medir o ciclo completo:** clique, conversão, comissão confirmada, dinheiro recebido e custo (seção 7).
5. **Decidir com critérios definidos antes:** os limites que significam "continuar", "ajustar" ou "parar" serão fixados pelo responsável **antes** de começar. **[A definir]**

Perguntas a responder: há demanda no nicho? A plataforma permite o que pretendemos automatizar? Conseguimos atribuir vendas a conteúdos? Qual é o esforço real por unidade de resultado? A aquisição orgânica leva quanto tempo? **[Hipótese]**: ela pode ser lenta, e não há prazo prometido.

## 4. Da operação de afiliados ao Ghost Commerce **[Proposta]**

A sequência abaixo é uma proposta de ordem. Cada fase só começa quando os critérios da seção 10 forem cumpridos. As fases D a F são direções, sem compromisso de execução.

| Fase | Foco |
|---|---|
| A. Fundação técnica e validação controlada | Base testada, dados de demonstração; validação controlada e não pública, incluindo produção, verificações e publicação privada ou não pública em pelo menos um canal **[Acordado — 05/11/2026]** |
| B. Validação de afiliados | Operação pública controlada, somente após autorização explícita do responsável **[Acordado — 05/11/2026]**; uma marca, dados reais, ciclo completo medido |
| C. Replicação | Segunda marca reaproveitando a infraestrutura; testar a separação entre marcas |
| D. Expansão de redes, canais e mercados | Novas redes de afiliados nacionais/internacionais, novos canais de distribuição, site/blog e mercados internacionais, sempre por etapas e após evidência operacional. A expansão de canais segue os critérios de `ACQUISITION_STRATEGY.md` seção 13 |
| E. Produtos próprios | Produtos digitais e print on demand |
| F. Dropshipping e lojas próprias | Dropshipping nacional e internacional, lojas próprias e marketplaces, somente se a viabilidade for demonstrada (seção 14) |

**Preparação em paralelo [Acordado — 08/11/2026]:** pesquisa e preparação de fases futuras (novos mercados, como a França, redes de afiliados e fornecedores) podem ocorrer antes da fase correspondente, sem custo não autorizado e sem desviar o desenvolvimento do MVP. A **operação** de cada frente continua sujeita aos critérios da seção 10 e à autorização do proprietário. A possibilidade de um piloto francês antes da Fase C está registrada como ponto em aberto (seção 21).

## 5. Estratégia de múltiplas marcas e separação entre elas

**Acordado:** as marcas são **independentes** e compartilham uma **infraestrutura** comum.

| Dimensão | Separada por marca | Compartilhada |
|---|---|---|
| Identidade pública (nome, tom, visual) | Sim | - |
| Site e domínio | Sim | - |
| Contas (afiliado, analytics, anúncios) | Sim | - |
| Credenciais e permissões | Sim | - |
| Métricas, custos e lucro | Sim | - |
| Código, agendador, relatórios e regras de segurança | - | Sim |
| Banco de dados | Dados comerciais separados por marca, via `brand_id` **[Acordado — L6]** | Mesma instância e mesmo esquema |

**Importante:**
- **Nada disso é implementado agora**, exceto uma preparação mínima: o `brand_id` existe desde o primeiro esquema do banco, mesmo com uma única marca **[Acordado — L6]**. *(Situação em 14/11/2026: a tabela `brands` existe, vazia, e ainda não há nenhuma tabela comercial; `products` é catálogo compartilhado, sem `brand_id`. Toda tabela comercial futura nasce com `brand_id` obrigatório: `ARCHITECTURE.md` seção 4.3, decisão de 07/11/2026.)* Ele é uma dimensão transversal dos dados de negócio; não cria módulos por marca, bancos ou esquemas separados. O restante da estrutura multi-marca (contas, configuração e credenciais por marca) só entra depois da validação comercial.
- **[Hipótese a verificar]:** as plataformas podem limitar múltiplas contas ou marcas por pessoa. Conferir os termos de cada uma **antes** de criar a segunda marca.
- Independência entre marcas não autoriza ocultar quem opera quando lei ou plataforma exigir identificação (ver seção 8).

## 6. Automação híbrida e níveis de autorização

**Princípio [Acordado]:** automação híbrida, com tarefas automáticas e aprovação humana para ações importantes.

**Níveis [Acordado quanto ao modelo geral; classificação por ação ainda [A definir]]**. Os níveis descrevem permissões, mas a autorização efetiva deve ser definida por categoria de ação e política, não por um rótulo global:

| Nível | Descrição | Exemplos |
|---|---|---|
| 0 | Manual | Decisões estratégicas, escolha de nicho |
| 1 | Automático, somente leitura | Importar vendas, métricas, relatórios, alertas |
| 2 | Automático, produz rascunhos e recomendações | Briefings, rascunhos, pontuação de produtos |
| 3 | Automático **após aprovação humana** | Ações fora das políticas vigentes |
| 4 | **Autonomia operacional dentro de limites previamente autorizados** **[Acordado — 05/11/2026]** | Planejar, executar, corrigir e otimizar atividades dentro das políticas, permissões e limites |

**Nível 4 e aprovação por política [Acordado — 05/11/2026], com salvaguarda editorial adicional [Acordado — 06/11/2026]:**
- A aprovação por política pode autorizar tarefas internas, preparatórias e operacionais reversíveis dentro de limites.
- Na fase inicial, ela não substitui a autorização humana individual de cada envio de conteúdo, público ou privado (`AUTONOMY_AND_AGENTS.md` seção 4.2). A evolução para publicação por política depende de decisão expressa do proprietário, revisão de riscos e implementação validada (seção 4.3 do mesmo documento).
- Nichos, produtos e ofertas comerciais exigem decisão explícita do proprietário antes de orientar uma campanha.
- Ações fora dos limites autorizados exigem aprovação específica.

**Publicação pública [Acordado — 05/11/2026]:** só na Fase B, depois de autorização explícita, sempre respeitando limites, permissões e o botão de parada.

**Até a versão 2 deste documento, o nível 4 significava "sempre com aprovação explícita e limites"** e cobria gasto, campanhas, compras, novas contas, credenciais e ações irreversíveis. Proposta para essas ações em `AUTONOMY_AND_AGENTS.md` seção 3: ficam fora de qualquer política por padrão, e credenciais nunca entram numa política **[Proposta]**. A possibilidade de incluir futuramente gasto, compras ou campanhas em uma política exige decisão expressa e não constitui autorização atual para gastar; nenhuma despesa está autorizada neste momento.

**Regras permanentes:** capacidades de nível 3 e 4 permanecem desligadas por padrão até que exista política aprovada e implementação testada; dry-run, registro da política/autorização, limites, verificações e kill switch são obrigatórios. Nível 4 não concede permissões automaticamente: cada tipo de ação continua sujeito à sua política e às exclusões específicas.

**Papel do responsável [Acordado — L2]:** supervisão, diretrizes e aprovação de decisões relevantes, inclusive pela definição de políticas **[Acordado — 05/11/2026]**. Detalhes em `AUTONOMY_AND_AGENTS.md`.

## 7. Métricas de desempenho

Todas medidas **por marca**, com dados de teste sempre separados:

| Métrica | Observação |
|---|---|
| Cliques | Depende do método de rastreio escolhido; ver `ARCHITECTURE.md` 4.8 |
| Conversões | Vendas atribuíveis; a atribuição pode ser aproximada |
| Comissões | Separar pendentes, confirmadas, liberadas e reembolsadas; verificar como a plataforma informa **[A verificar]**. Comissão confirmada só depois da aprovação efetiva da plataforma, inclusive depois do período de garantia quando aplicável **[Acordado — 05/11/2026]** |
| Dinheiro recebido | Valor que efetivamente entrou na conta bancária |
| Custos | Hospedagem, domínio, ferramentas, anúncios e demais despesas atribuídas à marca |

**Dois indicadores financeiros independentes [Acordado — L1, 04/11/2026]:**

| Indicador | Definição | Para que serve |
|---|---|---|
| **Resultado comercial confirmado** | Comissões confirmadas menos custos atribuíveis | Sinal antecipado do desempenho comercial |
| **Resultado realizado em caixa** | Dinheiro efetivamente recebido menos despesas efetivamente pagas | Situação financeira real e base de qualquer reinvestimento |

**Regra obrigatória [Acordado — L1]:** reinvestimentos só podem usar **dinheiro efetivamente recebido**. Comissões pendentes ou apenas confirmadas não constituem orçamento disponível.

Os dois indicadores são apurados por marca e por período e nunca são somados nem substituídos um pelo outro. As regras detalhadas de apuração estão em `ACQUISITION_STRATEGY.md` seção 12.

**Não há metas numéricas neste documento.** Quando existirem, serão definidas pelo responsável e registradas com data.

## 8. Segurança, privacidade, direitos autorais, transparência e conformidade

- **Segurança:** credenciais só em locais seguros (nunca no código, nos logs ou no chat), separadas por marca, com privilégio mínimo, autenticação em dois fatores e revogação imediata em caso de suspeita. A verificação automática de segredos (Gitleaks) no CI é **requisito** antes do uso de qualquer credencial real **[Acordado — L7]**. Detalhes em `ARCHITECTURE.md`, seção 10.
- **Privacidade:** guardar o mínimo de dados pessoais de compradores (LGPD).
- **Direitos autorais:** conteúdo original ou com licença; imagens e textos de terceiros só com permissão; revisar tudo que for gerado por IA antes de publicar.
- **Transparência:** declarar de forma clara o vínculo de afiliado nos conteúdos. Não criar avaliações, depoimentos ou perfis falsos.
- **Conformidade:** respeitar os termos de cada plataforma (afiliados, buscadores, redes sociais, anúncios) e as regras de publicidade aplicáveis. **[A verificar]** as políticas de buscadores sobre conteúdo produzido em escala com automação.
- **Aspectos fiscais e legais** (enquadramento para receber comissões, por exemplo): **[A verificar com profissional qualificado]**. Este documento não é aconselhamento jurídico.

## 9. Riscos, dependências e hipóteses a validar

| Item | Tipo | Status |
|---|---|---|
| A aquisição orgânica gera tráfego qualificado em prazo viável | Hipótese | Não validado |
| As comissões cobrem os custos e o esforço | Hipótese | Não validado |
| A API da Hotmart cobre vendas e comissões de afiliado | Dependência | Não verificado |
| As plataformas permitem várias contas ou marcas | Dependência | Não verificado |
| Políticas de buscadores sobre conteúdo automatizado | Risco | Não verificado |
| Planos gratuitos (banco, agendador) bastam para o protótipo | Dependência | Não verificado |
| Uma pessoa consegue operar o fluxo de aprovação | Hipótese | Não validado |
| Dropshipping e print on demand são viáveis | Hipótese | Não validado |
| Suspensão de contas ou mudança de regras das plataformas | Risco | Aberto |
| As plataformas de distribuição permitem a automação pretendida (publicação por API, auditorias, cotas) | Dependência | Parcialmente verificado; ver `ARCHITECTURE.md` seção 7 |
| A automação de produção e publicação cabe no orçamento zero | Hipótese | Não validado; serviços de IA e hospedagem podem gerar custo |
| Complexidade prematura (construir antes de validar) | Risco | Mitigar seguindo a seção 10 |

## 10. Critérios para avançar de uma fase para outra

Regra geral: só avança quando os critérios estiverem cumpridos **e registrados** em `PROJECT_STATUS.md`. Limites numéricos são **[A definir]** pelo responsável antes de iniciar cada fase.

| Transição | Critérios mínimos |
|---|---|
| A para B | Validação controlada e não pública concluída, incluindo produção, verificações e publicação privada ou não pública em pelo menos um canal **[Acordado — 05/11/2026]**; testes e CI com resultado registrado; Gitleaks ativo no CI antes de qualquer credencial real; segredos conferidos; **autorização explícita do responsável** para a operação pública **[Acordado — 05/11/2026]** |
| B para C | Ao menos um ciclo completo (clique, venda, comissão) medido com dados reais; custo e esforço registrados; decisão de continuar tomada com critérios fixados antes; termos das plataformas sobre múltiplas marcas verificados |
| C para D | Segunda marca operando com separação de contas e dados comprovada; métricas por marca confiáveis |
| D para E | Resultado positivo medido em canais atuais; capacidade operacional avaliada |
| E para F | Viabilidade logística, legal e de margem demonstrada; decisão explícita do responsável |

**Nota sobre o critério A para B:** a versão 1 exigia "publicação em rascunho testada num site de teste" (WordPress). A versão 2 o reescreveu como proposta. A decisão de 05/11/2026 definiu o conteúdo da Fase A e a exigência de autorização explícita para a Fase B. As etapas de desenvolvimento necessárias não estão fixadas: o critério implica os blocos 6 e 7 do `ARCHITECTURE.md` (conteúdo e publicação não pública), ainda não iniciados. Os identificadores P1 a P14 de versões anteriores foram aposentados; a correspondência e a ordem proposta estão no `PRODUCT_ROADMAP.md` (seções 4 e 5), e o estado verificado, em `PROJECT_STATUS.md`.


### 9.1 Riscos operacionais prioritários **[Proposta]**

Os riscos devem ser acompanhados em `RISK_REGISTER.md`, com responsavel, controles, evidencias e estado. A prioridade e qualitativa e revisavel; nao representa probabilidade estatistica. Os principais grupos sao: bloqueio/restricao de contas; mudancas de API e politicas; expiracao/revogacao de tokens; vazamento de credenciais; publicacao duplicada ou nao autorizada; informacao factual incorreta; falha de atribuicao; reembolsos; perda/corrupcao do banco; execucoes interrompidas; custos inesperados; dependencia de provedor de IA; e decisoes automatizadas inadequadas.


## 11. Visão de mídia, conteúdo e operação global **[Acordado como destino]**

O projeto deve evoluir de uma operação inicial de afiliados para um ecossistema privado de mídia digital e comércio por conteúdo, administrado por uma infraestrutura central e operado em diferentes marcas, canais e mercados.

### 11.1 Ativos e canais previstos

A visão de destino contempla:
- canais de vídeo (conteúdo longo e curto);
- artigos, guias, pesquisas documentadas e páginas evergreen em sites/blogs próprios;
- distribuição adaptada para redes sociais e plataformas de vídeo;
- mecanismos de busca e tráfego orgânico;
- ativos próprios de audiência, quando houver base legal, consentimento e viabilidade;
- monetização por afiliados e fontes complementares permitidas pelas plataformas.

A lista define a direção do negócio, não uma ordem de implementação nem autorização para abrir contas ou integrar tudo imediatamente.

### 11.2 Redes e programas de afiliados

Hotmart é uma possibilidade inicial, não uma dependência estratégica exclusiva. A camada comercial deverá poder acomodar diferentes redes e programas, por adaptadores independentes. Candidatos a investigar incluem Amazon Brasil e programas internacionais, Monetizze, Kiwify, ClickBank e outras redes adequadas aos mercados e nichos escolhidos.

Nenhuma integração é presumida disponível, gratuita ou permitida. Antes de implementar cada adaptador, verificar documentação oficial, elegibilidade, país, termos, atribuição, política de links, comissões, reembolsos, pagamentos e requisitos fiscais.

### 11.3 Internacionalização

A arquitetura deverá permitir, quando chegar a fase correspondente:
- idioma e variante regional (`locale`);
- moeda original da transação e moeda de apresentação (`currency`);
- país/mercado, fuso horário e formatos locais;
- conteúdo localizado e links/ofertas próprios de cada mercado;
- relatórios que preservem valor e moeda originais, com conversões identificadas por taxa, fonte e data.

Não converter valores históricos sobrescrevendo a moeda original. Conversões para relatórios consolidados devem ser rastreáveis e não podem confundir receita efetivamente recebida com estimativas cambiais.

### 11.4 Cadência editorial como hipótese inicial

**Não existe frequência universal [Acordado — 08/11/2026]:** a frequência de cada marca e canal depende da identidade da marca, da intenção do público, do mercado, do canal e do desempenho medido. Referências por tipo de marca estão em `CONTENT_STRATEGY.md` seção 16.6. Para a primeira marca, a referência inicial de planejamento é um vídeo longo de alta qualidade aproximadamente a cada duas semanas, com cerca de 4 a 8 cortes derivados por ciclo e, quando houver capacidade, um artigo aprofundado relacionado. Esses números são hipóteses de cadência, não metas obrigatórias nem compromisso de publicação. Devem ser ajustados com base em qualidade, tempo de produção, desempenho, custo e capacidade de aprovação do proprietário.

### 11.5 Situação jurídica e fiscal inicial

A intenção inicial é operar como pessoa física, usando CPF, se isso for legal e operacionalmente adequado. Essa intenção não constitui conclusão tributária nem presume isenção, enquadramento ou dispensa de obrigações. Antes de receber comissões em escala ou atuar em outros países, validar com profissional qualificado as obrigações fiscais, cadastrais, cambiais, consumeristas e de publicidade aplicáveis.

## 12. Princípio de aprovação móvel e controle editorial **[Acordado]**

O proprietário deverá ter uma central móvel para revisar e decidir sobre os itens que exigem aprovação. O fluxo de destino é:

1. O sistema pesquisa, coleta fontes e dados, prepara recomendações e cria rascunhos.
2. O item fica em `in_review`, com versão identificada e materiais de apoio.
3. O painel móvel apresenta conteúdo, fontes, produto, link, divulgação e riscos relevantes.
4. O proprietário pode aprovar, rejeitar ou solicitar ajustes.
5. Somente a versão com autorização válida pode avançar para envio ou publicação.
6. Qualquer alteração posterior gera nova versão, que exige nova revisão e nova aprovação (`AUTONOMY_AND_AGENTS.md` seção 4.6).

O painel móvel é a experiência de destino. Já a exigência de aprovação individual de cada peça, nos passos acima, é a regra da fase inicial (`AUTONOMY_AND_AGENTS.md` seção 4.2), não uma limitação definitiva da arquitetura: a evolução para publicação por política segue a seção 4.3 do mesmo documento.

A aprovação de um nicho, produto ou campanha não equivale à aprovação automática de todas as peças futuras. A aprovação de uma peça também não autoriza gastos, criação de contas ou ações irreversíveis.

## 13. Situação atual versus visão de longo prazo

As seções 14 a 20 descrevem a **visão de longo prazo** consolidada em 08/11/2026. O Affiliate Autopilot não é só um automatizador de marketing de afiliados ou de publicação: o destino é uma **infraestrutura inteligente, modular, diversificada e progressivamente autônoma**, capaz de administrar várias marcas, mercados, canais e operações comerciais. Para não confundir presente e futuro:

| Situação | O que inclui | Fonte de verdade |
|---|---|---|
| **Implementado** (na `main`, em 14/11/2026) | Fundação (configuração, logs com redação de segredos, erros, CLI, dados de demonstração, CI com lint, formatação, testes e Gitleaks); modelo `Product` e importadores JSON e CSV com governança; banco PostgreSQL com migrador, gravação de produtos com histórico e importação persistente (Lote 5); pontuação de produtos com persistência e rankings (Lote 6); executor de lotes e reconciliação de execuções abandonadas (Lote 7); Stop All e trilha de auditoria (Lote 8); agendador de um lote em simulação, desabilitado por padrão (Lote 9). **Tudo validado só em banco descartável:** não existe banco hospedado, a gravação real da pontuação depende de infraestrutura ainda não configurada (condição C3) e nada publica nem se conecta a serviços externos | `PROJECT_STATUS.md` |
| **Em desenvolvimento** | Nenhum lote em andamento; o próximo depende de decisão do responsável | `PROJECT_STATUS.md`; `PRODUCT_ROADMAP.md` seção 9 |
| **Próxima etapa planejada** | Concluir, testar e validar a operação de afiliados no Brasil (Fases A e B, seções 4 e 10), nos blocos técnicos de `ARCHITECTURE.md` seção 8. A reconciliação de execuções órfãs (débito M2), exigida antes de qualquer execução agendada ou autônoma, está implementada desde o Lote 7; a operação real continua dependendo de banco hospedado e da condição C3 | `PRODUCT_ROADMAP.md` seção 4, `ARCHITECTURE.md`, `PROJECT_STATUS.md` |
| **Visão de longo prazo** | Tudo o que está nas seções 14 a 20 e não aparece nas linhas acima | Este documento |

**Regra:** nenhum item da visão é escopo de desenvolvimento até ser aprovado e sequenciado em lote. A visão orienta decisões pequenas de arquitetura (por exemplo, não acoplar o núcleo a uma única rede, moeda ou país), mas não justifica implementar módulos, contratar serviços ou criar infraestrutura antes da necessidade (seção 20).

## 14. Diversificação de modelos de negócio **[Acordado como destino — 08/11/2026]**

### 14.1 Afiliados sem dependência estrutural da Hotmart

A Hotmart pode ser uma das primeiras integrações, mas não é dependência estrutural (seção 11.2). O destino inclui redes nacionais e internacionais, programas diretos de marcas e fabricantes, marketplaces com programa de afiliados, plataformas especializadas por nicho e redes que surgirem no futuro.

**Critérios de seleção de cada rede ou programa [Proposta]:** país de operação e disponibilidade para afiliados nesse país; categorias e produtos disponíveis; comissão e regras de atribuição; janela de cookies; EPC, CPA e conversão (quando houver dados próprios ou fonte verificável); taxas, condições e prazos de pagamento; reputação e confiabilidade; qualidade dos produtos e dos anunciantes; estabilidade e disponibilidade das APIs; condições contratuais e restrições de divulgação. Detalhes de avaliação em `ACQUISITION_STRATEGY.md` seção 17.2.

Integrações são **adicionadas, substituídas ou desativadas por adaptadores**, sem reconstruir o núcleo (`ARCHITECTURE.md` seção 2, regra 1, e seção 4.5).

### 14.2 Dropshipping nacional e internacional

Capacidades que o sistema poderá apoiar progressivamente: pesquisa de produtos; pesquisa, avaliação e validação de fornecedores e distribuidores; análise de qualidade; comparação de preços e custos; margem e viabilidade; estabilidade de estoque; prazos e confiabilidade de entrega; rastreamento de pedidos; atendimento e pós-venda; devoluções, reembolsos, garantias e reclamações; integração com lojas e marketplaces; monitoramento de desempenho.

Regras **[Acordado — 08/11/2026]**:
- Fornecedores são avaliados **por mercado** (Brasil, Europa e outros). Um fornecedor adequado ao Brasil não é automaticamente adequado à França ou a outro país.
- Sempre que viável, produtos destinados à venda em escala passam por **validação física** (amostras e testes). Dados da internet não comprovam todas as características físicas de um produto.
- A compra de amostras é gasto: exige autorização explícita e dinheiro efetivamente recebido (seção 7).

### 14.3 Lojas próprias e marketplaces

Capacidades de destino: catálogo, produtos e variantes, preços e promoções, estoque quando aplicável, pedidos, fornecedores, pagamentos, frete e logística, devoluções, atendimento, análise de margem e desempenho por produto, marca e mercado. Uma marca pode operar com afiliados, dropshipping ou loja própria, **ou combinar modelos** quando fizer sentido.

### 14.4 Canais e monetização de conteúdo

Nenhuma dependência de uma única plataforma de distribuição. Canais possíveis: YouTube, Instagram, TikTok, Pinterest, sites e blogs, páginas de pesquisa e intenção de compra, lojas próprias, marketplaces e outros canais que se tornarem relevantes. Cada canal tem estratégia, linguagem, formato, frequência e métricas próprios. A ordem operacional dos canais continua a da seção 1 (YouTube primeiro).

A monetização direta de plataformas (seção 2) inclui receitas em moeda estrangeira, como dólar e euro, quando disponíveis e elegíveis **[elegibilidade a verificar]**.

### 14.5 Tipos de receita que não se confundem

Monetização de conteúdo, comissão de afiliados, receita bruta de lojas, margem de dropshipping, lucro operacional e caixa efetivamente recebido são grandezas diferentes e aparecem separadas em todos os relatórios (seção 18).

## 15. Estratégia internacional e localização por mercado

### 15.1 Brasil como primeiro mercado **[Acordado]**

O Brasil é o primeiro mercado de operação e validação. A prioridade continua concluir e validar a operação de afiliados em desenvolvimento, sem antecipar integrações e custos dos modelos futuros.

### 15.2 França como primeiro mercado internacional **[Acordado como destino — 08/11/2026]**

- A pesquisa e a preparação do mercado francês podem começar **em paralelo** à operação brasileira, sem esperar a maturidade completa de todas as operações no Brasil.
- Um primeiro **piloto francês** só começa quando infraestrutura, parceiros e operação específica estiverem suficientemente preparados, com autorização do proprietário. Os critérios do piloto são **[A definir]** (seção 21).
- Expansão com rapidez responsável, sem sacrificar qualidade.

### 15.3 Cada país tem operação própria

Traduzir o conteúdo brasileiro não basta. Cada mercado define sua estratégia considerando: idioma e cultura; comportamento do consumidor; poder de compra e sensibilidade a preços; categorias e demandas locais; concorrentes; redes de afiliados, programas de marcas e marketplaces; fornecedores; meios de pagamento; moeda; logística; tributação; legislação; regras de publicidade e divulgação; políticas de devolução e garantia; preferências de conteúdo e canais.

Exemplos (possibilidades de integração, **não decisões** sobre fornecedores ou plataformas):

| Mercado | Possibilidades |
|---|---|
| Brasil | Redes e programas de afiliados disponíveis no Brasil; fornecedores e distribuidores brasileiros; marketplaces relevantes para o consumidor brasileiro; meios de pagamento como Mercado Pago, quando apropriado; estratégias em português |
| França | Redes de afiliados relevantes na França e na Europa; programas diretos de marcas europeias; fornecedores que atendam o mercado francês; marketplaces relevantes para o consumidor francês; pagamentos como Stripe, PayPal ou outras opções viáveis; operação em francês com estratégia própria |

O mesmo princípio vale para os próximos países. A preparação técnica de `locale`, mercado, fuso e moeda segue a seção 11.3 e `ARCHITECTURE.md` seções 12.3 e 12.4.

### 15.4 Diversificação de parceiros

Evitar dependência exclusiva de uma rede de afiliados, um fornecedor, um marketplace, um gateway de pagamento, uma plataforma de conteúdo, um país ou uma moeda. A substituição de um parceiro não deve exigir reconstrução do sistema.

## 16. Central de inteligência e operações independentes **[Acordado como destino — 08/11/2026; estrutura conceitual]**

A visão é uma **central de inteligência compartilhada** com **operações comerciais independentes** por mercado, marca e modelo de negócio.

A central pode reunir conhecimento sobre produtos, qualidade, fornecedores, categorias, mercados, tendências, demanda, conversões, devoluções, comissões, margens, conteúdo, canais, comportamento do consumidor e aprendizado com decisões anteriores.

**Compartilhar inteligência não significa replicar decisões.** Um produto com bom desempenho no Brasil pode ser inadequado à França por preço, concorrência, logística, legislação ou comportamento do consumidor. A central compartilha conhecimento útil e preserva a autonomia de cada operação local.

Estrutura conceitual: central de inteligência; operações por país; operações por marca; motores comerciais por modelo de negócio; integrações específicas por plataforma; camada financeira e de conciliação; camada de auditoria e governança; camada de automação e agentes.

**Isto não é desenho de serviços.** Os elementos acima não precisam virar serviços independentes. O desenvolvimento preserva o monólito modular, os adaptadores em `integrations/` e o PostgreSQL como fonte da verdade (`ARCHITECTURE.md` seções 1 e 2), evitando complexidade prematura. A separação por marca já segue a seção 5 (`brand_id`).

## 17. Inteligência de produtos e fornecedores **[Acordado como princípio — 08/11/2026]**

A qualidade dos produtos é princípio fundamental. Produtos não são selecionados apenas por viralidade, comissão elevada, volume de vendas ou nota média.

**Critérios de avaliação, quando houver dados suficientes:** qualidade; segurança; materiais e construção; durabilidade; desempenho; utilidade; reputação; avaliações verificadas; reclamações recorrentes; taxa de devolução; risco de falsificação; procedência; certificações aplicáveis; conformidade regulatória; garantia; assistência e pós-venda; disponibilidade de peças; confiabilidade do fornecedor; demanda; concorrência; preço; comissão; margem; custos logísticos.

**Duas avaliações separadas:**

| Avaliação | O que mede |
|---|---|
| **Qualidade do produto** | Confiabilidade, segurança e adequação do produto |
| **Atratividade comercial** | Demanda, preço, margem, comissão, concorrência e possibilidade de venda |

Um produto excelente pode não ser comercialmente viável, e um produto com grande potencial de vendas pode ser reprovado por qualidade ou segurança.

**Regras:**
- Registrar fontes, evidências, data da consulta e nível de confiança de cada avaliação. Campos desconhecidos continuam "desconhecidos", nunca zero (`ARCHITECTURE.md` seção 4.5).
- Considerar avaliações suspeitas, manipulação de reviews e informações contraditórias.
- Produtos perigosos, ilegais, falsificados ou com problemas graves conhecidos não são promovidos.
- A avaliação é **específica por mercado**: exigências de segurança e conformidade variam entre países. Na União Europeia, considerar as regras aplicáveis de segurança, rastreabilidade, operador econômico responsável, garantias e devoluções; exigir marcação CE só nas categorias em que a legislação a determina. Referências confirmadas e pendências por categoria estão na seção 17.1 (Compliance Intelligence).
- A IA não afirma ter comprovado fisicamente uma qualidade que apenas inferiu de informações digitais (ver também `CONTENT_STRATEGY.md` seção 6.4).
- A decisão final sobre produtos e ofertas continua do proprietário (seção 1, aprovação humana editorial).

**Classificação conceitual [Proposta]:** A (aprovado), B (em investigação), C (rejeitado). É uma classificação de **qualidade**, ainda não implementada. Não substitui o campo `status` existente do modelo `Product` (`candidate`, `approved`, `rejected`, `archived`), que registra a decisão humana no fluxo de avaliação. Como as duas se relacionam (por exemplo, se C impede `approved`) será definido quando a avaliação de qualidade entrar em um lote.

### 17.1 Compliance Intelligence **[Acordado como destino — 08/11/2026; não implementado]**

Camada conceitual de inteligência regulatória, integrada à inteligência de produtos (seção 17) e à central de inteligência (seção 16). É direção estratégica e arquitetural futura: **não amplia o escopo do MVP nem atrasa a validação da operação de afiliados**. Nada aqui significa que o projeto esteja juridicamente certificado ou em conformidade integral; a camada organiza evidências e pendências e não substitui profissional qualificado.

**Origem das informações:** pesquisa regulatória do responsável em fontes oficiais, registrada em 08/11/2026 (fontes na seção 17.1.5). O assistente não conseguiu reabrir as páginas nesta sessão (hosts bloqueados pela rede do ambiente); antes de depender de qualquer regra, reconferir a fonte e registrar a data.

#### 17.1.1 Referências gerais confirmadas — União Europeia e França **[Fato verificado em 08/11/2026, pesquisa do responsável]**

| Tema | Conclusão | Fonte (seção 17.1.5) |
|---|---|---|
| Segurança geral de produtos | O Regulamento (UE) 2023/988 (GPSR) estabelece requisitos gerais de segurança de produtos, incluindo vendas à distância direcionadas ao mercado europeu | F1, F2, F5 |
| Marcação CE | Exigida **somente** para categorias abrangidas por legislação europeia específica; não é exigência universal | F3 |
| Importadores e distribuidores | Têm obrigações próprias de verificação de conformidade, documentação e rastreabilidade | F4 |
| Dropshipping na França | O vendedor continua responsável perante o consumidor, mesmo quando o fornecedor faz a expedição | F9 |
| Direitos do consumidor | Regra geral de 14 dias para desistência em compras à distância, sujeita a exceções; garantia legal mínima de dois anos para bens, sem prejuízo de proteções nacionais adicionais | F6, F7 |
| IVA | OSS e IOSS são mecanismos europeus de declaração de IVA para operações específicas; a aplicabilidade depende da estrutura da operação | F8 |
| França — ambiental | Existem regimes de Responsabilidade Estendida do Produtor (REP) e sinalização Triman/Info-tri; a aplicação depende da categoria e do papel da empresa | F10 |

#### 17.1.2 Dependente de categoria ou de enquadramento **[A verificar]**

Não são requisitos universais nem regras definitivas:
- categorias de produtos sujeitas à marcação CE;
- documentação técnica e certificações exigidas por categoria;
- regras específicas para cosméticos, alimentos, suplementos, eletrônicos, baterias, brinquedos e equipamentos de proteção;
- aplicação de REP, Triman e Info-tri por categoria;
- obrigações fiscais e tributárias da estrutura empresarial (ver também seção 11.5);
- regras nacionais complementares da França e de outros países europeus;
- requisitos específicos de cada marketplace, gateway e fornecedor;
- regras de publicidade, divulgação comercial e marketing de afiliados;
- responsabilidades exatas de cada empresa conforme seu papel na cadeia de fornecimento.

#### 17.1.3 Avaliação de conformidade **[Proposta]**

Cada avaliação registra: país e mercado de destino; categoria do produto; identificação e origem; modelo comercial; **papel da empresa** (afiliado, vendedor, importador, distribuidor ou fabricante); requisitos regulatórios aplicáveis; evidências e documentos disponíveis; fonte oficial, artigo e data da consulta; grau de confiança; data da última verificação; necessidade de revisão humana.

| Estado conceitual | Significado |
|---|---|
| `APPROVED` | Conformidade aplicável verificada com evidências suficientes |
| `PENDING` | Informações ou documentos insuficientes |
| `BLOCKED` | Não conformidade, proibição ou risco crítico identificado |
| `NOT_APPLICABLE` | Requisito analisado e, de forma documentada, não aplicável |

**Regras:**
- Falta de evidência **nunca** equivale a aprovação. O estado inicial é `PENDING`.
- Produto `PENDING` não é liberado automaticamente para operação comercial que dependa da comprovação ausente; `BLOCKED` impede a promoção e a venda (seção 17).
- A avaliação vale para um mercado e um papel; não se transfere automaticamente para outro país ou modelo comercial (seção 16).
- Estes estados são conceituais. Não existem no código e são distintos do `status` do modelo `Product` e da classificação de qualidade A/B/C (seção 17). A relação entre os três fica para o lote que implementar a avaliação (seção 21, item 4).

#### 17.1.4 Responsabilidade por modelo comercial **[Proposta]**

Não presumir que afiliados, dropshipping, lojas próprias, importadores e fabricantes têm as mesmas responsabilidades. A avaliação identifica o papel real da empresa em cada transação:

| Modelo | Foco principal da análise |
|---|---|
| Afiliado | Transparência comercial, publicidade e alegações sobre os produtos (`CONTENT_STRATEGY.md` seção 13) |
| Dropshipping | Responsabilidade do vendedor pela venda e pela execução do pedido, mesmo com expedição pelo fornecedor (F9) |
| Operação própria e importação | Também as obrigações de vendedor, importador, distribuidor ou fabricante, conforme o enquadramento efetivo (F4) |

O agente "Compliance" proposto em `AUTONOMY_AND_AGENTS.md` seção 5 é uma possível forma de executar essas verificações; continua sem implementação.

#### 17.1.5 Fontes oficiais iniciais

| Id | Fonte |
|---|---|
| F1 | GPSR — Regulamento (UE) 2023/988: <https://eur-lex.europa.eu/eli/reg/2023/988/oj/eng> |
| F2 | Orientações da Comissão sobre o GPSR: <https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:52025XC06233> |
| F3 | Marcação CE: <https://single-market-economy.ec.europa.eu/single-market/goods/ce-marking_en> |
| F4 | Importadores e distribuidores: <https://single-market-economy.ec.europa.eu/single-market/goods/ce-marking/importers-and-distributors_en> |
| F5 | Conformidade geral de produtos (Your Europe): <https://europa.eu/youreurope/business/product-rules-compliance/general-product-compliance/index_en.htm> |
| F6 | Garantias e direitos do consumidor (Your Europe): <https://europa.eu/youreurope/business/selling-in-eu/consumer-contracts-guarantees/consumer-guarantees/index_en.htm> |
| F7 | Venda à distância e comércio eletrônico (Your Europe): <https://europa.eu/youreurope/business/selling-in-eu/selling-goods-services/ecommerce-distance-selling/index_en.htm> |
| F8 | OSS/IOSS: <https://vat-one-stop-shop.ec.europa.eu/one-stop-shop_en> |
| F9 | DGCCRF — dropshipping: <https://www.economie.gouv.fr/dgccrf/les-fiches-pratiques/dropshipping-comment-respecter-la-reglementation> |
| F10 | REP na França: <https://www.ecologie.gouv.fr/politiques-publiques/cadre-general-filieres-responsabilite-elargie-producteurs> |

Data de consulta: 08/11/2026 (pesquisa do responsável). Reconferir antes de cada uso.

## 18. Inteligência financeira por modelo de negócio **[Acordado]**

A separação entre resultado comercial e dinheiro efetivamente recebido (seção 7, decisão L1) vale para todos os modelos:

| Modelo | Grandezas sempre separadas |
|---|---|
| Afiliados | Comissão **pendente** (sujeita a validação, cancelamento ou reembolso); comissão **confirmada** (aprovada pela plataforma, não necessariamente disponível para saque); comissão **recebida** (efetivamente depositada) |
| Lojas e dropshipping | Faturamento bruto; custo do produto; frete; taxas de pagamento; impostos; devoluções; reembolsos; custos de aquisição; margem de contribuição; resultado operacional; caixa disponível |
| Monetização de conteúdo | Receita por plataforma, país e moeda |

- Os dois indicadores da seção 7 (resultado comercial confirmado e resultado realizado em caixa) continuam distintos.
- **Reinvestimento só com dinheiro efetivamente recebido**, nunca com comissões pendentes ou apenas confirmadas.
- A consolidação não mistura moedas, modelos de negócio nem estados de recebimento; conversões preservam valor original, taxa, fonte e data (seção 11.3).

## 19. Horizontes de evolução **[Hipótese — cenários de maturação, não cronograma]**

Os marcos abaixo são objetivos de maturação e cenários possíveis. **Não são promessas de faturamento, prazos rígidos nem obrigações tecnológicas.** A evolução depende dos dados reais, do desempenho, da capacidade operacional, dos recursos financeiros e da qualidade das integrações. Tecnologias citadas (filas, particionamento, microsserviços, modelos preditivos) só entram com necessidade medida (seção 20).

### 19.1 Cerca de 5 meses — calibração e aprendizado inicial

- **Produtos:** acumular dados reais de produtos, categorias, cliques, conversões e devoluções; identificar categorias de melhor desempenho; refinar pesos e critérios de classificação com evidência; identificar problemas de qualidade e de fornecedores; comparar marcas e canais quando houver dados suficientes.
- **Validação:** validação rigorosa de valores monetários, percentuais, comissões e preços; evitar falsos positivos em ofertas voláteis; registrar decisões e motivos; começar a identificar padrões entre aprovações, rejeições e resultados.
- **Operação:** operação inicial validada com tráfego e transações reais, **se** os critérios de qualidade e segurança tiverem sido alcançados; intervenção humana reduzida em tarefas de baixo risco; monitorar falhas, integrações e atribuição.
- **Infraestrutura:** acompanhar volume de dados, consultas e desempenho; otimizar consultas e índices só quando medições mostrarem necessidade.
- **Mercados e modelos:** priorizar a validação dos afiliados no Brasil; preparar pesquisa e estrutura para a França; investigar novas redes e programas; pesquisar fornecedores e dropshipping sem comprometer o orçamento.
- **Resultado esperado:** operação inicial verificável, dados confiáveis e primeiros aprendizados reais. Não se pressupõe Product-Market Fit comprovado em cinco meses.

### 19.2 Cerca de 1 ano — maturidade operacional inicial

- **Sazonalidade:** acumular ciclos sazonais relevantes (Black Friday, Natal e datas de cada mercado) quando o tempo de operação permitir; antecipar oportunidades só com histórico suficiente.
- **Arquitetura:** identificar módulos que precisam de mais isolamento; melhorar adaptadores; reforçar tratamento de erros, limites de requisição, retentativas e idempotência; avaliar processamento assíncrono e filas só com necessidade comprovada. Um monólito modular bem estruturado pode continuar sendo a melhor escolha.
- **Confiabilidade:** testes de regressão de regras financeiras e comerciais; auditoria das integrações; monitoramento de falhas; segurança de credenciais; rastreabilidade de alterações; conciliação financeira confiável.
- **Expansão:** Brasil em operação; França preparada e, se os critérios forem atingidos, com piloto; mais redes de afiliados; avaliação de dropshipping e lojas próprias conforme viabilidade; diversificação de canais.
- **Resultado esperado:** operação mais previsível, que aprende com dados reais, reduz erros e amplia gradualmente as fontes de receita.

### 19.3 Cerca de 2 anos — expansão de mercados, nichos e autonomia

- **Catálogo:** histórico de produtos mais amplo; identificação de produtos promissores, nichos e cauda longa; redução de prioridade de produtos indisponíveis, descontinuados ou com desempenho ruim; monitoramento contínuo de qualidade e fornecedores. Qualquer projeção de dezenas ou centenas de milhares de itens depende da capacidade real de aquisição, validação e manutenção dos dados.
- **Expansão:** operações brasileira e francesa mais consolidadas, se viáveis; avaliação de outros mercados europeus; novas marcas e nichos; mais redes de afiliados; dropshipping nacional e internacional; lojas próprias e marketplaces quando economicamente justificáveis.
- **Autonomia:** menos curadoria manual; agentes dentro de políticas predefinidas; aprendizado com aprovações, rejeições e resultados; decisões rotineiras automatizadas; supervisão humana para ações sensíveis (`AUTONOMY_AND_AGENTS.md`).
- **Escalabilidade:** revisar armazenamento histórico e retenção de logs; avaliar particionamento só quando o volume justificar; preservar a integridade dos registros financeiros.
- **Resultado esperado:** portfólio de operações com inteligência compartilhada, mais autonomia e expansão sem depender de um único mercado ou parceiro.

### 19.4 Cerca de 5 anos — ativo consolidado e modernização contínua

- **Inteligência:** histórico amplo de produtos, marcas, mercados, fornecedores e consumidores; análise de tendências e sazonalidade; cruzamento com indicadores externos confiáveis; modelos preditivos mais maduros, se validados.
- **Modernização:** avaliar dívida técnica; atualizar linguagens, bibliotecas e runtimes; revisar módulos antigos; substituir integrações obsoletas, sem comprometer a continuidade. Sem reescritas completas por moda: modernizar conforme risco, custo e benefício.
- **Governança:** auditoria financeira robusta; histórico de decisões e alterações; proteção contra fraudes e inconsistências; segurança de dados; conciliação entre plataformas, moedas e operações; controles de acesso.
- **Operação comercial:** portfólio internacional de marcas; afiliados diversificados; dropshipping em diferentes mercados; lojas próprias; monetização de conteúdo; possíveis novos modelos comerciais.
- **Resultado esperado:** infraestrutura comercial consolidada, capaz de operar diferentes negócios e mercados com inteligência, governança e adaptação.

### 19.5 6 anos ou mais — plataforma madura e renovação tecnológica

- **IA e agentes:** agentes mais especializados; pesquisa de mercado contínua; otimização de conteúdo e recomendações; estratégias personalizadas por marca e mercado; dados em tempo real quando técnica e legalmente adequados.
- **Tecnologia:** avaliar novos paradigmas de IA; modernizar integrações; melhorar segurança e resiliência; reescrever módulos só com justificativa técnica e econômica.
- **Comércio:** operações internacionais mais amplas; mais marcas e categorias; modelos comerciais diversificados; parceiros em diferentes regiões; integrar novas oportunidades sem reconstruir a infraestrutura central.
- **Governança:** auditoria financeira e operacional rigorosa; proteção de dados; integridade dos registros; continuidade operacional e recuperação de falhas; limites de autonomia; controle humano das decisões críticas.
- **Resultado esperado:** plataforma interna madura, infraestrutura de um grupo de operações comerciais diversificadas, capaz de se renovar sem perder estabilidade.

## 20. Princípios técnicos e restrições financeiras para todos os horizontes **[Acordado]**

Os horizontes não são cronograma de adoção de tecnologias. A evolução segue:

1. Modularidade antes de complexidade distribuída.
2. Núcleo de negócio independente de fornecedores e plataformas.
3. Adaptadores para integrações externas.
4. Dados confiáveis e rastreáveis.
5. Testes automatizados.
6. Segurança desde o início.
7. Observabilidade proporcional à complexidade.
8. Integridade financeira.
9. Governança da autonomia.
10. Capacidade de substituir integrações.
11. Evolução orientada por métricas reais.
12. Controle de custos.
13. Compatibilidade com expansão internacional.
14. Capacidade de modernização progressiva.

Microsserviços, mensageria, particionamento e infraestrutura distribuída são possibilidades futuras, não requisitos. A arquitetura atual continua simples e modular enquanto for suficiente (`ARCHITECTURE.md` seção 1).

**Restrições financeiras:** o projeto começa com orçamento extremamente limitado, sem capital externo pressuposto. Priorizar ferramentas gratuitas ou de baixo custo; evitar APIs pagas sem justificativa de retorno; não contratar infraestrutura antecipadamente; não criar complexidade para escala hipotética; reinvestir progressivamente só valores efetivamente recebidos; não comprometer dinheiro com base em comissões pendentes; preparar a arquitetura para expansão sem implementar tudo antecipadamente.

**A prioridade atual permanece concluir, testar e validar a operação de afiliados. A visão não desvia o desenvolvimento do MVP.**

## 21. Pontos em aberto da revisão 6

| # | Ponto | Tipo |
|---|---|---|
| 1 | **Autonomia × aprovação individual:** a visão de longo prazo é que o proprietário supervisione, sem operar manualmente cada publicação, produto ou pedido (`AUTONOMY_AND_AGENTS.md` seção 3.1). **Direção definida em 12/11/2026 [Decisão conceitual]:** a aprovação individual de cada envio é regra da fase inicial, não limitação definitiva; a publicação poderá evoluir para execução por política (`AUTONOMY_AND_AGENTS.md` seção 4.3). Nichos, marcas, produtos e ofertas permanecem sempre sob decisão do proprietário. A ativação de qualquer política continua dependendo de decisão expressa, revisão de riscos e implementação validada; nenhuma está ativa | Direção definida; a ativação é decisão futura |
| 2 | **Piloto francês antes da Fase C:** a preparação em paralelo está acordada (seções 4 e 15.2); falta decidir se o piloto francês pode começar antes da segunda marca brasileira e com quais critérios | Decisão |
| 3 | **Cadência:** a referência quinzenal da primeira marca (seção 11.4) e as referências por tipo de marca (`CONTENT_STRATEGY.md` seção 16.6) são hipóteses; o proprietário escolhe a da primeira marca | Decisão |
| 4 | Relação entre a classificação de qualidade A/B/C e o `status` do produto (seção 17) | Decisão técnica futura |
| 5 | Orçamento e regra para compra de amostras físicas (seção 14.2) | Decisão futura |
| 6 | Obrigações fiscais, consumeristas e de conformidade de produtos para dropshipping, lojas e operação na França/UE: referências gerais registradas em 08/11/2026; itens por categoria e enquadramento continuam pendentes (seção 17.1.2) | Verificação com fonte oficial e profissional qualificado |

## 22. Histórico de revisões

| Revisão | Data | Mudanças |
|---|---|---|
| 7.3 | 14/11/2026 | Reconciliação documental, só fatos: linha "Implementado" e "Próxima etapa" da seção 13 (Lotes 6 a 9 na `main`, validados só em banco descartável); notas sobre o `PRODUCT_ROADMAP.md` (cabeçalho e seção 10); situação real do `brand_id` (seção 5). Nenhuma decisão nem conteúdo estratégico alterado. |
| 7.2 | 12/11/2026 | Consolidação da especificação de autorização de publicação (decisões conceituais de 12/11/2026; regras em `AUTONOMY_AND_AGENTS.md` seção 4): aprovação individual descrita como regra da fase inicial, válida para todo envio, e não como limitação definitiva (1, 3, 6, 12); ponto em aberto 1 da seção 21 atualizado com a direção definida. Decisão do proprietário sobre nichos, marcas, produtos e ofertas preservada. Registrada a ambiguidade de status da revisão 5. |
| 7.1 | 08/11/2026 | Seção 13 atualizada após a integração do Lote 5 (PR #11, merge `bd62e83`): Lote 5 marcado como implementado; nenhum lote em desenvolvimento; condição do débito M2 na próxima etapa. Nenhum conteúdo estratégico alterado. |
| 7 | 08/11/2026 | Compliance Intelligence (17.1): referências gerais confirmadas de UE e França (GPSR, marcação CE por categoria, importadores e distribuidores, dropshipping na França, desistência e garantia, OSS/IOSS, REP e Triman/Info-tri), pendências por categoria e enquadramento, avaliação por mercado e papel, estados `APPROVED`/`PENDING`/`BLOCKED`/`NOT_APPLICABLE` e fontes oficiais. Ajustes em 17 e 21 (item 6). |
| 6 | 08/11/2026 | Consolida a visão de longo prazo: mapa entre implementado, em desenvolvimento, próxima etapa e visão (13); diversificação de modelos de negócio, incluindo dropshipping nacional/internacional, lojas próprias e marketplaces (2, 4, 14); Brasil e França (15); central de inteligência conceitual (16); inteligência de produtos e fornecedores (17); inteligência financeira por modelo (18); horizontes de 5 meses a 6+ anos como cenários (19); princípios técnicos e restrições financeiras (20); pontos em aberto (21). Cadência por marca (11.4). Histórico renumerado de 13 para 22. Nenhuma decisão anterior removida. |
| 5 | 06/11/2026 | Formaliza a visão de ecossistema privado (não SaaS), multicanal e internacional, múltiplas redes, blog/site, monetização complementar, central móvel e aprovação editorial individual; cadência e operação por CPF ficam qualificadas como hipótese/intenção sujeita a validação. |
| 1 | Até 04/11/2026 | Versão original no GitHub (`main`, `d1bb139`) |
| 2 | 04/11/2026 | L1: dois indicadores financeiros e regra de reinvestimento (7). L2: objetivo de automação operacional, papel do responsável e distribuição multicanal (1, 3, 4, 6, 9). L6: `brand_id` desde o esquema v1 (5). L7: Gitleaks como requisito (8, 10). Critério A para B reescrito como proposta (10). Nenhuma outra decisão alterada |
| 3 | 05/11/2026 | Em revisão. Ordem dos canais, Google como site e SEO e operação manual como contingência (1, 3); aprovação por política (3, 6); Fases A e B (4, 10); nível 4 redefinido (6); comissão confirmada (7); critério A para B segundo a decisão de 05/11 (10) |
| 4 | 05/11/2026 | Em revisão, não aprovada. Seção 6: esclarecido que eventual inclusão futura de gastos, compras ou campanhas em política exige decisão expressa e não autoriza despesas no momento. |
