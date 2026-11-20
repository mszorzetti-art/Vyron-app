# Affiliate Autopilot — Autonomia e agentes

> **Revisão 1.6 — 12/11/2026 (consolidação da especificação de autorização de publicação):** a seção 4 passa a separar invariantes permanentes (4.1), regra vigente da fase inicial (4.2), evolução futura por política (4.3), categorias (4.4), verificações obrigatórias (4.5) e versão, validade e novas versões (4.6). Este documento é a **referência normativa central** dessas regras; a especificação técnica está em `ARCHITECTURE.md` seção 4.7. **Classificação usada nesta revisão:** **[Decisão conceitual — 12/11/2026]** = regra ou princípio definido pelo proprietário; **[Proposta técnica]** = solução sugerida, ainda sujeita a validação durante a implementação; **[Parâmetro pendente]** = configuração ou valor que ainda precisa ser definido e aprovado. **Nada disto está implementado.** Esta revisão é documental: não autoriza implementação, não ativa políticas e não altera níveis ou permissões de autonomia.
> **Nota sobre as revisões de 06/11/2026:** as revisões 1.3 e 1.4 tinham cabeçalho "proposta para aprovação", embora o corpo usasse a marcação **[Acordado]**. O status histórico é, portanto, ambíguo e não deve ser lido como aprovação definitiva de todo o seu conteúdo. A decisão conceitual de 12/11/2026 estabelece a separação entre invariantes, regra inicial e evolução futura, sem aprovação retroativa dos demais conteúdos daquelas revisões.

> **Revisão 1.5 — 08/11/2026 (proposta para aprovação):** acrescenta o objetivo de autonomia de longo prazo (seção 3.1) e a diretriz de aprendizado contínuo e Machine Learning (seção 11.4). Nada disso está implementado.

> **Revisão 1.4 — 06/11/2026 (proposta para aprovação):** explicita a aprovação humana individual obrigatória para toda publicação pública e decisões de nicho/produto/oferta, com central móvel como experiência de destino. A autonomia por política continua válida para tarefas internas e preparatórias, sem substituir o controle editorial.

> **O que este documento é:** como a automação operacional (decisão L2) pode ser organizada em agentes especializados, com níveis de autonomia, aprovação humana, limites de custo, permissões, registros, recuperação de falhas e botão de parada (kill switch).
> **O que ele não é:** não descreve agentes existentes (não há nenhum) e não aprova a implementação de nenhum agente.
>
> **Situação:** **[Proposta]** — versão 1.6, 12/11/2026 (em revisão, não aprovada), com as decisões de autonomia aprovadas em 05/11/2026 marcadas como **[Acordado]** e as decisões conceituais de 12/11/2026 sobre autorização de publicação marcadas como **[Decisão conceitual — 12/11/2026]**. Planejamento de longo prazo. **Nenhum agente, framework de agentes ou provedor de IA está implementado.** Os agentes listados são possibilidades de arquitetura, não funcionalidades aprovadas.
> **Legenda:** a mesma de `PROJECT_VISION.md`.
> **Nota de 07/11/2026:** `FUTURE_ARCHITECTURE.md` e `PRODUCT_ROADMAP.md`, citados neste documento, nunca foram criados no repositório. Os "departamentos" (Central, Market & Product, Content Studio etc.) e os itens "P6" a "P11" do roadmap continuam sem documento de referência; a sequência real de lotes está em `PROJECT_STATUS.md`.

---

## 1. Objetivo **[Acordado — L2]**

- O sistema deve automatizar pesquisa, produção, adaptação, agendamento, publicação e análise.
- O responsável não deve depender de trabalho operacional manual recorrente. Seu papel é supervisionar, definir diretrizes e aprovar decisões relevantes.
- Trabalho manual só como solução temporária de validação ou contingência técnica.
- A automação respeita as APIs, as políticas e os limites de cada plataforma.

## 2. O que é um agente neste projeto **[Proposta]**

- **Um agente é um conjunto de tipos de tarefa** do núcleo de tarefas (`ARCHITECTURE.md` seção 4.1), e não um processo independente.
- Cada tipo de tarefa declara:
  - o nível máximo de autonomia;
  - as integrações que pode usar;
  - o custo máximo por execução.
- Agentes seguem as regras de comunicação de `ARCHITECTURE.md` seção 2:
  - consultas curtas pela interface interna do módulo dono dos dados;
  - trabalho demorado ou com efeito externo como tarefa na fila;
  - resultados gravados no PostgreSQL;
  - sem dependências circulares.
- A orquestração é do departamento Central (documento de departamentos ainda não criado; ver nota no início).
- **Sem framework de agentes por enquanto.** Um provedor de IA só entra pelo `LLMProvider`, com orçamento aprovado e limites de custo ativos.

## 3. Níveis de autonomia

| Nível | Descrição | Exemplos |
|---|---|---|
| 0 | Manual (decisão humana) | Estratégia, escolha de nicho, aprovação de orçamento e de políticas |
| 1 | Automático, somente leitura | Importar vendas, ler métricas, gerar relatórios e alertas |
| 2 | Automático, produz rascunhos e recomendações | Briefings, roteiros, pontuação de produtos, recomendações |
| 3 | Automático **após aprovação humana** | Ações fora das políticas vigentes, ou que alguma política exija aprovar individualmente |
| 4 | **Autonomia operacional dentro de limites previamente autorizados** **[Acordado — 05/11/2026]** | Planejar, executar, corrigir e otimizar atividades dentro das políticas, permissões e limites vigentes |

**Regras do nível 4 [Acordado — 05/11/2026]:**
- O sistema pode planejar, executar, corrigir e otimizar atividades dentro das políticas, permissões e limites.
- Ações fora desses limites exigem aprovação.
- A aprovação humana de tarefas operacionais pode funcionar **por política**, sem aprovação individual de cada execução. **Na fase inicial**, isso não se aplica a nenhum envio de conteúdo a plataforma externa, público ou privado, que exige autorização individual da versão exata (seção 4.2); a evolução para envio por política segue a seção 4.3. Nunca se aplica à escolha de nichos, marcas, produtos e ofertas (seção 4.1).

**Regras permanentes:**
- níveis 3 e 4 desligados por padrão;
- modo de simulação (dry-run);
- registro de quem aprovou ou de qual política autorizou cada ação;
- botão de parada.

**Ações que ficam fora de qualquer política por padrão [Proposta]:** só são executadas com aprovação explícita, salvo se o responsável as incluir expressamente numa política, com limites e salvaguardas próprios:
- gasto, compras e campanhas;
- criação de contas;
- ações irreversíveis.

A inclusão futura de gasto, compras ou campanhas em uma política não está aprovada neste momento. Exigiria decisão expressa, orçamento baseado somente em dinheiro efetivamente recebido, teto, período, critério de parada, registro e kill switch. Até lá, cada ação desse tipo permanece fora das políticas e exige aprovação individual. A aprovação por política é o mecanismo geral aprovado, mas não autoriza por si só nenhuma categoria de ação sensível.

Gerenciar credenciais nunca entra numa política (seção 6).

### 3.1 Objetivo de autonomia de longo prazo **[Acordado como destino — 08/11/2026]**

- A referência de autonomia é o **nível 4**: execução e otimização autônomas dentro de limites previamente autorizados. O objetivo é reduzir progressivamente a operação manual, de modo que o proprietário supervisione a operação e intervenha quando necessário, em vez de operar cada publicação, produto ou pedido.
- Continuam sob controle humano, conforme a criticidade: mudanças estratégicas relevantes; gastos fora dos limites aprovados; novos compromissos financeiros; alterações de políticas de segurança; decisões comerciais sensíveis; ações regulatórias ou jurídicas; operações que ultrapassem as permissões concedidas.
- Kill switch, auditoria das ações e rastreabilidade das decisões são obrigatórios (seções 9, 10 e 11.3).
- **Este objetivo não altera a regra vigente da fase inicial (seção 4.2) nem os invariantes (seção 4.1):** na fase inicial, todo envio continua exigindo autorização humana individual da versão exata, e nichos, marcas, produtos e ofertas continuam exigindo decisão do proprietário. A autorização individual de cada envio é regra de fase, não limitação definitiva da arquitetura: a evolução por política segue a seção 4.3 e depende de decisão expressa do proprietário (`PROJECT_VISION.md` seção 21, item 1).

## 4. Aprovação por política e autorização de publicação **[Acordado — 05/11/2026; Decisão conceitual — 12/11/2026]**

> **Registro [Decisão conceitual — 12/11/2026]:** esta seção separa invariantes permanentes (4.1), regra vigente da fase inicial (4.2) e evolução futura por política (4.3). Ela não autoriza implementação nem ativação de políticas. A edição dos documentos, a implementação da autorização individual e a ativação de qualquer política são três autorizações distintas e independentes do proprietário.

**Regra geral:** a aprovação por política autoriza tarefas internas e operacionais delimitadas, mas não elimina os pontos de decisão reservados ao proprietário. **Na fase inicial, todo envio de conteúdo a uma plataforma externa, público ou privado, exige autorização humana individual da versão exata** (4.2). Essa exigência é regra de fase, não limitação definitiva da arquitetura: a publicação poderá evoluir para execução dentro de políticas previamente autorizadas (4.3). A escolha de nicho, marca, produto e oferta comercial exige sempre decisão explícita do proprietário antes de orientar uma campanha (4.1). O que estiver fora de uma política exige aprovação específica.

**Conteúdo mínimo de uma política [Proposta]:**

| Elemento | Exemplo |
|---|---|
| Escopo | Canal, marca, tipo de ação, categoria de conteúdo |
| Limites | Quantidade por dia, custo máximo, horários |
| Condições | Checklist editorial (`CONTENT_STRATEGY.md` 12.1) e verificações de conformidade aprovados |
| Fase | Fase A (só não público) ou Fase B (público, depois de autorização explícita) |
| Validade e revogação | Data de início, revisão periódica, revogação imediata pelo responsável |
| Registro | Identificador da política gravado no `audit_log` em cada ação |

Uma política de publicação (4.3) precisa definir também marca, canal, formato, categoria de conteúdo, quantidade e frequência máximas, verificações obrigatórias e versão.

**Publicação [Acordado — 05/11/2026; ajustado pela decisão conceitual de 12/11/2026]:**
- Fase A: validação privada/não pública, com visibilidade explicitamente definida. **No MVP, o envio privado também exige autorização individual vinculada ao hash da versão exata** (4.1, item 4, e 4.2). A automação da Fase A dentro de política específica, prevista em 05/11/2026, fica **adiada**: permanece na arquitetura futura e segue a seção 4.3.
- Fase B: publicação pública somente depois de autorização do responsável para operar publicamente **e com autorização válida para a versão exata — individual na fase inicial** (4.2).
- A autorização da Fase B habilita a operação pública controlada, mas não aprova conteúdos futuros. Na fase inicial, cada peça passa pelo painel móvel e recebe registro de autorização vinculado ao hash da sua versão (4.6).
- Todo envio respeita limites, permissões, verificações obrigatórias (4.5) e o botão de parada.

**Ainda em aberto [A definir]:**
- o conteúdo da primeira política;
- quais tarefas internas/preparatórias podem operar por política e quais categorias de decisão continuam reservadas ao proprietário; na fase inicial, a autorização individual de cada envio é obrigatória (4.2; `CONTENT_STRATEGY.md` seção 15);
- se gasto, compras ou campanhas poderão algum dia ser incluídos em política com limites; **nenhuma autorização de gasto está vigente** (`ARCHITECTURE.md` seção 4.11);
- a ativação de qualquer política de publicação (4.3): depende de decisão expressa do proprietário, revisão de riscos e implementação testada. **Nenhuma política de publicação está ativa ou implementada**;
- os parâmetros pendentes e as propostas técnicas listados na seção 13.

### 4.1 Invariantes permanentes **[Decisão conceitual — 12/11/2026]**

Valem em qualquer fase e sob qualquer política:

1. Nichos, marcas, produtos, ofertas e decisões comerciais estratégicas são decisão do proprietário. Nenhuma política as delega.
2. Gastos, compras e campanhas ficam fora de política por padrão. Criação de contas e ações irreversíveis exigem ação direta do proprietário. Credenciais nunca entram em política (seções 3 e 6).
3. O sistema nunca cria, altera, amplia, renova ou reativa por conta própria suas políticas, seus limites financeiros ou seu nível de autonomia. Pode recomendar; a mudança é ato do proprietário, versionado e auditado.
4. Todo envio de conteúdo a uma plataforma externa, público ou privado, exige autorização válida para o hash exato da versão (4.6). Uma autorização vale para um único hash; um hash antigo nunca autoriza um conteúdo cujo hash mudou.
5. O Stop All (seções 10 e 11.3) permanece sempre disponível. Quando acionado, bloqueia as operações abrangidas, inclusive envios e publicações, e prevalece sobre qualquer autorização ou política. A auditoria é permanente.
6. As verificações obrigatórias não têm mecanismo de exceção. Uma falha real exige correção antes do envio; nenhuma aprovação, individual ou por política, serve para contornar uma falha (4.5).
7. A classificação definitiva de riscos cabe exclusivamente ao proprietário. O sistema nunca declara, por conta própria, que um risco desconhecido é seguro (4.4).

### 4.2 Regra vigente da fase inicial **[Decisão conceitual — 12/11/2026]**

- Todo envio externo exige autorização humana individual para a versão exata do conteúdo, inclusive o envio privado.
- A autorização precisa estar válida no momento do envio (4.6).
- As verificações obrigatórias são executadas imediatamente antes de cada envio (4.5).
- É uma regra desta fase, não uma limitação definitiva da arquitetura. As políticas de autorização permanecem na arquitetura futura (4.3), mas não são implementadas nem ativadas nesta etapa: o MVP implementa apenas a autorização individual.

### 4.3 Evolução futura por política **[Decisão conceitual — 12/11/2026; não implementada, não ativada]**

- Só pode ser ativada por decisão expressa do proprietário, depois de revisão de riscos e de implementação validada.
- Nunca é ativada pelo sistema nem por quantidade de aprovações anteriores.
- Cada política tem escopo definido: marca, canal, formato, categoria de conteúdo e demais limites pertinentes. Inclui quantidade e frequência máximas, validade, verificações obrigatórias, registro de versão e revogação imediata pelo proprietário.
- O sistema pode recomendar mudanças numa política, mas nunca a modifica nem a amplia por conta própria (4.1, item 3).

| Situação | Efeito |
|---|---|
| Política vencida | O conteúdo editorial comum volta à aprovação individual |
| Política revogada | Não autoriza novas publicações; o conteúdo editorial comum pode voltar à aprovação individual, desde que continue permitido. O histórico de autorizações, decisões e publicações anteriores é preservado |
| Política suspensa por incidente | Bloqueio até investigação e resolução |
| Falha de conformidade | Bloqueio até correção e nova verificação (4.5) |
| Conteúdo proibido ou inseguro | Permanece bloqueado, sem possibilidade de liberação por aprovação individual |

### 4.4 Categorias de aprovação **[Decisão conceitual — 12/11/2026]**

| Categoria | Regra |
|---|---|
| Conteúdo editorial comum | Autorização individual na fase inicial (4.2); poderá futuramente operar por política (4.3) |
| Nicho, marca, produto, oferta e decisões comerciais estratégicas | Sempre decisão do proprietário (4.1, item 1) |
| Temas sensíveis e de alto risco | Sempre aprovação individual, mesmo com política ativa |
| Alteração material de peça já autorizada | Sempre aprovação individual, mesmo com política ativa |
| Conteúdo editorial comum fora do escopo da política | Não é publicado automaticamente; pode ser encaminhado à aprovação individual |
| Conteúdo proibido, inseguro ou com falha de conformidade | Bloqueado; não é liberado apenas por aprovação individual (4.5) |
| Risco relevante ainda não classificado | Bloqueio preventivo até a classificação pelo proprietário |

**Temas sensíveis.** Aprovação individual obrigatória para: saúde e alegações médicas; finanças e investimentos; apostas e jogos de azar; conteúdo direcionado ao público infantil; segurança de produtos e pessoas. A lista não é fechada: novas categorias podem ser incluídas por decisão do proprietário.

**Riscos relevantes ainda não classificados.**
- O sistema pode detectar, identificar e sinalizar riscos; o proprietário também pode sinalizá-los diretamente.
- Enquanto um risco relevante não estiver classificado, o conteúdo fica bloqueado preventivamente.
- O sistema pode recomendar uma classificação, mas a classificação definitiva e a decisão sobre a política aplicável cabem exclusivamente ao proprietário (4.1, item 7).

**Alteração material.** É material qualquer mudança em:
- preço, desconto, condição de pagamento, oferta, benefício, disponibilidade, garantia, prazo ou condição de compra;
- promessa comercial ou alegação central;
- link ou destino comercial, por alteração ou substituição, inclusive a mudança do destino comercial efetivo sem mudança do endereço escrito;
- identificação ou divulgação de conteúdo afiliado;
- arquivo de mídia, por substituição ou modificação;
- configuração de visibilidade (**[Proposta técnica]**: decorre de a visibilidade integrar o manifesto, 4.6).

Não há limiar financeiro arbitrário. Não se presume equivalência entre arquivos visualmente semelhantes. No MVP, toda alteração, material ou não, já exige nova aprovação individual (4.6); a definição acima orienta a futura aplicação de políticas.

### 4.5 Verificações obrigatórias **[Decisão conceitual — 12/11/2026, salvo onde indicado]**

1. **Dois controles distintos.** A autorização humana autoriza o conteúdo exato. As verificações determinam se ele ainda pode ser enviado. Um controle não substitui o outro.
2. **Momento.** Todo envio passa novamente pelas verificações obrigatórias, com as regras vigentes, imediatamente antes da publicação real, mesmo que a peça já tenha passado por elas na aprovação.
3. **Falha.** Uma falha em qualquer verificação bloqueia o envio. Não existe mecanismo de exceção para ignorar verificações obrigatórias.
4. **Falha real de conformidade.** Exige correção antes do envio. A correção gera nova versão (4.6).
5. **Falso positivo.** Pode levar à revisão do mecanismo ou da regra, mediante decisão do proprietário, com versionamento e auditoria. A peça só segue depois de passar na verificação revisada; não há liberação pontual.
6. **Mudança de regras.** Não apaga a autorização original, que permanece registrada. Ficam registradas a versão das regras usada na aprovação e a versão usada na verificação imediatamente anterior ao envio.
7. **Destino dos links.**
   - Compara-se o destino comercial efetivo, não apenas o endereço bruto.
   - O destino final verificado e a cadeia de redirecionamentos são registrados no momento da aprovação e verificados novamente antes do envio.
   - Todos os parâmetros de URL são significativos por padrão. Um parâmetro só pode ser desconsiderado se constar em lista explícita, determinística, específica por plataforma, versionada e auditável, e apenas quando for comprovadamente volátil e sem efeito comercial. **[Parâmetro pendente]**: as listas por plataforma.
   - Parâmetros que identifiquem produto, oferta, campanha ou afiliado nunca são ignorados.
   - Se o destino comercial mudar: bloqueio e nova aprovação individual. Se não for possível verificar o destino, ou determinar com segurança que ele continua equivalente: bloqueio.
   - Nenhuma IA decide equivalência entre destinos.
   - A verificação não pode servir de caminho para acessar endereços internos ou recursos privados por meio de redirecionamentos. Os requisitos do verificador estão em `ARCHITECTURE.md` seção 4.7.3 (**[Proposta técnica]**).
   - **[Proposta técnica]** Para plataforma sem regra definida, comparação exata do destino final.
8. **Condições comerciais e ofertas.**
   - Antes do envio, verificam-se as condições comerciais relevantes para a data prevista de publicação, incluindo preço, oferta, disponibilidade, garantia e prazos, em fontes confiáveis, quando houver integração disponível.
   - Não há prazo universal: cada tipo de informação tem prazo máximo de atualização por fonte e mercado. **[Parâmetro pendente]**: esses prazos. **[Proposta técnica]**: sem prazo configurado, o dado é tratado como vencido.
   - Dado vencido ou não verificável: bloqueio. Condição comercial alterada: bloqueio até nova aprovação.
   - Enquanto não houver integração capaz de confirmar a informação atual, importações manuais antigas não são tratadas como confirmação atualizada.
   - **Validade da oferta e validade da autorização são coisas distintas.** A primeira é um fato comercial; a segunda é a permissão operacional de envio (4.6).
   - Uma oferta cuja data final seja informada sem horário vale até o fim daquele dia no fuso do mercado. Se não for possível determinar com segurança o fuso ou o instante aplicável: bloqueio até confirmação do proprietário.
9. **Confirmação manual de condições comerciais no MVP.** O proprietário pode confirmar explicitamente preço, disponibilidade e outras condições, registrando valor, fonte consultada, horário e fuso, responsável, data prevista de publicação e validade da confirmação. Confirmação vencida ou sem evidência suficiente bloqueia o envio. A confirmação manual é uma fonte de verificação; não é exceção às verificações.
10. **Atualização de evidências.**
    - Atualizar evidência não é renovar autorização.
    - Reconfirmar preço, disponibilidade ou condições com os mesmos valores, usando evidência atualizada, não invalida automaticamente a autorização.
    - Alteração efetiva de preço, oferta, disponibilidade, garantia, prazo ou outra condição de referência invalida a autorização. Alteração do destino comercial efetivo também invalida.
    - Atualizar evidências não renova nem estende a validade da autorização.
    - Evidências anteriores e novas ficam todas registradas, com fonte, horário, fuso, resultado e vínculo com o hash. Nada é sobrescrito.
    - **[Proposta técnica]** A comparação entre valores de referência é exata e determinística.
11. **Campos opcionais e conformidade.**
    - Um campo opcional ausente (`null`) não representa dispensa de verificação.
    - Quando a divulgação de afiliado for obrigatória (`CONTENT_STRATEGY.md` seção 13), sua ausência, incompletude ou posição inadequada bloqueia o envio.
    - O mesmo princípio vale para metadados e declarações exigidos pela plataforma ou por regras aplicáveis.
    - As verificações consideram o contexto e os requisitos aplicáveis à peça, sem presumir que um campo opcional possa ser ignorado.
12. **Registro.** O resultado de cada verificação é gravado para auditoria, vinculado ao hash.

### 4.6 Versão, validade e novas versões **[Decisão conceitual — 12/11/2026, salvo onde indicado]**

**Versão autorizada.** Uma versão é o conjunto completo do que será enviado à plataforma e, consequentemente, o que compõe o hash:
- texto ou roteiro integral;
- título e descrição;
- arquivos de vídeo, imagem e áudio;
- legendas e elementos visuais incorporados;
- links e destinos, como escritos;
- divulgação de afiliado;
- configurações relevantes de publicação, como marca, canal, formato e a configuração exata de visibilidade.

A especificação do manifesto e do cálculo do hash está em `ARCHITECTURE.md` seção 4.7.2 (**[Proposta técnica]**).

**Regras do MVP.**
1. Toda autorização é vinculada ao hash exato de uma versão específica do conteúdo.
2. Qualquer alteração, inclusive de formatação, espaçamento, quebra de linha ou correção ortográfica, gera uma nova versão sem autorização.
3. Toda nova versão exige nova aprovação individual antes do envio.
4. Não há herança automática, autorização derivada nem equivalência automática entre versões.
5. O sistema pode apresentar uma comparação visual entre a versão anterior e a nova, destacando as diferenças. Essa comparação é apenas informativa: não concede autorização.
6. A possibilidade de autorizações derivadas ou de herança de autorização fica reservada para uma evolução futura, dependente de nova decisão expressa do proprietário, revisão de riscos e implementação testada.
7. **[Proposta técnica]** Considera-se envio toda operação que cria ou altera conteúdo ou visibilidade na plataforma. Tornar público um item enviado como privado é novo envio, de nova versão.

**Agendamento.** Data e hora são exclusivamente operacionais e ficam fora do manifesto, mesmo quando possam ser enviadas à plataforma como parâmetros de agendamento. Reagendar não altera o hash nem exige nova aprovação por si só, mas a autorização e todas as verificações precisam continuar válidas no momento do envio. No MVP, o sistema envia o conteúdo no horário programado, sem utilizar o agendamento nativo da plataforma, para que as verificações ocorram imediatamente antes da publicação real.

**Adaptador.** O adaptador de publicação só pode enviar campos e valores presentes no manifesto autorizado e parâmetros operacionais de uma lista fechada e documentada. Esses parâmetros não podem alterar conteúdo, visibilidade, destino comercial ou condições autorizadas; qualquer campo não previsto é recusado; a configuração efetivamente enviada é auditável (`ARCHITECTURE.md` seção 4.7.4). **[Parâmetro pendente]**: a lista por adaptador.

**Validade da autorização individual.**
1. A aprovação histórica permanece registrada e nunca é apagada.
2. A permissão operacional para publicar pode expirar. Toda autorização individual tem um instante explícito de vencimento, com fuso horário, registrado no momento da aprovação.
3. A autorização não pode ultrapassar o fim de qualquer oferta citada (4.5, item 8).
4. Se não for possível determinar com segurança o instante de vencimento, a autorização não é emitida.
5. O sistema não renova nem estende autonomamente uma autorização. Estender é nova aprovação individual.
6. Revogação, alteração do conteúdo, invalidação (4.5) ou vencimento impedem o envio. Autorização vencida exige nova aprovação individual.
7. **[Parâmetro pendente]** A validade padrão por marca, canal e categoria. Sem padrão configurado, a aprovação só é emitida com vencimento informado pelo proprietário (**[Proposta técnica]**).
8. **[Proposta técnica]** A autorização vale enquanto o instante atual for anterior ao vencimento; no instante do vencimento, já não vale.

**Evidências da aprovação.** Junto à autorização ficam registrados o destino final e a cadeia de redirecionamentos dos links, as condições comerciais de referência com fonte e horário, a versão das regras de verificação e a validade. As evidências não integram o hash. Mudança do destino comercial ou de condição comercial sem mudança do conteúdo invalida a autorização, sem apagá-la; uma nova aprovação individual pode ser emitida para o mesmo hash, com novas evidências.

## 5. Agentes possíveis

Cada agente pertence a um departamento (lista de departamentos ainda não documentada; ver nota no início). "Nível máximo" é o teto proposto; a classificação final de cada ação é **[A definir]**.

| Agente | Departamento | Responsabilidade | Entradas | Saídas | Ferramentas permitidas | Nível máximo | Dependências | Custo e risco |
|---|---|---|---|---|---|---|---|---|
| Orchestrator | Central | Criar e distribuir tarefas, aplicar níveis, limites e botão de parada | Agendas, aprovações | Tarefas, registros | Banco | — (é o núcleo; não usa IA) | Núcleo de tarefas | Loops; mitigado pela seção 9 |
| Research | Market & Product | Pesquisar nichos e perguntas da audiência | Palavras-chave, dados próprios | Candidatos e relatórios para decisão do proprietário | Leitura de fontes permitidas | 2 | Banco | Fontes não confiáveis; seleção final do nicho é humana |
| Trend Intelligence | Market & Product | Detectar tendências do nicho | Métricas e buscas | Sinais e recomendações | Leitura de APIs permitidas | 2 | Métricas | Sobreposição com Research; podem ser um só agente |
| Product Intelligence | Market & Product | Importar, comparar e pontuar produtos candidatos | Arquivos e APIs da plataforma | Lista de candidatos, dados e grau de confiança; decisão final do proprietário | Importador, plataforma de afiliados (leitura) | 1 (importação) e 2 (pontuação) | Etapa 2 | Dados desconhecidos tratados como zero (proibido); seleção final não é automática |
| SEO | Content Studio | Otimizar títulos, descrições e palavras-chave (no YouTube e, se houver, no site) | Peças em rascunho, buscas | Sugestões | Leitura de métricas de busca | 2 | Content | Clickbait (proibido por `CONTENT_STRATEGY.md` 5.2) |
| Scriptwriter | Content Studio | Escrever roteiros e textos a partir do dossiê | Briefing, dossiê, guia da marca | Rascunhos | `LLMProvider` | 2 | Content; orçamento de IA | Custo; erros factuais; políticas de conteúdo sintético |
| Creative | Content Studio | Produzir narração, imagens e montagem; adaptar para cada canal | Roteiros aprovados para produção | Mídia em rascunho | Provedores de mídia | 2 | P11 do roadmap | Custo; direitos autorais |
| Distribution | Distribution & Traffic | Preparar publicação e publicar somente a peça aprovada na versão exata | Conteúdo e aprovação válida | `publications` | Adaptadores de publicação | 3 na fase inicial para todo envio, público ou privado (autorização individual, seção 4.2); 4 somente sob política ativa (seção 4.3), que hoje não existe | P6 | Publicação indevida; vídeo público por padrão no YouTube se o estado não for explícito |
| Analytics | Analytics | Ler métricas e calcular os dois indicadores (L1) | Canais, vendas, recebimentos | Relatórios | Leitura de APIs | 1 | P7, P8 | Atribuição apresentada como fato (proibido) |
| Optimization | Optimization | Recomendar ajustes e, dentro de política, aplicá-los | Relatórios | Recomendações e ajustes registrados | Banco e interfaces dos módulos | 2 (recomendações); 4 para ajustes previstos em política | P9 | Conclusões com poucos dados |
| Compliance | Optimization, Finance & Compliance | Verificar divulgação, fontes, privacidade e políticas antes de aprovar e publicar | Peças, regras | Aprovado na verificação ou bloqueado | Regras em código | 2 (bloqueia, não publica) | Content, Distribution | Funciona melhor como verificação obrigatória do que como agente autônomo. O bloqueio não tem exceção (seção 4.1, item 6); sinaliza riscos, mas não os classifica (seção 4.1, item 7) |

## 6. Ações com controles específicos **[Proposta]**

| Ação | Controle |
|---|---|
| Gasto, compra, campanha | Fora de política por padrão (seção 3); orçamento só com dinheiro efetivamente recebido (L1); teto por execução e por mês |
| Publicação | Todo envio, público ou privado, exige autorização válida vinculada ao hash da versão exata (seção 4.1); individual na fase inicial (seção 4.2); não público na Fase A; público só na Fase B; verificações obrigatórias imediatamente antes de cada envio (seção 4.5); idempotência; botão de parada |
| Criação de contas e mudança de credenciais | Somente o responsável; nunca dentro de política; nenhum agente lê ou altera credenciais |
| Ações irreversíveis (apagar, despublicar em massa) | **Lista fechada no código**, não só no documento; fora de política por padrão |
| Uso de IA paga | Bloqueado sem orçamento aprovado; consumo registrado por execução |

## 7. Segurança e permissões **[Proposta]**

- **Uma credencial por integração**, com privilégio mínimo e somente leitura sempre que a API permitir.
- **Segredos sempre fora do repositório** e Gitleaks no CI antes de qualquer credencial real **[Acordado — L7]**.
- Cada tipo de tarefa só acessa as integrações que declarou.
- Logs nunca contêm segredos (redação já existe em `core/log.py`).
- No futuro, credenciais separadas por marca (`PROJECT_VISION.md` seção 5).

## 8. Limites de custo **[Proposta]**

- Antes de qualquer serviço pago: teto por execução, por dia e por mês, definidos pelo responsável **[A definir]**. Nenhum valor é fixado neste documento.
- Ao atingir o teto, as tarefas que geram custo param e o responsável é notificado.
- O consumo é registrado por tarefa, por agente e por marca, e entra nos custos dos dois indicadores (L1).
- Orçamento só a partir de dinheiro efetivamente recebido **[Acordado — L1]**.

## 9. Registros, falhas e prevenção de loops **[Proposta]**

- **Registros:**
  - toda execução grava em `job_runs`;
  - toda aprovação, publicação e mudança de estado grava em `audit_log`, com quem, quando, o quê e o resultado.
- **Recuperação de falhas:**
  - concessão com prazo;
  - retentativa com espera crescente;
  - estado `dead` com notificação;
  - idempotência nos efeitos externos (`ARCHITECTURE.md` seção 9.2).
- **Prevenção de loops:**
  - limite de tentativas por tarefa;
  - limite de tarefas filhas por tarefa;
  - profundidade máxima de cadeia de tarefas;
  - limite de execuções por agente e por dia.

## 10. Botão de parada (kill switch) **[Proposta]**

- Uma configuração global verificada por **todas** as tarefas de nível 3 e 4 antes de agir, além de desativar as agendas (`ARCHITECTURE.md` seção 10).
- Pode ser acionado pelo celular. Uma opção é um workflow manual do GitHub, acionado pelo app **[A validar]**.
- Desligar o botão de parada exige ação explícita do responsável, registrada no `audit_log`.
- **[Decisão conceitual — 12/11/2026]** O mecanismo de emergência permanece permanentemente disponível. Quando acionado, bloqueia as operações abrangidas, inclusive envios e publicações, e prevalece sobre qualquer autorização ou política (seção 4.1, item 5).

## 11. Aprovação pelo celular **[Acordado como requisito de destino]**

- O proprietário deverá revisar e decidir pelo celular. A experiência final pretendida é uma central/painel móvel do Affiliate Autopilot; pode começar como web responsiva segura, sem exigir aplicativo nativo no MVP.
- O painel deve apresentar prévia do conteúdo, roteiro/texto, título, descrição, mídia, fontes, produto/oferta, links, divulgação de afiliado, canal/formato e visibilidade pretendida. Deve exibir todos os elementos do manifesto da versão (seção 4.6), o destino comercial verificado de cada link, as condições comerciais confirmadas, o fim de cada oferta citada e o vencimento da autorização. Havendo versão anterior, pode exibir a comparação entre as versões, apenas informativa.
- Ações disponíveis: aprovar, rejeitar ou solicitar ajustes. A aprovação fica vinculada ao hash/versão exata e registrada no `audit_log` (ou tabela específica de aprovações), com as evidências e a validade (seção 4.6).
- Qualquer alteração após a aprovação gera nova versão sem autorização e devolve o item para `in_review` (seção 4.6). No MVP não há herança de autorização entre versões.
- Workflow manual do GitHub pode servir como contingência temporária, mas não substitui a experiência móvel de destino.
- A etapa e a implementação concreta devem ser alinhadas à sequência de lotes registrada em `PROJECT_STATUS.md`.

## 11.1 Feedback adaptativo e aprendizado editorial **[Diretriz de destino]**

- O sistema registra decisões do proprietário (aprovar, rejeitar, solicitar ajuste e editar) vinculadas à versão exata do conteúdo. Quando possível, o proprietário pode classificar o motivo: precisão/fonte, tom, estrutura, originalidade, adequação ao público, produto/oferta, divulgação ou conformidade.
- O histórico pode orientar briefings, listas de verificação, regras editoriais e exemplos para futuras gerações. A utilização de exemplos deve ser seletiva, contextual e revisável; uma rejeição sem motivo não deve ser interpretada automaticamente como uma regra geral.
- Mudanças em prompts, pesos ou regras devem ser versionadas, testáveis e reversíveis. O sistema deve distinguir preferência editorial de requisito legal, factual ou de política de plataforma; feedback não pode enfraquecer controles obrigatórios.
- O sistema pode sugerir que uma preferência parece consistente após várias decisões, mas não deve declarar confiança suficiente com base apenas em uma sequência curta de aprovações. Edições, rejeições e resultados posteriores também precisam ser considerados.
- **O aprendizado nunca concede autorização, não classifica riscos e não ativa nem amplia políticas** (seção 4.1, itens 3 e 7). Na fase inicial, todo envio continua condicionado à autorização humana individual da versão exata, conforme as seções 4.2 e 11 e `ARCHITECTURE.md` 12.2. A evolução por política depende de decisão expressa do proprietário (seção 4.3) e não decorre de uma sequência de aprovações. O aprendizado reduz retrabalho; não transfere a decisão para o sistema.

## 11.2 Fuso horário e janelas locais **[Diretriz de destino]**

- Marcas/canais poderão definir fuso IANA e janelas locais preferenciais. O cálculo deve respeitar horário de verão e alterações legais, e não usar apenas offsets fixos.
- A janela orienta quando uma peça já aprovada pode ser distribuída; não substitui aprovação, disponibilidade da plataforma ou política de publicação. Horários devem ser tratados como hipóteses a validar com métricas, não como garantia algorítmica.

## 11.3 Stop All global **[Diretriz de destino]**

- O controle global `ACTIVE`/`HALTED` deve ser consultado no início do lote e novamente antes de cada efeito externo ou ação sensível.
- Em `HALTED`, bloquear publicações, chamadas externas mutáveis e novas ações automatizadas; permitir apenas diagnóstico/leitura explicitamente seguros.
- Se o estado não puder ser consultado, falhar fechado para efeitos externos. Retomar somente por ação explícita e auditada do proprietário, após reconciliar operações incertas.
- O botão móvel é a experiência pretendida. Suspender agendamentos ajuda, mas não substitui a verificação por tarefa de processos já iniciados.
- **[Decisão conceitual — 12/11/2026]** O mecanismo permanece sempre disponível. `ACTIVE` indica operação normal e não equivale a autorização para publicar; nenhum estado de emergência acionado pode ser interpretado como autorização (seção 4.1, item 5).

## 11.4 Aprendizado contínuo e Machine Learning **[Diretriz de destino — 08/11/2026]**

O aprendizado contínuo é objetivo central da evolução do sistema. Fontes de aprendizado: aprovações e rejeições; produtos selecionados e descartados; desempenho comercial e conversões; devoluções e reclamações; alterações de preços; sazonalidade; desempenho de conteúdos; resultados por canal e por país; decisões humanas; erros e acertos operacionais. Decisões e seus motivos são armazenados para reconhecer padrões em situações futuras.

Três mecanismos distintos:

| Mecanismo | Uso | Situação |
|---|---|---|
| Regras determinísticas | Critérios explícitos, validações, limites e políticas | Base atual (por exemplo, validação dos importadores); pontuação de produtos planejada (`ARCHITECTURE.md` seção 4.5) |
| LLMs e agentes | Pesquisa, interpretação, análise, classificação e geração de conteúdo, com controles | Não implementado; só via `LLMProvider` com orçamento aprovado (seção 2) |
| Machine Learning | Modelos estatísticos e preditivos treinados ou ajustados com dados reais suficientes | Não implementado; **não antecipar** sem dados e casos de uso validados |

Evolução gradual:
1. Coleta e estruturação confiável de dados.
2. Estatísticas e regras baseadas em evidências.
3. Modelos preditivos em modo de observação (sem afetar decisões).
4. Validação em produção com monitoramento, comparação e rollback.
5. Só então, uso controlado nas decisões operacionais.

O sistema **não altera seus próprios critérios críticos sem governança**: mudanças de pesos, regras, prompts ou modelos são versionadas, testáveis, reversíveis e registradas (seção 11.1). Aprendizado não concede autoaprovação nem amplia permissões.

## 12. O que não fazer agora

- Implementar agentes, frameworks de agentes ou provedores de IA.
- Dar a qualquer agente acesso a credenciais, gasto ou criação de contas.
- Publicar publicamente antes da autorização explícita da Fase B, ou enviar qualquer conteúdo sem autorização válida para a versão exata (seção 4).
- Implementar ou ativar políticas de publicação (seção 4.3) sem decisão expressa do proprietário.

## 13. Pendências

| # | Item | Tipo |
|---|---|---|
| 1 | ~~Definição do nível 4~~ **Resolvido em 05/11/2026** (seção 3) | — |
| 2 | ~~Granularidade geral da aprovação operacional~~ **Resolvido em 05/11/2026: por política para tarefas delimitadas**; salvaguarda editorial de 06/11/2026 exige aprovação individual de cada peça pública (seção 4). Em 12/11/2026, essa exigência foi definida como regra da fase inicial (4.2), estendida a todo envio, com evolução futura por política (4.3) | — |
| 2a | Conteúdo da primeira política e categorias com aprovação individual | Decisão |
| 2b | Se gasto, compras e campanhas poderão futuramente entrar em política com limite (seção 3); nenhuma autorização de gasto está vigente | Decisão |
| 3 | Classificação de cada ação por nível e por política | Decisão |
| 4 | Tetos de custo, quando houver serviço pago | Decisão |
| 5 | Implementar e testar a central móvel de aprovação e o botão de parada | Implementação/verificação |
| 6 | Conteúdo e ativação da primeira política de publicação (seção 4.3). Nenhuma política de publicação está ativa ou implementada | Decisão futura do proprietário |
| 7 | Autorização derivada ou herança de autorização entre versões (seção 4.6, regra 6) | Decisão futura do proprietário |
| 8 | Validação das propostas técnicas de `ARCHITECTURE.md` seção 4.7: manifesto e cálculo do hash, serialização canônica, verificador de destinos externos, adaptador de publicação e tratamento de instantes; e das propostas técnicas marcadas nas seções 4.4 a 4.6 | Proposta técnica (validar na implementação) |
| 9 | Prazos máximos de atualização das evidências comerciais, por tipo de informação, fonte e mercado (seção 4.5, item 8) | Parâmetro pendente |
| 10 | Validade padrão das autorizações por marca, canal e categoria (seção 4.6) | Parâmetro pendente |
| 11 | Listas de parâmetros de URL que podem ser desconsiderados, por plataforma (seção 4.5, item 7) | Parâmetro pendente |
| 12 | Limites do verificador de destinos: redirecionamentos, tempo e tamanho de resposta (`ARCHITECTURE.md` seção 4.7.3) | Parâmetro pendente |
| 13 | Parâmetros operacionais permitidos por adaptador de publicação (seção 4.6; `ARCHITECTURE.md` seção 4.7.4) | Parâmetro pendente |
| 14 | Fuso horário de referência de cada mercado (seção 4.5, item 8; `ARCHITECTURE.md` seção 4.7.5) | Parâmetro pendente |
| 15 | Implementação da autorização individual por hash (seção 4.2). Não autorizada por esta revisão | Implementação (autorização separada) |


### 13.1 Matriz de permissões por tipo de ação **[Proposta]**

O nivel de autonomia nao e uma autorizacao geral. A permissao deve ser avaliada para cada acao, marca, canal, fase e politica.

| Tipo de acao | Regra inicial |
|---|---|
| Pesquisa, leitura de metricas e importacao | Automatizavel dentro de limites tecnicos e de privacidade |
| Pontuacao, classificacao e recomendacoes | Automatizavel, com criterios explicaveis, origem dos dados e grau de confianca |
| Briefings, roteiros e pecas em rascunho | Automatizavel; sem publicacao e sujeito a verificacao factual/editorial |
| Ajustes reversiveis de metadados ou agenda | Somente se uma politica especifica autorizar escopo, limites, condicoes e registro |
| Upload privado/não público | Somente na Fase A. No MVP, com autorização individual vinculada ao hash da versão exata e visibilidade explícita no manifesto (seções 4.1, 4.2 e 4.6); a automação por política fica adiada (seção 4.3) |
| Publicação pública | Somente na Fase B, depois de autorização para operação pública e com autorização válida para a versão exata: individual na fase inicial, pelo painel móvel (seção 4.2); evolução por política conforme as seções 4.3 e 4.4 |
| Gasto, compra, anuncio ou compromisso financeiro | Bloqueado por padrao; nenhuma autorizacao atual |
| Criacao de contas, gestao de credenciais e acoes irreversiveis | Sempre fora das politicas operacionais comuns; exigem acao direta do responsavel |

### 13.2 Controles que nao podem ser presumidos **[Proposta]**

- A ausencia de cartao cadastrado nao e controle de custo suficiente. Provedores pagos devem permanecer desativados por configuracao, com limites de chamadas, timeout, retentativas, teto aprovado e registro de consumo quando habilitados.
- Gitleaks ajuda a detectar segredos no repositorio, mas nao substitui redacao de logs, privilegio minimo, rotacao/revogacao e protecao de dados.
- Falha de autenticacao deve pausar a integracao afetada; nao repetir chamadas indefinidamente nem tentar contornar restricoes de conta.
- A autorização aponta para o hash exato da versão do conteúdo (seção 4.6). Qualquer alteração gera nova versão, que não herda a autorização anterior.
- Um campo opcional ausente não dispensa verificação, e atualizar evidências não renova nem estende uma autorização (seção 4.5).
- Uma resposta perdida apos uma chamada externa nao prova que a operacao falhou. Reconciliar com a plataforma antes de repetir para evitar duplicidade.

## 14. Histórico de revisões

| Versão | Data | Mudanças |
|---|---|---|
| 1.6 | 12/11/2026 | Consolidação da especificação de autorização de publicação (decisões conceituais de 12/11/2026). Seção 4 reorganizada em invariantes permanentes (4.1), regra vigente da fase inicial (4.2), evolução futura por política e seus estados (4.3), categorias, temas sensíveis, riscos não classificados e alteração material (4.4), verificações obrigatórias, destinos de links, condições comerciais, evidências e campos opcionais (4.5) e versão, hash exato, agendamento, adaptador, validade e evidências (4.6). Envio privado passa a exigir autorização individual por hash no MVP; automação da Fase A por política adiada. Ajustes de coerência nas seções 3, 3.1, 5, 6, 10, 11, 11.1, 11.3, 12, 13, 13.1 e 13.2. Propostas técnicas e parâmetros pendentes identificados como tais. Registrada a ambiguidade de status das revisões de 06/11/2026. Nada implementado; nenhuma política ativada. |
| 1.5 | 08/11/2026 | Objetivo de autonomia de longo prazo (nível 4 como referência, itens sob controle humano), sem alterar a aprovação individual de publicações públicas nem a decisão do proprietário sobre nichos, produtos e ofertas (3.1). Diretriz de aprendizado contínuo: regras determinísticas, LLMs/agentes e Machine Learning distinguidos, com evolução gradual e governança (11.4). |
| 1.4 | 06/11/2026 | Diretrizes de destino para feedback adaptativo versionado, fusos/janelas locais e Stop All com falha fechada. Explicitado que aprendizado não autoriza autoaprovação; aprovação humana individual de cada publicação pública permanece obrigatória. |
| 1.3 | 06/11/2026 | Proposta: aprovação humana individual obrigatória para cada publicação pública e decisão do proprietário sobre nichos/produtos/ofertas; central móvel como requisito de destino; políticas permanecem válidas para tarefas internas e preparatórias. |
| 1 | 04/11/2026 | Versão inicial (decisão L5) |
| 1.1 | 05/11/2026 | Em revisão. Nível 4 redefinido e aprovação por política, conforme as decisões de 05/11 (3 e 4); Fases A e B de publicação; comunicação entre agentes alinhada à `ARCHITECTURE.md` seção 2; tabelas de agentes e controles ajustadas; pendências 1 e 2 resolvidas |
| 1.2 | 05/11/2026 | Em revisao, nao aprovada. Secoes 3, 4 e 13: esclarecido que gasto, compras e campanhas permanecem fora de politicas por padrao; eventual inclusao futura depende de decisao expressa, limites e salvaguardas. Conteudo comercial e categorias de aprovacao continuam pendentes de politica especifica. |
