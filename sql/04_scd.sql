-- ============================================================
-- Больница. Часть II. SCD Type 2 для таблицы doctors
-- Версионируем: specialization, phone, doctor_fullname
-- ============================================================

CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP TABLE IF EXISTS doctors_history CASCADE;

CREATE TABLE doctors_history (
    version_id      SERIAL PRIMARY KEY,
    doctor_id       INTEGER NOT NULL,
    doctor_fullname VARCHAR(150) NOT NULL,
    specialization  VARCHAR(100) NOT NULL,
    phone           VARCHAR(20),
    hire_date       DATE NOT NULL,
    valid_from      TIMESTAMP NOT NULL DEFAULT NOW(),
    valid_to        TIMESTAMP,
    is_current      BOOLEAN NOT NULL DEFAULT TRUE,
    operation       VARCHAR(10) NOT NULL,

    CONSTRAINT chk_valid_range CHECK (valid_to IS NULL OR valid_from < valid_to),
    CONSTRAINT chk_current_open CHECK (
        (is_current = TRUE AND valid_to IS NULL)
        OR (is_current = FALSE AND valid_to IS NOT NULL)
    )
);

CREATE UNIQUE INDEX uq_doctors_history_current
    ON doctors_history (doctor_id)
    WHERE is_current = TRUE;

ALTER TABLE doctors_history
    ADD CONSTRAINT ex_doctors_history_no_overlap
    EXCLUDE USING gist (
        doctor_id WITH =,
        tsrange(valid_from, valid_to, '[)') WITH &&
    );

-- ---------- Триггерная функция ----------
CREATE OR REPLACE FUNCTION fn_doctors_scd() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO doctors_history
            (doctor_id, doctor_fullname, specialization, phone, hire_date,
             valid_from, valid_to, is_current, operation)
        VALUES
            (NEW.doctor_id, NEW.doctor_fullname, NEW.specialization, NEW.phone, NEW.hire_date,
             NOW(), NULL, TRUE, 'INSERT');
        RETURN NEW;

    ELSIF (TG_OP = 'UPDATE') THEN
        UPDATE doctors_history
        SET valid_to = NOW(), is_current = FALSE
        WHERE doctor_id = OLD.doctor_id AND is_current = TRUE;

        INSERT INTO doctors_history
            (doctor_id, doctor_fullname, specialization, phone, hire_date,
             valid_from, valid_to, is_current, operation)
        VALUES
            (NEW.doctor_id, NEW.doctor_fullname, NEW.specialization, NEW.phone, NEW.hire_date,
             NOW(), NULL, TRUE, 'UPDATE');
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE doctors_history
        SET valid_to = NOW(), is_current = FALSE, operation = 'DELETE'
        WHERE doctor_id = OLD.doctor_id AND is_current = TRUE;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_doctors_scd ON doctors;
CREATE TRIGGER trg_doctors_scd
    AFTER INSERT OR UPDATE OR DELETE ON doctors
    FOR EACH ROW
    EXECUTE FUNCTION fn_doctors_scd();
