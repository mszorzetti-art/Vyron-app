# Affiliate Autopilot - Arquitetura Tecnica

> **Revisão 13 — 12/11/2026 (consolidação da especificação de autorização de publicação):** as regras normativas estão em `AUTONOMY_AND_AGENTS.md` seção 4 (referência central); este documento traz as consequências arquiteturais (princípio 9; seções 4.7, 8 e 12) e a especificação técnica (seções 4.7.1 a 4.7.6). **Classificação:** **[Decisão conceitual — 12/11/2026]** = regra definida pelo proprietário; **[Proposta técnica]** = solução sugerida, sujeita a validação na implementação, que não é decisão de implementação nem garantia de segurança; **[Parâmetro pendente]** = valor ou configuração ainda a definir e aprovar. Nada disto está implementado; esta revisão não autoriza implementação nem ativação de políticas. As revisões de 06/11/2026 (5 e 6) tinham cabeçalho de proposta e corpo marcado como **[Acordado]**: o status histórico é ambíguo e não equivale à aprovação definitiva de todo o seu conteúdo.

> **Revisão 5 — 06/11/2026 (proposta para aprovação):** explicita a arquitetura de destino para ecossistema privado multicanal, múltiplas redes de afiliados, conteúdo escrito/site, mercados internacionais e aprovação editorial móvel obrigatória. A arquitetura do MVP continua simples e sequencial.

> Status: **proposta**, em implementacao gradual. O estado real do codigo e a ordem real de desenvolvimento (lotes) estao em `PROJECT_STATUS.md` (somente informacoes verificadas).
> Visao de longo prazo e estado atual do projeto: ver `PROJECT_VISION.md` e `PROJECT_STATUS.md`. Esta arquitetura cobre so a fase inicial (uma operacao de afiliados); a evolucao futura orienta decisoes, mas nao e requisito atual. A arquitetura de destino esta nas secoes 12.1 a 12.6 deste documento, e os agentes e a autonomia, em `AUTONOMY_AND_AGENTS.md`.
> Nota (revisao 7, 07/11/2026): versoes anteriores citavam `PRODUCT_ROADMAP.md` e `FUTURE_ARCHITECTURE.md`. Esses arquivos **nunca existiram no repositorio**; as referencias foram redirecionadas para onde o conteudo realmente esta.
> Ultima verificacao de limites gratuitos: 04/11/2026 (paginas oficiais; ver secoes 6, 7 e 13).
> **Revisao 2 — 04/11/2026:** incorpora as decisoes L1, L2, L4, L6 e L7 aprovadas pelo responsavel e as contribuicoes de `ARCHITECTURE_proposta.md`. Mudancas na secao 14.
> **Revisao 3 — 05/11/2026 (em revisao, nao aprovada):** comunicacao entre modulos (secao 2), decisoes de 05/11/2026 sobre autonomia, publicacao, canais e comissao confirmada, e fatos oficiais sobre OAuth do YouTube (secoes 4.7 e 7). Mudancas na secao 14.
> Regra deste documento: nada aqui afirma que uma API e gratuita ou tem determinado recurso sem indicar o que **precisa ser verificado**.

## 1. Principios

1. **Custo zero no prototipo.** So servicos gratuitos ou de codigo aberto. Qualquer custo futuro precisa de decisao explicita.
2. **Simplicidade antes de escala.** Um unico pacote Python (monolito modular). Sem microsservicos, filas externas ou containers obrigatorios.
3. **O banco e a fonte da verdade.** Estado de tarefas, agenda, conteudo e metricas ficam no PostgreSQL. Isso permite trocar *onde* o codigo roda sem perder nada.
4. **Seguro por padrao.** Publicar e desligado por padrao, e so conteudo aprovado por uma pessoa pode ser publicado.
5. **Idempotencia.** Rodar a mesma tarefa duas vezes nao pode duplicar publicacoes, vendas ou relatorios.
6. **Desenvolvimento pelo celular.** Os testes rodam na nuvem (CI), nao numa maquina local.
7. **Dados reais ou dados de teste identificados.** Nunca valores inventados apresentados como reais.
8. **Crescer sem construir antes da hora.** A visao de longo prazo (varias marcas independentes sobre uma infraestrutura compartilhada, ver `PROJECT_VISION.md`) orienta decisoes pequenas, como nao gravar no codigo nome de marca, dominio ou conta. Nenhuma estrutura multi-marca e implementada antes de a validacao comercial inicial justificar. A unica preparacao aprovada e o `brand_id` como dimensao transversal dos dados desde o esquema v1 (secao 4.3, decisao L6).
9. **Automacao operacional como objetivo [Acordado — L2].** Pesquisa, coleta, analise, producao, adaptacao, agendamento e preparacao de publicacao devem ser progressivamente automatizadas. O responsavel supervisiona e aprova decisões editoriais/comerciais relevantes. **Nenhum envio a plataforma externa, público ou privado, ocorre sem autorização válida para o hash exato da versão; na fase inicial, essa autorização é sempre humana e individual** (`AUTONOMY_AND_AGENTS.md` seções 4.1 e 4.2). É regra da fase inicial, não limitação definitiva da arquitetura: a evolução para publicação por política segue a seção 4.3 do mesmo documento e depende de decisão expressa do proprietário. A automacao e hibrida e respeita APIs, políticas, custos e limites de cada plataforma.

## 2. Visao geral

```
                 +-------------------------+
  Agendador ---> |  CLI  (autopilot ...)   |   <- unico ponto de entrada
  (Actions/cron) +------------+------------+
                              |
                 +------------v------------+
                 |  Executor de lotes      |  estados, retentativas, logs
                 +------------+------------+
                              |
   +----------+----------+----+-----+-----------+-----------+
   |          |          |          |           |           |
 nichos   produtos   conteudo   publicacao  rastreio   relatorios
   |          |          |          |           |           |
   +----------+----------+----+-----+-----------+-----------+
                              |
                 +------------v------------+
                 |  integrations/ (adaptadores, um por servico externo)
                 +------------+------------+
                              |
                        PostgreSQL
```

Regras de dependencia e de comunicacao (monolito modular):

1. **Servicos externos so por `integrations/`.** Modulos de negocio **nao chamam** servicos externos diretamente; usam as interfaces de `integrations/`.
2. **Chamadas sincronas por interfaces internas explicitas.** Quando um modulo precisa de outro na mesma execucao (por exemplo, o conteudo consultar um produto pontuado), chama uma interface publica desse modulo (funcoes ou servicos expostos no pacote), nunca suas tabelas ou seus detalhes internos.
3. **Execucao procedural em lotes no MVP.** O scheduler chama a CLI (`autopilot run-pipeline`); o processo consulta itens elegiveis no PostgreSQL e os executa em sequencia, persistindo o estado por item. Nao implementar broker, fila concorrente, `SKIP LOCKED`, leases ou workers paralelos sem necessidade demonstrada. Retentativas e recuperacao devem ser simples e idempotentes.
4. **PostgreSQL como fonte da verdade e persistencia.** Estados ficam gravados no banco. O banco nao e o mecanismo obrigatorio de comunicacao entre todos os modulos; cada modulo e dono das suas tabelas e os demais acessam esses dados pela interface do modulo dono.
5. **Dependencias controladas, sem ciclos.** As dependencias entre modulos seguem uma direcao definida (por exemplo, `core` <- `products` <- `content` <- `publishing`); um modulo nunca depende de outro que dependa dele. Quando dois modulos precisarem reagir um ao outro, a reacao passa por estado persistido no PostgreSQL, processado na etapa seguinte do lote ou no proximo lote (regra 3; nao ha fila no MVP). **[Proposta]** verificar a ausencia de ciclos por teste ou ferramenta de lint quando houver mais de um modulo de negocio.

## 3. Stack minima (todas gratuitas e de codigo aberto)

| Necessidade | Escolha | Por que |
|---|---|---|
| Linguagem | Python 3.12 | Definido no projeto |
| Banco | PostgreSQL (psycopg 3) | Fonte da verdade para estados e histórico; sem exigir fila concorrente no MVP |
| Migracoes | Arquivos `.sql` numerados + migrador simples proprio | Menos dependencias e totalmente transparente. Alternativa a avaliar no bloco 2 (banco): Alembic |
| CLI | `argparse` (biblioteca padrao) | Zero dependencia |
| Configuracao | Variaveis de ambiente (`os.environ`) + dataclass | Zero dependencia |
| HTTP | `httpx` | Cliente moderno, facil de simular em testes |
| Expressoes de agenda | `croniter` | Pequena, calcula proximos horarios |
| Modelos de texto | `Jinja2` | Briefings e rascunhos a partir de modelos |
| Testes | `pytest` | Padrao |
| Qualidade | `ruff` | Lint e formatacao em uma ferramenta |
| Varredura de segredos | `gitleaks` (no CI) | Gratuito; ver secao 10. **Requisito de seguranca [Acordado — L7]**: deve estar ativo no CI antes do uso de qualquer credencial real. Deve ser adicionado **depois do lote atual** e obrigatoriamente antes de credenciais reais **[Acordado — 05/11/2026]**. **Situacao em 07/11/2026:** implementado no Lote 4.1 (`.github/workflows/secrets.yml`, Gitleaks 8.30.1 com checksum conferido) na branch `feature/lote-4`; ainda nao esta na `main` |

Sem framework web no núcleo inicial. A visão de destino inclui uma central de controle móvel para revisão e aprovação. O MVP pode começar com uma interface web responsiva mínima, protegida e hospedada de forma compatível com o orçamento; aplicativo nativo não é pré-requisito. A aprovação deve ser registrada no banco e ligada à versão exata do item.

## 4. Modulos e como implementar cada um

Estrutura de pastas prevista (criada gradualmente, nunca tudo de uma vez). Em 07/11/2026 existem apenas `cli.py`, `core/` (`config.py`, `log.py`, `errors.py` e, no Lote 5.1, `db.py` e `migrator.py`), `products/` (`seeds.py`, `models.py`, `json_importer.py`, `csv_importer.py`), `migrations/` (Lote 5.1: `0001_schema_v1.sql`), `data/seeds/`, `tests/` (com `tests/integration/` no Lote 5.1) e `.github/workflows/` (`ci.yml`, `secrets.yml`); o restante continua planejado. O que esta em cada branch fica em `PROJECT_STATUS.md`:

```
src/autopilot/
  core/            config, logging, banco, erros
  tasks/           executor de lotes, registro de execucoes (job_runs)
  niches/          pesquisa e pontuacao de nichos
  products/        cadastro, importacao e avaliacao de produtos
  content/         briefings, rascunhos, maquina de estados
  publishing/      fila de aprovacao, publicacao e distribuicao multicanal
  tracking/        links, cliques, conversoes, comissoes, recebimentos
  reporting/       relatorios e notificacoes
  optimization/    recomendacoes por regras
  integrations/    hotmart, youtube, wordpress, google, demais canais, notificacoes, llm, ads
migrations/        0001_*.sql, 0002_*.sql ...
tests/
.github/workflows/ ci.yml, scheduler.yml
```

### 4.1 Executor procedural em lotes

O MVP usa execução procedural em lotes, iniciada pela CLI e pelo agendador. O PostgreSQL mantém o estado de cada item e o histórico das execuções; não é necessário introduzir uma fila concorrente.

- O comando principal será `autopilot run-pipeline` (ou nome equivalente definido na implementação).
- Cada etapa consulta os registros elegíveis, processa um item por vez e persiste o resultado antes de avançar.
- Estados devem permitir identificar itens pendentes, em processamento, concluídos, com falha recuperável, rejeitados ou aguardando aprovação.
- `job_runs` (ou registro equivalente) guarda início, fim, resultado, duração e erro resumido de cada lote. **[Implementado — Lote 5.3a; `tasks/job_runs.py`]:** `start_job_run` e `finish_job_run` rodam na transação de quem chama (não confirmam nem desfazem); só encerram uma execução `running`, como `succeeded` ou `failed`; `finished_at` usa `clock_timestamp()`. Regras completas na docstring do módulo.
- Retentativas devem ser limitadas e idempotentes. Antes de repetir uma operação externa cujo resultado ficou incerto, reconciliar o estado na plataforma.
- O MVP não exige `SELECT ... FOR UPDATE SKIP LOCKED`, leases, dead-letter queue, broker externo ou múltiplos workers. Só adicionar esses mecanismos quando volume, concorrência ou falhas reais justificarem.
- A execução deve ter limite de itens/tempo por lote e permitir retomada sem reprocessar efeitos já concluídos.

### 4.2 Agendamento

- O primeiro agendador será GitHub Actions, acionando a CLI em horários definidos no workflow; também deve ser possível executar manualmente por `workflow_dispatch`.
- O comando inicia um lote limitado e encerra. Se houver itens restantes, uma execução posterior continua a partir dos estados persistidos.
- Horários de execução são configuração do scheduler no MVP; não criar um sistema próprio de cron no banco sem necessidade.
- Agendamentos podem atrasar ou falhar; manter acionamento manual e recuperação por estado, sem depender de execução em minuto exato.
- Um agendamento não autoriza publicação pública: o pipeline deve respeitar estados de aprovação e visibilidade.

### 4.3 Persistencia

Tabelas previstas (esquema v1, refinado na etapa do banco):

- Operação: `job_runs` (ou registro equivalente de lote), estados persistentes dos itens e `audit_log`. Uma tabela simples de tarefas pode ser adicionada se a implementação demonstrar necessidade; não criar desde já fila concorrente ou `schedules` sofisticada.
- Negocio: `brands`, `niches`, `products`, `product_snapshots` (historico de preco e comissao), `content_items`, `publications`, `tracked_links`, `click_events`, `conversions`, `commissions`, `reports`.
- Financeiro **[Proposta, para atender L1]**: registro de recebimentos (dinheiro que entrou na conta) e de despesas efetivamente pagas, alem dos estados de comissao (pendente, confirmada, liberada, reembolsada). Os nomes das tabelas sao definidos na etapa do banco.
- **Identificacao de marca [Acordado — L6]:** o `brand_id` existe desde o esquema v1, mesmo com uma unica marca. Regras:
  - e uma **dimensao transversal**: aparece nas tabelas de dados comerciais que pertencem a uma marca (por exemplo, conteudo, publicacoes, links, cliques, conversoes, comissoes, recebimentos, despesas e relatorios), e nao em tabelas puramente operacionais ou compartilhadas;
  - a aplicacao exata a cada tabela (inclusive `products` e `niches`, que podem ser compartilhados entre marcas) e definida na etapa do banco, com justificativa por tabela;
  - nao cria modulos, bancos nem esquemas por marca; a infraestrutura e o codigo sao compartilhados;
  - nenhum modulo passa a depender de outro por causa do `brand_id`; consultas comerciais filtram por marca na camada de dados.
- **Aplicacao do `brand_id` por tabela no esquema v1 [Acordado — 07/11/2026, Lote 5.1; migracao `0001_schema_v1.sql`]:**
  - `products`: **sem** `brand_id`. Catalogo central compartilhado entre marcas; a chave de deduplicacao e `(platform, external_id)`. O vinculo de produtos com marcas, quando necessario, sera uma tabela de associacao propria.
  - `niches`: compartilhados, sem propriedade de uma marca. Por enquanto o nicho e texto em `products.niche`; a tabela entra quando for usada.
  - `brands`: cadastro independente de cada marca. Existe **vazia**: nenhuma marca ficticia ou provisoria e cadastrada; a primeira marca sera cadastrada depois.
  - `product_snapshots` (historico de preco e comissao do catalogo) e `job_runs`, `schema_migrations` (operacionais): sem `brand_id`.
  - **Obrigacao para tabelas futuras:** toda tabela comercial que pertencer a uma marca (conteudo, publicacoes, links, cliques, conversoes, comissoes, recebimentos, despesas, relatorios, informacoes editoriais e de posicionamento) deve nascer com `brand_id bigint NOT NULL REFERENCES brands (id)`, e o teste da migracao que a criar deve comprovar isso. No v1 nao existe nenhuma tabela desse tipo, entao nao ha teste de presenca do `brand_id`.
  - **Tabelas financeiras:** adiadas para o lote que implementar vendas e comissoes (bloco 8). A decisao L1 nao muda; so o momento de criar as tabelas.
- Historico desta decisao: a versao anterior (`ARCHITECTURE_proposta.md`) previa o identificador de marca so quando existisse a segunda marca. A decisao L6, de 04/11/2026, antecipou o campo para o esquema v1; o restante da estrutura multi-marca continua adiado (principio 8).
- **Preparação para mercados e moedas [Acordado como destino]:** ao definir o esquema, avaliar campos de `locale`, país/mercado e moeda original (`currency`) em produtos, ofertas, conteúdos e transações, sem implementar conversão cambial prematura. Valores financeiros devem preservar moeda e valor originais; conversões para relatórios precisam guardar taxa, fonte e data. A aplicação exata por tabela será justificada na etapa do banco, evitando campos redundantes ou conversões que sobrescrevam o dado de origem.
- Toda linha de dado de teste tem `is_test = true`. Relatorios reais excluem esses registros por padrao.
- O plano gratuito do banco e pequeno (ver secao 6): definir retencao desde o inicio (ex.: apagar `click_events` e `job_runs` antigos, mantendo agregados diarios).
- **Migrador [Lote 5.1]:** `autopilot db migrate` aplica `migrations/NNNN_nome.sql` em ordem, uma transacao por migracao (SQL e registro em `schema_migrations` juntos), com SHA-256 de cada arquivo. Checksum ou nome divergente, lacuna ou migracao desconhecida interrompem sem aplicar nada; `--dry-run` so lista as pendentes. Execucoes simultaneas sao serializadas por advisory lock de sessao: na primeira execucao `schema_migrations` ainda nao existe, entao um `LOCK TABLE` nao serviria (excecao justificada a secao 9.2, item 3, coberta por teste de concorrencia). Valores monetarios usam `numeric` sem escala fixa, que guarda o valor como veio (`numeric(p,4)` arredondaria em silencio), com `CHECK (scale(trim_scale(...)) <= 4)`: conta so as casas efetivas, como o modelo `Product` (`97.50000` e aceito; `1.23456` e recusado). `schema_migrations` e localizada pelo mesmo `search_path` usado pelo DDL das migracoes.
  - **Regras de operacao do migrador [07/11/2026]:**
    - migracoes devem usar uma **conexao PostgreSQL direta**, nunca uma URL de pooler em modo transacao (por exemplo, o endpoint "pooled" do Neon): o advisory lock e o `lock_timeout` sao de sessao e nao funcionam quando cada instrucao pode ir para uma conexao de servidor diferente;
    - um arquivo de migracao **nao pode** conter comandos que controlam a transacao (`BEGIN`, `COMMIT`, `ROLLBACK`): o migrador ja executa SQL e registro numa transacao unica, e um `COMMIT` no meio confirmaria parte da migracao sem o registro;
    - os arquivos `.sql` sao versionados com fim de linha LF (`.gitattributes`), para o SHA-256 ser o mesmo em qualquer ambiente.
- **Banco local e CI sem TLS [Acordado — 07/11/2026]:** TLS e usuario de banco com permissoes restritas (secao 10) sao obrigatorios antes de usar qualquer banco hospedado.
- Backups: exportacao periodica (`pg_dump`) para local externo ao banco e ao repositorio, protegida contra acesso indevido. Fazer backup antes de migracoes relevantes e testar restauracao periodicamente. Uma copia nao testada nao deve ser considerada recuperacao comprovada.

### 4.4 Logs e tratamento de erros

- Logs estruturados (JSON) em **stderr**, deixando o stdout livre para o resultado dos comandos, com `job_id` e `task_name`. No CI/Actions ficam nos logs da execucao (verificar tempo de retencao).
- Filtro de redacao: valores de variaveis sensiveis, cabecalhos `Authorization` e tokens nunca sao registrados. Implementado na etapa 1 para variaveis cujo nome indique dado sensivel (por exemplo `SECRET`, `PASSWORD`, `TOKEN`, `KEY`, `AUTH`) com valor de ao menos 6 caracteres, e para credenciais em URLs. **Limite:** um segredo guardado em variavel com nome fora desse padrao nao e reconhecido automaticamente.
- Hierarquia de erros: `TransientError` (retenta), `PermanentError` (vai para `dead`), `AuthError` (pausa a integracao e notifica, sem insistir), `ConfigError` (falha imediata e clara).
- Erros resumidos tambem em `job_runs.error`, com limite de tamanho, para consulta sem abrir logs. **[Implementado — Lote 5.3a]:** o texto passa pela redacao de segredos e depois e truncado em 2000 caracteres (nessa ordem, para que um segredo cortado no limite nao escape da mascara).
- Toda integracao tem timeout explicito e respeita cabecalhos de limite de taxa (quando a API os fornecer).

### 4.5 Pesquisa e avaliacao de produtos

Ponto critico: **nao ha, ate onde foi verificado, garantia de que a API da Hotmart liste produtos de afiliacao para descoberta.** Fontes de terceiros indicam endpoints de vendas, comissoes e assinaturas; descoberta de produtos no marketplace nao foi confirmada. Por isso:

- **Fonte 1 (sempre disponivel, sem API):** importacao de arquivo CSV/JSON preenchido manualmente, com campos do esquema interno (nome, plataforma, preco, percentual de comissao, URL, data da coleta). Registros de demonstracao ficam em `data/seeds/` com `is_test = true`.
- **Fonte 2 (a verificar):** API da plataforma de afiliados, so depois de confirmar na documentacao oficial o que ela expoe.
- **Raspagem de paginas:** nao sera usada sem confirmar que os termos de uso da plataforma permitem.
- **Pontuacao:** funcao deterministica e documentada (pesos em configuracao). Exemplo de fatores: comissao estimada por venda, preco, qualidade dos dados disponiveis, concorrencia do nicho. **Campos desconhecidos contam como "desconhecido", nunca como zero ou valor inventado**, e a pontuacao informa o grau de confianca.
- Pesquisa de nichos: a mesma logica, alimentada por palavras-chave informadas por voce e, depois, por dados do Search Console (leitura) quando houver site.
- **Múltiplas redes [Acordado como destino]:** `products/` e `integrations/` não podem pressupor Hotmart como fonte única. A arquitetura deve permitir adaptadores independentes para programas como Amazon (Brasil/internacional), Monetizze, Kiwify, ClickBank e outros candidatos. Cada adaptador só será implementado após validar documentação oficial, termos, país/conta elegível, atribuição, dados de comissão, reembolsos, pagamentos e custos. A ausência de API oficial de descoberta deve ser tratada por importação CSV/JSON permitida, sem scraping não autorizado.
- **Gravação de produtos [Acordado — 07/11/2026, Lote 5.2; `products/repository.py`]:** a identidade é `(platform, external_id)`, onde `external_id` é o `Product.id`. Quem grava recebe só `Product` já validado: o repositório não revalida campos; as restrições do banco ficam como segunda barreira. Regras de estado persistido:
  - produto novo só entra com `status` `candidate` (regra K2 dos importadores); snapshot inicial de preço e comissão só se houver algum valor econômico (D4);
  - `is_test` diferente do gravado: recusado, nada é gravado;
  - `updated_at` mais antigo que o gravado: desatualizado, nada é gravado; mesmo `updated_at` com estado efetivo diferente depois da mesclagem: conflito, nada é gravado (D3). Por isso o preço não muda sem `updated_at` novo, e um snapshot novo sempre tem `observed_at` maior que o anterior;
  - campo descritivo ausente (`None`) mantém o valor gravado: ausência não apaga (D1);
  - preço, moeda, percentual e valor fixo de comissão formam um grupo substituído inteiro quando qualquer um vem informado; nenhum informado mantém o gravado (D2). Valor numericamente igual (`97.5` e `97.50`) não é mudança e mantém a representação gravada;
  - reimportação sem mudança só avança `last_imported_at` (D5), que nunca volta no tempo (`GREATEST` com o valor gravado); desatualizado e recusado não mexem nele;
  - `status`, `created_at` e `is_test` gravados nunca são alterados por uma importação; `created_at` divergente não é conflito (D6);
  - a gravação roda na transação de quem chama, sem confirmar nem desfazer nada; a linha é lida com `FOR UPDATE`, e produto novo usa `INSERT ... ON CONFLICT DO NOTHING`, seguindo como atualização se outra transação inseriu antes. Erros do banco viram `TransientError` (conexão, bloqueio, deadlock) ou `PermanentError`, com SQLSTATE e nome da restrição, sem valores do produto.
  - O Lote 5 foi reorganizado em 5.1, 5.2 e 5.3 (decisão D7): histórico e idempotência ficaram na 5.2; a importação pela CLI, `job_runs` e a transação por arquivo, na 5.3.
- **Importação operacional [Acordado — 08/11/2026, Lote 5.3; `products/importing.py` e `cli.py`]:** resumo das decisões; as regras completas estão nas docstrings de `products/importing.py` (serviço) e de `tasks/job_runs.py` (registro de execuções), e no comando em `cli.py`.
  - **Comando:** `autopilot products import ARQUIVO [ARQUIVO ...] [--dry-run | --commit]`. A simulação é o padrão; só `--commit` grava produtos. Formato (`.json`/`.csv`) e arquivos repetidos (caminhos resolvidos) são conferidos antes de conectar (C2). Uma conexão para todos os arquivos, sem commit implícito. Códigos de saída: 0 (todos concluídos), 1 (falha, estado indeterminado ou erro inesperado), 2 (uso ou configuração), 130 (interrupção).
  - **Transações por arquivo (P3):** T1 cria a execução (`running`, já com `dry_run = true` na simulação) e confirma; T2 grava os produtos válidos em ordem `(platform, id)` (P6) e, na gravação, encerra a execução como `succeeded` na mesma transação; a simulação desfaz a T2 e encerra a execução na T3. A simulação percorre o mesmo caminho da gravação (P4).
  - **Falhas (P5):** arquivo ou estrutura inválidos, erro do banco, resumo inconsistente ou arquivo alterado durante a leitura desfazem o arquivo inteiro, sem savepoint e sem retentativa (reimportar é idempotente pelas regras D1 a D7); a execução fica `failed` e os demais arquivos seguem. Registros inválidos não impedem a gravação dos válidos.
  - **Decisões N1 a N4:** posições dos produtos válidos deduzidas dos índices de erro, com o invariante "um produto ou um erro por registro" conferido (N1); `sha256` do arquivo calculado antes e depois da leitura, sem travar em FIFO nem ler sem limite (N2); se o commit da T2 ou o registro final não puderem ser confirmados, o estado é declarado **indeterminado**, sem afirmar se a execução ficou `running` nem se os produtos foram gravados (N3); em `job_runs.error`, só o nome base do arquivo (N4).
  - **Dados gravados e exibidos:** `job_runs.summary` tem só nome base, formato, `sha256` e contagens, conferidas antes de gravar (somas fecham, inteiros não negativos); numa falha, as contagens de gravação são omitidas porque foram desfeitas. O relatório no terminal mostra só o nome base, as contagens e até 50 detalhes por arquivo somando erros de registro e recusas (C1), sem caminhos, identificadores ou valores dos produtos.
  - **Interrupções e erros (C3 a C5):** Ctrl+C sai com 130 e lista os arquivos não processados; estado indeterminado (C4) e erro inesperado (C5, só a classe, sem mensagem nem traceback) interrompem os arquivos seguintes; os avisos de estado indeterminado são exibidos e contados à parte no resumo, não como falha confirmada.

### 4.6 Geracao e organizacao de conteudo

- Maquina de estados em `content_items`: `brief` -> `draft` -> `in_review` -> `approved` -> `published` (ou `rejected`).
- O sistema gera **briefings** (palavras-chave, fatos do produto vindos do banco, estrutura sugerida, aviso de divulgacao de afiliado) por modelos Jinja2. Isso roda localmente e custa zero.
- O texto final pode ser escrito por voce com ajuda de um assistente de IA no chat (copiando o briefing) e importado como `draft`. Esse e o caminho de custo zero e com humano no controle.
- Interface `LLMProvider` com implementacao padrao `NullProvider` (nao faz nada). Um provedor de IA por API so entra se houver orcamento; nesse caso, usar limites de gasto e registrar consumo.
- **Objetivo de automacao (principio 9):** o caminho "copiar o briefing para um assistente no chat" e uma solucao temporaria de validacao. O destino e a producao e a adaptacao automaticas por provedores (`LLMProvider` e, para video, provedores de narracao, imagem e montagem), sempre com revisao conforme `AUTONOMY_AND_AGENTS.md`. Nenhum provedor pago e adotado sem orcamento aprovado; alternativas de codigo aberto sao avaliadas primeiro.
- Conteudo deve sempre incluir a divulgacao de que ha link de afiliado; **verificar as regras de publicidade aplicaveis** e as politicas da plataforma de afiliados antes de publicar.
- **Formatos editoriais [Acordado como destino]:** o pipeline deve poder preparar vídeos longos, cortes verticais adaptados e artigos/guias de pesquisa documentada. A peça-mãe e o material-fonte podem ser reutilizados, mas cada derivação precisa de adaptação e aprovação própria antes de publicação. Artigos para blog não devem ser transcrições automáticas sem valor editorial.

### 4.7 Publicacao e distribuicao multicanal por integracoes autorizadas

- **Multicanal [Acordado — L2]:** a publicacao usa uma interface comum (`PublisherProvider`) com um adaptador por canal em `integrations/`. Uma mesma peca pode gerar `publications` em varios canais, cada uma com seu estado e sua chave de idempotencia.
- **Ordem dos canais [Acordado — 05/11/2026]:** o YouTube e o primeiro canal operacional. Instagram, TikTok e Pinterest so entram na integracao operacional depois da validacao do fluxo do YouTube; pesquisa e preparacao tecnica desses canais podem ocorrer antes. Google, na estrategia, significa trafego organico por site proprio e SEO (adaptador WordPress ou equivalente).
- **Fases de publicacao [Acordado — 05/11/2026]:**
  - **Fase A:** validacao controlada e nao publica, incluindo producao, verificacoes e publicacao privada ou nao publica em pelo menos um canal.
  - **Fase B:** operacao publica controlada, somente apos autorizacao explicita do responsavel.
  - Publicacao publica sempre respeita limites, permissoes e o botao de parada (kill switch).
- Cada adaptador so e implementado depois de verificar na documentacao oficial: autenticacao, cotas, auditorias exigidas, regras de divulgacao e termos de automacao (secoes 7 e 12).
- A autorização é vinculada ao hash exato do manifesto da versão, cujos elementos estão definidos em `AUTONOMY_AND_AGENTS.md` seção 4.6 (especificação técnica na seção 4.7.2). Qualquer alteração posterior gera nova versão sem autorização e exige nova verificação e nova aprovação individual; no MVP não há herança de autorização entre versões.
- So publica `content_items` com status `approved`. **Todo envio, público ou privado, exige autorização válida para o hash exato da versão**, registrada no `audit_log` (`AUTONOMY_AND_AGENTS.md` seções 4.1 e 4.6). **Na fase inicial, essa autorização é sempre humana e individual.** Políticas previamente autorizadas podem automatizar pesquisa, produção de rascunhos e tarefas internas, mas, nesta fase, não substituem a autorização individual de cada envio. A publicação por política permanece na arquitetura futura e depende de decisão expressa do proprietário, revisão de riscos e implementação validada (`AUTONOMY_AND_AGENTS.md` seção 4.3); a exigência atual não é limitação definitiva da arquitetura. Seleção de nicho, produto e oferta comercial exige sempre decisão do proprietário antes de orientar uma campanha.
- **Fluxo de aprovação móvel [Acordado como destino]:** o item passa a `in_review`; o painel móvel mostra prévia, fontes, produto/oferta, links, divulgação, canal e versão. O responsável pode aprovar, rejeitar ou solicitar ajustes. A decisão cria registro auditável (`content_approvals` ou estrutura equivalente) com usuário, timestamp, hash da versão, escopo, evidências e validade. Qualquer alteração gera nova versão, que não herda a autorização (`AUTONOMY_AND_AGENTS.md` seção 4.6). A primeira implementação pode ser web responsiva; a experiência deve funcionar pelo celular e evoluir conforme necessidade.
- Dois interruptores independentes, ambos desligados por padrao: modo `dry-run` (monta a requisicao e registra, sem enviar) e `PUBLISHING_ENABLED`.
- Chave de idempotencia por publicacao: reenviar a mesma tarefa nao cria post duplicado.
- WordPress: a API REST do WordPress com senha de aplicativo esta documentada para sites WordPress **proprios (auto-hospedados)**; **verificar** se o plano gratuito de qualquer hospedagem escolhida permite REST e senhas de aplicativo. Criar um usuario dedicado, com o menor papel que permita criar rascunhos.
- Primeira versao real publica em **modo nao publico** (video privado ou nao listado no YouTube; rascunho no WordPress), nunca como post publico.
- **YouTube [Fato verificado em 05/11/2026]:** o envio por API (`videos.insert`) fica **publico por padrao** se `privacyStatus` nao for informado; a mesma pagina afirma que videos enviados por projetos de API nao verificados nao ficam restritos ao modo privado ([Google](https://developers.google.com/youtube/v3/docs/videos/insert), atualizada em 03/11/2026). O adaptador deve sempre enviar o estado de privacidade explicitamente.
- **Autorizacao do YouTube (OAuth):** fatos, limitacoes e alternativas na secao 7.1. Reautorizacao manual semanal nao e solucao arquitetural aceitavel.
- Como aprovar pelo celular: na versao inicial, via comando/consulta SQL; evolucao possivel: uma pagina de aprovacao minima protegida por login (exige hospedagem web, ver 4.8). Alternativa sem hospedagem **[A validar]**: workflow manual do GitHub (`workflow_dispatch`) acionado pelo app, com registro no `audit_log` (`AUTONOMY_AND_AGENTS.md` secao 11). Qualquer que seja o meio de aprovação, ele precisa gerar a autorização com hash, evidências e validade (seção 4.7.1).

#### 4.7.1 Autorização de envio **[Decisão conceitual — 12/11/2026; não implementado]**

As regras estão em `AUTONOMY_AND_AGENTS.md` seções 4.1 a 4.6 e não são repetidas aqui. Consequências para o módulo de publicação:

- Há dois tipos de autorização: `individual` (quem aprovou e quando) e `policy` (identificador e versão da política). **No MVP só o tipo `individual` é aceito**; o tipo `policy` é recusado enquanto não houver decisão expressa do proprietário, revisão de riscos e implementação validada. Prever o tipo no registro não implementa nem ativa políticas: o MVP não cria tabela de políticas nem motor de regras.
- Imediatamente antes de cada envio, público ou privado, o módulo confere:
  1. o hash recalculado sobre o material a enviar é igual ao hash autorizado;
  2. a autorização está dentro da validade e não foi revogada, suspensa nem invalidada;
  3. as verificações obrigatórias passam com as regras vigentes, incluindo o destino comercial dos links, as condições comerciais para a data prevista e a divulgação (`AUTONOMY_AND_AGENTS.md` seção 4.5);
  4. não há risco relevante pendente de classificação pelo proprietário;
  5. o sistema está em operação normal (`ACTIVE`, seção 12.5);
  6. `PUBLISHING_ENABLED` está ligado.
- Qualquer divergência, ou estado que não possa ser lido, impede o envio. Nenhum estado de emergência é interpretado como autorização para publicar.
- A autorização humana e a liberação pelas verificações são controles distintos: a primeira autoriza o conteúdo exato; as segundas determinam se ele ainda pode ser enviado. Resultado de verificação obtido para outro hash não vale.
- Autorizações, evidências e resultados de verificação nunca são apagados: revogação, vencimento, suspensão e invalidação são registrados, preservando o histórico. Ficam registradas a versão das regras usada na aprovação e a usada imediatamente antes do envio.
- Nome e esquema das tabelas ficam para o lote de publicação. A proposta é generalizar o registro `content_approvals` citado acima, não criar um registro paralelo.

#### 4.7.2 Manifesto e hash **[Proposta técnica — validar na implementação]**

Os elementos que compõem a versão são decisão conceitual (`AUTONOMY_AND_AGENTS.md` seção 4.6). A forma de calcular o hash abaixo é proposta técnica; seu objetivo é que a mesma versão produza sempre o mesmo hash.

- **Codificação dos textos:** UTF-8, forma Unicode NFC, quebra de linha LF, sem marca de ordem de bytes. A padronização é aplicada uma única vez, ao gravar a versão e antes da serialização, porque a serialização canônica não realiza normalização Unicode. No cálculo, um texto fora desse padrão é recusado, nunca corrigido. O que é gravado é o que é exibido na revisão, hasheado e enviado.
- **Esquema:** fixo e versionado. Campos desconhecidos e chaves duplicadas são recusados.
- **Campos obrigatórios e não vazios:** versão do esquema, marca, canal, formato, visibilidade e título.
- **Campos que admitem `null`:** texto ou roteiro, descrição, divulgação de afiliado e legendas em texto. `null` significa apenas ausência do valor; se o valor é exigido para aquela peça, quem decide são as verificações obrigatórias, não o esquema (`AUTONOMY_AND_AGENTS.md` seção 4.5, item 11).
- **Texto vazio:** texto vazio ou composto só de espaços não é aceito em nenhum campo; a ausência é sempre `null`.
- **Listas:** arquivos, links e metadados em lista. Lista ausente é `[]`. A ordem é sempre a posição de envio ou exibição.
- **Tipos:** texto, inteiro, booleano, lista e objeto. Sem números decimais. Inteiros limitados ao intervalo de −(2^53 − 1) a 2^53 − 1; fora dele, recusa.
- **Arquivos:** cada arquivo é representado por função (vídeo principal, capa, áudio, legenda etc.), posição, SHA-256 dos seus bytes em 64 caracteres hexadecimais minúsculos e tamanho em bytes. Nome, caminho e data do arquivo não entram. Arquivo vazio é recusado. Não se presume equivalência entre arquivos semelhantes.
- **Links:** posição, endereço exatamente como escrito e indicação de link comercial.
- **Fora do manifesto:** data e hora de publicação e demais dados operacionais (identificadores internos, datas de criação, chave de idempotência).
- **Serialização canônica:** JSON canônico, com chaves ordenadas e sem espaços opcionais. Candidato: JCS (RFC 8785), **a confirmar na implementação**, inclusive se por biblioteca ou por código próprio. Nenhuma dependência foi escolhida (seção 3).
- **Versão do esquema:** tem uma única fonte de verdade, o campo de versão do manifesto validado. A versão usada na composição do hash é lida desse mesmo campo, depois da validação, e o manifesto não pode ser alterado entre a validação e o cálculo. São recusados o manifesto cuja versão não corresponda ao esquema usado na validação e o identificador cuja versão difira da registrada no manifesto.
- **Composição do hash:** SHA-256 sobre a sequência de bytes formada por um prefixo de domínio fixo em ASCII, um byte zero, a versão do esquema em dígitos ASCII, um byte zero e a serialização canônica. Os dois primeiros componentes não contêm byte zero, o que torna a separação inequívoca.
- **Identificador gravado:** versão do esquema e hash em hexadecimal minúsculo. Mudança de esquema não cria equivalência: uma autorização continua valendo apenas para o hash com que foi emitida.

#### 4.7.3 Verificação de destinos externos **[Proposta técnica — validar na implementação]**

A regra de negócio (destino comercial efetivo, parâmetros significativos, bloqueio na dúvida) é decisão conceitual e está em `AUTONOMY_AND_AGENTS.md` seção 4.5, item 7. O requisito de que a verificação não sirva de caminho para recursos internos nem contorne controles de rede também é decisão conceitual. As proteções abaixo são propostas técnicas a validar e testar; não constituem garantia de segurança.

- O verificador fica em `integrations/` (seção 2, regra 1).
- Aceita apenas `http` e `https`, nas portas padrão. Endereço com usuário e senha embutidos, ou IP em notação não canônica, é recusado.
- Proxies herdados do ambiente são desativados. Se a rede só permitir saída por proxy, o resultado é "não verificável".
- Redirecionamentos são seguidos manualmente, um a um, e cada um é validado por completo antes de qualquer conexão.
- A cada etapa: resolver o nome, validar todos os endereços resolvidos e conectar ao próprio endereço validado, sem nova resolução, para que uma mudança de resolução DNS entre a validação e a conexão não tenha efeito.
- IPv4 e IPv6 são validados. IPv4 mapeado em IPv6 é convertido e validado como IPv4. Formas de tradução e de túnel são recusadas.
- São recusados endereços privados, locais, de enlace, reservados, internos e de metadados de nuvem.
- O TLS é validado contra o domínio original, mesmo quando a conexão é feita ao endereço IP validado. Redirecionamento de `https` para `http` é recusado.
- Há limites de tempo por etapa e total, de quantidade de redirecionamentos e de tamanho da resposta. O corpo da resposta não é interpretado nem executado; redirecionamentos feitos por script na página não são seguidos.
- Nenhuma credencial, cookie ou cabeçalho de autenticação é enviado.
- Falha fechada: qualquer erro, limite atingido ou dúvida resulta em "não verificável" e bloqueia o envio.
- A cadeia de redirecionamentos e o resultado de cada verificação são registrados para auditoria.
- Em dry-run, nenhuma chamada de rede é feita (seção 8, bloco 7).

#### 4.7.4 Adaptador de publicação **[Decisão conceitual — 12/11/2026 quanto aos limites; mecanismo como Proposta técnica]**

- O adaptador envia à plataforma somente: (1) campos e valores presentes no manifesto autorizado; (2) parâmetros operacionais de uma lista fechada e documentada por adaptador, como instante de execução e identificadores técnicos necessários à API.
- Parâmetros operacionais não podem alterar conteúdo, visibilidade, destino comercial nem condições autorizadas.
- Qualquer campo não previsto é recusado.
- A configuração efetivamente enviada à plataforma é auditável.
- No MVP, o agendamento nativo da plataforma não é usado (seção 12.4).
- **[Proposta técnica]** O mapeamento entre manifesto e campos da API é determinístico e documentado por adaptador; a configuração enviada é registrada sem segredos, com os arquivos representados por seus hashes.

#### 4.7.5 Validade e instantes **[Proposta técnica — validar na implementação]**

As regras de validade são decisão conceitual (`AUTONOMY_AND_AGENTS.md` seções 4.5 e 4.6): toda autorização tem instante explícito de vencimento, com fuso; não ultrapassa o fim de nenhuma oferta citada; oferta com data final sem horário vale até o fim daquele dia no fuso do mercado; sem fuso ou instante determinável, bloqueio até confirmação. Proposta de tratamento técnico:

- O vencimento é gravado como instante, com o fuso IANA de referência do mercado (seção 12.4).
- "Fim do dia" é o primeiro instante do dia seguinte no fuso do mercado, calculado pela base IANA, inclusive em mudanças de horário de verão.
- A autorização vale enquanto o instante atual for anterior ao vencimento; a comparação usa o relógio do banco.
- Validade da oferta e validade da autorização são registradas separadamente.

#### 4.7.6 Parâmetros pendentes **[Parâmetro pendente]**

Nenhum valor abaixo está definido ou aprovado. Todos precisam de decisão do proprietário antes de qualquer envio real (`AUTONOMY_AND_AGENTS.md` seção 13):

- prazos máximos de atualização das evidências comerciais, por tipo de informação, fonte e mercado;
- validade padrão das autorizações, por marca, canal e categoria;
- listas de parâmetros de URL que podem ser desconsiderados, por plataforma, a partir da documentação oficial de cada uma;
- limites do verificador de destinos: quantidade de redirecionamentos, tempos e tamanho de resposta;
- parâmetros operacionais permitidos por adaptador;
- fuso de referência de cada mercado.

### 4.8 Rastreamento de cliques, conversoes e comissoes

- **Conversoes e comissoes:** vem das vendas da plataforma. A Hotmart documenta oficialmente APIs de vendas, assinaturas e webhooks, e seus termos incluem afiliados entre os usuarios ([Hotmart Developers](https://developers.hotmart.com/docs/pt-BR/)); **confirmar** quais campos existem para afiliados antes da etapa de vendas. Importacao por tarefa agendada, com upsert pelo identificador da transacao (idempotente).
- **Estados financeiros [Acordado — L1]:** a importacao registra separadamente venda confirmada, comissao pendente, comissao liberada e reembolso. O dinheiro efetivamente recebido vem do registro de recebimentos (secao 4.3), nao das comissoes. **Comissao confirmada [Acordado — 05/11/2026]:** so depois da aprovacao efetiva da plataforma, inclusive depois do periodo de garantia quando aplicavel; antes disso, a comissao e pendente. O mapeamento entre os estados da plataforma e esses estados e definido na etapa de vendas, a partir da documentacao oficial.
- **Cliques:** opcoes, da mais simples a mais complexa: (a) metricas do Google Analytics nas paginas do proprio site; (b) redirecionador proprio (exige um endpoint web publico sempre ligado, ou seja, hospedagem); (c) parametros de rastreamento aceitos pela plataforma de afiliados (**verificar** se existem e como retornam nos relatorios de venda).
- Associacao conteudo -> venda depende de (b) ou (c). Sem isso, a atribuicao sera aproximada e o relatorio deve dizer isso.
- Dados pessoais de compradores: guardar apenas o necessario (idealmente nenhum), por causa da LGPD.

### 4.9 Relatorios e notificacoes

- Relatorio semanal e diario resumido, gerado a partir do banco e salvo em `reports`.
- Os relatorios financeiros mostram, por marca e periodo, os **dois indicadores independentes** da decisao L1: resultado comercial confirmado (comissoes confirmadas menos custos atribuiveis) e resultado realizado em caixa (dinheiro recebido menos despesas pagas). Nunca somados nem substituidos um pelo outro.
- Canais gratuitos candidatos: e-mail por SMTP; bot do Telegram; e-mails de falha do proprio GitHub Actions. **Verificar** limites e exigencias de cada um (conta, senha de aplicativo, politica anti-spam).
- Notificacoes obrigatorias: tarefa `dead`, integracao com erro de autenticacao, limite de uso do banco proximo.
- Relatorios nao sao commitados no repositorio (contem dados de negocio).

### 4.10 Otimizacao

- **Primeira implementacao:** regras simples e explicaveis geram recomendacoes (ex.: conteudo sem cliques apos N dias vira candidato a revisao; produto com queda de comissao perde pontuacao). Nesta etapa, o sistema nao aplica alteracoes automaticamente.
- **Evolucao prevista:** a arquitetura pode permitir que o sistema aplique ajustes operacionais reversiveis quando a acao estiver expressamente coberta por uma politica previamente autorizada, dentro dos limites, permissoes e condicoes definidos. Acoes fora da politica exigem aprovacao humana.
- Otimizacoes que envolvam gasto, aumento de orcamento, compra ou compromisso financeiro nao sao autorizadas por esta capacidade geral. Exigem autorizacao especifica e permanecem fora de qualquer politica por padrao enquanto nao houver decisao expressa em contrario.
- Toda recomendacao e acao automatica deve registrar dados que a motivaram, politica aplicavel e resultado; manter modo de simulacao e botao de parada.

### 4.11 Futura integracao com publicidade paga

- Fora do escopo atual e sem autorizacao para gastos. Preparar apenas, para o futuro, a interface `AdsProvider` e tabelas de custo (`ad_spend`), cujos valores entram como custo nos dois indicadores da secao 4.9.
- Orcamento de anuncios so pode vir de **dinheiro efetivamente recebido**; comissoes pendentes ou apenas confirmadas nao constituem orcamento disponivel **[Acordado — L1]**. Essa regra nao constitui autorizacao para gastar.
- Antes de qualquer integracao: **verificar** exigencias de aprovacao de cada plataforma (contas de desenvolvedor, tokens de acesso, revisao de aplicativo) e politicas de anuncios para produtos de afiliados.
- **Regra de autorizacao:** campanhas e gastos ficam fora das politicas por padrao. Cada campanha exige aprovacao individual enquanto nao existir uma politica especifica, expressamente autorizada pelo responsavel, que defina marca, plataforma, finalidade, periodo, teto de gasto e criterio de parada. Somente dentro dessa politica o sistema podera operar sem aprovacao individual de cada execucao.
- Salvaguardas obrigatorias antes de qualquer gasto autorizado: teto diario e total, orcamento fechado, modo de simulacao, registro de autorizacao, verificacao de saldo recebido suficiente e botao de parada (kill switch). Nenhuma campanha pode renovar ou ampliar seu orcamento automaticamente fora dos limites autorizados.

## 5. O que roda localmente e o que depende de servicos externos

| Funcionalidade | Local/offline (sem internet de terceiros) | Depende de servico externo |
|---|---|---|
| Executor de lotes, agendador, logs, migracoes | Sim (precisa de um PostgreSQL) | Banco hospedado, se nao houver PostgreSQL local |
| Importacao CSV/JSON e pontuacao de produtos | Sim | - |
| Briefings por modelos | Sim | - |
| Maquina de estados e aprovacao | Sim | - |
| Testes automatizados | Sim | No celular: GitHub Actions |
| Publicacao | Dry-run: sim | Real: YouTube (canal inicial) e, no futuro, WordPress e demais canais |
| Producao automatica de texto, audio e video | Parte pode rodar com ferramentas de codigo aberto **[A verificar]** | Provedores de IA e de midia (podem ter custo) |
| Vendas e comissoes | - | API da plataforma de afiliados |
| Trafego, buscas e metricas de canais | - | YouTube Analytics; Google Analytics / Search Console (se houver site); APIs dos demais canais |
| Redirecionamento e contagem de cliques | - | Hospedagem web sempre ligada (ou Analytics) |
| Notificacoes | - | E-mail / Telegram |
| Texto por IA automatica | - | Provedor de IA (pago ou com cota a verificar) |
| Anuncios | - | Plataformas de anuncios (pago) |

## 6. Comparacao de alternativas gratuitas

Dados abaixo vem de pesquisa de 28/10/2026 em fontes publicas, muitas de terceiros, com os pontos marcados **[Fato verificado em 04/11/2026]** conferidos em paginas oficiais. **Limites mudam com frequencia: confirmar na pagina oficial antes de depender de qualquer numero.**

**[Fato verificado em 04/11/2026]**
- GitHub Actions no plano gratuito: cota expressa como US$ 12 de computacao por mes, nao como minutos; sem meio de pagamento cadastrado, o uso e bloqueado ao atingir a cota ([GitHub Docs](https://docs.github.com/en/billing/concepts/product-billing/github-actions)).
- Agendamento: intervalo minimo de 5 minutos; pode atrasar em horarios de pico; em repositorio publico, agendamentos sao desativados apos 60 dias sem atividade ([GitHub Docs](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)).
- Neon gratuito: 1 GB e 100 CU-horas por projeto, ate 100 projetos, computacao suspensa apos 5 minutos ociosa, restauracao de ate 6 horas ([Neon](https://neon.com/pricing)). Os numeros das tabelas 6.1 e 6.2 foram atualizados com esses dados.

### 6.1 Execucao programada

| Opcao | O que oferece | Limites / riscos conhecidos | A verificar |
|---|---|---|---|
| **GitHub Actions (agendamento)** | Roda sem servidor proprio; integrado ao repositorio; segredos do GitHub | Em repositorios privados, a cota do plano gratuito e expressa como US$ 12 de computacao por mes, com uso bloqueado ao atingir a cota sem meio de pagamento (verificado em 04/11/2026); intervalo minimo de 5 minutos; agendamentos podem atrasar e nao sao exatos; agendamentos de repositorios publicos sao desativados apos 60 dias sem atividade | Politica de desativacao de agendas em repositorios privados |
| Servico de cron de hospedagem (ex.: Render) | Cron e workers na nuvem | Fontes divergem sobre o que e gratuito (uma cita cron gratuito, outra cita minimo mensal de US$ 1); servicos web gratuitos "dormem" apos 15 min | Preco e limites atuais do cron |
| VM gratuita sempre ligada (ex.: Oracle Cloud Always Free) | Maquina real para cron e processos continuos | Capacidade nao garantida na hora; risco de recusa de cadastro (cartao); exige administrar o servidor | Disponibilidade na sua regiao e exigencias de cadastro |
| Computador proprio (cron ou agendador em Python) | Controle total, custo zero | Precisa ficar ligado; hoje nao ha acesso garantido | - |

**Recomendacao:** comecar com GitHub Actions, porque nao exige servidor nem computador. Como o estado vive no banco e os horarios ficam na configuracao do agendador (secao 4.2), migrar para VM ou computador depois e apenas mudar quem chama `autopilot run-pipeline`.

### 6.2 Banco de dados PostgreSQL

| Opcao | Limites conhecidos (28/10/2026) | Observacoes |
|---|---|---|
| **Neon (plano gratuito)** | 1 GB por projeto (verificado em 04/11/2026; antes, fontes de terceiros citavam 0,5 GB); 100 horas de computacao (CU-hours) por projeto/mes; ate 2 CU; janela de restauracao de 6 horas; sem cartao; computacao suspende ao ficar ociosa | Postgres padrao (string de conexao comum). Partida a frio ao acordar: tarefas devem tolerar a primeira conexao lenta |
| Supabase (plano gratuito) | 500 MB por projeto; 2 projetos gratuitos; **projeto pausa apos 7 dias sem atividade** e precisa ser reativado | Pausa e risco para automacao; so serviria com atividade garantida |
| Render PostgreSQL gratuito | Fonte indica 90 dias gratuitos | Nao serve para dados duradouros |
| PostgreSQL local | Sem limite pratico | Depende de computador; bom para desenvolvimento |

**Recomendacao:** Neon gratuito como banco principal; PostgreSQL local para desenvolvimento quando houver computador. Planejar retencao de dados por causa do limite de 1 GB por projeto.

### 6.3 Hospedagem (so se for necessaria)

Necessaria apenas para redirecionador de cliques ou painel de aprovacao. Opcoes citadas em fontes de terceiros: Google Cloud Run e Oracle Always Free (sem prazo de expiracao, mas com exigencias de cadastro), Render (suspende por inatividade), Fly.io (fontes indicam que o plano gratuito acabou). **Nenhuma sera adotada antes de verificacao oficial e de existir necessidade real.** Ate la, a hospedagem e dispensavel.

## 7. Dependencias que podem gerar custo, exigir aprovacao ou limitar a automacao

| Dependencia | Risco | Acao |
|---|---|---|
| Conta de afiliado/produtor e credenciais da Hotmart | Credenciais de API sao criadas na area de desenvolvedores; fontes de terceiros citam Client ID, Client Secret e um token "basic". O `.env.example` atual so lista os dois primeiros | Ler documentacao oficial; decidir ajuste do `.env.example` em etapa propria |
| Escopo da API da Hotmart | Nao confirmado se cobre descoberta de produtos e dados de afiliado | Verificar antes da etapa 8 |
| Google Analytics / Search Console | Autenticacao OAuth: em modo "Testing", refresh tokens expiram em 7 dias (secao 7.1); para estas APIs, a possibilidade de usar conta de servico **[A verificar]** | Verificar e escolher o metodo antes da etapa 9 |
| Cotas das APIs do Google | Podem limitar frequencia de consultas | Verificar cotas oficiais |
| WordPress | Precisa de site proprio com REST e senhas de aplicativo; hospedagem pode ter custo e limites | Definir onde o site vai ficar |
| Dominio e hospedagem do site | Custo | Fora do prototipo; usar dry-run |
| Provedor de IA por API | Pago por uso | Fica desligado (`NullProvider`) |
| Anuncios | Dinheiro, aprovacoes e politicas | Fora de escopo |
| GitHub Actions | Cota de minutos, atrasos, possivel desativacao de agendamentos | Monitorar consumo |
| Banco gratuito | 1 GB por projeto e horas de computacao limitadas (verificado em 04/11/2026) | Retencao e agregacao de dados |
| YouTube Data API | Cota padrao de 100 chamadas de `videos.insert`, 100 de `search.list` e 10.000 unidades/dia para os demais metodos; cota adicional exige auditoria de conformidade ([Google](https://developers.google.com/youtube/v3/guides/quota_and_compliance_audits)). OAuth: ver secao 7.1 | Definir o modo de publicacao do app OAuth antes de automatizar (7.1); envio sempre com `privacyStatus` explicito |
| Instagram (API de publicacao) | Exige conta profissional, fluxo de login da Meta e midia hospedada em servidor publico; limite de 100 posts por API em 24 horas ([Meta](https://developers.facebook.com/docs/instagram-platform/content-publishing/)) | Hospedagem publica de midia pode gerar custo; verificar antes |
| TikTok (Content Posting API) | Conteudo de clientes nao auditados fica restrito a visualizacao privada; e preciso auditoria para publicar ([TikTok](https://developers.tiktok.com/doc/content-posting-api-get-started)) | Auditoria antes de qualquer publicacao automatica |
| Pinterest (API) | Acesso por solicitacao revisada pelo Pinterest, com conta empresarial ([Pinterest](https://developers.pinterest.com/docs/getting-started/set-up-app/)) | Verificar niveis de acesso antes |
| Termos de uso das plataformas | Podem restringir automacao, raspagem e divulgacao | Ler antes de cada integracao |

### 7.1 OAuth do YouTube: expiracao de tokens e alternativas

**Fatos confirmados em documentacao oficial do Google (consulta em 05/11/2026):**

1. **Modo "Testing" com usuario externo:** o refresh token expira em **7 dias**, salvo se os escopos forem so nome, e-mail e perfil ([Google — OAuth 2.0](https://developers.google.com/identity/protocols/oauth2), atualizada em 29/10/2026). As autorizacoes de usuarios de teste expiram sete dias apos o consentimento; projetos em "Testing" aceitam ate 100 usuarios de teste ([Google Cloud — Manage App Audience](https://support.google.com/cloud/answer/15549945)).
2. **Outras causas de perda do refresh token** ([Google — OAuth 2.0](https://developers.google.com/identity/protocols/oauth2)):
   - revogacao pelo usuario;
   - seis meses sem uso;
   - troca de senha, se houver escopos do Gmail;
   - acesso por tempo limitado concedido pelo usuario;
   - politica de administrador;
   - limite de 100 refresh tokens por conta Google e por client ID: o mais antigo e invalidado sem aviso.
3. **Modo "In production":** fica disponivel a qualquer conta Google. Escopos sensiveis ou restritos sem verificacao exibem o aviso de app nao verificado ([Google Cloud — Manage App Audience](https://support.google.com/cloud/answer/15549945)).
4. **Excecao de uso pessoal:** apps de uso pessoal (menos de 100 usuarios) podem continuar sem verificacao, com o usuario passando pelo aviso de app nao verificado no login ([Google Cloud — When is verification not needed](https://support.google.com/cloud/answer/13464323)). Apps sem verificacao ficam limitados a 100 novos usuarios ([Google Cloud — Unverified apps](https://support.google.com/cloud/answer/7454865)).
5. **App interno:** exige projeto de uma organizacao Google Workspace ou Cloud Identity, e so usuarios dessa organizacao podem usa-lo; nao ha aviso de app nao verificado nem limite de 100 usuarios ([Google Cloud — When is verification not needed](https://support.google.com/cloud/answer/13464323)).
6. **Conta de servico:** a YouTube Data API so a aceita para "content owners" que gerenciam varios canais (gravadoras, estudios), nao para um canal comum ([YouTube — OAuth para servidores web](https://developers.google.com/youtube/v3/guides/auth/server-side-web-apps)).
7. **Acesso offline:** tarefas sem o usuario presente exigem `access_type=offline`. O refresh token so vem na primeira autorizacao, e, se for perdido, o consentimento precisa ser repetido ([YouTube — OAuth para servidores web](https://developers.google.com/youtube/v3/guides/auth/server-side-web-apps)).
8. **Fluxo para dispositivos:** suporta apenas os escopos `youtube` e `youtube.readonly`, e nao `youtube.upload` ([YouTube — OAuth para dispositivos](https://developers.google.com/youtube/data/guides/auth/devices)).
9. **Verificacao de escopo sensivel:**
   - exige pagina inicial em dominio verificado proprio e politica de privacidade no mesmo dominio ([Google Cloud — Verification requirements](https://support.google.com/cloud/answer/13464321));
   - prazo esperado de 10 dias uteis ([Google Cloud — FAQ](https://support.google.com/cloud/answer/13463817?hl=En)).

**O problema se aplica ao fluxo planejado?** Sim, se o app OAuth ficar em "Testing". O fluxo planejado e uma tarefa agendada (GitHub Actions) usando o refresh token da conta do responsavel, sem o usuario presente. Uma conta Google pessoal so pode criar app externo, e o modo padrao de um app novo e "Testing" **[A verificar no Console]**. Nesse modo, a automacao pararia a cada 7 dias.

**Alternativas sustentaveis [Proposta, nenhuma decidida]:**

| Alternativa | Como funciona | Requisitos | Custo | Limitacoes |
|---|---|---|---|---|
| A. Producao sem verificacao (uso pessoal) | Publicar o app como "In production" e usa-lo so com a conta do responsavel | Aceitar o aviso de app nao verificado uma vez, no consentimento | Nenhum custo citado nas paginas oficiais | Limite de 100 usuarios; aviso no login; a ausencia da expiracao de 7 dias e inferida da documentacao **[confirmar em teste controlado]** |
| B. Producao com verificacao | Submeter os escopos sensiveis a verificacao do Google | Dominio proprio verificado, pagina inicial e politica de privacidade; prazo esperado de 10 dias uteis | Dominio e hospedagem do site (exigem autorizacao de gasto); a taxa da verificacao de escopo sensivel nao e informada nas paginas consultadas **[A verificar]** | Nova revisao se novos escopos forem adicionados |
| C. App interno | Projeto e canal ligados a uma organizacao Workspace ou Cloud Identity | Organizacao Google com dominio; canal do YouTube operado por conta da organizacao **[A verificar]** | Workspace e pago; Cloud Identity Free e a viabilidade com YouTube **[A verificar]** | Muda a titularidade das contas; maior complexidade |
| D. Conta de servico | — | So para content owners | — | **Nao aplicavel** a este projeto |

**Regras para qualquer alternativa [Proposta]:**
- pedir o menor escopo necessario (`youtube.upload` para envio; `youtube.readonly` para leitura);
- guardar o refresh token so em segredos do Actions, nunca no repositorio, e com Gitleaks ativo no CI;
- detectar `invalid_grant` e notificar o responsavel, sem tentar de novo indefinidamente;
- nao autorizar o mesmo client ID repetidamente, por causa do limite de 100 tokens.

**Pontos ainda incertos:**
- se `youtube.upload` aparece como escopo sensivel ou restrito no Console (fontes de terceiros indicam sensivel);
- se a verificacao de escopo sensivel tem custo;
- a confirmacao pratica de que o token de app em producao nao verificado nao expira em 7 dias;
- mudancas recentes de politica: a pagina de `videos.insert` foi atualizada em 03/11/2026 e contradiz a regra antiga de restricao a privado para projetos nao auditados.

## 8. Sequencia de desenvolvimento e criterios de conclusao

Cada etapa termina com os testes passando no CI. Nenhuma etapa avanca sem seu criterio cumprido. Sem datas fixas: o prazo acompanha o cumprimento dos criterios.

**Ordem real de desenvolvimento [Fato, decisao L3]:** a execucao nao seguiu a numeracao abaixo. Depois da Etapa 1 (fundacao), o desenvolvimento entrou no **Product Intelligence** (Lotes 1 a 3: modelo de produto e importadores JSON e CSV, branch `feature/product-intelligence`), que corresponde a uma parte do bloco 5 abaixo, e depois no Lote 4 (seguranca e governanca, branch `feature/lote-4`). Versoes anteriores chamavam o Product Intelligence de "Etapa 2", o que colidia com o bloco 2 (banco); a partir da revisao 7 o desenvolvimento e identificado por **lotes**, e a tabela abaixo e apenas o **catalogo de blocos tecnicos** com seus criterios de conclusao: os numeros identificam blocos, nao a ordem nem a etapa atual. A sequencia real de lotes e o estado verificado ficam em `PROJECT_STATUS.md`.

| # | Etapa | Entrega | Criterio objetivo de conclusao |
|---|---|---|---|
| 0 | Repositorio | README, .gitignore, .env.example, este documento | **Concluida** (este documento fecha a etapa de planejamento) |
| 1 | Fundacao | `pyproject.toml`, pacote, configuracao, logs, CLI com `--help`, workflow de CI (ruff + pytest + gitleaks) | CI verde na branch principal; `autopilot --help` executa no CI |
| 2 | Banco | Migrador, esquema v1 (com `brand_id` transversal, secao 4.3; o registro financeiro foi adiado para o bloco 8 por decisao de 07/11/2026), repositorios de dados | Migracoes aplicam do zero em PostgreSQL no CI; reaplicar nao falha; teste confirma tabelas, restricoes unicas e presenca do `brand_id` nas tabelas comerciais definidas (no v1 nao ha nenhuma; a obrigacao vale para as futuras) |
| 3 | Executor de lotes | Execucao procedural em lotes (`autopilot run-pipeline`), estado persistido por item, retentativas limitadas, `job_runs` (secao 4.1) | Testes provam: reexecutar o lote nao repete efeitos ja concluidos; erro transitorio retenta com limite e erro permanente fica registrado como falha; lote interrompido retoma a partir dos estados persistidos; resultado externo incerto fica como `unknown` e nao e repetido sem reconciliacao (secao 9.2); **reconciliacao de execucoes orfas [debito tecnico M2, aceito em 08/11/2026]:** execucoes `running` abandonadas em `job_runs` (processo interrompido entre o inicio e o registro final) sao identificadas, encerradas com estado apropriado e com o motivo registrado, com testes. **Obrigatoria antes de qualquer execucao agendada ou operacao autonoma em producao** (`RISK_REGISTER.md` R-12). Nao implementada |
| 4 | Agendador | Workflow agendado do GitHub Actions chamando `run-pipeline`, `concurrency` e acionamento manual (secao 4.2) | Duas execucoes do mesmo workflow nao se sobrepoem (`concurrency`); workflow agendado roda em simulacao sem erro; uma execucao repetida para o mesmo horario nao duplica efeitos (garantido pelos estados do bloco 3) |
| 5 | Produtos e nichos | Importador CSV/JSON, pontuacao, dados de teste identificados | Ranking determinista coberto por testes; 100% dos registros de demonstracao com `is_test = true`; campo desconhecido nunca vira zero |
| 6 | Conteudo | Briefings, maquina de estados, importacao de rascunhos | Transicoes invalidas rejeitadas em teste; briefing gerado inclui divulgacao de afiliado; nada passa a `approved` sem acao registrada em `audit_log` |
| 7 | Publicacao multicanal (primeiro adaptador: YouTube; WordPress e demais canais depois) | Interface `PublisherProvider`, primeiro adaptador, aprovacao, dry-run, publicacao em modo nao publico | Dry-run nao faz chamadas de rede (teste); so `approved` com autorização válida para o hash exato é processado, inclusive em envio privado (seção 4.7.1); reenvio nao duplica; estado nao publico enviado explicitamente (teste); teste manual em canal ou site de teste, uma vez. **Marco M1: primeira versao funcional** (etapas 1 a 7 em modo de teste) |
| 8 | Vendas e comissoes | Importacao somente leitura da plataforma de afiliados | Antes: documentacao oficial lida e registrada. Depois: respostas simuladas em testes; upsert idempotente por id de transacao. **Marco M2: dados reais** |
| 9 | Trafego e buscas | Analytics e Search Console somente leitura; rastreio de cliques conforme opcao escolhida | Metricas diarias gravadas sem duplicidade; atribuicao documentada com limites declarados |
| 10 | Relatorios e notificacoes | Relatorio semanal, alertas | Relatorio gerado por tarefa agendada; alerta recebido em falha provocada de proposito |
| 11 | Otimizacao | Recomendacoes por regras | Cada recomendacao cita os dados que a motivaram; nenhuma acao automatica com gasto |
| 12 | Anuncios | Somente desenho de interface e custos | Fora do prototipo; exige decisao de orcamento. **Marco M3: operacao comercial controlada** depende de M2 e de revisao de seguranca |

**Historico dos blocos 3 e 4 (revisao 7):** ate a revisao 6, o bloco 3 se chamava "Nucleo de tarefas" (fila, reserva, retentativas, concessao e `job_runs`, com o criterio "tarefa executada uma unica vez com dois executores simultaneos; tarefa de processo morto e recuperada") e o bloco 4 previa `schedules` e `run-due` ("executar `run-due` duas vezes para o mesmo horario cria uma unica tarefa"). Esses criterios contradiziam as secoes 4.1, 4.2, 9.2 e 9.3, que desde a revisao 3 definem para o MVP a execucao procedural em lotes, sem fila concorrente, leases, `SKIP LOCKED` nem agenda no banco. A revisao 7 so alinhou o catalogo a essas secoes; fila, leases e reserva atomica continuam possiveis no futuro, se volume ou concorrencia reais os justificarem (secao 9.2, item 3).

## 9. Testes automatizados e prevencao de execucao duplicada

### 9.1 Estrategia de testes

- **Unitarios:** pontuacao, maquina de estados, redacao de logs, calculo de agenda. Rapidos, sem banco.
- **Integracao:** executor de lotes, migracoes e repositorios contra um PostgreSQL real, iniciado como servico no GitHub Actions.
- **Contrato das integracoes:** respostas das APIs simuladas com transporte falso do `httpx`, a partir de exemplos salvos retirados da **documentacao oficial**. Testes nunca acessam a rede.
- **Marcadores:** `unit`, `integration`; os de integracao falham claramente se nao houver banco. Os testes sao classes `unittest.TestCase` executadas pelo `pytest`. Situacao no Lote 5.1: existe o marcador `integration` (`tests/integration/`), excluido da execucao padrao (`addopts` no `pyproject.toml`) e rodado explicitamente no CI com `pytest -m integration` contra o PostgreSQL 16 do job. Sem `TEST_DATABASE_URL` esses testes falham, nao sao pulados. Os unitarios continuam rodando so com a biblioteca padrao.
- **Dados:** fabricas de dados sempre com `is_test = true`.
- **CI:** a cada alteracao rodam ruff, pytest e gitleaks. Alteracao so entra na branch principal com CI verde. Situacao em 07/11/2026: `ci.yml` (ruff check, pytest e comandos de fumaca da CLI) roda a cada `push`, exceto alteracoes so em `.md`, com limite de 10 minutos; o gitleaks roda em workflow separado (`secrets.yml`), em todo `push` inclusive so de `.md`, com historico completo. O `secrets.yml` existe na `feature/lote-4` e ainda nao na `main`. A formatacao (`ruff format --check`) nao e verificada (incremento 4.3, adiado).

### 9.2 Barreiras contra duplicidade (em camadas)

1. **Execucao em lotes:** no MVP, o agendador (GitHub Actions ou acionamento manual) inicia um comando CLI, por exemplo `autopilot run-pipeline`. O processo consulta o PostgreSQL, executa um lote limitado e encerra; nao manter um worker permanente.
2. **Banco como fonte da verdade:** estados, tentativas, resultados e erros ficam persistidos. O banco pode fornecer trabalho pendente, mas nao deve ser tratado como uma fila distribuida complexa.
3. **Concorrencia minima:** configurar `concurrency` no GitHub Actions para evitar sobreposicao do mesmo workflow. Adotar reserva atomica, leases, `SKIP LOCKED` ou advisory locks somente se testes demonstrarem concorrencia real que nao possa ser evitada de forma mais simples.
4. **Idempotencia nos efeitos externos:** importacoes usam identificadores externos; publicacoes usam chave por marca, conteudo e canal, alem de estado da operacao externa.
5. **Recuperacao de resultado incerto:** se uma chamada externa puder ter sido concluida mas a resposta se perdeu, marcar como `unknown` e reconciliar com a plataforma antes de repetir. Nao repetir cegamente uma publicacao.
6. **Registro:** cada lote e item processado tem estado, horario, tentativas, erro resumido e resultado em `job_runs`/tabelas de dominio.

## 10. Seguranca

- **Segredos:** em desenvolvimento, `.env` local (ignorado pelo Git); no CI e agendamento, **Segredos do GitHub Actions**. Nunca em codigo, logs, issues, commits ou conversas.
- **Privilegio minimo:** credenciais somente leitura sempre que a API permitir (vendas, Analytics, Search Console). Usuario WordPress dedicado, com papel minimo. Papel de banco da aplicacao sem permissao de alterar esquema; migracoes usam outro papel.
- **Conexao com o banco** sempre com TLS.
- **Rotacao:** documentar como revogar e recriar cada credencial; trocar imediatamente se houver suspeita de vazamento.
- **Varredura de segredos [Acordado — L7]:** `gitleaks` no GitHub Actions e **requisito** antes do uso de qualquer credencial real. Recomenda-se tambem rodar a mesma verificacao no fluxo de desenvolvimento, antes de cada envio. A protecao de push nativa do GitHub exige "GitHub Secret Protection" ([GitHub Docs](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection)), e a protecao de branch em repositorio privado exige GitHub Pro (resposta da API em 04/11/2026); nenhuma das duas e pressuposta.
- **Tokens e senhas sempre fora do repositorio**, inclusive em arquivos de exemplo, testes e historico. Valores de teste usam dominios reservados (`.invalid`).
- **Redacao de logs** e proibicao de imprimir configuracao completa.
- **Dados pessoais (LGPD):** nao armazenar dados de compradores alem do indispensavel; definir retencao.
- **Seguranca operacional:** `PUBLISHING_ENABLED` e dry-run desligados por padrao; aprovacao humana registrada; botao de parada que desativa todas as agendas.
- **Dependencias:** versoes fixas e Dependabot (gratuito) para avisos.
- **Permissoes do repositorio:** repositorio privado; fluxos do Actions com permissao minima (`contents: read`).
- **Contas:** autenticacao em dois fatores no GitHub, no banco e em cada plataforma.

## 11. Desenvolvimento pelo celular

- Alteracoes por commits ou pull requests; **o CI e o ambiente de testes**, entao nao e preciso computador para validar.
- Edicao possivel pelo editor web do GitHub e por este assistente; o editor em nuvem do GitHub (Codespaces) pode ter cota gratuita limitada (**verificar**).
- Quando houver computador: instalar Python e PostgreSQL local (ou usar o banco de desenvolvimento no Neon), rodar `pytest` e fazer o primeiro teste manual de publicacao em rascunho.
- Trabalhar em pequenas etapas, uma por pull request, com o criterio de conclusao da secao 8 na descricao.

## 12. Decisoes pendentes e itens a verificar

Checklist antes das etapas correspondentes:

- [x] Cota atual do GitHub Actions em repositorio privado no plano gratuito e regras de agendamento (verificado em 04/11/2026, secao 6).
- [x] Limites atuais do plano gratuito do Neon, confirmados na pagina oficial (verificado em 04/11/2026, secao 6).
- [ ] Documentacao oficial da API da Hotmart: autenticacao, endpoints disponiveis para afiliados, limites de uso, termos (etapa 8).
- [x] Politica de expiracao de tokens OAuth do Google e cotas da YouTube Data API (verificado em 05/11/2026, secao 7.1).
- [ ] Mesma verificacao para Analytics e Search Console, se houver site (etapa 9).
- [ ] Onde ficara o site WordPress e se permite REST e senhas de aplicativo (etapa 7).
- [ ] Regras de divulgacao de publicidade e politicas de afiliados aplicaveis ao conteudo (etapa 6).
- [ ] Canal de notificacao gratuito e seus limites (etapa 10).
- [ ] Forma de rastrear cliques (etapa 9).
- [ ] Ajuste futuro do `.env.example` (nomes das variaveis da Hotmart), em alteracao propria.
- [x] Primeira execucao real do CI no GitHub (ruff e pytest): verde na `main` em `c2167a5` e no branch `feature/product-intelligence` em `9c8fdaa` (historico de execucoes consultado em 04/11/2026).
- [x] Incluir o `gitleaks` no CI: feito no Lote 4.1 (`secrets.yml`, commit `3ae9782` na `feature/lote-4`, execucao verde no GitHub). Pendente: chegar a `main` por decisao do responsavel.
- [ ] Confirmar as versoes das acoes `actions/checkout` e `actions/setup-python` (hoje referenciadas por `@v4`/`@v5`; fixar por hash e melhoria opcional).
- [ ] Antes de qualquer segunda marca: definir regras de separacao entre marcas (contas, credenciais, dados, metricas) e conferir os termos das plataformas sobre multiplas contas ou marcas (ver `PROJECT_VISION.md`).
- [ ] Antes de cada adaptador de canal: autenticacao, cotas, auditoria, regras de divulgacao e termos de automacao do canal (secoes 4.7 e 7).
- [x] Antes da etapa do banco: definir em quais tabelas o `brand_id` entra (secao 4.3, decisao de 07/11/2026). Os nomes das tabelas financeiras ficam para o lote de vendas e comissoes, por decisao da mesma data.
- [ ] Escolher a alternativa de OAuth do YouTube (secao 7.1, alternativas A a C) e confirma-la em teste controlado antes de automatizar.
- [ ] Antes do lote de publicação: validar as propostas técnicas das seções 4.7.2 a 4.7.5 (manifesto e hash, serialização canônica, verificador de destinos externos, adaptador e tratamento de instantes), inclusive a escolha de dependências.
- [ ] Antes de qualquer envio real, inclusive privado: definir e aprovar os parâmetros pendentes da seção 4.7.6.
- [ ] Antes de ativar qualquer política de publicação: decisão expressa do proprietário, revisão de riscos e implementação validada (`AUTONOMY_AND_AGENTS.md` seção 4.3; `RISK_REGISTER.md` R-29).

## 13. Fontes consultadas em 28/10/2026

Paginas de documentacao e de terceiros sobre GitHub Actions (cobranca e uso), Neon (precos), Supabase (plano gratuito), Hotmart (SDKs e conectores de terceiros) e hospedagem gratuita. Varias sao de terceiros e podem estar desatualizadas; **este documento deve ser revisado contra as paginas oficiais antes de cada etapa que dependa de um limite ou recurso.**

**Fontes consultadas em 04/11/2026 (oficiais):** [GitHub — cobranca do Actions](https://docs.github.com/en/billing/concepts/product-billing/github-actions); [GitHub — eventos de workflow](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows); [GitHub — protecao de push](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection); [Neon — precos](https://neon.com/pricing); [Hotmart Developers](https://developers.hotmart.com/docs/pt-BR/); [Hotmart — autenticacao](https://developers.hotmart.com/docs/en/start/app-auth/); [YouTube Data API — visao geral](https://developers.google.com/youtube/v3/getting-started); [YouTube — videos.insert](https://developers.google.com/youtube/v3/docs/videos/insert); [Google — OAuth 2.0](https://developers.google.com/identity/protocols/oauth2); [Meta — publicacao no Instagram](https://developers.facebook.com/docs/instagram-platform/content-publishing/); [TikTok — Content Posting API](https://developers.tiktok.com/doc/content-posting-api-get-started); [Pinterest — configuracao de app](https://developers.pinterest.com/docs/getting-started/set-up-app/); [WordPress — autenticacao REST](https://developer.wordpress.org/rest-api/using-the-rest-api/authentication/).

**Fontes consultadas em 05/11/2026 (oficiais):** [Google — OAuth 2.0](https://developers.google.com/identity/protocols/oauth2); [Google Cloud — Manage App Audience](https://support.google.com/cloud/answer/15549945); [Google Cloud — When is verification not needed](https://support.google.com/cloud/answer/13464323); [Google Cloud — Unverified apps](https://support.google.com/cloud/answer/7454865); [Google Cloud — Verification requirements](https://support.google.com/cloud/answer/13464321); [Google Cloud — FAQ de verificacao](https://support.google.com/cloud/answer/13463817?hl=En); [YouTube — videos.insert](https://developers.google.com/youtube/v3/docs/videos/insert); [YouTube — OAuth para servidores web](https://developers.google.com/youtube/v3/guides/auth/server-side-web-apps); [YouTube — OAuth para dispositivos](https://developers.google.com/youtube/data/guides/auth/devices); [YouTube — cotas e auditorias](https://developers.google.com/youtube/v3/guides/quota_and_compliance_audits).


### 9.3 Escopo operacional minimo do MVP **[Proposta]**

- O agendador apenas dispara o CLI; o fluxo principal e procedural e executado em lotes limitados. Estados persistidos no PostgreSQL permitem retomar execucoes sem introduzir um broker ou framework de orquestracao.
- Persistir o resultado de cada item, nao apenas o resultado agregado do lote. Uma falha em um item nao deve apagar o progresso dos demais.
- Retentativas devem ser limitadas, com timeout e espera crescente para falhas transitorias. Erros de autenticacao (401/403) pausam a integracao e exigem verificacao/reautorizacao; 429 respeita limites e `Retry-After` quando fornecido; falhas 5xx podem ser retentadas com limite.
- Nao adotar dead-letter queue, leases, workers concorrentes ou `SKIP LOCKED` no MVP sem necessidade demonstrada. Manter interfaces e estados que permitam evolucao posterior sem impor essa complexidade desde o inicio.

### 9.4 Operacoes externas e integridade financeira **[Proposta]**

- Para publicacoes, registrar estados como `pending`, `uploading`, `uploaded_private`, `published`, `failed` e `unknown` (ou equivalentes coerentes com o adaptador). Em estado `unknown`, consultar a plataforma antes de reenviar.
- Preservar historico de mudancas de comissao (pendente, confirmada/liberada, reembolsada/cancelada) em vez de sobrescrever o estado anterior sem trilha. Registrar separadamente recebimentos e estornos efetivos em caixa.
- A ausencia de um identificador de atribuicao (por exemplo, `src`) nao prova que a venda nao ocorreu nem autoriza atribui-la a um conteudo. Usar estados explicitos: confirmada, estimada ou nao atribuida, conforme evidencia disponivel.


### 12.1 Visão de destino: ecossistema multicanal e global **[Acordado]**

A arquitetura deve permanecer preparada para uma operação privada com múltiplas marcas, canais, redes de afiliados, sites/blogs e mercados. Isso não exige implementar tudo no MVP. O princípio é manter interfaces e dados capazes de evoluir sem acoplar o núcleo a uma única plataforma.

- `PublisherProvider`: adaptador por canal de publicação (YouTube primeiro; outros após validação).
- Adaptadores de programas/redes de afiliados: isolados por integração, sem pressupor que todas oferecem API de descoberta.
- Conteúdo: suporte a vídeo longo, vídeo curto e artigo/guia; cada publicação tem canal, formato, versão, aprovação e estado próprios.
- Localização: preservar locale, mercado e moeda original quando aplicável.
- Site/blog: WordPress ou solução equivalente pode ser integrado em fase posterior; não é requisito para concluir o lote atual ou o MVP do YouTube.
- Monetização: comissões, anúncios e programas de criadores devem ser fontes identificadas separadamente nos relatórios.

### 12.2 Limite entre automação e aprovação humana **[Acordado]**

A automação pode executar pesquisa, coleta, análise, rascunhos, adaptações e verificações técnicas dentro de limites. Entretanto:
- o proprietário decide sobre nichos, marcas, produtos e ofertas;
- todo envio a plataforma externa, público ou privado, exige autorização válida para o hash exato da versão; na fase inicial, a autorização é individual (`AUTONOMY_AND_AGENTS.md` seções 4.1 a 4.4). É regra de fase, não limitação definitiva da arquitetura;
- o painel móvel é a interface de controle pretendida;
- políticas operacionais não autorizam automaticamente publicação pública, gastos, criação de contas ou ações irreversíveis;
- toda aprovação e execução deve ser auditável.

### 12.3 Preparação internacional sem antecipar implementação

Ao criar tabelas e contratos, considerar país/mercado, locale, timezone e currency quando realmente relevantes. Preservar moeda original, taxa e data de conversão. Não construir conversor cambial, localização de todos os conteúdos ou integrações internacionais antes de haver um mercado concreto e uma decisão de ativação.

### 12.4 Fusos horários e janelas de publicação por mercado **[Diretriz de destino]**

- Cada marca/canal poderá declarar `locale`, mercado, fuso IANA (por exemplo, `America/Sao_Paulo` ou `America/New_York`) e uma janela local preferencial de publicação. A configuração deve ficar no nível que realmente controla a distribuição (marca, canal ou combinação marca-canal), sem presumir que todos os canais de uma marca usam a mesma janela.
- Agendamentos são calculados usando a base IANA de fusos horários, respeitando horário de verão e mudanças legais. Não armazenar apenas deslocamentos fixos como `UTC-3`.
- O agendador continua iniciando lotes curtos; o processo consulta tarefas elegíveis e só prepara/publica quando a janela configurada e as demais autorizações forem satisfeitas. Não manter um processo dormindo à espera da próxima janela.
- Janelas são hipóteses operacionais a testar com dados de audiência, não garantias de alcance ou conversão. Devem ser configuráveis e revisadas por mercado/canal.
- A janela de horário nunca substitui a autorização válida para a versão exata de uma peça (individual na fase inicial).
- **[Decisão conceitual — 12/11/2026]** Data e hora de publicação são exclusivamente operacionais e ficam fora do manifesto da versão, mesmo quando possam ser enviadas à plataforma como parâmetros de agendamento. No MVP, o sistema envia o conteúdo no horário programado, sem utilizar o agendamento nativo da plataforma, para que as verificações ocorram imediatamente antes da publicação real. Reagendar não altera o hash nem exige nova aprovação por si só; a validade da autorização e todas as verificações são conferidas no momento do envio (`AUTONOMY_AND_AGENTS.md` seções 4.5 e 4.6). O fim de ofertas com data sem horário segue a seção 4.7.5.

### 12.5 Interruptor global de emergência (Stop All) **[Diretriz de destino]**

- Manter um controle global persistente, por exemplo `system_controls`, com estado explícito `ACTIVE`/`HALTED`, motivo, instante, autor e trilha de auditoria. O nome e o esquema finais dependem da migração e revisão de implementação.
- Toda execução consulta o controle no início; além disso, cada tarefa deve revalidá-lo imediatamente antes de qualquer efeito externo ou ação sensível. Uma checagem apenas no início do lote não interrompe com segurança lotes longos.
- Em `HALTED`, bloquear novas chamadas externas, publicações, agendamentos de publicação e ações mutáveis automatizadas. Permitir apenas operações explicitamente classificadas como seguras, como leitura de estado, diagnóstico e recuperação.
- Se o banco ou o controle global estiver indisponível/inconsistente, falhar fechado para efeitos externos: não publicar nem executar ações sensíveis. Registrar o motivo localmente/na saída disponível e alertar quando possível.
- O Stop All deve também desativar ou suspender os disparadores agendados quando viável, mas não depender exclusivamente disso: uma execução já iniciada precisa verificar o controle antes de cada efeito externo.
- A retomada exige ação explícita do proprietário, motivo e registro de auditoria. Antes de retomar, reconciliar operações em estado incerto (`unknown`) e itens parcialmente processados; não presumir que todo lote parado pode ser repetido integralmente.
- O Stop All é uma salvaguarda operacional, não substitui backups, idempotência, permissões mínimas nem procedimentos de resposta a incidentes.
- **[Decisão conceitual — 12/11/2026]** O mecanismo de emergência permanece permanentemente disponível. Quando acionado, bloqueia as operações abrangidas, inclusive envios e publicações, e prevalece sobre qualquer autorização ou política. `ACTIVE` indica apenas operação normal: não é, por si, autorização para publicar. `HALTED`, ou estado que não possa ser lido, impede qualquer envio (`AUTONOMY_AND_AGENTS.md` seção 4.1, item 5).

### 12.6 Feedback adaptativo e melhoria editorial **[Diretriz de destino]**

- Registrar aprovações, rejeições, pedidos de ajuste e edições do proprietário com referência à versão exata da peça, marca/canal, data e categorias de feedback quando fornecidas (por exemplo: tom, estrutura, precisão, fonte, adequação comercial ou conformidade).
- Usar esse histórico para melhorar briefings, recomendações e rascunhos futuros, preferencialmente por regras transparentes e exemplos selecionados/revisados. O feedback é sinal contextual, não verdade universal nem autorização para alterar políticas.
- Manter rastreabilidade das versões de prompts/regras e permitir desativar ou reverter um ajuste que piore qualidade. Não incorporar automaticamente texto rejeitado como exemplo negativo sem classificação; rejeições podem ocorrer por motivos distintos.
- Medir qualidade com sinais separados (edições, rejeições, correções factuais, desempenho posterior) e evitar inferir preferências a partir de uma amostra pequena.
- **O aprendizado adaptativo não concede aprovação automática.** Na fase inicial, todo envio continua exigindo autorização humana individual da versão exata. A evolução para publicação por política está prevista em `AUTONOMY_AND_AGENTS.md` seção 4.3 e exige decisão expressa do proprietário e revisão de riscos, políticas e controles; não decorre de um número de aprovações consecutivas nem é ativada pelo sistema.

## 14. Historico de revisoes

| Revisao | Data | Mudancas |
|---|---|---|
| 13 | 12/11/2026 | Consolidação da especificação de autorização de publicação (decisões conceituais de 12/11/2026; regras normativas em `AUTONOMY_AND_AGENTS.md` seção 4). Princípio 9 e seções 4.7 e 12.2: todo envio, público ou privado, exige autorização válida para o hash exato; individual na fase inicial, sem ser limitação definitiva da arquitetura. Novas seções 4.7.1 (autorização de envio), 4.7.2 (manifesto e hash, proposta técnica), 4.7.3 (verificação de destinos externos, proposta técnica), 4.7.4 (adaptador de publicação), 4.7.5 (validade e instantes, proposta técnica) e 4.7.6 (parâmetros pendentes). Seção 8, bloco 7: critério passa a citar a autorização por hash. Seção 12: novos itens de verificação; 12.4 (agendamento operacional, sem agendamento nativo no MVP), 12.5 (Stop All permanentemente disponível) e 12.6. Nada implementado; nenhuma dependência escolhida; nenhuma política ativada. |
| 12 | 08/11/2026 | Debito tecnico M2 registrado no criterio de conclusao do bloco 3 (secao 8): reconciliacao de execucoes `running` orfas, obrigatoria antes de execucao agendada ou operacao autonoma em producao. Lote 5 integrado a `main` pelo PR #11 (merge `bd62e83`). Nenhuma decisao anterior alterada. |
| 11 | 08/11/2026 | Lote 5.3: importação operacional registrada na secao 4.5 (comando `autopilot products import`, transações por arquivo, simulação por rollback, decisões P1 a P11, N1 a N4 e C1 a C5) e `job_runs` marcado como implementado nas secoes 4.1 e 4.4. Resumo com referência às docstrings, sem repetir as regras completas. |
| 10 | 08/11/2026 | Lote 5.2: regras de gravação de produtos registradas na secao 4.5 (decisoes D1 a D7 aprovadas em 07/11/2026), incluindo a correcao da 5.2c: `last_imported_at` nunca volta no tempo nem fica antes de `first_imported_at` em transacoes concorrentes. Reorganizacao do Lote 5 em 5.1, 5.2 e 5.3 (D7). |
| 9 | 07/11/2026 | Correcao do Lote 5.1 apos revisao: limite de casas decimais por `scale(trim_scale(...))`, igual ao modelo; `schema_migrations` localizada pelo `search_path`; regras de operacao do migrador (conexao direta, sem pooler em modo transacao; sem `BEGIN`/`COMMIT`/`ROLLBACK` nos arquivos; `.sql` com LF). A `0001` foi corrigida no lugar, por decisao do responsavel, porque so tinha sido aplicada em bancos descartaveis. |
| 8 | 07/11/2026 | Lote 5.1: aplicacao do `brand_id` por tabela registrada (secao 4.3: `products` e nichos compartilhados, `brands` vazia, obrigacao de `brand_id NOT NULL` para tabelas comerciais futuras); tabelas financeiras adiadas para o bloco 8 (bloco 2 e checklist da secao 12); migrador e excecao do advisory lock; banco local e CI sem TLS ate haver banco hospedado. Decisoes aprovadas pelo responsavel em 07/11/2026. |
| 7 | 07/11/2026 | Consistencia documental (Lote 4.4), sem mudar decisoes: catalogo da secao 8 (blocos 3 e 4) e trechos das secoes 2, 3, 4, 5, 6.1 e 9.1 alinhados a execucao procedural em lotes ja definida em 4.1, 4.2, 9.2 e 9.3 (sem fila, leases, `schedules` nem `run-due`), com nota historica dos criterios antigos; Product Intelligence identificado por lotes, nao como "Etapa 2"; referencias a `PRODUCT_ROADMAP.md` e `FUTURE_ARCHITECTURE.md`, que nunca existiram, redirecionadas; situacao do Gitleaks (Lote 4.1) e estrutura atual registradas (secoes 3, 4, 9.1 e 12). |
| 6 | 06/11/2026 | Acrescentadas diretrizes de destino para fuso IANA/janelas locais por mercado e canal, Stop All com verificação antes de efeitos externos e falha fechada, e feedback adaptativo rastreável sem aprovação automática. Preservada aprovação humana individual de toda publicação pública. |
| 5 | 06/11/2026 | Proposta de alinhamento à visão de ecossistema privado multicanal/global; múltiplas redes, blog/artigos e monetização complementar; preparação locale/currency; central móvel e aprovação individual obrigatória de toda publicação pública. MVP permanece sequencial e simples. |
| 1 | Ate 04/11/2026 | Versao no GitHub (`main`, `d1bb139`) |
| 2 | 04/11/2026 | L4: incorporadas as quatro contribuicoes de `ARCHITECTURE_proposta.md` (referencia a visao no cabecalho; principio 8; nota de identificacao de marca, ajustada pela L6, em 4.3; item de checklist sobre segunda marca em 12). L1: dois indicadores e regra de reinvestimento (4.8, 4.9, 4.11). L2: principio 9, publicacao multicanal (4.7), automacao de producao (4.6), dependencias de canais (5, 7), bloco 7 generalizado (8). L3: ordem real de desenvolvimento e tabela da secao 8 como catalogo de blocos. L6: `brand_id` transversal no esquema v1 (4.3, bloco 2). L7: Gitleaks como requisito (3, 10, 12). Fatos de limites gratuitos e da API atualizados com fontes oficiais (6, 7, 13) |
| 3 | 05/11/2026 | Em revisao, nao aprovada. Secao 2: regras de comunicacao do monolito modular (interfaces internas sincronas, fila para o assincrono, banco como fonte da verdade e nao como canal obrigatorio, dependencias sem ciclos). Secao 4.8: definicao de comissao confirmada. Principio 9: automacao hibrida e contingencia manual. Secoes 3 e 12: momento do Gitleaks. Secao 4.7: ordem dos canais, Fases A e B de publicacao, aprovacao por politica, fatos atualizados do `videos.insert`. Secao 7 e nova 7.1: OAuth do YouTube. Secao 8: estado do desenvolvimento como informacao nao verificada. Secao 13: fontes de 05/11 |
| 4 | 05/11/2026 | Em revisao, nao aprovada. Secoes 4.10 e 4.11: diferenca entre recomendacoes iniciais e otimizacoes futuras dentro de politica; campanhas e gastos fora de politica por padrao, sem autorizacao atual, com requisitos para eventual politica expressa. |
