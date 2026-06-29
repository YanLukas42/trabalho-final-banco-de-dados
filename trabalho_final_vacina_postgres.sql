-- ============================================================
-- TRABALHO FINAL - BANCO DE DADOS
-- UFRJ - Escola de Engenharia / Departamento de Eletrônica
-- Prof. Sergio Palma  |  Tema: Sistema de Vacinação
-- Banco: PostgreSQL 16
-- ============================================================

-- ============================================================
-- ITEM 1: MODELO DE DADOS NA 3ª FORMA NORMAL (3FN)
-- Entidades: fabricante, vacina, lote, paciente, vacinador, vacinacao
-- 3FN garantida:
--   - Sem dependências parciais   (todas as colunas dependem da PK completa)
--   - Sem dependências transitivas (colunas dependem apenas da PK)
-- ============================================================

DROP TABLE IF EXISTS vacinacao           CASCADE;
DROP TABLE IF EXISTS estoque_vacina      CASCADE;
DROP TABLE IF EXISTS estoque_vacina_hist CASCADE;
DROP TABLE IF EXISTS lote                CASCADE;
DROP TABLE IF EXISTS vacina              CASCADE;
DROP TABLE IF EXISTS fabricante          CASCADE;
DROP TABLE IF EXISTS vacinador           CASCADE;
DROP TABLE IF EXISTS paciente            CASCADE;

-- ============================================================
-- CRIAÇÃO DAS TABELAS (DDL)
-- ============================================================

CREATE TABLE fabricante (
    id_fabricante  SERIAL        PRIMARY KEY,
    nome           VARCHAR(100)  NOT NULL,
    pais_origem    VARCHAR(50)   NOT NULL,
    cnpj           CHAR(18)      UNIQUE NOT NULL
);

-- NOTA: id_fabricante permite NULL para demonstrar FULL JOIN (item 13).
--       Vacina sem fabricante será inserida apenas antes do FULL JOIN,
--       para não interferir no NOT EXISTS (item 5).
CREATE TABLE vacina (
    id_vacina      SERIAL        PRIMARY KEY,
    nome           VARCHAR(100)  NOT NULL,
    tipo           VARCHAR(50)   NOT NULL,
    id_fabricante  INT           NULL,
    CONSTRAINT fk_vacina_fabricante FOREIGN KEY (id_fabricante)
        REFERENCES fabricante(id_fabricante)
);

CREATE TABLE lote (
    id_lote         SERIAL       PRIMARY KEY,
    codigo_lote     VARCHAR(20)  UNIQUE NOT NULL,
    id_vacina       INT          NOT NULL,
    data_fabricacao DATE         NOT NULL,
    data_validade   DATE         NOT NULL,
    quantidade      INT          NOT NULL,
    -- ITEM 12: CONSTRAINT CHECK – impede quantidade > 100
    CONSTRAINT ck_lote_quantidade CHECK (quantidade <= 100),
    CONSTRAINT fk_lote_vacina FOREIGN KEY (id_vacina)
        REFERENCES vacina(id_vacina)
);

CREATE TABLE paciente (
    id_paciente  SERIAL        PRIMARY KEY,
    nome         VARCHAR(100)  NOT NULL,
    cpf          CHAR(14)      UNIQUE NOT NULL,
    nascimento   DATE          NOT NULL,
    telefone     VARCHAR(15)   NULL
);

CREATE TABLE vacinador (
    id_vacinador  SERIAL        PRIMARY KEY,
    nome          VARCHAR(100)  NOT NULL,
    coren         VARCHAR(20)   UNIQUE NOT NULL,
    especialidade VARCHAR(50)   NOT NULL
);

CREATE TABLE vacinacao (
    id_vacinacao   SERIAL      PRIMARY KEY,
    id_paciente    INT         NOT NULL,
    id_lote        INT         NOT NULL,
    id_vacinador   INT         NOT NULL,
    data_vacinacao TIMESTAMP   NOT NULL DEFAULT NOW(),
    dose           SMALLINT    NOT NULL DEFAULT 1,
    CONSTRAINT fk_vac_paciente  FOREIGN KEY (id_paciente)  REFERENCES paciente(id_paciente),
    CONSTRAINT fk_vac_lote      FOREIGN KEY (id_lote)      REFERENCES lote(id_lote),
    CONSTRAINT fk_vac_vacinador FOREIGN KEY (id_vacinador) REFERENCES vacinador(id_vacinador)
);

-- ============================================================
-- ITEM 3: IMPORTAÇÃO DE DADOS (mínimo 5 ocorrências por tabela)
-- ============================================================

-- 6 fabricantes
INSERT INTO fabricante (nome, pais_origem, cnpj) VALUES
('Pfizer-BioNTech',    'EUA',         '60.396.060/0001-00'),
('Janssen',            'Bélgica',     '11.435.917/0001-00'),
('AstraZeneca',        'Reino Unido', '10.225.177/0001-00'),
('Sinovac (Butantan)', 'China',       '61.148.461/0001-00'),
('Moderna',            'EUA',         '05.846.180/0001-00'),
('Fiocruz',            'Brasil',      '33.781.055/0001-00');

-- 6 vacinas – TODAS com fabricante vinculado neste momento.
-- [CORREÇÃO BUG 1]: vacina 6 agora pertence ao Fiocruz (id=6).
-- A vacina com id_fabricante=NULL (para FULL JOIN) é inserida separadamente no item 13.
INSERT INTO vacina (nome, tipo, id_fabricante) VALUES
('Comirnaty',             'mRNA',             1),  -- Pfizer
('Janssen COVID-19',      'Vetor Viral',      2),  -- Janssen
('Vaxzevria',             'Vetor Viral',      3),  -- AstraZeneca
('CoronaVac',             'Viral Inativada',  4),  -- Sinovac
('Spikevax',              'mRNA',             5),  -- Moderna
('Vacina Fiocruz/Butantan','Viral Inativada', 6);  -- Fiocruz

-- 7 lotes (3 vencidos, 2 vencendo em breve, 2 válidos)
INSERT INTO lote (codigo_lote, id_vacina, data_fabricacao, data_validade, quantidade) VALUES
('LOT-PFZ-001', 1, '2023-01-10', '2023-06-10',                         80),  -- vencido >30d
('LOT-PFZ-002', 1, '2024-05-01', '2025-01-01',                         60),  -- vencido >30d
('LOT-JNS-001', 2, '2023-03-15', '2023-09-15',                         50),  -- vencido >30d
('LOT-AZ-001',  3, '2024-06-01', CURRENT_DATE + INTERVAL '20 days',    90),  -- vence em 20d
('LOT-SIN-001', 4, '2024-04-20', CURRENT_DATE + INTERVAL '25 days',    70),  -- vence em 25d
('LOT-MOD-001', 5, '2024-07-01', CURRENT_DATE + INTERVAL '180 days',   40),  -- válido
('LOT-FIO-001', 6, '2024-08-01', CURRENT_DATE + INTERVAL '365 days',  100);  -- válido

-- 6 pacientes
INSERT INTO paciente (nome, cpf, nascimento, telefone) VALUES
('Ana Lima',       '111.111.111-11', '1985-03-20', '21-91111-1111'),
('Bruno Souza',    '222.222.222-22', '1990-07-14', '21-92222-2222'),
('Carla Mendes',   '333.333.333-33', '1978-11-05', '21-93333-3333'),
('Diego Ferreira', '444.444.444-44', '2000-01-30', '21-94444-4444'),
('Elisa Castro',   '555.555.555-55', '1995-09-18', '21-95555-5555'),
('Felipe Rocha',   '666.666.666-66', '1988-06-22', '21-96666-6666');

-- 5 vacinadores
INSERT INTO vacinador (nome, coren, especialidade) VALUES
('Dra. Maria Oliveira', 'COREN-RJ-123456', 'Enfermagem'),
('Dr. João Pedro',      'COREN-RJ-234567', 'Técnico de Enfermagem'),
('Enf. Paula Santos',   'COREN-RJ-345678', 'Enfermagem'),
('Tec. Carlos Ramos',   'COREN-RJ-456789', 'Técnico de Enfermagem'),
('Enf. Rita Nunes',     'COREN-RJ-567890', 'Enfermagem');

-- [CORREÇÃO BUG 1]: Ana Lima agora tem vacinação dos 6 fabricantes (lotes 1,3,4,5,6,7)
INSERT INTO vacinacao (id_paciente, id_lote, id_vacinador, data_vacinacao, dose) VALUES
-- Ana Lima: cobre TODOS os 6 fabricantes
(1, 1, 1, '2022-01-10', 1),  -- Pfizer (lote 1)
(1, 3, 2, '2022-01-10', 1),  -- Janssen (lote 3)
(1, 4, 3, '2022-02-01', 1),  -- AstraZeneca (lote 4)
(1, 5, 1, '2022-02-15', 1),  -- Sinovac (lote 5)
(1, 6, 4, '2022-03-01', 1),  -- Moderna (lote 6)
(1, 7, 5, '2022-03-20', 1),  -- Fiocruz (lote 7) ← adicionado
-- Demais pacientes (parcial):
(2, 2, 2, '2022-01-20', 1),
(2, 4, 5, '2022-02-20', 1),
(3, 1, 3, '2022-01-25', 1),
(4, 5, 4, '2022-02-10', 1),
(5, 6, 1, '2022-03-05', 1),
(6, 2, 5, '2022-01-30', 1),
(3, 4, 2, '2022-04-01', 2);

-- ITEM 3: EXPORTAÇÃO DE DADOS
-- COPY server-side exige superusuário no PostgreSQL.
-- Para exportar os dados, execute os comandos abaixo via psql (\COPY é client-side):
-- \COPY fabricante TO '/caminho/export_fabricante.csv' WITH (FORMAT CSV, HEADER)
-- \COPY vacina     TO '/caminho/export_vacina.csv'     WITH (FORMAT CSV, HEADER)
-- \COPY lote       TO '/caminho/export_lote.csv'       WITH (FORMAT CSV, HEADER)
-- \COPY paciente   TO '/caminho/export_paciente.csv'   WITH (FORMAT CSV, HEADER)
-- \COPY vacinador  TO '/caminho/export_vacinador.csv'  WITH (FORMAT CSV, HEADER)
-- \COPY vacinacao  TO '/caminho/export_vacinacao.csv'  WITH (FORMAT CSV, HEADER)
--
-- Ou use o script export.sh na raiz do projeto.

-- ============================================================
-- ITEM 4: LISTAR TABELAS COM NOMES E CARDINALIDADES
-- ============================================================
SELECT tabela, cardinalidade FROM (
    SELECT 'fabricante' AS tabela, COUNT(*) AS cardinalidade FROM fabricante UNION ALL
    SELECT 'vacina',               COUNT(*)                  FROM vacina      UNION ALL
    SELECT 'lote',                 COUNT(*)                  FROM lote        UNION ALL
    SELECT 'paciente',             COUNT(*)                  FROM paciente    UNION ALL
    SELECT 'vacinador',            COUNT(*)                  FROM vacinador   UNION ALL
    SELECT 'vacinacao',            COUNT(*)                  FROM vacinacao
) t ORDER BY tabela;

-- ============================================================
-- ITEM 5: SUB-SELECT COM NOT EXISTS
-- Listar Pacientes que tomaram vacina de TODOS os fabricantes.
-- Requer ao menos 1 resultado (Ana Lima cobre os 6 fabricantes).
-- ============================================================
-- [CORREÇÃO BUG 1]: com vacina 6 vinculada ao Fiocruz e vacinação da Ana Lima
-- no lote 7, a query agora retorna corretamente "Ana Lima".
-- [CORREÇÃO]: a subquery de fabricantes filtra apenas aqueles que possuem
-- pelo menos uma vacina cadastrada, evitando que fabricantes sem vacinas
-- (ex: BioFarma Test, inserido no item 13) invalidem o resultado.
SELECT p.nome AS "Paciente vacinado por todos os fabricantes"
FROM paciente p
WHERE NOT EXISTS (
    -- Existe algum fabricante COM vacina para o qual este paciente NÃO tem vacinação?
    SELECT 1 FROM fabricante f
    WHERE EXISTS (
        SELECT 1 FROM vacina va2 WHERE va2.id_fabricante = f.id_fabricante
    )
    AND NOT EXISTS (
        SELECT 1
        FROM vacinacao vc
        INNER JOIN lote   l  ON vc.id_lote    = l.id_lote
        INNER JOIN vacina va ON l.id_vacina   = va.id_vacina
        WHERE va.id_fabricante = f.id_fabricante
          AND vc.id_paciente   = p.id_paciente
    )
);

-- ============================================================
-- ITEM 6: TRANSAÇÕES — COMMIT e ROLLBACK
-- ============================================================

-- Cenário A: UPDATE com COMMIT → dado persiste
BEGIN;
    UPDATE paciente SET telefone = '21-99999-0001' WHERE id_paciente = 1;
COMMIT;
-- Confirma persistência após COMMIT:
SELECT id_paciente, nome, telefone FROM paciente WHERE id_paciente = 1;

-- Cenário B: UPDATE com ROLLBACK → dado volta ao original
BEGIN;
    UPDATE paciente SET nome = 'NOME ALTERADO - ROLLBACK TESTE' WHERE id_paciente = 2;
    -- Estado durante a transação (antes do rollback):
    SELECT id_paciente, nome FROM paciente WHERE id_paciente = 2;
ROLLBACK;
-- Confirma que o nome voltou ao original após ROLLBACK:
SELECT id_paciente, nome FROM paciente WHERE id_paciente = 2;

-- ============================================================
-- ITEM 7: SUPORTE A CHAVE ESTRANGEIRA
-- Demonstrar erro ao inserir Vacina com Fabricante inexistente
-- ============================================================
DO $$
BEGIN
    INSERT INTO vacina (nome, tipo, id_fabricante)
    VALUES ('Vacina Fantasma', 'Desconhecido', 9999);  -- id 9999 não existe
    RAISE NOTICE 'Inserção bem-sucedida (ERRO: não deveria ocorrer)';
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'ERRO DE CHAVE ESTRANGEIRA CAPTURADO: %', SQLERRM;
END;
$$;

-- ============================================================
-- ITEM 8: VIEW — Todos os Lotes com data vencida
-- ============================================================
CREATE OR REPLACE VIEW vw_lotes_vencidos AS
    SELECT
        l.id_lote,
        l.codigo_lote,
        va.nome                          AS vacina,
        COALESCE(f.nome, 'Sem Fab.')     AS fabricante,
        l.data_validade,
        l.quantidade,
        (CURRENT_DATE - l.data_validade) AS dias_vencido
    FROM lote l
    INNER JOIN vacina     va ON l.id_vacina      = va.id_vacina
    LEFT  JOIN fabricante f  ON va.id_fabricante = f.id_fabricante
    WHERE l.data_validade < CURRENT_DATE;

-- Demonstração da VIEW:
SELECT * FROM vw_lotes_vencidos;

-- ============================================================
-- ITEM 9: STORED PROCEDURE
-- Pacientes que tomaram Vacina Vencida, com Fabricante e Lote.
-- NOTA: PostgreSQL usa FUNCTION (retorna TABLE) no lugar de PROCEDURE
-- quando há retorno de conjunto de dados. CREATE PROCEDURE existe no
-- PG 11+, mas não suporta RETURNS TABLE — por isso usamos FUNCTION.
-- ============================================================
CREATE OR REPLACE FUNCTION sp_pacientes_vacina_vencida()
RETURNS TABLE (
    paciente       TEXT,
    vacina         TEXT,
    fabricante     TEXT,
    codigo_lote    TEXT,
    data_validade  DATE,
    data_vacinacao TIMESTAMP
) LANGUAGE sql AS $$
    SELECT
        p.nome,
        va.nome,
        COALESCE(f.nome, 'Sem Fabricante'),
        l.codigo_lote,
        l.data_validade,
        vc.data_vacinacao
    FROM vacinacao vc
    INNER JOIN paciente   p  ON vc.id_paciente  = p.id_paciente
    INNER JOIN lote       l  ON vc.id_lote       = l.id_lote
    INNER JOIN vacina     va ON l.id_vacina       = va.id_vacina
    LEFT  JOIN fabricante f  ON va.id_fabricante  = f.id_fabricante
    WHERE l.data_validade < CURRENT_DATE
    ORDER BY p.nome;
$$;

-- Demonstração:
SELECT * FROM sp_pacientes_vacina_vencida();

-- ============================================================
-- ITEM 10: TRIGGER
-- Atualizar data_vacinacao toda vez que houver inclusão de Vacinação
-- ============================================================
CREATE OR REPLACE FUNCTION fn_atualiza_data_vacinacao()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.data_vacinacao := NOW();
    RAISE NOTICE 'Trigger disparado: data_vacinacao atualizada para %', NEW.data_vacinacao;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_atualiza_data_vacinacao ON vacinacao;
CREATE TRIGGER trg_atualiza_data_vacinacao
BEFORE INSERT ON vacinacao
FOR EACH ROW EXECUTE FUNCTION fn_atualiza_data_vacinacao();

-- Demonstração: passamos data '2020-01-01', trigger substitui por NOW()
INSERT INTO vacinacao (id_paciente, id_lote, id_vacinador, data_vacinacao, dose)
VALUES (4, 7, 3, '2020-01-01 00:00:00', 2);

SELECT id_vacinacao, data_vacinacao,
       '(data 2020 foi substituída pelo trigger)' AS observacao
FROM vacinacao ORDER BY id_vacinacao DESC LIMIT 1;

-- ============================================================
-- ITEM 11: UNIONS
-- Lotes com vencimento nos próximos 30 dias
-- UNION
-- Lotes vencidos há até 30 dias
-- [CORREÇÃO BUG 5]: > CURRENT_DATE (não >=) para não incluir lotes vencendo hoje
-- ============================================================
SELECT codigo_lote, data_validade, 'Vence em 30 dias'   AS status_lote
FROM lote
WHERE data_validade > CURRENT_DATE
  AND data_validade <= CURRENT_DATE + INTERVAL '30 days'

UNION

SELECT codigo_lote, data_validade, 'Vencido há 30 dias' AS status_lote
FROM lote
WHERE data_validade < CURRENT_DATE
  AND data_validade >= CURRENT_DATE - INTERVAL '30 days'

ORDER BY data_validade;

-- ============================================================
-- ITEM 12: CONSTRAINT CHECK
-- Impedir Lotes cuja Quantidade seja maior que 100 — mostrar violação
-- ============================================================
DO $$
BEGIN
    INSERT INTO lote (codigo_lote, id_vacina, data_fabricacao, data_validade, quantidade)
    VALUES ('LOT-ERRO-001', 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 year', 150);
    RAISE NOTICE 'Inserção bem-sucedida (ERRO: não deveria ocorrer)';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'ERRO DE CONSTRAINT CHECK capturado: %', SQLERRM;
END;
$$;

-- Confirma que o lote inválido NÃO foi inserido:
SELECT COUNT(*) AS "Lotes com codigo LOT-ERRO-001 (deve ser 0)"
FROM lote WHERE codigo_lote = 'LOT-ERRO-001';

-- ============================================================
-- ITEM 13: FULL JOIN
-- Unir Fabricante e Vacina garantindo NULL nos dois lados
-- ============================================================

-- Lado 1: Fabricante sem vacina (NULL no lado da Vacina)
INSERT INTO fabricante (nome, pais_origem, cnpj)
VALUES ('BioFarma Test', 'Brasil', '99.999.999/0001-99');

-- Lado 2: Vacina sem fabricante (NULL no lado do Fabricante)
-- [NOTA]: inserida AQUI, após o NOT EXISTS (item 5), para não interferir naquele resultado
INSERT INTO vacina (nome, tipo, id_fabricante)
VALUES ('VacSem Fabricante', 'Experimental', NULL);

-- FULL JOIN: mostra todos os pares, com NULLs em ambos os lados
SELECT
    f.id_fabricante,
    f.nome   AS fabricante,
    va.id_vacina,
    va.nome  AS vacina,
    va.tipo
FROM fabricante f
FULL JOIN vacina va ON f.id_fabricante = va.id_fabricante
ORDER BY f.id_fabricante NULLS LAST, va.id_vacina NULLS LAST;

-- ============================================================
-- ITEM 14: TABELA TEMPORÁRIA
-- [CORREÇÃO BUG 3]: PostgreSQL não possui Tabela Temporária Global (##Tabela
-- do SQL Server). O equivalente mais próximo é a TEMP TABLE de sessão:
-- visível para toda a conexão atual, destruída ao encerrar a sessão.
-- Em ambientes multi-sessão, a alternativa é uma tabela UNLOGGED permanente.
-- ============================================================
CREATE TEMP TABLE temp_fabricantes AS
    SELECT * FROM fabricante;

-- Verifica que a tabela temporária existe no catálogo (pg_class)
SELECT relname AS tabela_temporaria, relpersistence
FROM pg_class
WHERE relname = 'temp_fabricantes';
-- relpersistence = 't' significa TEMP (temporária)

-- Demonstração de uso:
SELECT * FROM temp_fabricantes;

-- ============================================================
-- ITEM 15A: CURSOR 1
-- Saída com Data, Pacientes, Lotes e Fabricantes
-- ============================================================
DO $$
DECLARE
    cur CURSOR FOR
        SELECT
            TO_CHAR(vc.data_vacinacao, 'DD/MM/YYYY') AS dt,
            p.nome                                    AS paciente,
            l.codigo_lote,
            COALESCE(f.nome, 'Sem Fabricante')        AS fabricante
        FROM vacinacao vc
        INNER JOIN paciente   p  ON vc.id_paciente  = p.id_paciente
        INNER JOIN lote       l  ON vc.id_lote       = l.id_lote
        INNER JOIN vacina     va ON l.id_vacina       = va.id_vacina
        LEFT  JOIN fabricante f  ON va.id_fabricante  = f.id_fabricante
        ORDER BY vc.data_vacinacao;
    r RECORD;
BEGIN
    RAISE NOTICE '--- RELATÓRIO DE VACINAÇÕES ---';
    RAISE NOTICE '%', REPEAT('-', 65);
    OPEN cur;
    LOOP
        FETCH cur INTO r;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Data: % | Paciente: % | Lote: % | Fabricante: %',
            r.dt, r.paciente, r.codigo_lote, r.fabricante;
    END LOOP;
    CLOSE cur;
END;
$$;

-- ============================================================
-- ITEM 15B: CURSOR 2
-- Listar Vacinadores que tomaram vacina, mostrando tipo,
-- fabricante e data de validade da vacina
-- ============================================================

-- Inserir vacinador como paciente (mesmo nome) para o cenário funcionar
INSERT INTO paciente (nome, cpf, nascimento, telefone)
VALUES ('Dra. Maria Oliveira', '777.777.777-77', '1980-05-10', '21-97777-7777');

-- Vacinação da "Dra. Maria Oliveira" como paciente (id_paciente=7), aplicada por ela mesma (id_vacinador=1)
-- Isso garante que p.nome = vd.nome seja verdadeiro no cursor
INSERT INTO vacinacao (id_paciente, id_lote, id_vacinador, data_vacinacao, dose)
VALUES (7, 5, 1, NOW(), 1);

DO $$
DECLARE
    cur CURSOR FOR
        SELECT
            vd.nome                                AS vacinador,
            va.tipo                                AS tipo_vacina,
            COALESCE(f.nome, 'Sem Fabricante')     AS fabricante,
            TO_CHAR(l.data_validade, 'DD/MM/YYYY') AS validade
        FROM vacinacao vc
        INNER JOIN paciente   p  ON vc.id_paciente  = p.id_paciente
        INNER JOIN vacinador  vd ON vc.id_vacinador  = vd.id_vacinador
        INNER JOIN lote       l  ON vc.id_lote       = l.id_lote
        INNER JOIN vacina     va ON l.id_vacina      = va.id_vacina
        LEFT  JOIN fabricante f  ON va.id_fabricante = f.id_fabricante
        WHERE p.nome = vd.nome   -- vacinador que também é paciente (mesmo nome)
        ORDER BY vd.nome;
    r RECORD;
BEGIN
    RAISE NOTICE '--- VACINADORES QUE TAMBÉM TOMARAM VACINA ---';
    RAISE NOTICE '%', REPEAT('-', 65);
    OPEN cur;
    LOOP
        FETCH cur INTO r;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Vacinador: % | Tipo: % | Fabricante: % | Validade: %',
            r.vacinador, r.tipo_vacina, r.fabricante, r.validade;
    END LOOP;
    CLOSE cur;
END;
$$;

-- ============================================================
-- ITEM 16: TABELA TEMPORAL
-- Criar tabela temporal, alimentar em tempos diferentes,
-- consultar por intervalo de tempo.
-- PostgreSQL não possui FOR SYSTEM_TIME nativamente (recurso do SQL Server).
-- Implementamos o padrão equivalente: history table + trigger BEFORE UPDATE.
-- ============================================================

CREATE TABLE estoque_vacina (
    id_estoque  SERIAL     PRIMARY KEY,
    id_vacina   INT        NOT NULL REFERENCES vacina(id_vacina),
    quantidade  INT        NOT NULL,
    valid_from  TIMESTAMP  NOT NULL DEFAULT NOW()
);

CREATE TABLE estoque_vacina_hist (
    id_hist     SERIAL     PRIMARY KEY,
    id_estoque  INT        NOT NULL,
    id_vacina   INT        NOT NULL,
    quantidade  INT        NOT NULL,
    valid_from  TIMESTAMP  NOT NULL,
    valid_to    TIMESTAMP  NOT NULL
);

-- Trigger: move versão antiga para histórico a cada UPDATE
CREATE OR REPLACE FUNCTION fn_hist_estoque()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO estoque_vacina_hist
        (id_estoque, id_vacina, quantidade, valid_from, valid_to)
    VALUES
        (OLD.id_estoque, OLD.id_vacina, OLD.quantidade, OLD.valid_from, NOW());
    NEW.valid_from := NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_hist_estoque ON estoque_vacina;
CREATE TRIGGER trg_hist_estoque
BEFORE UPDATE ON estoque_vacina
FOR EACH ROW EXECUTE FUNCTION fn_hist_estoque();

-- Alimentar dados (T1)
INSERT INTO estoque_vacina (id_vacina, quantidade) VALUES (1, 80), (2, 50);

-- [CORREÇÃO BUG 4]: capturamos o timestamp de início para usar no filtro final,
-- garantindo que o intervalo seja sempre relativo ao início do bloco.
DO $$
DECLARE
    v_inicio TIMESTAMP := NOW();
BEGIN
    -- Gravar o timestamp de início para uso posterior
    CREATE TEMP TABLE IF NOT EXISTS _ts_inicio (ts TIMESTAMP);
    DELETE FROM _ts_inicio;
    INSERT INTO _ts_inicio VALUES (v_inicio);

    -- T2: atualizar após 1 segundo
    PERFORM pg_sleep(1);
    UPDATE estoque_vacina SET quantidade = 60 WHERE id_vacina = 1;
    UPDATE estoque_vacina SET quantidade = 30 WHERE id_vacina = 2;

    -- T3: atualizar após mais 1 segundo
    PERFORM pg_sleep(1);
    UPDATE estoque_vacina SET quantidade = 45 WHERE id_vacina = 1;
END;
$$;

-- Estado atual (versão mais recente de cada registro)
SELECT ev.id_estoque, va.nome AS vacina, ev.quantidade,
       ev.valid_from AS vigente_desde
FROM estoque_vacina ev
INNER JOIN vacina va ON ev.id_vacina = va.id_vacina;

-- Histórico completo (equivalente a FOR SYSTEM_TIME ALL)
SELECT 'historico' AS origem, h.id_estoque, va.nome AS vacina,
       h.quantidade, h.valid_from, h.valid_to
FROM estoque_vacina_hist h
INNER JOIN vacina va ON h.id_vacina = va.id_vacina

UNION ALL

SELECT 'atual', ev.id_estoque, va.nome,
       ev.quantidade, ev.valid_from, NULL::TIMESTAMP
FROM estoque_vacina ev
INNER JOIN vacina va ON ev.id_vacina = va.id_vacina

ORDER BY id_estoque, valid_from;

-- Filtrar por intervalo de tempo (a partir do início do bloco acima)
SELECT h.id_estoque, va.nome AS vacina, h.quantidade,
       h.valid_from, h.valid_to
FROM estoque_vacina_hist h
INNER JOIN vacina va ON h.id_vacina = va.id_vacina
WHERE h.valid_from >= (SELECT ts FROM _ts_inicio)
ORDER BY h.valid_from;

-- ============================================================
-- FIM DO TRABALHO FINAL — PostgreSQL 16
-- ============================================================
