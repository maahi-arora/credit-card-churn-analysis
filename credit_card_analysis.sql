-- ================================================
-- Project: Credit Card Churn Analysis
-- Tools: MySQL, Advanced Excel
-- Dataset: BankChurners.csv (Kaggle)
-- Author: Maahi Arora
-- Date: March 2026
-- Description: End-to-end churn analysis to identify
--              key drivers of customer attrition
--              for a credit card business
-- ================================================

USE credit_card_analysis;

-- ================================================
-- SECTION 1: DATA EXPLORATION
-- ================================================

SELECT 
COUNT(*) AS total_rows,
COUNT(DISTINCT ï»¿CLIENTNUM) AS unique_customers
FROM bankchurners;

SELECT 
    SUM(CASE WHEN Attrition_Flag IS NULL THEN 1 ELSE 0 END) AS null_attrition,
    SUM(CASE WHEN Customer_Age IS NULL THEN 1 ELSE 0 END) AS null_age,
    SUM(CASE WHEN Gender IS NULL THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN Income_Category IS NULL THEN 1 ELSE 0 END) AS null_income,
    SUM(CASE WHEN Card_Category IS NULL THEN 1 ELSE 0 END) AS null_card,
    SUM(CASE WHEN Marital_Status IS NULL THEN 1 ELSE 0 END) AS null_marital,
    SUM(CASE WHEN Education_Level IS NULL THEN 1 ELSE 0 END) AS null_education
FROM bankchurners;

SELECT DISTINCT Marital_Status FROM bankchurners;

SELECT DISTINCT Education_Level FROM bankchurners;

SELECT DISTINCT Income_Category FROM bankchurners;

SELECT DISTINCT Card_Category FROM bankchurners;

SELECT COUNT(*) AS total_customers 
FROM bankchurners;

-- ================================================
-- SECTION 2: CHURN ANALYSIS BY DEMOGRAPHICS
-- ================================================

-- Overall churn rate across all 10,127 customers
SELECT 
  Attrition_Flag,
  COUNT(*) AS customer_count,
  ROUND(COUNT(*)*100/ (SELECT COUNT(*) FROM bankchurners),2) AS percentage
FROM bankchurners
GROUP BY Attrition_Flag;


-- Churn rate breakdown by card category (Blue, Silver, Gold, Platinum)
SELECT
  Card_Category,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN Attrition_Flag='Attrited Customer' THEN 1 ELSE 0 END) AS churned,
  ROUND(SUM(CASE WHEN Attrition_Flag='Attrited Customer' THEN 1 ELSE 0 END)*100/COUNT(*),2) AS churn_rate 
FROM bankchurners
GROUP BY Card_Category
ORDER BY churn_rate DESC;


-- Churn rate breakdown by customer income category
SELECT
Income_Category,
COUNT(*) AS total_customers,
SUM(CASE WHEN Attrition_Flag='Attrited Customer' THEN 1 ELSE 0 END) AS churned,
ROUND((SUM(CASE WHEN Attrition_Flag='Attrited Customer' THEN 1 ELSE 0 END))*100/ COUNT(*),2) AS churn_rate
FROM bankchurners
GROUP BY Income_Category
ORDER BY churn_rate DESC;


-- Churn rate breakdown by gender
SELECT
Gender,
COUNT(*) AS total_Customers,
SUM(CASE WHEN Attrition_Flag='Attrited Customer' THEN 1 ELSE 0 END) AS churned,
ROUND((SUM(CASE WHEN Attrition_Flag='Attrited Customer' THEN 1 ELSE 0 END)*100)/COUNT(*), 2) AS churn_rate
FROM bankchurners
GROUP BY Gender
ORDER BY churn_rate DESC;


-- Churn rate breakdown by education level
SELECT
Education_Level,
COUNT(*) AS total_customers,
SUM(CASE WHEN Attrition_Flag='Attrited Customer' THEN 1 ELSE 0 END) AS churned,
ROUND(SUM(CASE WHEN Attrition_Flag='Attrited Customer' THEN 1 ELSE 0 END)*100/COUNT(*), 2) AS churn_rate
FROM bankchurners
GROUP BY Education_Level
ORDER BY churn_rate DESC;


-- Churn rate breakdown by age group
SELECT
 CASE 
    WHEN Customer_Age<30 THEN 'Under 30'
    WHEN Customer_Age BETWEEN 30 AND 40 THEN '30-40'
    WHEN Customer_Age BETWEEN 41 AND 50 THEN '41-50'
    WHEN Customer_Age BETWEEN 51 AND 60 THEN '51-60'
    ELSE 'Above 60'
    END 
AS Age_Group,
COUNT(*) AS total_customers,
SUM(CASE WHEN Attrition_Flag='Attrited Customer' THEN 1 ELSE 0 END) AS churned,
ROUND(SUM(CASE WHEN Attrition_Flag='Attrited Customer' THEN 1 ELSE 0 END)*100/COUNT(*), 2) AS churn_rate
FROM bankchurners
GROUP BY Age_Group
ORDER BY churn_rate DESC;


-- ================================================
-- SECTION 3: BEHAVIOURAL ANALYSIS
-- ================================================

-- Comparing transaction behaviour between churned and existing customers
SELECT 
    Attrition_Flag,
    ROUND(AVG(Total_Trans_Amt), 2) AS avg_transaction_amount,
    ROUND(AVG(Total_Trans_Ct), 2) AS avg_transaction_count,
    ROUND(AVG(Total_Revolving_Bal), 2) AS avg_revolving_balance,
    ROUND(AVG(Avg_Utilization_Ratio), 2) AS avg_utilization_ratio
FROM bankchurners
GROUP BY Attrition_Flag;


-- ================================================
-- SECTION 4: CUSTOMER SEGMENTATION
-- ================================================

-- Identifying 638 high risk existing customers showing early churn warning signs
SELECT
  ï»¿CLIENTNUM,
  Customer_Age,
  Gender,
  Income_Category,
  Card_Category,
  Credit_Limit,
  Total_Trans_Amt,
  Total_Trans_Ct,
  Avg_Utilization_Ratio
FROM bankchurners
WHERE Attrition_Flag='Existing Customer'
AND Total_Trans_Amt < (SELECT AVG(Total_Trans_Amt) FROM bankchurners WHERE Attrition_Flag='Attrited Customer')
AND Total_Trans_Ct < (SELECT AVG(Total_Trans_Ct) FROM bankchurners WHERE Attrition_Flag='Attrited Customer')
AND Avg_Utilization_Ratio < (SELECT AVG(Avg_Utilization_Ratio) FROM bankchurners WHERE Attrition_Flag='Attrited Customer')
ORDER BY Total_Trans_Amt;


-- Segmenting existing customers into 4 risk tiers using NTILE window function
SELECT 
    ï»¿CLIENTNUM,
    Card_Category,
    Income_Category,
    Total_Trans_Amt,
    Total_Trans_Ct,
    Avg_Utilization_Ratio,
    NTILE(4) OVER (ORDER BY Total_Trans_Amt ASC) AS risk_tier
FROM bankchurners
WHERE Attrition_Flag = 'Existing Customer';


SELECT
risk_tier,
COUNT(*) AS total_customers,
ROUND(AVG(Total_Trans_Amt),2) AS avg_transaction_amt,
ROUND(AVG(Total_Trans_Ct),2)AS avg_transaction_count,
ROUND(AVG(Avg_Utilization_Ratio),2) AS avg_utilization
FROM
 (SELECT 
    ï»¿CLIENTNUM,
    Card_Category,
    Income_Category,
    Total_Trans_Amt,
    Total_Trans_Ct,
    Avg_Utilization_Ratio,
    NTILE(4) OVER (ORDER BY Total_Trans_Amt ASC) AS risk_tier
FROM bankchurners
WHERE Attrition_Flag = 'Existing Customer') AS tiered_customers
GROUP BY risk_tier
ORDER BY risk_tier;


-- ================================================
-- SECTION 5: EARLY WARNING INDICATORS
-- ================================================

-- Churn rate by number of inactive months in last 12 months
SELECT 
    Months_Inactive_12_mon,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM bankchurners
GROUP BY Months_Inactive_12_mon
ORDER BY Months_Inactive_12_mon;


-- Churn rate by number of times customer contacted the bank in last 12 months
SELECT 
    Contacts_Count_12_mon,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM bankchurners
GROUP BY Contacts_Count_12_mon
ORDER BY Contacts_Count_12_mon;









