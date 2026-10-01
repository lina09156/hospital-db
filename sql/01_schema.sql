-- ============================================================
-- Больница — Часть I. Схема базы данных
-- PostgreSQL 18
-- ============================================================

-- Очистка (на случай повторного запуска)
DROP TABLE IF EXISTS doctor_examinations CASCADE;
DROP TABLE IF EXISTS doctor_departments CASCADE;
DROP TABLE IF EXISTS wards CASCADE;
DROP TABLE IF EXISTS examinations CASCADE;
DROP TABLE IF EXISTS doctors CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

-- ============================================================
-- 1. departments — отделения
-- ============================================================
CREATE TABLE departments (
    department_id   SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    building        VARCHAR(50),
    floor           INTEGER CHECK (floor > 0)
);

-- ============================================================
-- 2. doctors — врачи
-- ============================================================
CREATE TABLE doctors (
    doctor_id       SERIAL PRIMARY KEY,
    doctor_fullname VARCHAR(150) NOT NULL,
    specialization  VARCHAR(100) NOT NULL,
    phone           VARCHAR(20)  UNIQUE,
    hire_date       DATE NOT NULL DEFAULT CURRENT_DATE
);

-- ============================================================
-- 3. doctor_departments — связь M:N: врач ↔ отделение
--    (врач может работать в нескольких отделениях)
-- ============================================================
CREATE TABLE doctor_departments (
    doctor_id     INTEGER NOT NULL REFERENCES doctors (doctor_id) ON DELETE CASCADE,
    department_id INTEGER NOT NULL REFERENCES departments (department_id) ON DELETE CASCADE,
    is_primary    BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (doctor_id, department_id)
);

-- ============================================================
-- 4. wards — палаты
-- ============================================================
CREATE TABLE wards (
    ward_id       SERIAL PRIMARY KEY,
    ward_number   VARCHAR(20) NOT NULL,
    capacity      INTEGER NOT NULL CHECK (capacity > 0),
    ward_type     VARCHAR(50) NOT NULL,
    department_id INTEGER NOT NULL REFERENCES departments (department_id) ON DELETE CASCADE,
    UNIQUE (department_id, ward_number)
);

-- ============================================================
-- 5. examinations — обследования (расписание)
--    День недели 1..7 (1=Пн, 7=Вс)
-- ============================================================
CREATE TABLE examinations (
    examination_id   SERIAL PRIMARY KEY,
    examination_name VARCHAR(150) NOT NULL,
    day_of_week      INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    time_start       TIME NOT NULL,
    time_end         TIME NOT NULL,
    room             VARCHAR(20),
    CONSTRAINT chk_time_order CHECK (time_start < time_end),
    CONSTRAINT uq_exam_schedule UNIQUE (examination_name, day_of_week, time_start)
);

-- ============================================================
-- 6. doctor_examinations — связь M:N: врач ↔ обследование
-- ============================================================
CREATE TABLE doctor_examinations (
    doctor_id      INTEGER NOT NULL REFERENCES doctors (doctor_id) ON DELETE CASCADE,
    examination_id INTEGER NOT NULL REFERENCES examinations (examination_id) ON DELETE CASCADE,
    PRIMARY KEY (doctor_id, examination_id)
);

-- ============================================================
-- Индексы для ускорения поиска
-- ============================================================
CREATE INDEX idx_wards_department  ON wards (department_id);
CREATE INDEX idx_exam_day          ON examinations (day_of_week);
CREATE INDEX idx_dd_department     ON doctor_departments (department_id);
CREATE INDEX idx_de_examination    ON doctor_examinations (examination_id);
