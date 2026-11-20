# Affiliate Autopilot

Plataforma de automação de marketing de afiliados: pesquisa de nichos, análise de produtos,
criação de conteúdo, publicação **autorizada**, acompanhamento de vendas e otimização.

> **Status (14/11/2026):** na `main` existem a fundação (configuração, logs, erros, dados de
> demonstração, CLI), o modelo de produto e os importadores de produtos por arquivo JSON e CSV
> (Product Intelligence, Lotes 1 a 3), a governança desses importadores e a varredura de segredos
> com Gitleaks (Lote 4), integrados pelo merge commit `c97017d`; o Lote 5, integrado pelo
> merge commit `bd62e83` (PR #11): a conexão com o PostgreSQL, o migrador e o esquema inicial
> (5.1), a gravação de produtos com histórico de preço e comissão (5.2) e a importação
> persistente pelo comando `autopilot products import` (5.3); e o Lote 6, integrado pelos merge
> commits `08e0ece` (PR #13) e `cc34e2e` (PR #14): a pontuação de produtos (6.1), sua
> persistência no PostgreSQL (6.2a e 6.2b) e os comandos `autopilot products score` e
> `autopilot products ranking` (6.2c). A pontuação simula por padrão; a gravação real só pode
> rodar num workflow autorizado do GitHub Actions, **que ainda não existe**. Os Lotes 7, 8 e 9 e o
> incremento 4.3 foram integrados em 14/11/2026 (PRs #16 a #19, último merge `69758d4`): executor
> de lotes `autopilot run-pipeline`, reconciliação de execuções abandonadas
> `autopilot jobs reconcile`, interruptor de emergência Stop All (`autopilot control`) com trilha
> de auditoria, agendador de um lote em simulação (**desabilitado por padrão**) e verificação de
> formatação no CI. **Tudo isso foi validado em banco descartável: não existe banco hospedado, e
> o projeto não está pronto para produção.**
> **Nada publica
> conteúdo, cria campanhas, gasta dinheiro ou se conecta a serviços externos**; não há
> integrações ainda. O estado verificado está em [PROJECT_STATUS.md](PROJECT_STATUS.md).

A arquitetura completa, com decisões, limites conhecidos de serviços gratuitos e o plano por
etapas, está em [ARCHITECTURE.md](ARCHITECTURE.md).

## Princípios

- Custo zero no protótipo: só bibliotecas gratuitas e de código aberto.
- Seguro por padrão: nenhum segredo no repositório; publicar será sempre opcional e aprovado por uma pessoa.
- Dados reais ou dados de teste claramente identificados (`is_test`, prefixo `[TESTE]`). Nunca valores inventados apresentados como reais.
- Pequeno e testável: uma etapa por vez, cada uma com critério de conclusão.

## Estrutura

```
src/autopilot/
  cli.py               comandos: check-config, demo-data, db migrate, products import,
                       products score, products ranking, jobs reconcile, run-pipeline,
                       control status | halt | resume | history
  core/config.py       configuração por variáveis de ambiente (segredos mascarados)
  core/log.py          logs JSON em stderr, com redação de segredos
  core/errors.py       hierarquia de erros
  core/db.py           conexão com o PostgreSQL (DATABASE_URL nunca aparece em mensagens)
  core/migrator.py     migrador SQL próprio (checksum, uma transação por migração, lock)
  core/provenance.py   validação da proveniência exigida para a gravação real da pontuação
  core/controls.py     Stop All: leitura com falha fechada, acionamento, retomada e histórico
  products/seeds.py    leitura e validação dos dados de demonstração
  products/models.py   modelo de produto (Product), validado e imutável
  products/json_importer.py, csv_importer.py
                       leitura e validação de arquivos de produtos (não gravam nada)
  products/repository.py
                       gravação de produtos no PostgreSQL, idempotente, com histórico de preço
  products/importing.py
                       importação de um arquivo: validação, gravação e registro da execução
  products/scoring.py  pontuação de produtos: função pura e determinística
  products/scoring_runs.py
                       execução da pontuação com persistência e leitura de rankings gravados
  tasks/job_runs.py    registro de execuções (tabela job_runs)
  tasks/reconcile.py   reconciliação de execuções abandonadas (running sem registro final)
  tasks/pipeline.py    executor procedural em lotes: recuperação e etapas em sequência
migrations/            migrações SQL numeradas (0001_schema_v1.sql, 0002_product_scores.sql,
                       0003_system_controls.sql); aplicadas nunca são editadas
data/seeds/            produtos FICTÍCIOS de demonstração
tests/                 testes unitários; tests/integration/ exige PostgreSQL
.github/workflows/     ci.yml (lint, testes, CLI), secrets.yml (Gitleaks) e scheduler.yml
                       (agendador do lote em simulação, desabilitado por padrão)
```

Regras de leitura dos arquivos (`import_products_from_json` e `import_products_from_csv`):
campos desconhecidos e valores inválidos são recusados sem correção silenciosa; o `status`
importado só pode ser `candidate` (aprovar produto é decisão do responsável, não do arquivo); um
`id` repetido no mesmo arquivo recusa todas as ocorrências; registros inválidos não impedem a
importação dos válidos. Os formatos aceitos estão descritos nas docstrings desses módulos.

Importação persistente (`autopilot products import`, etapa 5.3):

- **simula por padrão**: só `--commit` grava produtos. A simulação percorre o mesmo caminho da
  gravação e desfaz tudo no fim; a execução fica registrada em `job_runs` com `dry_run = true`;
- cada arquivo tem a própria transação e o próprio registro em `job_runs`: um arquivo com falha
  não desfaz os anteriores nem impede os seguintes;
- formato (`.json` ou `.csv`) e arquivos repetidos são conferidos antes de conectar ao banco;
- o relatório no terminal mostra só o nome base de cada arquivo, as contagens e até 50 detalhes
  (erros de registro e recusas) por arquivo, nunca caminhos, identificadores ou valores dos
  produtos.

As regras de gravação (o que conta como novo, atualizado, sem mudança, desatualizado ou
recusado) estão no `ARCHITECTURE.md`, seção 4.5.

Pontuação de produtos (`autopilot products score` e `autopilot products ranking`, Lote 6):

- a nota é uma **classificação econômica preliminar** dos produtos `candidate`, não previsão de
  vendas, receita ou lucro, e nunca muda o `status` do produto. Campo desconhecido fica
  desconhecido, nunca vira zero: produto sem nota calculável aparece à parte, "sem pontuação";
- **não há conversão entre moedas**: o ranking é separado por moeda, e hoje só há referência
  para BRL (moedas sem referência ficam sem pontuação);
- `products score` **simula por padrão**: calcula e mostra o ranking, registra a execução em
  `job_runs` com `dry_run = true` e não grava notas, rankings nem configurações;
- `products score --commit` grava notas e ranking, mas **só no workflow autorizado do GitHub
  Actions a partir da `main`, que ainda não existe**: a gravação real está desabilitada
  operacionalmente. A CLI já confere a proveniência e as condições C1 e C2 e, se faltar alguma,
  recusa antes de conectar ao banco (código 2), sem registrar nada. A condição C3 (credenciais
  e controles do workflow) depende de infraestrutura ainda não configurada e não é verificada
  pela CLI. Não use `--commit` localmente;
- `products ranking` só lê rankings gravados; simulações e execuções com falha não têm ranking;
- os relatórios agrupam os produtos por moeda e mostram só plataforma e id, nunca nomes, URLs ou
  credenciais.

O algoritmo, a persistência e os requisitos da gravação real (proveniência e condições C1 a C3)
estão no `ARCHITECTURE.md`, seção 4.5.

Lotes e recuperação (`autopilot run-pipeline` e `autopilot jobs reconcile`, Lote 7):

- `jobs reconcile` trata as execuções que ficaram `running` em `job_runs` porque o processo
  morreu antes do registro final (débito M2): as iniciadas há mais de 60 minutos (ajustável,
  mínimo 10) são encerradas como `failed`, com o motivo gravado. **Simula por padrão**: só
  `--commit` encerra;
- `run-pipeline` executa um lote: primeiro a mesma recuperação, depois as etapas em sequência
  (hoje, só a pontuação de produtos). **Simula por padrão**; `--commit` exige a mesma
  proveniência de `products score --commit`, então a gravação real continua desabilitada
  operacionalmente;
- cada lote tem a própria execução em `job_runs` (`pipeline.run`), com o desfecho de cada etapa:
  falha transitória é repetida até 3 vezes; falha permanente fica registrada; estado
  indeterminado nunca é repetido; depois de uma etapa que não terminou bem, as seguintes não
  rodam. Na gravação, uma etapa não começa enquanto houver execução real da mesma tarefa em
  andamento ou aguardando reconciliação;
- sem o agendador ligado (Lote 9, abaixo), os dois comandos só rodam quando alguém os executa.

As regras completas estão nas docstrings de `tasks/reconcile.py` e `tasks/pipeline.py`.

Interruptor de emergência (`autopilot control`, Stop All, Lote 8):

- o banco guarda um estado global, `ACTIVE` ou `HALTED`, com motivo, autor e instante. Toda
  mudança fica registrada numa trilha de auditoria que só aceita inserções (`audit_log`);
- com o Stop All acionado (`HALTED`), **toda gravação é recusada** antes de registrar qualquer
  execução (código 3): `products import --commit`, `products score --commit` e
  `run-pipeline --commit`. O lote confere de novo antes de cada etapa, e a importação, antes
  de cada arquivo;
- **falha fechada**: se o estado não puder ser lido (banco sem a migração 0003, por exemplo), as
  gravações também são recusadas;
- simulações, consultas, `jobs reconcile` e os próprios comandos `control` continuam disponíveis;
- `control resume` exige autor e motivo e é recusado enquanto houver execução real em andamento
  ou abandonada: rode `jobs reconcile --commit` antes;
- `ACTIVE` é só operação normal: não autoriza publicar nada. Uma gravação que já passou pela
  conferência termina mesmo que o Stop All seja acionado em seguida.

As regras completas estão na docstring de `core/controls.py` e no `ARCHITECTURE.md`, seção 12.5.

## Como executar (quando houver acesso a um computador)

Requisitos: Python 3.12 ou superior. A instalação traz o driver `psycopg[binary]` (versão fixa);
quem instalou o projeto antes do Lote 5 precisa reinstalar (`pip install -e ".[dev]"`).
Um PostgreSQL só é necessário para os comandos `db`, `products import`, `products score`,
`products ranking`, `jobs reconcile`, `run-pipeline` e `control` e para os testes de integração.

```bash
git clone https://github.com/mszorzetti-art/affiliate-autopilot.git
cd affiliate-autopilot
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
python -m pip install -e ".[dev]"

python -m autopilot --help
python -m autopilot check-config   # mostra a configuração, sem expor segredos
python -m autopilot demo-data      # lista os produtos fictícios de demonstração
python -m autopilot db migrate --dry-run   # lista migrações pendentes (exige DATABASE_URL)
python -m autopilot db migrate             # aplica as pendentes; reaplicar não muda nada

# importação de produtos (exige DATABASE_URL e as migrações aplicadas)
python -m autopilot products import produtos.json outros.csv            # simula (padrão)
python -m autopilot products import --commit produtos.json outros.csv   # grava os válidos

# pontuação (exige DATABASE_URL e as migrações aplicadas); só simula fora do workflow autorizado
python -m autopilot products score                  # simula (padrão); o mesmo que --dry-run
python -m autopilot products score --include-test   # inclui produtos de teste (is_test)
python -m autopilot products score --top 5          # até 5 classificados por moeda (1 a 20)

# rankings gravados (somente leitura)
python -m autopilot products ranking                # o mais recente
python -m autopilot products ranking --run 42       # o da execução (job_run) 42
python -m autopilot products ranking --list         # lista os gravados (padrão 10; --limit 1 a 100)

# execuções abandonadas e lote (exigem DATABASE_URL e as migrações aplicadas)
python -m autopilot jobs reconcile                  # lista as abandonadas há mais de 60 min (simula)
python -m autopilot jobs reconcile --commit         # encerra as abandonadas como failed
python -m autopilot jobs reconcile --older-than-minutes 15   # outro limite (10 a 10080)
python -m autopilot run-pipeline                    # lote em simulação: recuperação e etapas
python -m autopilot run-pipeline --max-seconds 120  # limite de tempo do lote (1 a 3600; padrão 300)

# Stop All (exige DATABASE_URL e as migrações aplicadas)
python -m autopilot control status                  # estado atual (código 0 só se ACTIVE)
python -m autopilot control halt --actor maria --reason "Incidente no canal"    # bloqueia gravações
python -m autopilot control resume --actor maria --reason "Incidente resolvido" # retoma
python -m autopilot control history                 # mudanças registradas (padrão 10; --limit 1 a 100)
```

`products score --commit` não aparece nos exemplos de propósito: a gravação real só é aceita
dentro do workflow autorizado do GitHub Actions, que ainda não existe. A CLI confere a
proveniência e as condições C1 e C2; a condição C3 é da infraestrutura do workflow, ainda não
configurada (`ARCHITECTURE.md`, seção 4.5).

Códigos de saída de `products import`:

| Código | Significado |
|---|---|
| 0 | Todos os arquivos concluídos (mesmo com registros inválidos ou recusados, que aparecem no relatório) |
| 1 | Algum arquivo falhou, ficou com estado indeterminado no banco ou houve erro inesperado |
| 2 | Erro de uso ou de configuração (extensão inválida, arquivo repetido, `DATABASE_URL` ausente) |
| 3 | `--commit` recusado pelo Stop All (acionado ou ilegível), antes de registrar qualquer execução |
| 130 | Interrompido (Ctrl+C) |

Códigos de saída de `products score`:

| Código | Significado |
|---|---|
| 0 | Pontuação concluída (simulação, ou gravação no workflow autorizado) |
| 1 | Execução com falha, estado indeterminado no banco ou erro inesperado (só a classe do erro é mostrada) |
| 2 | Erro de uso ou de configuração (`DATABASE_URL` ausente), ou gravação recusada pela proveniência ou pelas condições C1 e C2, antes de conectar ao banco |
| 3 | `--commit` recusado pelo Stop All (acionado ou ilegível), antes de registrar qualquer execução |
| 130 | Interrompido (Ctrl+C) |

Códigos de saída de `products ranking`:

| Código | Significado |
|---|---|
| 0 | Ranking ou lista exibidos, ou nenhum ranking gravado ainda |
| 1 | `--run` com execução sem ranking (id inexistente, simulação, falha ou outra tarefa), ou erro na leitura |
| 2 | Erro de uso ou de configuração (`--top` com `--list`, `--limit` sem `--list`, `DATABASE_URL` ausente) |

Códigos de saída de `jobs reconcile` e `run-pipeline`:

| Código | Significado |
|---|---|
| 0 | Reconciliação ou lote concluídos (no lote, também quando o limite de tempo deixou etapas para o próximo) |
| 1 | Execução com falha, etapa com falha, bloqueada ou com estado indeterminado, ou erro inesperado (só a classe do erro é mostrada) |
| 2 | Erro de uso ou de configuração (`DATABASE_URL` ausente); em `run-pipeline --commit`, gravação recusada pela proveniência ou pelas condições C1 e C2, antes de conectar ao banco |
| 3 | Só em `run-pipeline --commit`: recusado pelo Stop All no início (nada é registrado) ou interrompido por ele antes de uma etapa (o lote fica `failed`) |
| 130 | Interrompido (Ctrl+C) |

Códigos de saída de `control`:

| Código | Significado |
|---|---|
| 0 | `status`: o estado é `ACTIVE`. `halt` e `resume`: o estado pedido vale (mudou agora ou já valia). `history`: exibido |
| 1 | `resume` recusado (execução real por reconciliar), mudança não confirmada ou erro na leitura |
| 2 | Erro de uso ou de configuração (`--actor` ou `--reason` ausentes ou inválidos, `DATABASE_URL` ausente) |
| 3 | Só em `status`: o estado é `HALTED` ou não pôde ser lido |
| 130 | Interrompido (Ctrl+C) |

O projeto funciona **sem nenhuma credencial**. Se quiser definir variáveis, copie
`.env.example` para `.env` (o `.env` é ignorado pelo Git) e preencha só o que precisar.
As variáveis lidas são `APP_ENV`, `LOG_LEVEL` e `DATABASE_URL` (usada pelos comandos `db`,
`products import`, `products score`, `products ranking`, `jobs reconcile`, `run-pipeline` e
`control`). Na
gravação real da pontuação, inclusive pelo `run-pipeline --commit`, a CLI
também confere as variáveis do GitHub Actions (`GITHUB_*`); isso só tem efeito dentro do
workflow autorizado.
Banco local e CI não usam TLS; antes de qualquer banco hospedado, TLS e um usuário de banco com
permissões restritas são obrigatórios.
**Nunca** coloque valores reais em `.env.example`.

## Como testar

```bash
python -m pytest -q              # testes unitários (com as ferramentas de desenvolvimento)
TEST_DATABASE_URL=postgresql://usuario:senha@localhost:5432/postgres \
    python -m pytest -q -m integration   # integração: exige PostgreSQL que permita criar bancos
ruff check .                     # lint
ruff format --check .            # formatação (o CI recusa o que estiver fora do padrão)
```

Sem o driver `psycopg` instalado, os testes unitários rodam apenas com a biblioteca padrão
**exceto** `tests/test_job_runs.py` e `tests/test_product_importing.py`, que precisam do driver
(limitação registrada no `PROJECT_STATUS.md`, seção D). Os de `tests/integration/` não entram
nessa execução. Com as dependências instaladas, o comando abaixo roda todos os unitários:

```bash
PYTHONPATH=src python -m unittest discover -s tests -v
```

## Integração contínua

Três workflows, nenhum deles usa segredos:

- `.github/workflows/ci.yml`: `ruff check`, testes unitários, testes de integração contra um
  PostgreSQL 16 descartável do próprio job, verificação de fumaça da CLI, aplicação e
  reaplicação das migrações, a leitura do Stop All (`control status`, Lote 8) e um lote em
  simulação (`jobs reconcile` e `run-pipeline`, Lote 7), a cada `push` (alterações só em arquivos `.md` não disparam).
  A formatação é conferida com `ruff format --check` (incremento 4.3).
- `.github/workflows/secrets.yml`: varredura de segredos com Gitleaks (versão fixa, checksum
  conferido) em **todo** `push`, inclusive só de `.md`, e por acionamento manual, sobre o
  histórico completo da branch. O resultado esconde o valor encontrado (`--redact`).
- `.github/workflows/scheduler.yml` (agendador, Lote 9): roda um lote **em simulação**
  (`db migrate`, `control status` e `run-pipeline`, sem `--commit`) contra o PostgreSQL
  descartável do próprio job. Tem gatilho diário (09:17 UTC, sem garantia de horário),
  acionamento manual e uma validação quando o próprio arquivo muda. Execuções não se sobrepõem
  (`concurrency`) e têm limite de 10 minutos.
  - **Desabilitado por padrão**: o gatilho agendado só executa se a variável do repositório
    `AUTOPILOT_SCHEDULE_ENABLED` for `true` (*Settings → Secrets and variables → Actions →
    Variables*). Sem ela, a execução agendada aparece como ignorada e não consome minutos.
    Ligar a variável é decisão do responsável; o acionamento manual roda sempre.
  - **É um ensaio do agendamento**: com banco descartável, o lote agendado não enxerga dados
    reais e nada do que ele registra é guardado. Passa a ser útil quando houver banco
    hospedado, o que exige as credenciais e os controles da condição C3.
  - Nunca grava: `--commit`, segredos e o gatilho `pull_request` são proibidos nesse arquivo e
    conferidos por `tests/test_workflows.py`.

**O GitHub Actions não é ilimitado.** Em repositório privado há uma cota mensal de minutos que
depende do plano da conta (confirmar o valor atual na página oficial de cobrança do GitHub).
Por isso o workflow cancela execuções antigas da mesma branch e tem limite de 10 minutos.
Acompanhe o consumo em *Settings → Billing* da conta.

## Dados de demonstração

`data/seeds/products_demo.json` contém produtos **fictícios** para desenvolver sem depender da
API da Hotmart. Todo registro tem `is_test: true`, nome começando com `[TESTE]` e URL no domínio
reservado `example.invalid`. Campos desconhecidos ficam `null` e nunca viram zero.

## Segurança

- Nenhum segredo no código, nos logs ou nos commits. Os logs mascaram valores de variáveis
  sensíveis, cabeçalhos `Authorization` e credenciais em URLs.
- `.env` e arquivos de credenciais estão no `.gitignore`.
- Use autenticação em dois fatores no GitHub e em cada serviço futuro.
- Se suspeitar de vazamento de algum segredo, revogue e recrie a credencial imediatamente.

## Plano de desenvolvimento

O desenvolvimento segue em **lotes**; o estado verificado fica em `PROJECT_STATUS.md` e a
sequência das próximas etapas, com o que cada uma exige antes de começar, em
[PRODUCT_ROADMAP.md](PRODUCT_ROADMAP.md). Já existe:

| Lote | Entrega | Situação |
|---|---|---|
| Fundação | Configuração, logs, erros, CLI, dados de demonstração, CI | Na `main` |
| 1 a 3 (Product Intelligence) | Modelo de produto e importadores JSON e CSV | Na `main` (merge `c97017d`) |
| 4 | Gitleaks no CI (4.1), governança dos importadores (4.2), documentação (4.4); formatação no CI (4.3) adiada na época | Na `main` (merge `c97017d`) |
| 4.3 | `ruff format --check` no CI, com os quatro arquivos pendentes formatados (sem mudança de comportamento) | Na `main` (merge `69758d4`, PR #19) |
| 5.1 | Conexão PostgreSQL, migrador, esquema inicial (`0001_schema_v1.sql`) e testes de integração no CI | Na `main` (merge `bd62e83`) |
| 5.2 | Gravação de produtos idempotente, com histórico de preço e comissão (`product_snapshots`) | Na `main` (merge `bd62e83`) |
| 5.3 | Registro de execuções (`job_runs`), serviço de importação por arquivo e comando `autopilot products import` | Na `main` (merge `bd62e83`) |
| 6.1 | Pontuação de produtos como função pura (algoritmo `score-6.1`, configuração `v0-hipotese`), com as correções B1 a B5 da revisão técnica | Na `main` (merge `08e0ece`, PR #13) |
| 6.2a | Migração `0002_product_scores.sql`: configurações, notas e rankings só de inserção, com integridade garantida no banco | Na `main` (merge `08e0ece`, PR #13) |
| 6.2b | Serviço de pontuação com persistência (`run_scoring`) e leitura de rankings gravados | Na `main` (merge `08e0ece`, PR #13) |
| 6.2c | Validação de proveniência (6.2c-1) e comandos `autopilot products score` e `autopilot products ranking` (6.2c-2, que absorveu a 6.2c-3) | Na `main` (merge `cc34e2e`, PR #14) |
| 7 | Executor de lotes (`autopilot run-pipeline`) e reconciliação de execuções abandonadas (`autopilot jobs reconcile`, débito M2) | Na `main` (merge `5c07776`, PR #16) |
| 8 | Stop All (`autopilot control`, migração `0003_system_controls.sql`) e trilha de auditoria (`audit_log`) | Na `main` (merge `6ad5823`, PR #17) |
| 9 | Agendador: workflow `scheduler.yml` com o lote em simulação, `concurrency` e acionamento manual; desabilitado por padrão | Na `main` (merge `63bc07a`, PR #18); gatilho agendado desabilitado |

Ainda **não** existe (planejado, nenhuma parte implementada): o workflow autorizado da gravação
real da pontuação (condição C3), banco hospedado para o agendador, acionamento do Stop All pelo
celular, retenção de `job_runs`, conteúdo e aprovação, publicação
(o YouTube será o primeiro canal, em modo não público e com dry-run), vendas, tráfego,
relatórios, otimização e anúncios. O catálogo de blocos técnicos, com os critérios de conclusão
de cada um, está em `ARCHITECTURE.md`, seção 8; a ordem proposta e as decisões em aberto, em
`PRODUCT_ROADMAP.md`, seções 4 e 9.
