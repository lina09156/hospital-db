# Больница — база данных с поддержкой историчности (SCD Type 2)

Учебный проект по проектированию БД. СУБД — **PostgreSQL 18** (Docker).
Автор: [lina09156](https://github.com/lina09156)

---

## Часть I. Базовая модель «Больница»

### Предметная область
В больнице проводятся обследования (название, день недели, время начала/окончания).
Обследования проводят врачи. Врачи закреплены за отделениями (возможна работа в нескольких).
Отделения состоят из палат. Нужно получать сведения о расписании обследований,
о врачах и их участии в обследованиях, об отделениях и палатах.

### Сущности и атрибуты

| Таблица | Атрибуты | PK |
|---|---|---|
| **departments** | department_name (UNIQUE), building, floor (CHECK > 0) | department_id |
| **doctors** | doctor_fullname, specialization, phone (UNIQUE), hire_date | doctor_id |
| **doctor_departments** | is_primary | (doctor_id, department_id) |
| **wards** | ward_number, capacity (CHECK > 0), ward_type, department_id | ward_id |
| **examinations** | examination_name, day_of_week (1..7), time_start, time_end, room | examination_id |
| **doctor_examinations** | — | (doctor_id, examination_id) |

### Связи и кардинальность

| Связь | Тип |
|---|---|
| departments -> wards | 1:M |
| departments <-> doctors | M:N (через `doctor_departments`) |
| doctors <-> examinations | M:N (через `doctor_examinations`) |

### Ответы на вопросы для проработки (Часть I)

1. **День недели + время в одной таблице?** Да, в одной — `examinations`.
   Это атомарные атрибуты одного факта «обследование». Вынос в отдельные таблицы
   создал бы лишние JOIN и не дал выигрыша в нормализации.
2. **Одно обследование несколько раз в неделю?** Да, если это разные слоты.
   В модели это отражается как несколько строк с одинаковым `examination_name`,
   но разными `(day_of_week, time_start)`. UNIQUE — на тройку
   `(examination_name, day_of_week, time_start)`.
3. **Врач в нескольких обследованиях / несколько врачей на обследовании?**
   Да, оба случая — M:N через `doctor_examinations`.
4. **Врач обязательно привязан к отделению? Может работать в нескольких?**
   В модели — да, привязан (через `doctor_departments`). Может работать в нескольких —
   поле `is_primary` помечает основное отделение.
5. **`time_start < time_end`?** Ограничение `CHECK (time_start < time_end)`.
6. **Уникальные поля:** `department_name`, `phone`, `(department_id, ward_number)`,
   `(examination_name, day_of_week, time_start)`.
7. **Расширение модели:** кабинеты/оборудование/пациенты/результаты легко добавляются
   как отдельные таблицы и связи M:N без изменения существующих.

### Нормализация
- **1НФ** — все атрибуты атомарны, нет повторяющихся групп.
- **2НФ** — каждый неключевой атрибут зависит от полного PK. В связующих таблицах
  дополнительных атрибутов почти нет (`is_primary` зависит от полного PK).
- **3НФ** — нет транзитивных зависимостей. Отделения вынесены отдельно,
  принадлежность врача к отделению — в связке (врач может быть в нескольких).

### Ограничения целостности
- `NOT NULL` — обязательные поля.
- `UNIQUE` — названия отделений, телефон врача, номер палаты внутри отделения,
  расписание обследования.
- `CHECK` — этаж > 0, вместимость > 0, `day_of_week BETWEEN 1 AND 7`, `time_start < time_end`.
- `FOREIGN KEY ... ON DELETE CASCADE` — во всех связях.

### SQL-запросы (9 шт.)
Файл `sql/03_queries.sql`:
1. Список всех обследований с днём недели и временем
2. Врачи конкретного обследования (ЭКГ)
3. Расписание на заданный день недели
4. Врачи с указанием отделений
5. Отделения и количество палат
6. Обследования после заданного времени
7. Врачи, участвующие более чем в одном обследовании
8. Обследования заданного врача
9. Палаты заданного отделения

---

## Часть II. Историчность (SCD Type 2)

### Что версионируется и почему

| Сущность | Решение | Обоснование |
|---|---|---|
| **doctors** (поля `doctor_fullname`, `specialization`, `phone`) | SCD Type 2 | Смена ФИО, специализации, телефона — значимые события, важные для аудита и для восстановления состояния на любую дату. |
| **doctor_departments** | не версионируется | В этом проекте принадлежность к отделу отслеживается через основную таблицу `doctors`; при необходимости легко расширить SCD-механизмом. |
| **departments** | не версионируется | Справочник, меняется редко. Актуального состояния достаточно. |
| **wards** | не версионируется | Палаты меняются редко; при расширении задания — можно добавить историю. |
| **examinations** | не версионируется | Расписание стабильно; история расписания не входит в обязательные запросы. |
| **doctor_examinations** | не версионируется | Факт «врач проводит обследование» — в этом проекте стабилен; для полноты можно расширить. |

**Type 3 не выбран** (хранение только предыдущего значения): он не даёт полной
истории — только одну предыдущую версию, что неприемлемо для аудита за год.

### Схема исторической таблицы `doctors_history`

| Поле | Тип | Смысл |
|---|---|---|
| `version_id` | SERIAL PK | Суррогатный ключ версии |
| `doctor_id` | INTEGER | Бизнес-ключ (ссылка на `doctors`) |
| `doctor_fullname` | VARCHAR(150) | Снимок |
| `specialization` | VARCHAR(100) | Снимок |
| `phone` | VARCHAR(20) | Снимок |
| `hire_date` | DATE | Снимок |
| `valid_from` | TIMESTAMP | Начало действия версии |
| `valid_to` | TIMESTAMP | Конец действия (NULL = открытый) |
| `is_current` | BOOLEAN | Признак актуальности |
| `operation` | VARCHAR(10) | INSERT / UPDATE / DELETE |

### Ограничения истории
- `CHECK (valid_to IS NULL OR valid_from < valid_to)`
- `CHECK` согласованности `is_current` и `valid_to`
- **Частичный UNIQUE** `uq_doctors_history_current` — одна текущая версия на врача
- **EXCLUDE USING gist** `ex_doctors_history_no_overlap` — интервалы версий одного врача не пересекаются (требуется расширение `btree_gist`)

### Триггер
Единый `AFTER INSERT OR UPDATE OR DELETE` на `doctors` -> функция `fn_doctors_scd()`:
- INSERT — заводит первую версию
- UPDATE — закрывает старую (`valid_to = NOW()`, `is_current = FALSE`), открывает новую
- DELETE — логически закрывает текущую (физическое удаление только в `doctors`)

### Ответы на вопросы для проработки (Часть II)

1. **Бизнес-ключ vs ключ версии.** Бизнес-ключ (`doctor_id`) идентифицирует сущность
   и одинаков у всех её версий. Ключ версии (`version_id`) — идентификатор состояния.
   PK исторической таблицы не может быть `doctor_id`, потому что у одного врача
   много строк-версий.
2. **Открытый vs закрытый интервал.** Закрытый интервал (`valid_to` = дата) удобен
   для срезов «на дату X»: `valid_from <= X AND valid_to > X`. Открытый (`NULL`)
   для текущей — проще искать «где сейчас работает» (`is_current = TRUE`).
3. **Зачем `is_current`, если есть `valid_from/valid_to`?** Удобство и производительность:
   быстрый поиск текущей версии через частичный индекс; страховка от логических ошибок.
4. **Почему триггер, а не приложение?** Гарантирует, что история пишется всегда,
   независимо от клиента и языка. Плюс транзакционность и целостность.
5. **Как гарантировать одну текущую версию?** Частичный UNIQUE
   `UNIQUE (doctor_id) WHERE is_current = TRUE` + EXCLUDE на пересечение интервалов.
6. **Версионировать ли справочники?** Обычно нет: справочники стабильны,
   их история — избыточна и дорога.
7. **Версионирование M:N-связи.** Период действия хранится в самой связующей таблице
   (а не в родителях).
8. **DELETE родителя.** В исторической таблице — только логическое закрытие
   (`valid_to = NOW()`, `is_current = FALSE`, `operation = DELETE`).
9. **Масштабирование.** В будущем потребуют истории: `patients`, `examination_results`,
   `equipment`. А справочники (`ward_types`, дни недели) — нет.

---

## Структура проекта

hospital-db/
  sql/
    01_schema.sql     — создание таблиц (Часть I)
    02_data.sql       — тестовые данные
    03_queries.sql    — 9 SQL-запросов
    04_scd.sql        — историческая таблица + триггер (Часть II)
    05_scd_demo.sql   — демонстрация SCD (INSERT/UPDATE/DELETE)
    06_scd_slice.sql  — запрос-срез «кто проводил обследование на дату X»
  README.md
  .gitignore

## Запуск

docker run -d --name postgres-db -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=shopdb -p 5432:5432 -v postgres-data:/var/lib/postgresql/data postgres:18

# Загрузка скриптов
docker cp .\sql\01_schema.sql    postgres-db:/tmp/01_schema.sql
docker cp .\sql\02_data.sql      postgres-db:/tmp/02_data.sql
docker cp .\sql\03_queries.sql   postgres-db:/tmp/03_queries.sql
docker cp .\sql\04_scd.sql       postgres-db:/tmp/04_scd.sql
docker cp .\sql\05_scd_demo.sql  postgres-db:/tmp/05_scd_demo.sql
docker cp .\sql\06_scd_slice.sql postgres-db:/tmp/06_scd_slice.sql

docker exec postgres-db sh -c "sed -i '1s/^\xEF\xBB\xBF//' /tmp/*.sql"

docker exec postgres-db psql -U postgres -d shopdb -f /tmp/01_schema.sql
docker exec postgres-db psql -U postgres -d shopdb -f /tmp/02_data.sql
docker exec postgres-db psql -U postgres -d shopdb -f /tmp/03_queries.sql
docker exec postgres-db psql -U postgres -d shopdb -f /tmp/04_scd.sql
docker exec postgres-db psql -U postgres -d shopdb -f /tmp/05_scd_demo.sql
docker exec postgres-db psql -U postgres -d shopdb -f /tmp/06_scd_slice.sql

## Автор
[lina09156](https://github.com/lina09156)
