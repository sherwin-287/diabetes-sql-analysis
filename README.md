# Diabetes Risk Analysis with SQL

SQL analysis of the synthetic diabetes dataset used in my machine learning project
([Diabetes-risk-prediction](https://github.com/sherwin-287/Diabetes-risk-prediction)).
The data (500 synthetic patients, not real patient data) is loaded into a SQLite database and explored
with ten queries.

## What it covers
| SQL feature | Queries |
|---|---|
| Aggregates (`COUNT`, `SUM`, `AVG`), `GROUP BY` | Q1, Q2 |
| `JOIN` with a lookup table (`age_groups`) | Q3, Q5 |
| `CASE` expressions | Q4 |
| `HAVING` | Q5 |
| Filtering, `ORDER BY`, `LIMIT` | Q6 |
| Correlated subquery | Q7 |
| CTE and window functions (`NTILE`, `RANK`) | Q8, Q9 |
| Data-quality checks | Q10 |
| Table constraints (`CHECK`, `PRIMARY KEY`) and a `VIEW` | `schema.sql` |

## Files
- `schema.sql`: tables, constraints, lookup table and the `patient_profile` view
- `queries.sql`: the ten queries, each with the question it answers
- `run_project.py`: loads the Excel file into `diabetes.db`, runs all queries, writes `results.md`
- `results.md`: output of every query
- `synthetic_diabetes_dataset.xlsx`: the dataset

## How to run
```
python3 -m pip install -r requirements.txt
python3 run_project.py
```
Python 3.9+ is needed (SQLite 3.25+ for window functions, which ships with current Python).
To explore by hand: `sqlite3 diabetes.db` then paste any query from `queries.sql`.

## Example results

**Diabetes prevalence by age group** (query Q3, a JOIN with a lookup table)

| Age group | Patients | Diabetic | Prevalence |
|---|---|---|---|
| Under 40 | 139 | 26 | 18.7% |
| 40-59 | 260 | 99 | 38.1% |
| 60 and over | 101 | 61 | 60.4% |

**Prevalence by BMI group** (query Q4, a CASE expression)

| BMI group | Patients | Prevalence |
|---|---|---|
| Normal (under 25) | 129 | 16.3% |
| Overweight (25-29.9) | 174 | 28.7% |
| Obese (30+) | 197 | 58.4% |

All ten queries and their results are in [results.md](results.md).

## Main findings
- 186 of 500 patients (37.2%) have diabetes.
- Prevalence rises with age (18.7% under 40, 38.1% at 40-59, 60.4% at 60+) and with BMI
  (16.3% normal, 28.7% overweight, 58.4% obese).
- Combining both: patients aged 60+ with obesity have 81.3% prevalence, while none of the 46 patients
  under 40 with normal BMI have diabetes (this is a synthetic dataset, so it shows how the data was generated,
  not real clinical patterns).
- The data-quality check found no missing values and no BMI that disagrees with height and weight.

## What I learned
- How a window function such as `NTILE` or `RANK` differs from `GROUP BY`: it keeps every row while still comparing it with its group.
- How a CTE makes a long query easier to read, and how a correlated subquery compares each row with its own group's average.
- Why data-quality checks come first: I verified there were no missing values and that BMI matched height and weight before analysing anything.
- How to connect SQL with Python: a short script loads the Excel file into SQLite and runs every query.
