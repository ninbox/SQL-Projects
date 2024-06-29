-- CREATION OF DATABASE AND TABLES__________________

DROP DATABASE IF EXISTS `Bradford_Council`;
CREATE DATABASE `Bradford_Council`;
USE `Bradford_Council`;


CREATE TABLE workers_demographics (
  employee_id INT NOT NULL,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  age INT,
  gender VARCHAR(10),
  birth_date DATE,
  PRIMARY KEY (employee_id)
);

INSERT INTO workers_demographics (employee_id, first_name, last_name, age, gender, birth_date)
VALUES
(1,'Leslie', 'Knope', 44, 'Female','1979-09-25'),
(3,'Tom', 'Haverford', 36, 'Male', '1987-03-04'),
(4, 'April', 'Ludgate', 29, 'Female', '1994-03-27'),
(5, 'Jerry', 'Gergich', 61, 'Male', '1962-08-28'),
(6, 'Donna', 'Meagle', 46, 'Female', '1977-07-30'),
(7, 'Ann', 'Perkins', 35, 'Female', '1988-12-01'),
(8, 'Chris', 'Traeger', 43, 'Male', '1980-11-11'),
(9, 'Ben', 'Wyatt', 38, 'Male', '1985-07-26'),
(10, 'Andy', 'Dwyer', 34, 'Male', '1989-03-25'),
(11, 'Mark', 'Brendanawicz', 40, 'Male', '1983-06-14'),
(12, 'Craig', 'Middlebrooks', 37, 'Male', '1986-07-27');

CREATE TABLE workers_salary (
  employee_id INT NOT NULL,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  occupation VARCHAR(50),
  salary INT,
  dept_id INT
);

INSERT INTO workers_salary (employee_id, first_name, last_name, occupation, salary, dept_id)
VALUES
(1, 'Leslie', 'Knope', 'Deputy Director of Parks and Recreation', 75000,1),
(2, 'Ron', 'Swanson', 'Director of Parks and Recreation', 70000,1),
(3, 'Tom', 'Haverford', 'Entrepreneur', 50000,1),
(4, 'April', 'Ludgate', 'Assistant to the Director of Parks and Recreation', 25000,1),
(5, 'Jerry', 'Gergich', 'Office Manager', 50000,1),
(6, 'Donna', 'Meagle', 'Office Manager', 60000,1),
(7, 'Ann', 'Perkins', 'Nurse', 55000,4),
(8, 'Chris', 'Traeger', 'City Manager', 90000,3),
(9, 'Ben', 'Wyatt', 'State Auditor', 70000,6),
(10, 'Andy', 'Dwyer', 'Shoe Shiner and Musician', 20000, NULL),
(11, 'Mark', 'Brendanawicz', 'City Planner', 57000, 3),
(12, 'Craig', 'Middlebrooks', 'Parks Director', 65000,1);


CREATE TABLE workers_departments (
  department_id INT NOT NULL AUTO_INCREMENT,
  department_name varchar(50) NOT NULL,
  PRIMARY KEY (department_id)
);

INSERT INTO workers_departments (department_name)
VALUES
('Parks and Recreation'),
('Animal Control'),
('Public Works'),
('Healthcare'),
('Library'),
('Finance');


SELECT *
FROM bradford_council.workers_demographics
;

SELECT *
FROM bradford_council.workers_salary
;

SELECT *
FROM bradford_council.workers_departments
;

# example a party council send a memo do determine employees new year salary and bonuses
-- condition
-- salary > 50000 = 7%
-- salary < 50000 = 5%
-- in finance dept = 10%
SELECT first_name, last_name, salary,
CASE
	WHEN salary > 50000 THEN salary + (salary * 0.07)
    WHEN salary < 50000 THEN salary + (salary * 0.05)
END AS new_salary,
CASE
	 WHEN dept_id = 6 THEN salary * 0.1
END AS bonus
FROM workers_salary AS sal
JOIN workers_departments AS dp
	ON sal.dept_id = dp.department_id
;

WITH CTE_example AS
(
SELECT employee_id, first_name, last_name, salary,
CASE
	WHEN salary > 50000 THEN salary + (salary * 0.07)
    WHEN salary < 50000 THEN salary + (salary * 0.05)
END AS new_salary,
CASE
	 WHEN dept_id = 6 THEN salary * 0.1
END AS bonus
FROM workers_salary AS sal
JOIN workers_departments AS dp
	ON sal.dept_id = dp.department_id
)
SELECT *
FROM CTE_Example
;


USE Bradford_Council;
DROP procedure IF EXISTS procedure1;
DELIMITER $$
CREATE PROCEDURE procedure1( p_employee_id INT)
BEGIN
	SELECT first_name, last_name, salary,
CASE
	WHEN salary > 50000 THEN salary + (salary * 0.07)
    WHEN salary < 50000 THEN salary + (salary * 0.05)
END AS new_salary,
CASE
	 WHEN dept_id = 6 THEN salary * 0.1
     ELSE 0
END AS bonus
FROM workers_salary AS sal
JOIN workers_departments AS dp
	ON sal.dept_id = dp.department_id
WHERE employee_id = p_employee_id;

END $$
DELIMITER ;

CALL  procedure1(1);


