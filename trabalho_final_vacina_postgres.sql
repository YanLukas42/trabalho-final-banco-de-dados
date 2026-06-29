-- ============================================================
-- TRABALHO FINAL - BANCO DE DADOS
-- UFRJ - Escola de Engenharia / Departamento de Eletrônica
-- Prof. Sergio Palma  |  Tema: Sistema de Vacinação
-- Banco: PostgreSQL 16
-- ============================================================

-- ============================================================
-- ITEM 1: MODELO DE DADOS NA 3FN
-- Entidades: fabricante, vacina, lote, paciente, vacinador, vacinacao
-- 3FN: sem dependências parciais nem transitivas
-- ============================================================

DROP TABLE IF EXISTS vacinacao              CASCADE;
DROP TABLE IF EXISTS estoque_vacina         CASCADE;
DROP TABLE IF EXISTS estoque_vacina_hist    CASCADE;
DROP TABLE IF EXISTS lote                   CASCADE;
DROP TABLE IF EXISTS vacina                 CASCADE;
DROP TABLE IF EXISTS fabricante             CASCADE;
DROP TABLE IF EXISTS vacinador              CASCADE;
DROP TABLE IF EXISTS paciente               CASCADE;

-- ============================================================
-- CRIAÇÃO DAS TABELAS (DDL)
-- ============================================================

CREATE TABLE fabricante (
    id_fabricante  SERIAL        PRIMARY KEY,
    nome           VARCHAR(100)  NOT NULL,
    pais_origem    VARCHAR(50)   NOT NULL,
    cnpj           CHAR(18)      UNIQUE NOT NULL
);

CREATE TABLE vacina (
    id_vacina      SERIAL        PRIMARY KEY,
    nome           VARCHAR(100)  NOT NULL,
    tipo           VARCHAR(50)   NOT NULL,
    id_fabricante  INT           NULL,  -- NULL para FULL JOIN com NULLs
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
    -- ITEM 12: CONSTRAINT CHECK
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
-- ITEM 3: CARGA DE DADOS (mínimo 5 ocorrências por tabela)
-- ============================================================

INSERT INTO fabricante (nome, pais_origem, cnpj) VALUES
('Pfizer-BioNTech',    'EUA',         '60.396.060/0001-00'),
('Janssen',            'Bélgica',     '11.435.917/0001-00'),
('AstraZeneca',        'Reino Unido', '10.225.177/0001-00'),
('Sinovac (Butantan)', 'China',       '61.148.461/0001-00'),
('Moderna',            'EUA',         '05.846.180/0001-00'),
('Fiocruz',            'Brasil',      '33.781.055/0001-00');

INSERT INTO vacina (nome, tipo, id_fabricante) VALUES
('Comirnaty',          'mRNA',             1),
('Janssen COVID-19',   'Vetor Viral',      2),
('Vaxzevria',          'Vetor Viral',      3),
('CoronaVac',          'Viral Inativada',  4),
('Spikevax',           'mRNA',             5),
('VacSem Fabricante',  'Experimental',     NULL); -- sem fabricante (para FULL JOIN)

INSERT INTO lote (codigo_lote, id_vacina, data_fabricacao, data_validade, quantidade) VALUES
('LOT-PFZ-001', 1, '2023-01-10', '2023-06-10',                         80),  -- vencido
('LOT-PFZ-002', 1, '2024-05-01', '2025-01-01',                         60),  -- vencido
('LOT-JNS-001', 2, '2023-03-15', '2023-09-15',                         50),  -- vencido
('LOT-AZ-001',  3, '2024-06-01', CURRENT_DATE + INTERVAL '20 days',    90),  -- vence em 20 dias
('LOT-SIN-001', 4, '2024-04-20', CURRENT_DATE + INTERVAL '25 days',    70),  -- vence em 25 dias
('LOT-MOD-001', 5, '2024-07-01', CURRENT_DATE + INTERVAL '180 days',   40),  -- válido
('LOT-FIO-001', 6, '2024-08-01', CURRENT_DATE + INTERVAL '365 days',  100);  -- válido

INSERT INTO paciente (nome, cpf, nascimento, telefone) VALUES
('Ana Lima',       '111.111.111-11', '1985-03-20', '21-91111-1111'),
('Bruno Souza',    '222.222.222-22', '1990-07-14', '21-92222-2222'),
('Carla Mendes',   '333.333.333-33', '1978-11-05', '21-93333-3333'),
('Diego Ferreira', '444.444.444-44', '2000-01-30', '21-94444-4444'),
('Elisa Castro',   '555.555.555-55', '1995-09-18', '21-95555-5555'),
('Felipe Rocha',   '666.666.666-66', '1988-06-22', '21-96666-6666');

INSERT INTO vacinador (nome, coren, especialidade) VALUES
('Dra. Maria Oliveira', 'COREN-RJ-123456', 'Enfermagem'),
('Dr. João Pedro',      'COREN-RJ-234567', 'Técnico de Enfermagem'),
('Enf. Paula Santos',   'COREN-RJ-345678', 'Enfermagem'),
('Tec. Carlos Ramos',   'COREN-RJ-456789', 'Técnico de Enfermagem'),
('Enf. Rita Nunes',     'COREN-RJ-567890', 'Enfermagem');

-- Ana Lima tomou vacinas de TODOS os 5 fabricantes (para NOT EXISTS)
INSERT INTO vacinacao (id_paciente, id_lote, id_vacinador, data_vacinacao, dose) VALUES
(1, 1, 1, '2022-01-10', 1),
(1, 3, 2, '2022-01-10', 1),
(1, 4, 3, '2022-02-01', 1),
(1, 5, 1, '2022-02-15', 1),
(1, 6, 4, '2022-03-01', 1),
(2, 2, 2, '2022-01-20', 1),
(2, 4, 5, '2022-02-20', 1),
(3, 1, 3, '2022-01-25', 1),
(4, 5, 4, '2022-02-10', 1),
(5, 6, 1, '2022-03-05', 1),
(6, 2, 5, '2022-01-30', 1),
(3, 4, 2, '2022-04-01', 2);

-- ============================================================
-- ITEM 4: LISTAR TABELAS COM CARDINALIDADES
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
-- Pacientes que tomaram vacina de TODOS os fabricantes
-- ============================================================
SELECT p.nome AS paciente
FROM paciente p
WHERE NOT EXISTS (
    SELECT 1 FROM fabricante f
    WHERE NOT EXISTS (
        SELECT 1
        FROM vacinacao vc
        INNER JOIN lote    l  ON vc.id_lote       = l.id_lote
        INNER JOIN vacina  va ON l.id_vacina       = va.id_vacina
        WHERE va.id_fabricante = f.id_fabricante
          AND vc.id_paciente   = p.id_paciente
    )
);

-- ============================================================
-- ITEM 6: TRANSAÇÕES - COMMIT e ROLLBACK
-- ============================================================

-- Cenário A: COMMIT (persistência)
BEGIN;
    UPDATE paciente SET telefone = '21-99999-0001' WHERE id_paciente = 1;
COMMIT;
SELECT id_paciente, nome, telefone FROM paciente WHERE id_paciente = 1;

-- Cenário B: ROLLBACK (desfaz alterações)
BEGIN;
    UPDATE paciente SET nome = 'NOME ALTERADO - ROLLBACK TESTE' WHERE id_paciente = 2;
    -- Antes do rollback:
    SELECT id_paciente, nome FROM paciente WHERE id_paciente = 2;
ROLLBACK;
-- Após rollback (nome original restaurado):
SELECT id_paciente, nome FROM paciente WHERE id_paciente = 2;

-- ============================================================
-- ITEM 7: CHAVE ESTRANGEIRA - erro ao inserir vacina com fabricante inexistente
-- ============================================================
DO $$
BEGIN
    INSERT INTO vacina (nome, tipo, id_fabricante)
    VALUES ('Vacina Fantasma', 'Desconhecido', 9999);
    RAISE NOTICE 'Inserção bem-sucedida (não deveria ocorrer)';
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'ERRO DE CHAVE ESTRANGEIRA: %', SQLERRM;
END;
$$;

-- ============================================================
-- ITEM 8: VIEW - Lotes com data vencida
-- ============================================================
CREATE OR REPLACE VIEW vw_lotes_vencidos AS
    SELECT
        l.id_lote,
        l.codigo_lote,
        va.nome                          AS vacina,
        COALESCE(f.nome,'Sem Fab.')      AS fabricante,
        l.data_validade,
        l.quantidade,
        (CURRENT_DATE - l.data_validade) AS dias_vencido
    FROM lote l
    INNER JOIN vacina     va ON l.id_vacina      = va.id_vacina
    LEFT  JOIN fabricante f  ON va.id_fabricante  = f.id_fabricante
    WHERE l.data_validade < CURRENT_DATE;

SELECT * FROM vw_lotes_vencidos;

-- ============================================================
-- ITEM 9: STORED PROCEDURE (FUNCTION no PostgreSQL)
-- Pacientes que tomaram vacina vencida, com fabricante e lote
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

SELECT * FROM sp_pacientes_vacina_vencida();

-- ============================================================
-- ITEM 10: TRIGGER - Atualiza data_vacinacao em todo INSERT
-- ============================================================
CREATE OR REPLACE FUNCTION fn_atualiza_data_vacinacao()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.data_vacinacao := NOW();
    RAISE NOTICE 'Trigger disparado: data_vacinacao = %', NEW.data_vacinacao;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_atualiza_data_vacinacao ON vacinacao;
CREATE TRIGGER trg_atualiza_data_vacinacao
BEFORE INSERT ON vacinacao
FOR EACH ROW EXECUTE FUNCTION fn_atualiza_data_vacinacao();

-- Demonstração: data antiga (2020) será substituída pelo trigger
INSERT INTO vacinacao (id_paciente, id_lote, id_vacinador, data_vacinacao, dose)
VALUES (4, 6, 3, '2020-01-01 00:00:00', 1);

SELECT id_vacinacao, data_vacinacao FROM vacinacao ORDER BY id_vacinacao DESC LIMIT 1;

-- ============================================================
-- ITEM 11: UNION
-- Lotes vencendo nos próximos 30 dias UNION vencidos há até 30 dias
-- ============================================================
SELECT codigo_lote, data_validade, 'Vence em 30 dias'   AS status_lote
FROM lote
WHERE data_validade >= CURRENT_DATE
  AND data_validade <= CURRENT_DATE + INTERVAL '30 days'

UNION

SELECT codigo_lote, data_validade, 'Vencido há 30 dias' AS status_lote
FROM lote
WHERE data_validade < CURRENT_DATE
  AND data_validade >= CURRENT_DATE - INTERVAL '30 days'

ORDER BY data_validade;

-- ============================================================
-- ITEM 12: CONSTRAINT CHECK - demonstrar violação (qtd > 100)
-- ============================================================
DO $$
BEGIN
    INSERT INTO lote (codigo_lote, id_vacina, data_fabricacao, data_validade, quantidade)
    VALUES ('LOT-ERRO-001', 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 year', 150);
    RAISE NOTICE 'Inserção bem-sucedida (não deveria ocorrer)';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'ERRO DE CONSTRAINT CHECK: %', SQLERRM;
END;
$$;

-- ============================================================
-- ITEM 13: FULL JOIN - Fabricante x Vacina com NULLs nos dois lados
-- ============================================================

-- Fabricante sem vacina (gera NULL no lado da Vacina)
INSERT INTO fabricante (nome, pais_origem, cnpj)
VALUES ('BioFarma Test', 'Brasil', '99.999.999/0001-99');

-- Vacina sem fabricante já existe (id_fabricante = NULL, inserida na carga)
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
-- PostgreSQL usa TEMP TABLE de sessão (equivalente ao ##GlobalTemp)
-- ============================================================
CREATE TEMP TABLE temp_fabricantes AS
    SELECT * FROM fabricante;

SELECT * FROM temp_fabricantes;

-- ============================================================
-- ITEM 15A: CURSOR 1 - Data, Paciente, Lote e Fabricante
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
-- ITEM 15B: CURSOR 2 - Vacinadores que também tomaram vacina
-- ============================================================
INSERT INTO paciente (nome, cpf, nascimento, telefone)
VALUES ('Dra. Maria Oliveira', '777.777.777-77', '1980-05-10', '21-97777-7777');

INSERT INTO vacinacao (id_paciente, id_lote, id_vacinador, data_vacinacao, dose)
VALUES (7, 5, 2, NOW(), 1);

DO $$
DECLARE
    cur CURSOR FOR
        SELECT
            vd.nome                                 AS vacinador,
            va.tipo                                 AS tipo_vacina,
            COALESCE(f.nome, 'Sem Fabricante')      AS fabricante,
            TO_CHAR(l.data_validade, 'DD/MM/YYYY')  AS validade
        FROM vacinacao vc
        INNER JOIN paciente   p  ON vc.id_paciente  = p.id_paciente
        INNER JOIN vacinador  vd ON vc.id_vacinador  = vd.id_vacinador
        INNER JOIN lote       l  ON vc.id_lote       = l.id_lote
        INNER JOIN vacina     va ON l.id_vacina      = va.id_vacina
        LEFT  JOIN fabricante f  ON va.id_fabricante = f.id_fabricante
        WHERE p.nome = vd.nome
        ORDER BY vd.nome;
    r RECORD;
BEGIN
    RAISE NOTICE '--- VACINADORES QUE TAMBÉM SÃO PACIENTES ---';
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
-- PostgreSQL não tem FOR SYSTEM_TIME nativamente.
-- Simulação com history table + trigger (padrão SCD tipo 4).
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

-- Trigger que move a linha antiga para o histórico no UPDATE
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

-- Alimentar dados em T1
INSERT INTO estoque_vacina (id_vacina, quantidade) VALUES (1, 80), (2, 50);

-- Simular passagem de tempo e atualizar (T2)
DO $$
BEGIN
    PERFORM pg_sleep(1);
    UPDATE estoque_vacina SET quantidade = 60 WHERE id_vacina = 1;
    UPDATE estoque_vacina SET quantidade = 30 WHERE id_vacina = 2;
    PERFORM pg_sleep(1);
    -- T3: segunda atualização
    UPDATE estoque_vacina SET quantidade = 45 WHERE id_vacina = 1;
END;
$$;

-- Estado atual
SELECT ev.id_estoque, va.nome AS vacina, ev.quantidade, ev.valid_from AS vigente_desde
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

-- Filtrar por intervalo de tempo (últimos 10 segundos)
SELECT h.id_estoque, va.nome AS vacina, h.quantidade, h.valid_from, h.valid_to
FROM estoque_vacina_hist h
INNER JOIN vacina va ON h.id_vacina = va.id_vacina
WHERE h.valid_from >= NOW() - INTERVAL '10 seconds'
ORDER BY h.valid_from;

-- ============================================================
-- FIM DO TRABALHO FINAL - PostgreSQL
-- ============================================================
