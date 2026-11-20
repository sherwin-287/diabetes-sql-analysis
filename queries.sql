-- ten analysis queries; each block starts with "-- Qn:" and a question

-- Q1: How many patients are there, and what share has diabetes?
SELECT COUNT(*) AS patients,
       SUM(outcome) AS diabetic,
       ROUND(100.0 * AVG(outcome), 1) AS diabetic_pct
FROM patients;

-- Q2: Average clinical values for diabetic vs non-diabetic patients
SELECT outcome,
       COUNT(*) AS n,
       ROUND(AVG(age), 1) AS avg_age,
       ROUND(AVG(bmi), 2) AS avg_bmi,
       ROUND(AVG(blood_pressure), 1) AS avg_bp,
       ROUND(AVG(insulin), 1) AS avg_insulin,
       ROUND(AVG(diabetes_pedigree_function), 3) AS avg_pedigree
FROM patients
GROUP BY outcome;

-- Q3: Diabetes prevalence by age group (JOIN with the lookup table)
SELECT g.group_name,
       COUNT(*) AS n,
       SUM(p.outcome) AS diabetic,
       ROUND(100.0 * AVG(p.outcome), 1) AS prevalence_pct
FROM patients p
JOIN age_groups g ON p.age BETWEEN g.min_age AND g.max_age
GROUP BY g.group_name
ORDER BY g.min_age;

-- Q4: Prevalence by BMI group (CASE expression)
SELECT CASE WHEN bmi < 25 THEN 'Normal (<25)'
            WHEN bmi < 30 THEN 'Overweight (25-29.9)'
            ELSE 'Obese (30+)' END AS bmi_group,
       COUNT(*) AS n,
       ROUND(100.0 * AVG(outcome), 1) AS prevalence_pct
FROM patients
GROUP BY bmi_group
ORDER BY MIN(bmi);

-- Q5: Age group and BMI group together, keeping only groups with 20+ patients (HAVING)
SELECT age_group, bmi_group,
       COUNT(*) AS n,
       ROUND(100.0 * AVG(outcome), 1) AS prevalence_pct
FROM patient_profile
GROUP BY age_group, bmi_group
HAVING COUNT(*) >= 20
ORDER BY prevalence_pct DESC;

-- Q6: Ten highest-risk-looking patients: obese, over 50, high pedigree (filtering and ORDER BY)
SELECT patient_id, age, bmi, blood_pressure, insulin, diabetes_pedigree_function, outcome
FROM patients
WHERE bmi >= 30 AND age > 50 AND diabetes_pedigree_function > 0.6
ORDER BY bmi DESC
LIMIT 10;

-- Q7: Patients whose insulin is above the average for their own outcome group (correlated subquery)
SELECT COUNT(*) AS above_group_avg_insulin
FROM patients p
WHERE insulin > (SELECT AVG(insulin) FROM patients WHERE outcome = p.outcome);

-- Q8: Quartiles of BMI with prevalence (CTE and window function NTILE)
WITH ranked AS (
    SELECT outcome, bmi, NTILE(4) OVER (ORDER BY bmi) AS bmi_quartile
    FROM patients
)
SELECT bmi_quartile,
       ROUND(MIN(bmi), 1) AS bmi_from,
       ROUND(MAX(bmi), 1) AS bmi_to,
       COUNT(*) AS n,
       ROUND(100.0 * AVG(outcome), 1) AS prevalence_pct
FROM ranked
GROUP BY bmi_quartile;

-- Q9: Rank patients by insulin within each age group (window function RANK)
SELECT * FROM (
    SELECT age_group, patient_id, insulin,
           RANK() OVER (PARTITION BY age_group ORDER BY insulin DESC) AS insulin_rank
    FROM patient_profile
)
WHERE insulin_rank <= 3
ORDER BY age_group, insulin_rank;

-- Q10: Data-quality check: missing, impossible or inconsistent values
SELECT SUM(CASE WHEN bmi IS NULL OR insulin IS NULL THEN 1 ELSE 0 END) AS missing_values,
       SUM(CASE WHEN bmi < 10 OR bmi > 70 THEN 1 ELSE 0 END) AS implausible_bmi,
       SUM(CASE WHEN ABS(bmi - weight_kg / ((height_cm / 100.0) * (height_cm / 100.0))) > 0.1
                THEN 1 ELSE 0 END) AS bmi_mismatch
FROM patients;
