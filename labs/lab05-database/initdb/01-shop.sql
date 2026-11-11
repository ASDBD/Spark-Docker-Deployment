-- Database di esempio "shop" caricato al primo avvio di MySQL
USE shop;
GRANT ALL PRIVILEGES ON shop.* TO 'spark'@'%';

CREATE TABLE customers (
  customer_id INT PRIMARY KEY,
  name        VARCHAR(50),
  city        VARCHAR(30),
  signup_date DATE
);

CREATE TABLE orders (
  order_id    INT PRIMARY KEY,
  customer_id INT,
  order_date  DATE,
  amount      DECIMAL(10,2),
  status      VARCHAR(12),
  INDEX (customer_id)
);

SET SESSION cte_max_recursion_depth = 20000;

INSERT INTO customers
WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 500)
SELECT n,
       CONCAT('Cliente_', LPAD(n, 3, '0')),
       ELT(1 + n % 6, 'Roma', 'Milano', 'Napoli', 'Torino', 'Bologna', 'Firenze'),
       DATE_ADD('2022-01-01', INTERVAL n * 2 DAY)
FROM seq;

INSERT INTO orders
WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 20000)
SELECT n,
       1 + (n * 7919) % 500,
       DATE_ADD('2024-01-01', INTERVAL n % 365 DAY),
       ROUND(5 + ((n * 37) % 1000) / 3.7, 2),
       ELT(1 + n % 4, 'NEW', 'PAID', 'SHIPPED', 'CANCELLED')
FROM seq;
