# 💉 Trabalho Final — Banco de Dados
**UFRJ · Escola de Engenharia · Departamento de Eletrônica**  
**Disciplina:** Banco de Dados · **Professor:** Sergio Palma  
**Tema:** Sistema de Vacinação · **Banco:** PostgreSQL 16

---

## 📋 Itens Implementados

| # | Item | Descrição |
|---|------|-----------|
| 1 | Modelo na 3FN | 6 tabelas normalizadas sem dependências parciais ou transitivas |
| 2 | Diagrama ER | Gerado visualmente pelo pgAdmin (instruções abaixo) |
| 3 | Carga de Dados | 6+ registros por tabela via `INSERT INTO` |
| 4 | Cardinalidades | `SELECT COUNT(*)` com `UNION ALL` por tabela |
| 5 | NOT EXISTS | Pacientes que vacinaram com **todos** os fabricantes |
| 6 | Transações | `BEGIN/COMMIT` com persistência + `ROLLBACK` desfazendo |
| 7 | Chave Estrangeira | Erro capturado ao inserir vacina com fabricante inexistente |
| 8 | View | `vw_lotes_vencidos` com dias vencido calculados |
| 9 | Stored Procedure | `sp_pacientes_vacina_vencida()` — vacinas vencidas por paciente |
| 10 | Trigger | `trg_atualiza_data_vacinacao` — força `NOW()` em todo `INSERT` |
| 11 | Union | Lotes vencendo em 30 dias **UNION** vencidos há 30 dias |
| 12 | Constraint CHECK | `quantidade <= 100` com demonstração de violação |
| 13 | Full Join | `fabricante FULL JOIN vacina` com NULLs nos dois lados |
| 14 | Tabela Temporária | `TEMP TABLE temp_fabricantes` (sessão) |
| 15A | Cursor 1 | Relatório: Data / Paciente / Lote / Fabricante |
| 15B | Cursor 2 | Vacinadores que também são pacientes vacinados |
| 16 | Tabela Temporal | `estoque_vacina` + `estoque_vacina_hist` + trigger de histórico |

---

## 🗂️ Modelo de Dados (3FN)

```
fabricante ──< vacina ──< lote ──< vacinacao >── paciente
                                         \──────> vacinador
```

| Tabela | Descrição |
|--------|-----------|
| `fabricante` | Fabricantes das vacinas |
| `vacina` | Vacinas disponíveis por fabricante |
| `lote` | Lotes de vacina com validade e quantidade |
| `paciente` | Pacientes vacinados |
| `vacinador` | Profissionais que aplicam as vacinas |
| `vacinacao` | Registro de cada aplicação |
| `estoque_vacina` | Estoque atual (tabela temporal) |
| `estoque_vacina_hist` | Histórico automático via trigger |

---

## 🐳 Rodando com Docker

### Pré-requisitos
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Subir o ambiente

```bash
# Clonar o repositório
git clone https://github.com/YanLukas42/trabalho-final-banco-de-dados.git
cd trabalho-final-banco-de-dados

# Subir PostgreSQL + pgAdmin
docker compose up -d

# Verificar se está rodando
docker compose ps
```

O script SQL é executado **automaticamente** na primeira inicialização do container.

### Parar o ambiente

```bash
docker compose down         # para e remove containers (dados persistem)
docker compose down -v      # para, remove containers E apaga dados
```

---

## 🖥️ Acessos

| Serviço | URL / Host | Usuário | Senha |
|---------|-----------|---------|-------|
| **PostgreSQL** | `localhost:5432` | `vacina_user` | `vacina_pass` |
| **pgAdmin 4** | http://localhost:8080 | `admin@vacina.com` | `admin123` |
| **Banco** | `vacinadb` | — | — |

### Conectar via psql (linha de comando)

```bash
# Dentro do container
docker exec -it vacina_db psql -U vacina_user -d vacinadb

# Ou diretamente do host (com psql instalado)
psql -h localhost -p 5432 -U vacina_user -d vacinadb
```

### Gerar Diagrama ER no pgAdmin
1. Abra http://localhost:8080
2. Faça login com `admin@vacina.com` / `admin123`
3. Registre o servidor: host `postgres`, porta `5432`, usuário `vacina_user`
4. Clique com botão direito no banco `vacinadb` → **ERD for Database**

---

## 📁 Estrutura dos Arquivos

```
.
├── docker-compose.yml                   # Ambiente Docker (PostgreSQL + pgAdmin)
├── trabalho_final_vacina_postgres.sql   # Script PostgreSQL completo (todos os itens)
├── trabalho_final_vacina.sql            # Versão original SQL Server (referência)
└── README.md
```

---

## ⚠️ Notas sobre adaptações SQL Server → PostgreSQL

| SQL Server | PostgreSQL |
|-----------|-----------|
| `IDENTITY(1,1)` | `SERIAL` ou `GENERATED ALWAYS AS IDENTITY` |
| `GETDATE()` | `NOW()` / `CURRENT_TIMESTAMP` |
| `DATEADD(DAY, n, d)` | `d + INTERVAL 'n days'` |
| `ISNULL(x, y)` | `COALESCE(x, y)` |
| `REPLICATE(s, n)` | `REPEAT(s, n)` |
| `CONVERT(VARCHAR, d, 103)` | `TO_CHAR(d, 'DD/MM/YYYY')` |
| `BEGIN TRY/CATCH` | `BEGIN/EXCEPTION` (bloco `DO $$`) |
| `PRINT` | `RAISE NOTICE` |
| `WAITFOR DELAY` | `PERFORM pg_sleep(n)` (em PL/pgSQL) |
| `##GlobalTemp` | `CREATE TEMP TABLE` (escopo de sessão) |
| `FOR SYSTEM_TIME ALL` | History table + trigger (simulação) |
| Stored Procedure | `CREATE OR REPLACE FUNCTION` |
