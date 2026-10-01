-- ============================================================
-- Часть II. Запрос-срез: кто проводил заданное обследование
-- на заданную дату (через doctors_history + doctor_examinations)
-- ============================================================

-- Пример: кто проводил обследование examination_id = 3 (ЭКГ)
-- на дату '2026-10-01 07:59:56'

SELECT
    e.examination_name,
    h.doctor_id,
    h.doctor_fullname,
    h.specialization,
    h.valid_from,
    h.valid_to
FROM examinations e
JOIN doctor_examinations de ON de.examination_id = e.examination_id
JOIN doctors_history h      ON h.doctor_id = de.doctor_id
WHERE e.examination_id = 3
  AND h.valid_from <= TIMESTAMP '2026-10-01 07:59:56'
  AND (h.valid_to IS NULL OR h.valid_to > TIMESTAMP '2026-10-01 07:59:56')
ORDER BY h.doctor_fullname;

-- Дополнительно: все версии врача 1 в хронологическом порядке
SELECT version_id, doctor_id, doctor_fullname, specialization,
       valid_from, valid_to, is_current, operation
FROM doctors_history
WHERE doctor_id = 1
ORDER BY valid_from;
