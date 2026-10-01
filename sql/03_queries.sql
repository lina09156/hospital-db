-- ============================================================
-- Больница. 9 SQL-запросов по заданию
-- ============================================================

-- 1. Список всех обследований с днём недели, временем начала и окончания
SELECT examination_id, examination_name,
       CASE day_of_week
           WHEN 1 THEN 'Понедельник' WHEN 2 THEN 'Вторник'
           WHEN 3 THEN 'Среда'        WHEN 4 THEN 'Четверг'
           WHEN 5 THEN 'Пятница'      WHEN 6 THEN 'Суббота'
           WHEN 7 THEN 'Воскресенье'
       END AS day_name,
       time_start, time_end, room
FROM examinations
ORDER BY day_of_week, time_start;

-- 2. Врачи, проводящие конкретное обследование (пример: ЭКГ)
SELECT d.doctor_id, d.doctor_fullname, d.specialization
FROM doctors d
JOIN doctor_examinations de ON de.doctor_id = d.doctor_id
JOIN examinations e ON e.examination_id = de.examination_id
WHERE e.examination_name = 'ЭКГ'
ORDER BY d.doctor_fullname;

-- 3. Расписание обследований на заданный день недели (пример: вторник)
SELECT examination_name, time_start, time_end, room
FROM examinations
WHERE day_of_week = 2
ORDER BY time_start;

-- 4. Врачи с указанием их отделений
SELECT d.doctor_fullname, d.specialization,
       dep.department_name, dd.is_primary
FROM doctors d
JOIN doctor_departments dd ON dd.doctor_id = d.doctor_id
JOIN departments dep ON dep.department_id = dd.department_id
ORDER BY d.doctor_fullname, dep.department_name;

-- 5. Отделения и количество палат в каждом
SELECT dep.department_id, dep.department_name, COUNT(w.ward_id) AS wards_count
FROM departments dep
LEFT JOIN wards w ON w.department_id = dep.department_id
GROUP BY dep.department_id, dep.department_name
ORDER BY wards_count DESC, dep.department_name;

-- 6. Обследования, начинающиеся после 12:00
SELECT examination_name, day_of_week, time_start, time_end
FROM examinations
WHERE time_start > '12:00'
ORDER BY time_start;

-- 7. Врачи, участвующие более чем в одном обследовании
SELECT d.doctor_id, d.doctor_fullname, COUNT(de.examination_id) AS exams_count
FROM doctors d
JOIN doctor_examinations de ON de.doctor_id = d.doctor_id
GROUP BY d.doctor_id, d.doctor_fullname
HAVING COUNT(de.examination_id) > 1
ORDER BY exams_count DESC, d.doctor_fullname;

-- 8. Обследования, проводимые заданным врачом (пример: doctor_id = 1)
SELECT e.examination_id, e.examination_name, e.day_of_week, e.time_start, e.time_end
FROM examinations e
JOIN doctor_examinations de ON de.examination_id = e.examination_id
WHERE de.doctor_id = 1
ORDER BY e.day_of_week, e.time_start;

-- 9. Список палат заданного отделения (пример: department_id = 1)
SELECT ward_id, ward_number, capacity, ward_type
FROM wards
WHERE department_id = 1
ORDER BY ward_number;
