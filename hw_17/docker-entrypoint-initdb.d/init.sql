-- Создаем таблицу (временную) изначальную как в CSV
CREATE TEMP TABLE customer (
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

-- Копируем из CSV в нашу БД
COPY customer (
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
WITH
  DELIMITER ','
  CSV
  HEADER
  FORCE NOT NULL
    title,
    first_name,
    last_name,
    correspondence_language,
    gender,
    marital_status,
    country,
    postal_code,
    region,
    city,
    street,
    building_number;

-- Из написанного скрипта analyze.py (код boilerplate) узнаем какие поля лучше сделать отдельными сущностями, основавыясь на параметрах (делаем нормализацию)
-- * сколько разных значений для этого поля по сравнению с общим числом записей
-- * сколько разных значений (словарь values в analyze.json для каждого поля) и их распределение
-- * используем знание о таких сущностях как страны, улицы, и т.д. понимаем, что при небольшой БД можно их пока оставить как есть и не делать в отдельных сущностях,
--   но затем с ростом числа записей пойдут дублирования, поэтому выносим их так же в отдельные сущности заранее.
-- Создаем для них таблицы и загружаем в них уникальные значения:
-- ЗАМЕЧАНИЯ: скрипт необязателен, можно было импортировать CSV через pgAdmin или создавай временную таблицу с минимальными ограничениями на поля а далее
--            делать запросы в бд через SQL типа SELECT MAX(LEN(customer.поле)) FROM customer; или SELECT DISTINCT title FROM customer; и таким образом выбирая
--            делать запросы в бд через SQL типа SELECT MAX(LEN(customer.поле)) FROM customer; или SELECT DISTINCT title FROM customer; и таким образом выбирая
--            необходимые ограничения на модель с запасом на будущее.
CREATE TABLE title (
  id SERIAL PRIMARY KEY NOT NULL,
  value VARCHAR(50) NOT NULL
);
INSERT INTO title(value) SELECT DISTINCT customer.title FROM customer;

CREATE TABLE correspondence_language (
  id SERIAL PRIMARY KEY NOT NULL,
  value VARCHAR(2) NOT NULL
);
INSERT INTO correspondence_language(value) SELECT DISTINCT customer.correspondence_language FROM customer;

CREATE TABLE gender (
  id SERIAL PRIMARY KEY NOT NULL,
  value VARCHAR(20) NOT NULL
);
INSERT INTO gender(value) SELECT DISTINCT customer.gender FROM customer;

CREATE TABLE marital_status (
  id SERIAL PRIMARY KEY NOT NULL,
  value VARCHAR(20) NOT NULL
);
INSERT INTO marital_status(value) SELECT DISTINCT customer.marital_status FROM customer;

CREATE TABLE country (
  id SERIAL PRIMARY KEY NOT NULL,
  value VARCHAR(2) NOT NULL
);
INSERT INTO country(value) SELECT DISTINCT customer.country FROM customer;

CREATE TABLE postal_code (
  id SERIAL PRIMARY KEY NOT NULL,
  value VARCHAR(20) NOT NULL
);
INSERT INTO postal_code(value) SELECT DISTINCT customer.postal_code FROM customer;

CREATE TABLE region (
  id SERIAL PRIMARY KEY NOT NULL,
  value VARCHAR(20) NOT NULL
);
INSERT INTO region(value) SELECT DISTINCT customer.region FROM customer;

CREATE TABLE city (
  id SERIAL PRIMARY KEY NOT NULL,
  value VARCHAR(100) NOT NULL
);
INSERT INTO city(value) SELECT DISTINCT customer.city FROM customer;

CREATE TABLE street (
  id SERIAL PRIMARY KEY NOT NULL,
  value VARCHAR(500) NOT NULL
);
INSERT INTO street(value) SELECT DISTINCT customer.street FROM customer;

CREATE TABLE building_number (
  id SERIAL PRIMARY KEY NOT NULL,
  value VARCHAR(50) NOT NULL
);
INSERT INTO building_number(value) SELECT DISTINCT customer.building_number FROM customer;

-- Делаем декомпозицию. Сначало разобьем все на две сущности person и address и заполним их данными:
-- * Подготовим временную таблицу с частичной нормализацией для выделения сущностей.
-- * Создаем зависимые сущности address и person;
-- * При рефакторинге создаем foreignkey и индексы на поля, где это надо:
--   (или ставим их на будущее, если видим, что кардинальность будет распологать в скором будущем в планах БД при поиске к индексу, а не перебором:
--    в будущем это сэкономит время на создание индексов по этим полям, но если на данном этапе будет допущена ошибка, то БД будет отрабатывать
--    запросы медленне из-за неиспользуемых индексов (чтобы исключить это необходимо просматривать статистику и анализ
--    часто используемых запросов, чтобы оптимизировать БД на данный момент)):
-- * Добавляем необходимые отношения типа many-to-many, on-to-many и т.д.
-- * Завершаем импорт из CSV, создавая индексы и удаляя временные таблицы.

-- Создаем нормализованную (но не полностью) таблицу (временную) на основе таблицы customers и удаляем временную таблицу customers:
CREATE TEMP TABLE normalized_customers (
  id SERIAL PRIMARY KEY,
  title_id INT,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  correspondence_language_id INT,
  birth_date DATE,
  gender_id INT,
  marital_status_id INT,
  country_id INT,
  postal_code_id INT,
  region_id INT,
  city_id INT,
  street_id INT,
  building_number_id INT
);

INSERT INTO normalized_customers (
  -- поля, который мы не выделяем в отдельные сущности при нормализации
  first_name,
  last_name,
  birth_date,
  -- информация о человеке с сылками на сущности
  title_id,
  correspondence_language_id,
  gender_id,
  marital_status_id,
  -- информация о его расположении с сылками на сущности
  country_id,
  postal_code_id,
  region_id,
  city_id,
  street_id,
  building_number_id
)
SELECT
  -- поля, который мы не выделяем в отдельные сущности при нормализации
  customer.first_name,
  customer.last_name,
  customer.birth_date,
  -- информация о человеке с сылками на сущности
  (SELECT title.id FROM title WHERE title.value = customer.title),
  (SELECT correspondence_language.id FROM correspondence_language WHERE correspondence_language.value = customer.correspondence_language),
  (SELECT gender.id FROM gender WHERE gender.value = customer.gender),
  (SELECT marital_status.id FROM marital_status WHERE marital_status.value = customer.marital_status),
  -- информация о его расположении с сылками на сущности
  (SELECT country.id FROM country WHERE country.value = customer.country),
  (SELECT postal_code.id FROM postal_code WHERE postal_code.value = customer.postal_code),
  (SELECT region.id FROM region WHERE region.value = customer.region),
  (SELECT city.id FROM city WHERE city.value = customer.city),
  (SELECT street.id FROM street WHERE street.value = customer.street),
  (SELECT building_number.id FROM building_number WHERE building_number.value = customer.building_number)
FROM customer;

DROP TABLE customer;

-- Создаем сущность address на основе таблицы normalized_customers
CREATE TABLE address (
  id SERIAL PRIMARY KEY NOT NULL,
  country_id INT,
  CONSTRAINT fk_country
    FOREIGN KEY(country_id)
    REFERENCES country(id),
  postal_code_id INT,
  CONSTRAINT fk_postal_code
    FOREIGN KEY(postal_code_id)
    REFERENCES postal_code(id),
  region_id INT,
  CONSTRAINT fk_region
    FOREIGN KEY(region_id)
    REFERENCES region(id),
  city_id INT,
  CONSTRAINT fk_city
    FOREIGN KEY(city_id)
    REFERENCES city(id),
  street_id INT,
  CONSTRAINT fk_street
    FOREIGN KEY(street_id)
    REFERENCES street(id),
  building_number_id INT,
  CONSTRAINT fk_building_number
    FOREIGN KEY(building_number_id)
    REFERENCES building_number(id)
);

-- * Также для сущности person:
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

-- * Создаем many-to-many между адрессом и клиентом (если все же one-to-many, то person_id нужно добавить ограничение на уникальность: UNIQUE):
CREATE TABLE customer_to_address (
  person_id INT,
  CONSTRAINT fk_to_person
    FOREIGN KEY(person_id)
    REFERENCES person(id),
  address_id INT,
  CONSTRAINT fk_to_address
    FOREIGN KEY(address_id)
    REFERENCES address(id)
);

-- Заполняем таблицы person и address, связывая ее отношением many-to-many:
INSERT INTO address (
  country_id,
  postal_code_id,
  region_id,
  city_id,
  street_id,
  building_number_id
)
SELECT DISTINCT
  country_id,
  postal_code_id,
  region_id,
  city_id,
  street_id,
  building_number_id
FROM normalized_customers;

INSERT INTO person (
  title_id,
  first_name,
  last_name,
  correspondence_language_id,
  birth_date,
  gender_id,
  marital_status_id
)
SELECT DISTINCT
  title_id,
  first_name,
  last_name,
  correspondence_language_id,
  birth_date,
  gender_id,
  marital_status_id
FROM normalized_customers;

INSERT INTO customer_to_address (
  person_id,
  address_id
)
SELECT
  (
    SELECT person.id FROM person
      WHERE
        normalized_customers.first_name = person.first_name AND
        normalized_customers.last_name = person.last_name AND
        normalized_customers.birth_date = person.birth_date AND
        normalized_customers.correspondence_language_id = person.correspondence_language_id AND
        normalized_customers.gender_id = person.gender_id AND
        normalized_customers.marital_status_id = person.marital_status_id
  ),
  (
    SELECT address.id FROM address
      WHERE
        normalized_customers.country_id = address.country_id AND
        normalized_customers.postal_code_id = address.postal_code_id AND
        normalized_customers.region_id = address.region_id AND
        normalized_customers.city_id = address.city_id AND
        normalized_customers.street_id = address.street_id AND
        normalized_customers.building_number_id = address.building_number_id
  )
FROM normalized_customers;

-- Создем индексы над сущностями: