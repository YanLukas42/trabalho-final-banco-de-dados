-- ============================================================
-- TRABALHO FINAL - BANCO DE DADOS
-- UFRJ - Escola de Engenharia / Departamento de Eletrônica
-- Prof. Sergio Palma
-- Tema: Sistema de Vacinação
-- ============================================================

-- ============================================================
-- ITEM 1: MODELO DE DADOS NA 3ª FORMA NORMAL (3FN)
-- ============================================================
-- Entidades: Fabricante, Vacina, Lote, Paciente, Vacinador, Vacinacao
-- Todas as tabelas estão na 3FN:
--   - Sem dependências parciais (todas as colunas dependem da PK completa)
--   - Sem dependências transitivas (colunas dependem apenas da PK, não de outras não-chave)

-- Criar e usar o banco de dados
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'VacinaDB')
    CREATE DATABASE VacinaDB;
GO
USE VacinaDB;
GO

-- Drop das tabelas (ordem inversa para respeitar FKs)
IF OBJECT_ID('Vacinacao', 'U') IS NOT NULL DROP TABLE Vacinacao;
IF OBJECT_ID('Lote', 'U') IS NOT NULL DROP TABLE Lote;
IF OBJECT_ID('Vacina', 'U') IS NOT NULL DROP TABLE Vacina;
IF OBJECT_ID('Fabricante', 'U') IS NOT NULL DROP TABLE Fabricante;
IF OBJECT_ID('Vacinador', 'U') IS NOT NULL DROP TABLE Vacinador;
IF OBJECT_ID('Paciente', 'U') IS NOT NULL DROP TABLE Paciente;
GO

-- ============================================================
-- CRIAÇÃO DAS TABELAS (DDL)
-- ============================================================

CREATE TABLE Fabricante (
    id_fabricante  INT           PRIMARY KEY IDENTITY(1,1),
    nome           VARCHAR(100)  NOT NULL,
    pais_origem    VARCHAR(50)   NOT NULL,
    cnpj           CHAR(18)      UNIQUE NOT NULL
);
GO

CREATE TABLE Vacina (
    id_vacina      INT           PRIMARY KEY IDENTITY(1,1),
    nome           VARCHAR(100)  NOT NULL,
    tipo           VARCHAR(50)   NOT NULL,   -- ex: mRNA, viral atenuada, etc.
    id_fabricante  INT           NULL,        -- NULL para demonstrar FULL JOIN com NULLs
    CONSTRAINT FK_Vacina_Fabricante FOREIGN KEY (id_fabricante)
        REFERENCES Fabricante(id_fabricante)
);
GO

CREATE TABLE Lote (
    id_lote         INT           PRIMARY KEY IDENTITY(1,1),
    codigo_lote     VARCHAR(20)   UNIQUE NOT NULL,
    id_vacina       INT           NOT NULL,
    data_fabricacao DATE          NOT NULL,
    data_validade   DATE          NOT NULL,
    quantidade      INT           NOT NULL,
    -- ITEM 12: CONSTRAINT CHECK - quantidade máxima de 100
    CONSTRAINT CK_Lote_Quantidade CHECK (quantidade <= 100),
    CONSTRAINT FK_Lote_Vacina FOREIGN KEY (id_vacina)
        REFERENCES Vacina(id_vacina)
);
GO

CREATE TABLE Paciente (
    id_paciente INT          PRIMARY KEY IDENTITY(1,1),
    nome        VARCHAR(100) NOT NULL,
    cpf         CHAR(14)     UNIQUE NOT NULL,
    nascimento  DATE         NOT NULL,
    telefone    VARCHAR(15)  NULL
);
GO

CREATE TABLE Vacinador (
    id_vacinador INT          PRIMARY KEY IDENTITY(1,1),
    nome         VARCHAR(100) NOT NULL,
    coren        VARCHAR(20)  UNIQUE NOT NULL,   -- registro profissional
    especialidade VARCHAR(50) NOT NULL
);
GO

CREATE TABLE Vacinacao (
    id_vacinacao  INT  PRIMARY KEY IDENTITY(1,1),
    id_paciente   INT  NOT NULL,
    id_lote       INT  NOT NULL,
    id_vacinador  INT  NOT NULL,
    data_vacinacao DATETIME NOT NULL DEFAULT GETDATE(),
    dose          TINYINT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Vacinacao_Paciente   FOREIGN KEY (id_paciente)  REFERENCES Paciente(id_paciente),
    CONSTRAINT FK_Vacinacao_Lote       FOREIGN KEY (id_lote)      REFERENCES Lote(id_lote),
    CONSTRAINT FK_Vacinacao_Vacinador  FOREIGN KEY (id_vacinador) REFERENCES Vacinador(id_vacinador)
);
GO

-- ============================================================
-- ITEM 3: IMPORTAÇÃO / CARGA DE DADOS (mínimo 5 por tabela)
-- ============================================================

-- Fabricantes (6 registros)
INSERT INTO Fabricante (nome, pais_origem, cnpj) VALUES
('Pfizer-BioNTech',    'EUA',         '60.396.060/0001-00'),
('Janssen',            'Bélgica',     '11.435.917/0001-00'),
('AstraZeneca',        'Reino Unido', '10.225.177/0001-00'),
('Sinovac (Butantan)', 'China',       '61.148.461/0001-00'),
('Moderna',            'EUA',         '05.846.180/0001-00'),
('Fiocruz',            'Brasil',      '33.781.055/0001-00');
GO

-- Vacinas (6 registros; última sem fabricante para FULL JOIN)
INSERT INTO Vacina (nome, tipo, id_fabricante) VALUES
('Comirnaty',           'mRNA',              1),  -- Pfizer
('Janssen COVID-19',    'Vetor Viral',       2),  -- Janssen
('Vaxzevria',           'Vetor Viral',       3),  -- AstraZeneca
('CoronaVac',           'Viral Inativada',   4),  -- Sinovac
('Spikevax',            'mRNA',              5),  -- Moderna
('VacSem Fabricante',   'Experimental',      NULL); -- sem fabricante (para FULL JOIN)
GO

-- Lotes (7 registros; alguns vencidos, alguns a vencer)
INSERT INTO Lote (codigo_lote, id_vacina, data_fabricacao, data_validade, quantidade) VALUES
('LOT-PFZ-001', 1, '2023-01-10', '2023-06-10',  80),  -- vencido há mais de 30 dias
('LOT-PFZ-002', 1, '2024-05-01', '2025-01-01',  60),  -- vencido
('LOT-JNS-001', 2, '2023-03-15', '2023-09-15',  50),  -- vencido há mais de 30 dias
('LOT-AZ-001',  3, '2024-06-01', DATEADD(DAY, 20, GETDATE()), 90),  -- vence em 20 dias
('LOT-SIN-001', 4, '2024-04-20', DATEADD(DAY, 25, GETDATE()), 70),  -- vence em 25 dias
('LOT-MOD-001', 5, '2024-07-01', DATEADD(DAY,180, GETDATE()), 40),  -- válido
('LOT-FIO-001', 6, '2024-08-01', DATEADD(DAY,365, GETDATE()), 100); -- válido, qtd máxima
GO

-- Pacientes (6 registros)
INSERT INTO Paciente (nome, cpf, nascimento, telefone) VALUES
('Ana Lima',       '111.111.111-11', '1985-03-20', '21-91111-1111'),
('Bruno Souza',    '222.222.222-22', '1990-07-14', '21-92222-2222'),
('Carla Mendes',   '333.333.333-33', '1978-11-05', '21-93333-3333'),
('Diego Ferreira', '444.444.444-44', '2000-01-30', '21-94444-4444'),
('Elisa Castro',   '555.555.555-55', '1995-09-18', '21-95555-5555'),
('Felipe Rocha',   '666.666.666-66', '1988-06-22', '21-96666-6666');
GO

-- Vacinadores (5 registros)
INSERT INTO Vacinador (nome, coren, especialidade) VALUES
('Dra. Maria Oliveira', 'COREN-RJ-123456', 'Enfermagem'),
('Dr. João Pedro',      'COREN-RJ-234567', 'Técnico de Enfermagem'),
('Enf. Paula Santos',   'COREN-RJ-345678', 'Enfermagem'),
('Tec. Carlos Ramos',   'COREN-RJ-456789', 'Técnico de Enfermagem'),
('Enf. Rita Nunes',     'COREN-RJ-567890', 'Enfermagem');
GO

-- Vacinações (12 registros)
-- Para o item 5 (NOT EXISTS), cada fabricante tem pelo menos 1 vacinação
-- Ana Lima tomou vacinas de TODOS os fabricantes (1..5)
-- Bruno Souza tomou de 4 fabricantes (não de todos)
INSERT INTO Vacinacao (id_paciente, id_lote, id_vacinador, data_vacinacao, dose) VALUES
-- Ana Lima: todos os fabricantes (Pfizer, Janssen, AstraZeneca, Sinovac, Moderna)
(1, 1, 1, '2022-01-10', 1),
(1, 3, 2, '2022-01-10', 1),
(1, 4, 3, '2022-02-01', 1),
(1, 5, 1, '2022-02-15', 1),
(1, 6, 4, '2022-03-01', 1),
-- Bruno Souza: apenas Pfizer e AstraZeneca
(2, 2, 2, '2022-01-20', 1),
(2, 4, 5, '2022-02-20', 1),
-- Carla, Diego, Elisa, Felipe: vacinações diversas
(3, 1, 3, '2022-01-25', 1),
(4, 5, 4, '2022-02-10', 1),
(5, 6, 1, '2022-03-05', 1),
(6, 2, 5, '2022-01-30', 1),
(3, 4, 2, '2022-04-01', 2);  -- Carla: 2ª dose
GO

-- ============================================================
-- ITEM 4: LISTAR TABELAS COM NOMES E CARDINALIDADES
-- ============================================================
SELECT
    t.name                          AS Tabela,
    p.rows                          AS Cardinalidade
FROM
    sys.tables t
    INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE
    p.index_id IN (0, 1)
ORDER BY
    t.name;
GO

-- ============================================================
-- ITEM 5: SUB-SELECT COM NOT EXISTS
-- Listar Pacientes que tomaram vacina de TODOS os Fabricantes existentes
-- ============================================================
SELECT P.nome AS Paciente
FROM Paciente P
WHERE NOT EXISTS (
    -- Existe algum fabricante para o qual este paciente NÃO tem vacinação?
    SELECT 1
    FROM Fabricante F
    WHERE NOT EXISTS (
        SELECT 1
        FROM Vacinacao VC
        INNER JOIN Lote L     ON VC.id_lote    = L.id_lote
        INNER JOIN Vacina VA  ON L.id_vacina   = VA.id_vacina
        WHERE VA.id_fabricante = F.id_fabricante
          AND VC.id_paciente   = P.id_paciente
    )
);
GO

-- ============================================================
-- ITEM 6: TRANSAÇÕES - COMMIT e ROLLBACK
-- ============================================================

-- Cenário A: Atualização com COMMIT (persistência garantida)
BEGIN TRANSACTION;
    UPDATE Paciente
    SET telefone = '21-99999-0001'
    WHERE id_paciente = 1;

    SELECT id_paciente, nome, telefone FROM Paciente WHERE id_paciente = 1;
    -- Confirma: dado persiste no banco
COMMIT;

SELECT id_paciente, nome, telefone FROM Paciente WHERE id_paciente = 1;
GO

-- Cenário B: Atualização com ROLLBACK (desfaz as mudanças)
BEGIN TRANSACTION;
    UPDATE Paciente
    SET nome = 'NOME ALTERADO - ROLLBACK TESTE'
    WHERE id_paciente = 2;

    SELECT id_paciente, nome FROM Paciente WHERE id_paciente = 2;
    -- Reverte: dado volta ao original
ROLLBACK;

SELECT id_paciente, nome FROM Paciente WHERE id_paciente = 2;
GO

-- ============================================================
-- ITEM 7: SUPORTE A CHAVE ESTRANGEIRA
-- Mostrar erro ao tentar inserir Vacina com Fabricante inexistente
-- ============================================================
-- Este INSERT deve gerar erro de violação de FK:
BEGIN TRY
    INSERT INTO Vacina (nome, tipo, id_fabricante)
    VALUES ('Vacina Fantasma', 'Desconhecido', 9999);  -- id 9999 não existe
    PRINT 'Inserção bem-sucedida (não deveria ocorrer)';
END TRY
BEGIN CATCH
    PRINT 'ERRO DE CHAVE ESTRANGEIRA:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- ============================================================
-- ITEM 8: VIEW - Lotes com data vencida
-- ============================================================
IF OBJECT_ID('vw_LotesVencidos', 'V') IS NOT NULL DROP VIEW vw_LotesVencidos;
GO

CREATE VIEW vw_LotesVencidos AS
    SELECT
        L.id_lote,
        L.codigo_lote,
        VA.nome         AS vacina,
        F.nome          AS fabricante,
        L.data_validade,
        L.quantidade,
        DATEDIFF(DAY, L.data_validade, GETDATE()) AS dias_vencido
    FROM Lote L
    INNER JOIN Vacina VA    ON L.id_vacina     = VA.id_vacina
    LEFT  JOIN Fabricante F ON VA.id_fabricante = F.id_fabricante
    WHERE L.data_validade < GETDATE();
GO

-- Demonstração da VIEW
SELECT * FROM vw_LotesVencidos;
GO

-- ============================================================
-- ITEM 9: STORED PROCEDURE
-- Pacientes que tomaram vacina vencida, com fabricante e código do lote
-- ============================================================
IF OBJECT_ID('sp_PacientesVacinaVencida', 'P') IS NOT NULL
    DROP PROCEDURE sp_PacientesVacinaVencida;
GO

CREATE PROCEDURE sp_PacientesVacinaVencida
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        P.nome              AS Paciente,
        VA.nome             AS Vacina,
        F.nome              AS Fabricante,
        L.codigo_lote       AS CódigoLote,
        L.data_validade     AS DataValidade,
        VC.data_vacinacao   AS DataVacinacao
    FROM Vacinacao VC
    INNER JOIN Paciente   P  ON VC.id_paciente  = P.id_paciente
    INNER JOIN Lote       L  ON VC.id_lote       = L.id_lote
    INNER JOIN Vacina     VA ON L.id_vacina       = VA.id_vacina
    LEFT  JOIN Fabricante F  ON VA.id_fabricante  = F.id_fabricante
    WHERE L.data_validade < GETDATE()
    ORDER BY P.nome;
END;
GO

-- Demonstração da Stored Procedure
EXEC sp_PacientesVacinaVencida;
GO

-- ============================================================
-- ITEM 10: TRIGGER
-- Atualiza data_vacinacao sempre que houver INSERT em Vacinacao
-- ============================================================
IF OBJECT_ID('trg_AtualizaDataVacinacao', 'TR') IS NOT NULL
    DROP TRIGGER trg_AtualizaDataVacinacao;
GO

CREATE TRIGGER trg_AtualizaDataVacinacao
ON Vacinacao
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE VC
    SET VC.data_vacinacao = GETDATE()
    FROM Vacinacao VC
    INNER JOIN inserted i ON VC.id_vacinacao = i.id_vacinacao;

    PRINT 'Trigger executado: data_vacinacao atualizada para ' + CONVERT(VARCHAR, GETDATE(), 120);
END;
GO

-- Demonstração do Trigger (inserção que dispara o trigger)
INSERT INTO Vacinacao (id_paciente, id_lote, id_vacinador, data_vacinacao, dose)
VALUES (4, 6, 3, '2020-01-01', 1);  -- data antiga será substituída pelo trigger

SELECT TOP 1 id_vacinacao, data_vacinacao FROM Vacinacao ORDER BY id_vacinacao DESC;
GO

-- ============================================================
-- ITEM 11: UNION
-- Lotes com vencimento nos próximos 30 dias UNION lotes vencidos há 30 dias
-- ============================================================
-- Lotes que vencem nos próximos 30 dias
SELECT
    codigo_lote,
    data_validade,
    'Vence em 30 dias' AS status_lote
FROM Lote
WHERE data_validade >= GETDATE()
  AND data_validade <= DATEADD(DAY, 30, GETDATE())

UNION

-- Lotes vencidos há até 30 dias
SELECT
    codigo_lote,
    data_validade,
    'Vencido há 30 dias' AS status_lote
FROM Lote
WHERE data_validade < GETDATE()
  AND data_validade >= DATEADD(DAY, -30, GETDATE())

ORDER BY data_validade;
GO

-- ============================================================
-- ITEM 12 (já criado acima): CONSTRAINT CHECK
-- Demonstrar violação: inserir lote com quantidade > 100
-- ============================================================
BEGIN TRY
    INSERT INTO Lote (codigo_lote, id_vacina, data_fabricacao, data_validade, quantidade)
    VALUES ('LOT-ERRO-001', 1, GETDATE(), DATEADD(YEAR,1,GETDATE()), 150);
    PRINT 'Inserção bem-sucedida (não deveria ocorrer)';
END TRY
BEGIN CATCH
    PRINT 'ERRO DE CONSTRAINT CHECK:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- ============================================================
-- ITEM 13: FULL JOIN
-- Unir Fabricante e Vacina com FULL JOIN, garantindo NULLs em ambos os lados
-- ============================================================

-- Inserir fabricante sem vacina associada (para NULL no lado da Vacina)
INSERT INTO Fabricante (nome, pais_origem, cnpj)
VALUES ('BioFarma Test', 'Brasil', '99.999.999/0001-99');
GO

-- FULL JOIN mostra: fabricante sem vacina (NULL no lado vacina) e vacina sem fabricante (NULL no lado fabricante)
SELECT
    F.id_fabricante,
    F.nome          AS Fabricante,
    VA.id_vacina,
    VA.nome         AS Vacina,
    VA.tipo
FROM Fabricante F
FULL JOIN Vacina VA ON F.id_fabricante = VA.id_fabricante
ORDER BY F.id_fabricante, VA.id_vacina;
GO

-- ============================================================
-- ITEM 14: TABELA TEMPORÁRIA GLOBAL
-- Criar ##TempFabricantes com dados da tabela Fabricante
-- ============================================================
IF OBJECT_ID('tempdb..##TempFabricantes') IS NOT NULL DROP TABLE ##TempFabricantes;

SELECT *
INTO ##TempFabricantes
FROM Fabricante;

-- Consulta na tabela temporária global
SELECT * FROM ##TempFabricantes;
GO

-- ============================================================
-- ITEM 15: CURSOR 1
-- Saída formatada com Data, Paciente, Lote e Fabricante
-- ============================================================
DECLARE
    @data_vac    VARCHAR(20),
    @paciente    VARCHAR(100),
    @lote        VARCHAR(20),
    @fabricante  VARCHAR(100);

DECLARE cur_Vacinacao CURSOR FOR
    SELECT
        CONVERT(VARCHAR, VC.data_vacinacao, 103) AS data_vac,
        P.nome,
        L.codigo_lote,
        ISNULL(F.nome, 'Sem Fabricante') AS fabricante
    FROM Vacinacao VC
    INNER JOIN Paciente   P  ON VC.id_paciente  = P.id_paciente
    INNER JOIN Lote       L  ON VC.id_lote       = L.id_lote
    INNER JOIN Vacina     VA ON L.id_vacina       = VA.id_vacina
    LEFT  JOIN Fabricante F  ON VA.id_fabricante  = F.id_fabricante
    ORDER BY VC.data_vacinacao;

OPEN cur_Vacinacao;
FETCH NEXT FROM cur_Vacinacao INTO @data_vac, @paciente, @lote, @fabricante;

PRINT '--- RELATÓRIO DE VACINAÇÕES ---';
PRINT REPLICATE('-', 70);

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Data: ' + @data_vac +
          ' | Paciente: ' + @paciente +
          ' | Lote: ' + @lote +
          ' | Fabricante: ' + @fabricante;
    FETCH NEXT FROM cur_Vacinacao INTO @data_vac, @paciente, @lote, @fabricante;
END;

CLOSE cur_Vacinacao;
DEALLOCATE cur_Vacinacao;
GO

-- ============================================================
-- ITEM 15B: CURSOR 2
-- Vacinadores que também tomaram vacina (vacinador = paciente)
-- Tipo, Fabricante e Data de Validade da vacina
-- (Vacinadores com mesmo nome dos Pacientes, para simular cenário)
-- ============================================================
-- Inserir vacinador que também é paciente (mesmo nome de Paciente existente)
-- Simular a regra inserindo vacinação para o vacinador como paciente
INSERT INTO Paciente (nome, cpf, nascimento, telefone)
VALUES ('Dra. Maria Oliveira', '777.777.777-77', '1980-05-10', '21-97777-7777');
GO

INSERT INTO Vacinacao (id_paciente, id_lote, id_vacinador, data_vacinacao, dose)
VALUES (7, 5, 2, GETDATE(), 1);  -- Dra. Maria Oliveira vacinada por Dr. João Pedro
GO

DECLARE
    @vacinador   VARCHAR(100),
    @tipo_vac    VARCHAR(50),
    @fab_nome    VARCHAR(100),
    @val_data    VARCHAR(20);

DECLARE cur_VacinadorVacinado CURSOR FOR
    SELECT
        VD.nome                                     AS vacinador,
        VA.tipo                                     AS tipo_vacina,
        ISNULL(F.nome, 'Sem Fabricante')            AS fabricante,
        CONVERT(VARCHAR, L.data_validade, 103)      AS data_validade
    FROM Vacinacao VC
    INNER JOIN Paciente   P  ON VC.id_paciente  = P.id_paciente
    INNER JOIN Vacinador  VD ON VC.id_vacinador  = VD.id_vacinador
    INNER JOIN Lote       L  ON VC.id_lote       = L.id_lote
    INNER JOIN Vacina     VA ON L.id_vacina      = VA.id_vacina
    LEFT  JOIN Fabricante F  ON VA.id_fabricante = F.id_fabricante
    WHERE P.nome = VD.nome   -- vacinador que também é paciente
    ORDER BY VD.nome;

OPEN cur_VacinadorVacinado;
FETCH NEXT FROM cur_VacinadorVacinado INTO @vacinador, @tipo_vac, @fab_nome, @val_data;

PRINT '--- VACINADORES QUE TOMARAM VACINA ---';
PRINT REPLICATE('-', 70);

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Vacinador: ' + @vacinador +
          ' | Tipo: ' + @tipo_vac +
          ' | Fabricante: ' + @fab_nome +
          ' | Validade: ' + @val_data;
    FETCH NEXT FROM cur_VacinadorVacinado INTO @vacinador, @tipo_vac, @fab_nome, @val_data;
END;

CLOSE cur_VacinadorVacinado;
DEALLOCATE cur_VacinadorVacinado;
GO

-- ============================================================
-- ITEM 16: TABELA TEMPORAL (System-Versioned / Temporal Table)
-- Alimentar em tempos diferentes e filtrar por intervalo
-- ============================================================

-- Criar tabela de histórico
IF OBJECT_ID('EstoqueVacinaHistorico', 'U') IS NOT NULL
BEGIN
    -- Desabilitar versionamento antes de dropar
    ALTER TABLE EstoqueVacina SET (SYSTEM_VERSIONING = OFF);
    DROP TABLE EstoqueVacina;
    DROP TABLE EstoqueVacinaHistorico;
END
GO

CREATE TABLE EstoqueVacinaHistorico (
    id_estoque   INT          NOT NULL,
    id_vacina    INT          NOT NULL,
    quantidade   INT          NOT NULL,
    SysStart     DATETIME2    NOT NULL,
    SysEnd       DATETIME2    NOT NULL
);
GO

CREATE TABLE EstoqueVacina (
    id_estoque   INT          PRIMARY KEY IDENTITY(1,1),
    id_vacina    INT          NOT NULL,
    quantidade   INT          NOT NULL,
    SysStart     DATETIME2    GENERATED ALWAYS AS ROW START NOT NULL,
    SysEnd       DATETIME2    GENERATED ALWAYS AS ROW END   NOT NULL,
    PERIOD FOR SYSTEM_TIME (SysStart, SysEnd),
    CONSTRAINT FK_Estoque_Vacina FOREIGN KEY (id_vacina) REFERENCES Vacina(id_vacina)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.EstoqueVacinaHistorico));
GO

-- Alimentar dados no tempo T1
INSERT INTO EstoqueVacina (id_vacina, quantidade) VALUES (1, 80);   -- Comirnaty: 80
INSERT INTO EstoqueVacina (id_vacina, quantidade) VALUES (2, 50);   -- Janssen: 50
GO

-- Aguardar 1 segundo para garantir timestamp diferente
WAITFOR DELAY '00:00:01';
GO

-- Atualizar no tempo T2 (gera histórico)
UPDATE EstoqueVacina SET quantidade = 60 WHERE id_vacina = 1;  -- Comirnaty: 80→60
UPDATE EstoqueVacina SET quantidade = 30 WHERE id_vacina = 2;  -- Janssen: 50→30
GO

WAITFOR DELAY '00:00:01';
GO

-- Atualizar no tempo T3
UPDATE EstoqueVacina SET quantidade = 45 WHERE id_vacina = 1;  -- Comirnaty: 60→45
GO

-- Estado atual
PRINT '--- ESTADO ATUAL DO ESTOQUE ---';
SELECT EV.id_estoque, VA.nome AS vacina, EV.quantidade, EV.SysStart, EV.SysEnd
FROM EstoqueVacina EV
INNER JOIN Vacina VA ON EV.id_vacina = VA.id_vacina;
GO

-- Consulta temporal: estado do estoque no intervalo entre T1 e T3
PRINT '--- HISTÓRICO COMPLETO DO ESTOQUE (ALL) ---';
SELECT EV.id_estoque, VA.nome AS vacina, EV.quantidade, EV.SysStart, EV.SysEnd
FROM EstoqueVacina FOR SYSTEM_TIME ALL EV
INNER JOIN Vacina VA ON EV.id_vacina = VA.id_vacina
ORDER BY EV.id_vacina, EV.SysStart;
GO

-- Consulta temporal: estado em momento específico (AS OF)
DECLARE @momento DATETIME2 = DATEADD(SECOND, -1, GETDATE());
PRINT '--- ESTOQUE EM MOMENTO ANTERIOR (AS OF) ---';
SELECT EV.id_estoque, VA.nome AS vacina, EV.quantidade
FROM EstoqueVacina FOR SYSTEM_TIME AS OF @momento EV
INNER JOIN Vacina VA ON EV.id_vacina = VA.id_vacina;
GO

-- ============================================================
-- FIM DO TRABALHO FINAL
-- ============================================================
PRINT 'Script executado com sucesso!';
GO
