create database Customers_transactions;
SET SQL_SAFE_UPDATES = 0;
UPDATE customers
SET Gender = NULL
WHERE Gender = '';
UPDATE customers
SET Age = NULL
WHERE Age = '';
ALTER TABLE customers MODIFY AGE INT NULL;
select * from Transactions;

create table Transactions 
(data_new date,
Id_check int,
ID_client int,
Count_products decimal (10,3),
Sum_payment decimal (10,2));

load data infile "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\TRANSACTIONS_final.csv.csv"
INTO TABLE Transactions 
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 

WITH MonthlyTransactions AS (
    SELECT
        ID_client,
        DATE_FORMAT(data_new, '%Y-%m') AS month_year
    FROM Transactions
    WHERE data_new BETWEEN '2015-06-01' AND '2016-05-31'
    GROUP BY ID_client, month_year
),
ClientsWithFullHistory AS (
    SELECT
        ID_client
    FROM MonthlyTransactions
    GROUP BY ID_client
    HAVING COUNT(DISTINCT month_year) = 12
)
SELECT * FROM ClientsWithFullHistory;

SELECT
    ID_client,
    AVG(Sum_payment) AS avg_check
FROM Transactions
WHERE data_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY ID_client;

SELECT
    ID_client,
    SUM(Sum_payment) / 12 AS avg_monthly_purchase
FROM Transactions
WHERE data_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY ID_client;

SELECT
    ID_client,
    COUNT(*) AS total_operations
FROM Transactions
WHERE data_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY ID_client;

SELECT 
    DATE_FORMAT(t.data_new, '%Y-%m') AS month,
    AVG(t.Sum_payment) AS avg_check_amount,
    COUNT(t.Id_check) / COUNT(DISTINCT t.ID_client) AS avg_operations_per_month,
    COUNT(DISTINCT t.ID_client) AS avg_clients_per_month,
    COUNT(t.Id_check) / (SELECT COUNT(*) FROM Transactions) AS operations_share_year,
    SUM(t.Sum_payment) / (SELECT SUM(Sum_payment) FROM Transactions) AS sum_share_year,
    SUM(CASE WHEN c.Gender = 'M' THEN t.Sum_payment ELSE 0 END) / SUM(t.Sum_payment) AS male_share,
    SUM(CASE WHEN c.Gender = 'F' THEN t.Sum_payment ELSE 0 END) / SUM(t.Sum_payment) AS female_share,
    SUM(CASE WHEN c.Gender IS NULL THEN t.Sum_payment ELSE 0 END) / SUM(t.Sum_payment) AS na_share
FROM 
    Transactions t
JOIN 
    customers c ON t.ID_client = c.Id_client
GROUP BY 
    month
ORDER BY 
    month;
    
    WITH AgeGroups AS (
    SELECT 
        CASE 
            WHEN Age IS NULL THEN 'Не указано'
            WHEN Age < 10 THEN '0-9'
            WHEN Age < 20 THEN '10-19'
            WHEN Age < 30 THEN '20-29'
            WHEN Age < 40 THEN '30-39'
            WHEN Age < 50 THEN '40-49'
            WHEN Age < 60 THEN '50-59'
            WHEN Age < 70 THEN '60-69'
            WHEN Age < 80 THEN '70-79'
            ELSE '80+'
        END AS Age_Group,
        COUNT(t.Id_check) AS Total_Transactions,
        SUM(t.Sum_payment) AS Total_Sum
    FROM 
        customers c
    LEFT JOIN 
        Transactions t ON c.Id_client = t.ID_client
    GROUP BY 
        Age_Group
)

SELECT * FROM AgeGroups;


WITH QuarterlyData AS (
    SELECT 
        DATE_FORMAT(t.data_new, '%Y-%m-01') + INTERVAL (QUARTER(t.data_new) - 1) * 3 MONTH AS Quarter,
        COUNT(t.Id_check) AS Total_Transactions,
        SUM(t.Sum_payment) AS Total_Sum
    FROM 
        Transactions t
    GROUP BY 
        Quarter
)
SELECT 
    Quarter,
    AVG(Total_Transactions) AS Avg_Transactions,
    AVG(Total_Sum) AS Avg_Sum,
    (AVG(Total_Sum) / NULLIF(SUM(Total_Sum), 0)) * 100 AS Percentage
FROM 
    QuarterlyData
GROUP BY 
    Quarter;