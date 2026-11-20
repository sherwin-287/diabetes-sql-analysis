-- Schema for the diabetes SQL project (SQLite)
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS age_groups;
DROP VIEW  IF EXISTS patient_profile;

CREATE TABLE patients (
    patient_id                  INTEGER PRIMARY KEY,
    age                         INTEGER NOT NULL CHECK (age BETWEEN 0 AND 120),
    height_cm                   REAL    NOT NULL,
    weight_kg                   REAL    NOT NULL,
    bmi                         REAL    NOT NULL,
    blood_pressure              INTEGER NOT NULL,      -- diastolic, mm Hg
    insulin                     INTEGER NOT NULL,
    diabetes_pedigree_function  REAL    NOT NULL,
    outcome                     INTEGER NOT NULL CHECK (outcome IN (0, 1))  -- 1 = diabetes
);

-- Lookup table used to demonstrate JOINs
CREATE TABLE age_groups (
    group_name TEXT PRIMARY KEY,
    min_age    INTEGER NOT NULL,
    max_age    INTEGER NOT NULL
);
INSERT INTO age_groups VALUES
    ('Under 40', 0, 39),
    ('40-59',   40, 59),
    ('60 and over', 60, 120);

-- View with derived columns
CREATE VIEW patient_profile AS
SELECT p.*,
       g.group_name AS age_group,
       CASE WHEN p.bmi < 25 THEN 'Normal'
            WHEN p.bmi < 30 THEN 'Overweight'
            ELSE 'Obese' END AS bmi_group
FROM patients p
JOIN age_groups g ON p.age BETWEEN g.min_age AND g.max_age;
