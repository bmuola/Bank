CREATE SCHEMA CUSTOMERS;
CREATE SCHEMA DATA;

CREATE TABLE bank.customers.churn_records (
    RowNumber FLOAT,
    CustomerId FLOAT PRIMARY KEY,
    Surname VARCHAR(255),
    Credit_Score INT,
    Geography VARCHAR(120),
    Gender VARCHAR(120),
    Age INT,
    Tenure INT,
    Balance FLOAT,
    Num_Of_Products INT,
    Has_CrCard INT,
    Is_Active_Member INT,
    Estimated_Salary FLOAT,
    Exited INT,
    Complain INT,
    Satisfaction_Score INT,
    Card_Type VARCHAR(120),
    Points_Earned FLOAT
);

COPY bank.customers.churn_records
FROM 'C:\Users\Ben\Downloads\archive (4)\Customer-Churn-Records.csv' DELIMITER ',' CSV HEADER;

SELECT *
FROM bank.customers.churn_records
LIMIT 10;

--Cleaning the dataset
ALTER TABLE bank.customers.churn_records
DROP COLUMN rownumber;

DELETE FROM bank.customers.churn_records
WHERE
    surname ~ '[^a-zA-Z]' -- Matches any row where "surname" contains numbers & special characters
    OR
    length(surname) < 2 -- Matches any row where "surname" has less than 2 characters
    OR
    CustomerID IS NULL; -- Matches any row where "CustomerID" is NULL

--Lets now separate the data into different schemas based on geography

CREATE SCHEMA FRANCE;

CREATE TABLE bank.france.customers AS
        SELECT *
        FROM bank.customers.churn_records
        WHERE geography = 'France';

SELECT *
FROM bank.france.customers
LIMIT 10; 

ALTER TABLE bank.france.customers
DROP COLUMN geography

CREATE SCHEMA SPAIN;

CREATE TABLE bank.spain.customers AS
        SELECT *
        FROM bank.customers.churn_records
        WHERE geography LIKE 'Spain'

ALTER TABLE bank.spain.customers
DROP COLUMN geography

SELECT *
FROM bank.spain.customers
LIMIT 10; 

CREATE SCHEMA GERMANY;

CREATE TABLE bank.germany.customers AS
        SELECT *
        FROM bank.customers.churn_records
        WHERE geography LIKE 'Germany'

ALTER TABLE bank.germany.customers
DROP COLUMN geography

SELECT *
FROM bank.germany.customers
LIMIT 10; 

SELECT DISTINCT geography
FROM bank.customers.churn_records



--Find out list of high_value_clients we have in each country
--Individuals with an excelent credit score and have an income of above $100K and an account balance of above $50K
WITH high_value_clients AS(
SELECT CustomerID,
        Surname,
        Credit_Score,
        Estimated_salary,
        Balance,
        'Germany' AS Country
FROM bank.germany.customers
WHERE estimated_salary >= 100000 AND balance >= 50000 AND credit_score >= 700

UNION ALL

SELECT CustomerID,
        Surname,
        Credit_Score,
        Estimated_salary,
        Balance,
        'Spain' AS Country
FROM bank.spain.customers
WHERE estimated_salary >= 100000 AND balance >= 50000 AND credit_score >= 700

UNION ALL

SELECT CustomerID,
        Surname,
        Credit_Score,
        Estimated_salary,
        Balance,
        'France' AS Country
FROM bank.france.customers
WHERE estimated_salary >= 100000 AND balance >= 50000 AND credit_score >= 700
)
SELECT *
FROM high_value_clients
ORDER BY credit_score DESC;

--Out of this list, whoever uses more 2 or more of our products should be added 50 extra points

UPDATE bank.germany.customers
SET points_earned = points_earned + 50
WHERE estimated_salary >= 100000 AND balance >= 50000 AND credit_score >= 700

UPDATE bank.spain.customers
SET points_earned = points_earned + 50
WHERE estimated_salary >= 100000 AND balance >= 50000 AND credit_score >= 700

UPDATE bank.france.customers
SET points_earned = points_earned + 50
WHERE estimated_salary >= 100000 AND balance >= 50000 AND credit_score >= 700

--Lets now look into the issue of exiting customers 
--Lets see how many customers we lost and how many clients we have lost and we'll look into the number of complaints launched together with the satisfaction level


CREATE VIEW bank.data.exited AS(
SELECT 'Germany' AS Country,
        CustomerID,
        Surname,
        complain,
        Satisfaction_score
FROM bank.germany.customers
WHERE exited = 1

UNION

SELECT 'Spain' AS Country,
        CustomerID,
        Surname,
        complain,
        Satisfaction_score
FROM bank.spain.customers
WHERE exited = 1

UNION

SELECT 'France' AS Country,
        CustomerID,
        Surname,
        complain,
        Satisfaction_score
FROM bank.france.customers
WHERE exited = 1
);
