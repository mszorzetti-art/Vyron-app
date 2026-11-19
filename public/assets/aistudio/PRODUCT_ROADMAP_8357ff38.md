# Affiliate Autopilot — Roadmap do produto

> **O que este documento é:** a sequência lógica de evolução do projeto: o que já foi entregue, o que vem a seguir, de que cada etapa depende e o que precisa ser decidido antes dela. **Não tem datas:** cada etapa avança quando seus critérios são cumpridos e comprovados.
> **O que ele não é:** não é o registro de fatos verificados (isso é o `PROJECT_STATUS.md`), não repete os critérios técnicos de cada bloco (`ARCHITECTURE.md` seção 8) nem as regras de autonomia e de autorização (`AUTONOMY_AND_AGENTS.md`). Se este documento divergir de um deles, vale o outro, e este deve ser corrigido.
>
> **Versão 2.1 — 14/11/2026** (versão 2, do mesmo dia, com a seção 4 e a seção 9 revistas). Reescrita depois da integração dos Lotes 7, 8 e 9 e do incremento 4.3 à `main` (PRs #16 a #19, último merge `69758d4`). Substitui a versão 1, de 04/11/2026, que descrevia o projeto antes do Lote 2.
> **Legenda:** **[Fato]** verificado no repositório em 14/11/2026 · **[Acordado]** decisão do responsável · **[Proposta]** sugestão ainda não aprovada · **[A definir]** depende de decisão ou dado que ainda não existe.
> **Situação:** as entregas (seção 2) são **[Fato]**. A ordem das etapas futuras (seção 4) é **[Proposta]**: nenhuma etapa futura está autorizada só por constar aqui.

---

## 1. Como ler este roadmap

Três coisas diferentes, que não se confundem:

| Tipo | O que é | Onde está |
|---|---|---|
| **Fase de negócio** | Estágio do negócio, avaliado por resultados (Fase A, Fase B...) | `PROJECT_VISION.md` seções 4 e 10; resumo na seção 6 |
| **Bloco técnico** e seus **lotes** | Entrega de código, avaliada por testes e CI. Os blocos (0 a 12) são o catálogo do `ARCHITECTURE.md` seção 8; os lotes são as entregas reais, numeradas na ordem em que aconteceram | Seções 2 e 4 |
| **Revisão documental** | Mudança em documentos, sem código | Histórico de cada documento |

Regras **[Acordado — L3]**:

1. Uma revisão documental nunca conclui um bloco técnico.
2. O estado real é registrado no `PROJECT_STATUS.md`, só com informações verificadas.
3. Os próximos lotes são definidos por dependências técnicas e critérios de aceitação; o escopo de cada lote novo é decisão do responsável.
4. Nenhuma data é inventada.
5. Nenhum lote é considerado concluído sem evidência: código no GitHub com o commit identificado, CI verde nesse commit, critérios de aceitação verificados e `PROJECT_STATUS.md` atualizado.

Os blocos são identificados pelo número do catálogo do `ARCHITECTURE.md`. Os identificadores P1 a P14 da versão 1 deixaram de ser usados; a correspondência está na seção 5.

## 2. O que já foi entregue **[Fato]**

Tudo abaixo está na `main` (`69758d4`), com CI e varredura de segredos verdes em cada integração. Detalhes, commits e contagens de testes: `PROJECT_STATUS.md` seção B.

| Bloco (`ARCHITECTURE.md` seção 8) | Lotes que o entregaram | O que existe | O que falta no bloco |
|---|---|---|---|
| 0 — Repositório | — | Documentos de base | Nada |
| 1 — Fundação | Fundação; Lote 4.1; incremento 4.3 | Configuração, logs com redação de segredos, erros, CLI, CI com lint, formatação, testes e Gitleaks | Nada |
| 2 — Banco | Lotes 5.1 e 5.2; migrações 0001 a 0003 | Conexão PostgreSQL, migrador próprio, esquema v1, gravação idempotente de produtos com histórico | Tabelas financeiras (adiadas para o bloco 8, decisão de 07/11/2026); nenhuma tabela comercial com `brand_id` existe ainda |
| 3 — Executor de lotes | Lote 5.3a (`job_runs`); Lote 7 | `autopilot run-pipeline`, retentativas limitadas, estado indeterminado nunca repetido, reconciliação de execuções abandonadas (`autopilot jobs reconcile`, débito M2) | Estado `unknown` por item para efeitos externos: entra com o primeiro efeito externo. Retenção de `job_runs` |
| 4 — Agendador | Lote 9 | Workflow `scheduler.yml`: lote em simulação, `concurrency`, acionamento manual | Banco hospedado; o gatilho agendado está desabilitado por padrão (seção 3) |
| 5 — Produtos e nichos | Lotes 1 a 3, 4.2, 5.3 e 6 | Modelo de produto, importação JSON e CSV com governança, importação persistente, pontuação determinística com persistência, rankings | Pesquisa de nichos. Gravação real da pontuação depende da condição C3 |
| Stop All e auditoria (`ARCHITECTURE.md` 12.5) | Lote 8 | `autopilot control`, estado global com falha fechada, `audit_log` só de inserção | Autenticação de quem aciona; acionamento pelo celular |
| 6 a 12 | — | Nada | Tudo (seção 4) |

A arquitetura adotada é a execução procedural em lotes: o agendador chama a CLI, que processa um lote limitado e encerra. Não há fila, reserva de tarefas, concessões com prazo nem agenda no banco (`ARCHITECTURE.md` seções 4.1, 4.2 e 9.2). A versão 1 deste roadmap ainda descrevia esses mecanismos; eles foram substituídos em 07/11/2026.

## 3. Construído, mas ainda não em operação real

O que está na `main` foi validado por testes automáticos em **banco descartável**. Isso não é evidência de operação real. Hoje **[Fato]**:

- **não existe banco hospedado persistente** nem credenciais; toda execução fora de testes é simulação;
- **a condição C3 não está implementada** (GitHub Environment restrito à `main`, credenciais do banco, workflow autorizado). Sem ela, `products score --commit` e `run-pipeline --commit` são recusados fora de testes;
- **o agendador está desabilitado.** Só roda por agendamento se o responsável ligar a variável `AUTOPILOT_SCHEDULE_ENABLED`; mesmo ligado, simula contra o banco descartável do próprio job e não enxerga dados reais;
- **a migração 0003 precisa ser aplicada** ao banco persistente antes de qualquer `--commit`: sem ela o Stop All não pode ser lido e toda gravação é recusada;
- **`--actor` não é autenticação:** é um identificador informado por quem roda o comando;
- **o Stop All não pode ser acionado pelo celular;**
- **a retenção de `job_runs` não existe.**

Cenários nunca exercitados em condições reais: o gatilho agendado e a condição da variável; o acionamento manual do agendador; `concurrency` com duas execuções simultâneas; a conferência de proveniência no GitHub Actions real; qualquer gravação, reconciliação ou Stop All contra um banco persistente. A lista completa está no `PROJECT_STATUS.md` seção D.

**O projeto não está pronto para produção.**

## 4. Próximas etapas **[Proposta]**

**Este roadmap orienta; não autoriza.** Para cada etapa, seis coisas diferentes precisam estar resolvidas, e nenhuma substitui a outra:

| O quê | Quem resolve | Onde fica registrado |
|---|---|---|
| **Decisão estratégica** (o que fazer e em que ordem) | Responsável | Seção 9.1 |
| **Pré-requisito técnico** (o que precisa existir para o trabalho ser possível) | Engenharia, ou o responsável quando é conta, credencial ou infraestrutura | Coluna "Entrada" e quadro da seção 4.2 |
| **Dependência entre blocos** (o que precisa estar pronto antes) | Arquitetura | Coluna "Depende de" |
| **Critério de entrada e de saída** | Tabelas abaixo (entrada) e `ARCHITECTURE.md` seção 8 (saída) | Colunas "Entrada" e "Saída" |
| **Prioridade** | Responsável. Este documento não fixa prioridade: descreve os caminhos possíveis e suas consequências | Seção 4.4 |
| **Autorização para implementar** | Responsável, por lote, depois de definido o escopo | `PROJECT_STATUS.md` |

Uma etapa pode ter todas as dependências satisfeitas e continuar sem autorização; pode também estar autorizada e não poder começar por falta de um pré-requisito. **Hoje nenhuma etapa desta seção está autorizada.**

### 4.1 Etapas que não dependem de código novo de produto

| Etapa | Objetivo | Entrada | Saída |
|---|---|---|---|
| **Infraestrutura de operação real** | Sair da simulação: banco hospedado, condição C3, primeira gravação real da pontuação, agendador com dados reais | **Ação do responsável:** escolher e criar o banco (Neon é só candidato, `ARCHITECTURE.md` 6.2), com TLS e usuário restrito; criar o GitHub Environment e as credenciais. Só então há trabalho de código (workflow autorizado) | Migrações 0001 a 0003 aplicadas; C3 validada no GitHub Actions real; uma gravação real conferida; decisão explícita sobre ligar o agendador |
| **Acionamento e autoria do Stop All** | Acionar pelo celular e registrar quem acionou de forma confiável | Banco hospedado; decisão sobre o meio (workflow manual do GitHub é uma opção **[A validar]**) | Stop All acionado fora do computador, com autor vindo da plataforma e não digitado |
| **Retenção de `job_runs`** | Limitar o crescimento da tabela | Decisão sobre o prazo e sobre os agregados a manter (`ARCHITECTURE.md` 4.3) | Retenção aplicada sem apagar execuções referenciadas por produtos ou rankings |

Dependências reais entre as três: o acionamento do Stop All pelo celular e a retenção só têm utilidade prática com um banco persistente, então na prática vêm depois da primeira; a retenção pode ser **decidida** (prazo e agregados) a qualquer momento. A primeira é também a única forma de validar em condições reais o que os Lotes 6 a 9 construíram. Nenhuma das três depende de decisão de produto, e nenhuma delas é pré-requisito técnico para **escrever** o código do bloco 6.

### 4.2 Etapas de produto

| Bloco | Objetivo | Depende de | Entrada | Estado da especificação |
|---|---|---|---|---|
| **6 — Conteúdo** | Briefings, máquina de estados do conteúdo, importação de rascunhos | Blocos 2, 3 e 5; `audit_log` (existe) | Primeira marca cadastrada (a tabela `brands` está vazia por decisão); regras de divulgação de publicidade conferidas; formatos e estrutura do briefing aprovados (`CONTENT_STRATEGY.md` é em grande parte proposta); esquema de `content_items` compatível com as regras de versão e hash de 12/11/2026 | **Insuficiente.** O esquema depende das propostas técnicas de `ARCHITECTURE.md` 4.7.2, ainda não validadas |
| **Autorização por hash** (parte dos blocos 6 e 7) | Aprovação individual vinculada à versão exata da peça | Bloco 6 | Autorização expressa de implementação (`AUTONOMY_AND_AGENTS.md` seção 13, item 15); listas de verificações e parâmetros pendentes (itens 9 a 18) | **Não autorizada.** Regras conceituais decididas em 12/11/2026; implementação pendente de decisão |
| **7 — Publicação** | Interface `PublisherProvider` e primeiro adaptador (YouTube), sempre não público na Fase A | Bloco 6 e autorização por hash | Propostas técnicas de `ARCHITECTURE.md` 4.7.2 a 4.7.5 validadas; parâmetros de 4.7.6 definidos; API, cotas e termos do YouTube conferidos; alternativa de OAuth escolhida (7.1) | **Não autorizada** pela revisão 13 do `ARCHITECTURE.md`. Conclui o Marco M1 |
| **8 — Vendas e comissões** | Importação somente leitura e registro financeiro para os dois indicadores (L1) | Blocos 2 e 3 | Documentação oficial da plataforma de afiliados lida e registrada; nomes das tabelas financeiras definidos | Insuficiente: campos da API para afiliados não confirmados |
| **9 — Tráfego e métricas** | Métricas dos canais e rastreio de cliques | Bloco 4 com dados reais; bloco 7 | Escopos de leitura verificados; forma de rastrear cliques escolhida | Insuficiente |
| **10 — Relatórios e notificações** | Relatório com os dois indicadores, lado a lado e nunca somados; alertas | Blocos 8 e 9 | Canal de notificação escolhido | Insuficiente |
| **11 — Otimização** | Recomendações por regras, cada uma citando os dados que a motivaram | Bloco 10 | Dados reais suficientes | Insuficiente |
| **12 — Anúncios** | Só desenho de interface e custos | Bloco 10 | Decisão de orçamento com dinheiro efetivamente recebido (L1) | Fora do protótipo |
| **5 — Pesquisa de nichos** (resto do bloco) | Avaliar nichos com a mesma lógica da pontuação de produtos | Bloco 5 | Fórmula, campos e fonte de dados definidos | Insuficiente: só existe a indicação "a mesma lógica" |

**Os blocos 6 e 7 não estão prontos para começar.** O que falta a cada um, separado por natureza:

| | Bloco 6 — Conteúdo | Bloco 7 — Publicação |
|---|---|---|
| Dependência entre blocos | Blocos 2, 3 e 5 e o `audit_log`: **satisfeita** | Bloco 6 e autorização por hash: **não satisfeita** |
| Decisões estratégicas em aberto | Primeira marca; formatos e estrutura do briefing; regras de divulgação aplicáveis (seção 9.1, itens 6 e 7) | Alternativa de OAuth; parâmetros pendentes de `ARCHITECTURE.md` 4.7.6 e de `AUTONOMY_AND_AGENTS.md` seção 13 (itens 9 a 18) |
| Pré-requisitos técnicos | Esquema de `content_items` compatível com versão e hash (`ARCHITECTURE.md` 4.7.2, proposta ainda não validada); dependência para os modelos de texto | Propostas de 4.7.2 a 4.7.5 validadas; API, cotas e termos do YouTube conferidos; credenciais do canal; na prática, banco persistente e Stop All operante, porque um envio privado já é efeito externo real |
| Autorização | Nenhuma | Negada expressamente pela revisão 13 do `ARCHITECTURE.md` e pelo item 15 da seção 13 do `AUTONOMY_AND_AGENTS.md` |

A pesquisa de nichos é independente dos demais blocos e pode entrar em qualquer momento depois de especificada.

### 4.3 Evoluções posteriores

Não têm bloco técnico próprio e não são compromisso de implementação:

| Item | Depende de | Observação |
|---|---|---|
| Central móvel de aprovação | Blocos 6 e 7 | Requisito de destino (`AUTONOMY_AND_AGENTS.md` seção 11); pode começar como web responsiva |
| Produção automática de mídia (roteiro, narração, imagem, montagem) | Bloco 6 | Só com orçamento aprovado e limites de custo ativos; alternativas de código aberto primeiro |
| Canais secundários (Instagram, TikTok, Pinterest, site) | Bloco 7 validado no YouTube | Cada canal exige verificação própria de API, auditoria e termos |
| Publicação por política, sem aprovação individual | Operação comprovada na fase inicial | Decisão expressa do proprietário e revisão de riscos (`AUTONOMY_AND_AGENTS.md` 4.3) |
| Machine Learning | Dados reais suficientes e casos de uso validados | Não antecipar (`AUTONOMY_AND_AGENTS.md` 11.4) |
| Novas redes, mercados, lojas próprias, dropshipping | Fases de negócio seguintes | `PROJECT_VISION.md` seções 14 a 19; requisitos regulatórios de outros mercados ainda dependem de verificação |

### 4.4 Dois caminhos possíveis para o próximo lote

Depois dos Lotes 7 a 9 há dois caminhos coerentes com as dependências. **A escolha é do responsável** (seção 9.1, item 1); este documento só descreve as consequências.

| | Caminho A — Infraestrutura de operação real | Caminho B — Preparação do bloco 6 (conteúdo) |
|---|---|---|
| O que é | Banco hospedado, condição C3, primeira gravação real, agendador com dados reais | Fechar as decisões de entrada do bloco 6 e só então implementá-lo |
| O que exige do responsável antes de qualquer código | Criar conta e banco, credenciais e GitHub Environment | Definir marca, formatos, briefing e regras de divulgação; validar a proposta de versão e hash |
| Custo | Pode gerar custo ou consumir limites de plano gratuito; a confirmar no provedor escolhido | Nenhum custo de infraestrutura |
| O que passa a ser verdade | O que os Lotes 6 a 9 construíram fica validado em condições reais; o Stop All e a reconciliação passam a proteger dados que existem | O critério de saída da Fase A fica mais próximo, porque ele exige os blocos 6 e 7 |
| O que continua pendente | Todo o caminho de produto (blocos 6 e 7) | Tudo o que foi construído continua validado só em banco descartável; o bloco 7 exigirá a infraestrutura de qualquer forma |
| Risco principal | Operar infraestrutura antes de haver conteúdo para ela servir | Fixar um esquema de conteúdo antes de as regras de versão e hash estarem validadas (migração aplicada nunca é editada) |

Os dois caminhos não se excluem e podem ser feitos em sequência, em qualquer ordem. Tecnicamente, **A não é pré-requisito para escrever o código do bloco 6**, mas é pré-requisito prático para o bloco 7. A retenção de `job_runs` e a pesquisa de nichos são independentes dos dois.

## 5. Correspondência com a versão 1 (P1 a P14)

Os identificadores provisórios da versão 1 deixaram de valer. O `AUTONOMY_AND_AGENTS.md` (tabela da seção 5) passou a citar os blocos, com o identificador antigo entre parênteses; esta tabela fica como referência para textos antigos.

| ID antigo | O que previa | Situação em 14/11/2026 |
|---|---|---|
| P1 | Gitleaks no CI; opcionalmente `ruff format --check` | **Entregue:** Lote 4.1 e incremento 4.3 |
| P2 | Banco, `brand_id`, registro financeiro | **Entregue em parte:** Lote 5 e migrações 0001 a 0003. Registro financeiro adiado para o bloco 8 |
| P3 | "Núcleo de tarefas": fila, reserva, botão de parada | **Entregue com outra arquitetura:** Lotes 7 e 8 (execução em lotes, sem fila nem reserva; Stop All) |
| P4 | Agendas e `run-due` | **Entregue com outra arquitetura:** Lote 9 (workflow agendado, sem `run-due`); desabilitado |
| P5 | Conteúdo | Bloco 6, não iniciado |
| P6 | Publicação multicanal | Bloco 7, não iniciado e não autorizado |
| P7 | Vendas, comissões e recebimentos | Bloco 8, não iniciado |
| P8 | Métricas dos canais | Bloco 9, não iniciado |
| P9 | Relatórios e notificações | Bloco 10, não iniciado |
| P10 | Aprovação pelo celular | Seção 4.3, não iniciado; o `audit_log` que ela usaria já existe |
| P11 | Produção automática de mídia | Seção 4.3, não iniciado |
| P12 | Otimização | Bloco 11, não iniciado |
| P13 | Canais secundários | Seção 4.3, não iniciado |
| P14 | Anúncios | Bloco 12, fora do protótipo |

A "Etapa 2 — Product Intelligence" da versão 1 corresponde aos Lotes 1 a 3 e, com a pontuação, ao Lote 6. O critério proposto de unificar `DemoProduct` e `Product` **não foi cumprido**: os dados de demonstração continuam num formato próprio, usado só pelo comando `demo-data` (`PROJECT_STATUS.md` seção D). Não impede nenhuma etapa.

## 6. Fases de negócio

Os critérios são os do `PROJECT_VISION.md` seção 10; aqui fica só a ligação com os blocos.

| Fase | Objetivo | Critério de saída | Situação |
|---|---|---|---|
| **A. Fundação técnica** | Base testada e publicação não pública com aprovação | Validação controlada e não pública concluída, incluindo produção, verificações e publicação privada ou não pública em pelo menos um canal; testes e CI com resultado registrado; Gitleaks ativo antes de qualquer credencial real; segredos conferidos; autorização explícita do responsável para a operação pública **[Acordado — 05/11/2026]** | **Em andamento.** Cumprido: testes e CI registrados; Gitleaks ativo. **Não cumprido:** produção, verificações e publicação não pública, que correspondem aos blocos 6 e 7 (Marco M1 do `ARCHITECTURE.md`). Nenhum dos dois está pronto para começar nem autorizado (seção 4.2). A conferência de segredos e a autorização para a operação pública só fazem sentido depois deles |
| **B. Validação de afiliados** | Uma marca, um nicho, YouTube como canal inicial, ciclo completo medido | Ao menos um ciclo completo (clique, venda, comissão) medido com dados reais | Não iniciada |
| **C. Replicação** | Segunda marca na mesma infraestrutura | Segunda marca com separação de contas e dados comprovada | Não iniciada |
| **D a F** | Novas redes e mercados; produtos próprios; dropshipping | `PROJECT_VISION.md` seção 10 | Não iniciadas |

**[Proposta]** Os blocos 8 a 10 podem ser concluídos durante a Fase B. Até lá, o registro de vendas e métricas pode ser manual, apenas como solução temporária de validação **[Acordado — L2]**. Quais blocos são obrigatórios antes da Fase B, além dos que o critério A para B já implica, é **[A definir]**.

## 7. Validação comercial e indicadores

- **Indicadores financeiros [Acordado — L1]:**
  - resultado comercial confirmado = comissões confirmadas menos custos atribuíveis;
  - resultado realizado em caixa = dinheiro efetivamente recebido menos despesas efetivamente pagas.
  - Os dois são independentes. Reinvestimento só com dinheiro recebido.
- **Estágios de validação de canal:** exploração, interesse, validação de conversão, resultado financeiro, sustentabilidade (`ACQUISITION_STRATEGY.md` seção 13.2).
- **Visualizações não são resultado comercial.**
- **Sem metas numéricas neste documento.** Os valores de cada critério são definidos pelo responsável antes de cada fase.

## 8. Riscos do roadmap

| Risco | Mitigação |
|---|---|
| Tomar testes em banco descartável por operação real | Seção 3 e `PROJECT_STATUS.md` seção D separam o que foi validado do que não foi; a primeira etapa da seção 4.1 existe para fechar essa lacuna |
| Começar o bloco 6 antes das decisões de entrada e fixar um esquema errado | Migração aplicada nunca é editada: decidir marca, formatos e regras de versão antes de escrever a migração |
| Ligar o agendador esperando operação real | O workflow, o `README.md` e o `PROJECT_STATUS.md` dizem que ele só ensaia enquanto não houver banco hospedado |
| Atualizar o código e gravar sem aplicar a migração 0003 | A gravação é recusada (falha fechada); rodar `autopilot db migrate` antes |
| Automação esbarrar em auditorias e políticas das plataformas | Verificar antes de cada adaptador (`ARCHITECTURE.md` seções 7 e 12) |
| Custo de IA, banco e hospedagem de mídia | Teto de custo, aprovação e uso exclusivo de dinheiro recebido (L1) |
| Este documento voltar a ficar para trás | Revisar a seção 2 a cada lote integrado, junto com o `PROJECT_STATUS.md` |

## 9. Decisões

### 9.1 Abertas

Três grupos, independentes entre si. A coluna "Destrava" diz o que a decisão libera **tecnicamente**; nenhuma decisão, sozinha, autoriza um lote.

**Sequência**

| # | Decisão | Destrava |
|---|---|---|
| 1 | Qual caminho seguir primeiro: A (infraestrutura de operação real), B (preparação do bloco 6) ou outro (seção 4.4) | Só a ordem do trabalho. Não substitui nenhuma das decisões abaixo: cada caminho continua dependendo das suas |
| 2 | Aprovação da ordem proposta na seção 4 | A sequência oficial; hoje ela é proposta |
| 3 | Blocos obrigatórios antes da Fase B, além dos 6 e 7 que o critério A para B já implica | O critério de entrada da Fase B |

**Infraestrutura e operação** (necessárias para o caminho A e, mais tarde, para o bloco 7)

| # | Decisão | Destrava |
|---|---|---|
| 4 | Banco hospedado: provedor, plano e momento | Operação real, condição C3, agendador com dados reais; pré-requisito prático das decisões 5 e 6 |
| 5 | Ligar ou não o gatilho agendado, e quando | Só o agendamento. Sem a decisão 4 ele continua sendo ensaio |
| 6 | Como autenticar quem aciona o Stop All e por qual meio acioná-lo pelo celular | Stop All utilizável em operação |
| 7 | Prazo de retenção de `job_runs` e agregados a manter | A retenção. Não depende de nenhuma outra decisão |

**Produto** (necessárias para o caminho B)

| # | Decisão | Destrava |
|---|---|---|
| 8 | Primeira marca (nome e identificador) | Qualquer dado de conteúdo: `content_items` exige `brand_id` |
| 9 | Formatos de conteúdo e estrutura do briefing; regras de divulgação aplicáveis | A especificação do bloco 6 |
| 10 | Autorizar a implementação da aprovação por hash e definir os parâmetros pendentes | A aprovação de conteúdo no bloco 6 e todo o bloco 7 |

As decisões 4 a 7 e 8 a 10 não dependem umas das outras: pode-se avançar num grupo sem tocar no outro. Dentro do grupo de produto, as três são necessárias em conjunto para o bloco 6 ficar especificado.

### 9.2 Já tomadas ou superadas (constavam como pendentes na versão 1)

| Pendência da versão 1 | Desfecho |
|---|---|
| Nome oficial e critério de conclusão da "Etapa 2" | Superada: desde a revisão 7 do `ARCHITECTURE.md` o desenvolvimento é identificado por lotes, e os critérios são os dos blocos |
| Redação final do critério A para B | Decidida em 05/11/2026 (`PROJECT_VISION.md` seção 10) |
| Momento de incluir o Gitleaks no CI | Feito no Lote 4.1 |
| Aplicação do `brand_id` por tabela | Decidida em 07/11/2026 (`ARCHITECTURE.md` seção 4.3) |

## 10. Histórico de revisões

| Versão | Data | Mudanças |
|---|---|---|
| 2.1 | 14/11/2026 | Revisão do PR #20. Seção 4: quadro que separa decisão estratégica, pré-requisito técnico, dependência, critérios, prioridade e autorização; situação dos blocos 6 e 7 por natureza do que falta; nova seção 4.4 com os dois caminhos possíveis e suas consequências, sem escolher. Seção 6: critério de saída da Fase A completo, com o que está e o que não está cumprido. Seção 9.1: decisões agrupadas em sequência, infraestrutura e produto, com o que cada uma destrava de fato (a primeira deixava de "destravar tudo"). Nenhuma decisão nova |
| 2 | 14/11/2026 | Reescrita depois da integração dos Lotes 7, 8 e 9 e do incremento 4.3 (`69758d4`). Estado entregue por bloco; seção de prontidão para operação real; próximas etapas reorganizadas pelos blocos do `ARCHITECTURE.md`, com as entradas que dependem do responsável; identificadores P1 a P14 aposentados, com tabela de correspondência; removidas as referências a fila, reserva, `run-due` e ao `FUTURE_ARCHITECTURE.md`, que nunca existiu; decisões abertas separadas das já tomadas. Nenhuma decisão nova |
| 1 | 04/11/2026 | Versão inicial (decisões L3 e L5), escrita antes do Lote 2. Chegou à `main` só em 14/11/2026 (`dffe0a5`) |
