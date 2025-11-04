create database CentralDatabase;
create database TerritorialDatabase1;
create database TerritorialDatabase2;
create database TerritorialDatabase3;

use CentralDatabase;
use TerritorialDatabase1;
use TerritorialDatabase2;
use TerritorialDatabase3;

select * from BODI;
select * from BODK;
truncate table BODI;
truncate table BODK;

CREATE TABLE BODI (
    IST CHAR(3) DEFAULT '-' CHECK (IST <= '999'), -- Код источника данных
    TABL CHAR(5) DEFAULT '-', -- Код таблицы (в БД ГО)
    POK CHAR(4) DEFAULT '-', -- Код показателя
    UT CHAR(2) DEFAULT '00' CHECK (UT <= '99'), -- Код уточнения показателя
    SUB CHAR(6) DEFAULT '-' CHECK (SUB <= '999999'), -- Код субъекта
    OTN CHAR(2) DEFAULT '00' CHECK (OTN <= '99'), -- Код отношения
    OBJ CHAR(16) DEFAULT '0000000000000000' CHECK (OBJ <= '9999999999999999'), -- Код объекта
    VID CHAR(2) DEFAULT '-' CHECK (VID <= '99'), -- Код вида информации
    PER CHAR(2) DEFAULT '-' CHECK (PER <= '99'), -- Код периода
    DATV DATETIME DEFAULT GETDATE(), -- Дата-время
    DATV_SET DATETIME DEFAULT GETDATE(), -- Дата-время установки
    ZNC FLOAT DEFAULT 1.7E+308, -- Значение показателя
    PP CHAR(2) DEFAULT NULL, -- Признак показателя
    CONSTRAINT unique_combination_bodi UNIQUE (IST, TABL, POK, UT, SUB, OTN, OBJ, VID, PER) -- Ограничение уникальности для комбинации полей
);

CREATE TABLE BODK (
    IST CHAR(3) DEFAULT '-' CHECK (IST <= '999'), -- Код источника данных
    SUB CHAR(6) DEFAULT '-' CHECK (SUB <= '999999'), -- Код субъекта отрасли
    DATV_SET DATETIME DEFAULT GETDATE(), -- Дата-время записи в таблицу BODK
    KZAP SMALLINT DEFAULT 0 CHECK (KZAP <= 32767), -- Количество строк (записей)
    CONSTRAINT unique_combination UNIQUE (IST, SUB, DATV_SET, KZAP) -- Ограничение уникальности для комбинации полей
);

CREATE TABLE N_TI (
    IST CHAR(3) NOT NULL,               -- Код источника
    TABL CHAR(5) NOT NULL,              -- Имя таблицы базы данных EXPOES
    POK CHAR(4) NOT NULL,               -- Код показателя
    UT CHAR(2) NOT NULL,                -- Код уточнения
    SUB CHAR(6) NOT NULL,               -- Код субъекта
    OTN CHAR(2) NOT NULL,               -- Код отношения
    OBJ CHAR(16) NOT NULL,              -- Код объекта
    VID CHAR(2) NOT NULL,               -- Код вида информации
    PER CHAR(2) NOT NULL,               -- Код периода
    N_TI INT NOT NULL DEFAULT 0,        -- Номер ТИ
    SUB_R CHAR(6) NOT NULL,             -- Код получателя
    NAME VARCHAR(50),                    -- Имя объекта
    ACT TINYINT NOT NULL DEFAULT 1,     -- Актуальность
    CONSTRAINT unique_combination_n_ti UNIQUE (IST, TABL, POK, SUB, OTN, PER, SUB_R, NAME) -- Ограничение уникальности для комбинации полей
);

CREATE TABLE T_IST (
    IST CHAR(3) NOT NULL,               -- Код источника
    PERIOD CHAR(3) NOT NULL,            -- Период обмена
    ED CHAR(1) NOT NULL,                -- Единица измерения (минуты, дни, часы, асинхронная)
    DT_BEG CHAR(2) NOT NULL,            -- Задержка начала
    DT_END CHAR(2) NOT NULL,            -- Задержка окончания
    CONSTRAINT unique_combination_t_ist UNIQUE (IST, PERIOD) -- Ограничение уникальности для комбинации полей
);

CREATE TABLE T_S_N (
    IST CHAR(3) NOT NULL,               -- Код источника
    SUB CHAR(6) NOT NULL,               -- Код субъекта
    S_N CHAR(1) NOT NULL,               -- Серийный номер
    CONSTRAINT unique_combination_t_s_n UNIQUE (IST, SUB, S_N) -- Ограничение уникальности для комбинации полей
);

CREATE TABLE T_SUB (
    ACT CHAR(1) NOT NULL DEFAULT '0',   -- Активность
    SUB CHAR(6) NOT NULL,                -- Код субъекта
    SUB_NAME CHAR(5) NOT NULL,          -- Имя субъекта
    WITH_PROXY CHAR(1) NOT NULL DEFAULT 'N', -- Работа через прокси
    SUB_ADR VARCHAR(50) NOT NULL,       -- IP-адрес или имя сайта
    SUB_PORT CHAR(5) NOT NULL DEFAULT '80', -- Порт
    SUB_PROXY VARCHAR(60),               -- Адрес прокси
    SUB_PATH VARCHAR(255) NOT NULL,      -- Путь к документу
    SUB_PROXY_PORT CHAR(5),              -- Порт прокси
    CONSTRAINT unique_combination_t_sub UNIQUE (SUB, SUB_NAME) -- Ограничение уникальности для комбинации полей
);

drop table T_SUB;
select * from T_SUB;

INSERT INTO T_SUB (SUB, SUB_NAME, SUB_ADR, SUB_PORT, SUB_PATH) VALUES
('001', 'CTR1', 'localhost', '3001', '/api/data'),
('002', 'CTR2', 'localhost', '3002', '/api/data'),
('101', 'SUB_A', 'localhost', '4001', '/api/data'),
('102', 'SUB_B', 'localhost', '4002', '/api/data'),
('103', 'SUB_C', 'localhost', '4003', '/api/data');

INSERT INTO T_IST (IST, PERIOD, ED, DT_BEG, DT_END) VALUES
('001', '1', 'm', '01', '02'),
('002', '1', 'm', '01', '01'),
('003', '1', 'm', '01', '03'),
('004', '2', 'm', '01', '02'),
('005', '2', 'm', '01', '01'),
('006', '2', 'm', '01', '03'),
('007', '3', 'm', '01', '02'),
('008', '3', 'm', '01', '01'),
('009', '3', 'm', '01', '03');

INSERT INTO T_S_N (IST, SUB, S_N) VALUES
('001', 'SUB101', '1'),
('002', 'SUB101', '2'),
('003', 'SUB101', '3'),
('004', 'SUB102', '1'),
('005', 'SUB102', '2'),
('006', 'SUB102', '3'),
('007', 'SUB103', '1'),
('008', 'SUB103', '2'),
('009', 'SUB103', '3');

INSERT INTO N_TI (IST, TABL, POK, UT, SUB, OTN, OBJ, VID, PER, N_TI, SUB_R, NAME, ACT) VALUES
('001', 'TAB01', 'POK1', 'UT', '101', 'OT', 'OBJ001', 'VI', '01', 1, '102', 'Object A', 1),
('002', 'TAB01', 'POK2', 'UT', '101', 'OT', 'OBJ002', 'VI', '02', 2, '102', 'Object B', 1),
('003', 'TAB01', 'POK3', 'UT', '101', 'OT', 'OBJ003', 'VI', '03', 3, '102', 'Object C', 1),
('004', 'TAB01', 'POK1', 'UT', '102', 'OT', 'OBJ001', 'VI', '01', 4, '103', 'Object A', 1),
('005', 'TAB01', 'POK2', 'UT', '102', 'OT', 'OBJ002', 'VI', '02', 5, '103', 'Object B', 1),
('006', 'TAB01', 'POK3', 'UT', '102', 'OT', 'OBJ003', 'VI', '03', 6, '103', 'Object C', 1),
('007', 'TAB01', 'POK1', 'UT', '103', 'OT', 'OBJ001', 'VI', '01', 7, '102', 'Object A', 1),
('008', 'TAB01', 'POK2', 'UT', '103', 'OT', 'OBJ002', 'VI', '02', 8, '102', 'Object B', 1),
('009', 'TAB01', 'POK3', 'UT', '103', 'OT', 'OBJ003', 'VI', '03', 9, '102', 'Object C', 1);