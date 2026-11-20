# Query results

## Q1: How many patients are there, and what share has diabetes?

```sql
SELECT COUNT(*) AS patients,
       SUM(outcome) AS diabetic,
       ROUND(100.0 * AVG(outcome), 1) AS diabetic_pct
FROM patients;
```

|   patients |   diabetic |   diabetic_pct |
|-----------:|-----------:|---------------:|
|        500 |        186 |           37.2 |


## Q2: Average clinical values for diabetic vs non-diabetic patients

```sql
SELECT outcome,
       COUNT(*) AS n,
       ROUND(AVG(age), 1) AS avg_age,
       ROUND(AVG(bmi), 2) AS avg_bmi,
       ROUND(AVG(blood_pressure), 1) AS avg_bp,
       ROUND(AVG(insulin), 1) AS avg_insulin,
       ROUND(AVG(diabetes_pedigree_function), 3) AS avg_pedigree
FROM patients
GROUP BY outcome;
```

|   outcome |   n |   avg_age |   avg_bmi |   avg_bp |   avg_insulin |   avg_pedigree |
|----------:|----:|----------:|----------:|---------:|--------------:|---------------:|
|         0 | 314 |      44.5 |     26.85 |     68.3 |          86   |          0.445 |
|         1 | 186 |      53.6 |     31.37 |     74.1 |         104.1 |          0.565 |


## Q3: Diabetes prevalence by age group (JOIN with the lookup table)

```sql
SELECT g.group_name,
       COUNT(*) AS n,
       SUM(p.outcome) AS diabetic,
       ROUND(100.0 * AVG(p.outcome), 1) AS prevalence_pct
FROM patients p
JOIN age_groups g ON p.age BETWEEN g.min_age AND g.max_age
GROUP BY g.group_name
ORDER BY g.min_age;
```

| group_name   |   n |   diabetic |   prevalence_pct |
|:-------------|----:|-----------:|-----------------:|
| Under 40     | 139 |         26 |             18.7 |
| 40-59        | 260 |         99 |             38.1 |
| 60 and over  | 101 |         61 |             60.4 |


## Q4: Prevalence by BMI group (CASE expression)

```sql
SELECT CASE WHEN bmi < 25 THEN 'Normal (<25)'
            WHEN bmi < 30 THEN 'Overweight (25-29.9)'
            ELSE 'Obese (30+)' END AS bmi_group,
       COUNT(*) AS n,
       ROUND(100.0 * AVG(outcome), 1) AS prevalence_pct
FROM patients
GROUP BY bmi_group
ORDER BY MIN(bmi);
```

| bmi_group            |   n |   prevalence_pct |
|:---------------------|----:|-----------------:|
| Normal (<25)         | 129 |             16.3 |
| Overweight (25-29.9) | 174 |             28.7 |
| Obese (30+)          | 197 |             58.4 |


## Q5: Age group and BMI group together, keeping only groups with 20+ patients (HAVING)

```sql
SELECT age_group, bmi_group,
       COUNT(*) AS n,
       ROUND(100.0 * AVG(outcome), 1) AS prevalence_pct
FROM patient_profile
GROUP BY age_group, bmi_group
HAVING COUNT(*) >= 20
ORDER BY prevalence_pct DESC;
```

| age_group   | bmi_group   |   n |   prevalence_pct |
|:------------|:------------|----:|-----------------:|
| 60 and over | Obese       |  48 |             81.3 |
| 60 and over | Overweight  |  32 |             56.3 |
| 40-59       | Obese       | 104 |             53.8 |
| Under 40    | Obese       |  45 |             44.4 |
| 40-59       | Overweight  |  94 |             27.7 |
| 40-59       | Normal      |  62 |             27.4 |
| 60 and over | Normal      |  21 |             19   |
| Under 40    | Overweight  |  48 |             12.5 |
| Under 40    | Normal      |  46 |              0   |


## Q6: Ten highest-risk-looking patients: obese, over 50, high pedigree (filtering and ORDER BY)

```sql
SELECT patient_id, age, bmi, blood_pressure, insulin, diabetes_pedigree_function, outcome
FROM patients
WHERE bmi >= 30 AND age > 50 AND diabetes_pedigree_function > 0.6
ORDER BY bmi DESC
LIMIT 10;
```

|   patient_id |   age |   bmi |   blood_pressure |   insulin |   diabetes_pedigree_function |   outcome |
|-------------:|------:|------:|-----------------:|----------:|-----------------------------:|----------:|
|          339 |    65 | 43.93 |               99 |        61 |                        0.763 |         1 |
|          167 |    62 | 42.44 |               84 |        67 |                        2.198 |         1 |
|          457 |    64 | 41.62 |               91 |       122 |                        0.739 |         1 |
|          127 |    70 | 38.91 |               56 |       102 |                        1.528 |         1 |
|          191 |    74 | 37.69 |               76 |        47 |                        0.629 |         1 |
|          444 |    68 | 37.01 |               57 |        83 |                        0.634 |         1 |
|           12 |    60 | 36.79 |               85 |        84 |                        1.181 |         1 |
|           31 |    80 | 36    |               89 |        96 |                        0.891 |         1 |
|          281 |    55 | 35.27 |               86 |       261 |                        0.853 |         1 |
|          370 |    61 | 34.17 |               80 |       106 |                        0.653 |         1 |


## Q7: Patients whose insulin is above the average for their own outcome group (correlated subquery)

```sql
SELECT COUNT(*) AS above_group_avg_insulin
FROM patients p
WHERE insulin > (SELECT AVG(insulin) FROM patients WHERE outcome = p.outcome);
```

|   above_group_avg_insulin |
|--------------------------:|
|                       201 |


## Q8: Quartiles of BMI with prevalence (CTE and window function NTILE)

```sql
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
```

|   bmi_quartile |   bmi_from |   bmi_to |   n |   prevalence_pct |
|---------------:|-----------:|---------:|----:|-----------------:|
|              1 |       17   |     24.8 | 125 |             16   |
|              2 |       24.9 |     28.6 | 125 |             22.4 |
|              3 |       28.6 |     32.3 | 125 |             48   |
|              4 |       32.3 |     44   | 125 |             62.4 |


## Q9: Rank patients by insulin within each age group (window function RANK)

```sql
SELECT * FROM (
    SELECT age_group, patient_id, insulin,
           RANK() OVER (PARTITION BY age_group ORDER BY insulin DESC) AS insulin_rank
    FROM patient_profile
)
WHERE insulin_rank <= 3
ORDER BY age_group, insulin_rank;
```

| age_group   |   patient_id |   insulin |   insulin_rank |
|:------------|-------------:|----------:|---------------:|
| 40-59       |          305 |       398 |              1 |
| 40-59       |           63 |       350 |              2 |
| 40-59       |          157 |       323 |              3 |
| 60 and over |          140 |       278 |              1 |
| 60 and over |          149 |       264 |              2 |
| 60 and over |           69 |       255 |              3 |
| Under 40    |          425 |       351 |              1 |
| Under 40    |          142 |       339 |              2 |
| Under 40    |          429 |       216 |              3 |


## Q10: Data-quality check: missing, impossible or inconsistent values

```sql
SELECT SUM(CASE WHEN bmi IS NULL OR insulin IS NULL THEN 1 ELSE 0 END) AS missing_values,
       SUM(CASE WHEN bmi < 10 OR bmi > 70 THEN 1 ELSE 0 END) AS implausible_bmi,
       SUM(CASE WHEN ABS(bmi - weight_kg / ((height_cm / 100.0) * (height_cm / 100.0))) > 0.1
                THEN 1 ELSE 0 END) AS bmi_mismatch
FROM patients;
```

|   missing_values |   implausible_bmi |   bmi_mismatch |
|-----------------:|------------------:|---------------:|
|                0 |                 0 |              0 |

