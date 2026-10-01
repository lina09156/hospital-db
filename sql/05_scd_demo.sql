-- 1. Заводим первую версию для каждого врача
INSERT INTO doctors_history
    (doctor_id, doctor_fullname, specialization, phone, hire_date,
     valid_from, valid_to, is_current, operation)
SELECT doctor_id, doctor_fullname, specialization, phone, hire_date,
       NOW() - INTERVAL '1 day', NULL, TRUE, 'INSERT'
FROM doctors;

-- 2. UPDATE — врач 1 сменил специализацию
UPDATE doctors SET specialization = 'Терапевт-кардиолог' WHERE doctor_id = 1;
SELECT pg_sleep(1);

-- 3. UPDATE — врач 2 сменил телефон
UPDATE doctors SET phone = '+7-900-999-99-99' WHERE doctor_id = 2;
SELECT pg_sleep(1);

-- 4. INSERT — новый врач
INSERT INTO doctors (doctor_fullname, specialization, phone, hire_date)
VALUES ('Тестов Тест Тестович', 'Психиатр', '+7-900-000-00-00', CURRENT_DATE);

-- 5. DELETE — врач уволен
DELETE FROM doctors WHERE doctor_id = 10;

-- ============ Проверка ============

-- Все версии врача 1
SELECT version_id, doctor_id, specialization, valid_from, valid_to, is_current, operation
FROM doctors_history
WHERE doctor_id = 1
ORDER BY valid_from;

-- Срез: состояние врача 2 на момент «30 минут назад»
SELECT doctor_id, specialization, phone, valid_from, valid_to
FROM doctors_history
WHERE doctor_id = 2
  AND valid_from <= NOW() - INTERVAL '30 minutes'
  AND (valid_to IS NULL OR valid_to > NOW() - INTERVAL '30 minutes');

-- Только текущие версии
SELECT doctor_id, doctor_fullname, specialization, phone, is_current
FROM doctors_history
WHERE is_current = TRUE
ORDER BY doctor_id;
