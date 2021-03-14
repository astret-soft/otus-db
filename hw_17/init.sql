CREATE TABLE customers (
  id SERIAL,
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
  building_number VARCHAR(50),
  PRIMARY KEY (id)
)

COPY customers (
  title,
  first_name,
  last_name,
  correspondence_language,
  birth_date,
  gender,
  marital_status,
  country,
  postal_code,
  region,
  city,
  street,
  building_number
) FROM '/data.csv' DELIMITER ',' CSV HEADER;

