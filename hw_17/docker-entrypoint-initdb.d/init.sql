-- создаем БД изначальную как в CSV
CREATE TABLE customer (
  id SERIAL PRIMARY KEY,
  title VARCHAR(50),
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  correspondence_language VARCHAR(2),
  birth_date DATE,
  gender VARCHAR(20),
  marital_status VARCHAR(20),
  country VARCHAR(2),
  postal_code VARCHAR(20),
  region VARCHAR(50),
  city VARCHAR(100),
  street VARCHAR(500),
  building_number VARCHAR(50)
);

-- копируем из CSV в нашу БД
COPY customer(
  -- информация о человеке
  title,
  first_name,
  last_name,
  correspondence_language,
  birth_date,
  gender,
  marital_status,
  -- информация о его расположении
  country,
  postal_code,
  region,
  city,
  street,
  building_number
)
FROM '/docker-entrypoint-initdb.d/data.csv'
DELIMITER ','
CSV HEADER;

-- Из написанного скрипта analyze.py узнаем какие поля лучше сделать отдельными сущностями, основавыясь на параметрах (делаем нормализацию)
-- * сколько разных значений для этого поля по сравнению с общим числом записей
-- * сколько разных значений (словарь values в analyze.json для каждого поля) и их распределение
-- * используем знание о таких сущностях как страны, улицы, и т.д. понимаем, что для небольшой БД можно их пока оставить как есть и не делать как в БД ФИАС
-- Создаем для них таблицы и загружаем в них уникальные значения:
-- ЗАМЕЧАНИЯ: скрипт необязателен, можно было импортировать CSV через pgAdmin или создавай временную таблицу с минимальными ограничениями на поля а далее
--            делать запросы в бд через SQL типа SELECT MAX(LEN(customer.поле)) FROM customer; и таким образом выбирая необходимые ограничения на модель.
CREATE TABLE title (
  id SERIAL PRIMARY KEY,
  value VARCHAR(50)
);
INSERT INTO title(value) SELECT DISTINCT customer.title FROM customer;

CREATE TABLE correspondence_language (
  id SERIAL PRIMARY KEY,
  value VARCHAR(2)
);
INSERT INTO correspondence_language(value) SELECT DISTINCT customer.correspondence_language FROM customer;

CREATE TABLE gender (
  id SERIAL PRIMARY KEY,
  value VARCHAR(20)
);
INSERT INTO gender(value) SELECT DISTINCT customer.gender FROM customer;

CREATE TABLE marital_status (
  id SERIAL PRIMARY KEY,
  value VARCHAR(20)
);
INSERT INTO marital_status(value) SELECT DISTINCT customer.marital_status FROM customer;

CREATE TABLE country (
  id SERIAL PRIMARY KEY,
  value VARCHAR(2)
);
INSERT INTO country(value) SELECT DISTINCT customer.country FROM customer;

-- Делаем декомпозицию. Сначало разобьем все на две сущности person и address и заполним их данными:
-- * Начнем с адресов (маловероятно что будет по 100-500 person в одном месте, если только у нас не всемирная перепись,
--   но тогда нужно и адрес рефакторить - нормализовать все поля);
-- * При рефакторинге создаем foreignkey и индексы на поля, где это надо:
--   (или ставим их на будущее, если видим, что кардинальность будет распологать в скором будущем в планах БД при поиске к индексу, а не перебором:
--    в будущем это сэкономит время на создание индексов по этим полям, но если на данном этапе будет допущена ошибка, то БД будет отрабатывать
--    запросы медленне из-за неиспользуемых индексов (чтобы исключить это необходимо просматривать статистику и анализ
--    часто используемых запросов, чтобы оптимизировать БД на данный момент)):
CREATE TABLE address (
  id SERIAL PRIMARY KEY,
  country_id INT,
  CONSTRAINT fk_country
    FOREIGN KEY(country_id)
    REFERENCES country(id),
  postal_code VARCHAR(20),
  region VARCHAR(50),
  city VARCHAR(100),
  street VARCHAR(500),
  building_number VARCHAR(50)
);

INSERT INTO address (
  country_id,
  postal_code,
  region,
  city,
  street,
  building_number
)
SELECT
  (SELECT country.id FROM country WHERE country.value = customer.country),
  postal_code,
  region,
  city,
  street,
  building_number
FROM customer AS customer;

-- * Делаем декомпозицию с созданием таблицы person, связывая ее с созданной address и другими нормализованными ранее полями:
CREATE TABLE person (
  id SERIAL PRIMARY KEY,
  title_id INT,
  CONSTRAINT fk_title
    FOREIGN KEY(title_id)
    REFERENCES title(id),
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  correspondence_language_id INT,
  CONSTRAINT fk_correspondence_language
    FOREIGN KEY(correspondence_language_id)
    REFERENCES correspondence_language(id),
  birth_date DATE,
  gender_id INT,
  CONSTRAINT fk_gender
    FOREIGN KEY(gender_id)
    REFERENCES gender(id),
  marital_status_id INT,
  CONSTRAINT fk_marital_status
    FOREIGN KEY(marital_status_id)
    REFERENCES marital_status(id)
);

INSERT INTO person (
  title_id,
  first_name,
  last_name,
  correspondence_language_id,
  birth_date,
  gender_id,
  marital_status_id
)
SELECT
  (SELECT title.id FROM title WHERE title.value = customer.title),
  first_name,
  last_name,
  (SELECT correspondence_language.id FROM correspondence_language WHERE correspondence_language.value = customer.correspondence_language),
  birth_date,
  (SELECT gender.id FROM gender WHERE gender.value = customer.gender),
  (SELECT marital_status.id FROM marital_status WHERE marital_status.value = customer.marital_status)
FROM customer AS customer;

-- Создадим FTS (полнотекстовый поиск) над полями fts_address и fts_person, чтобы поиск можно было проводить из строки по нашим сущностям (address и person):
TODO
