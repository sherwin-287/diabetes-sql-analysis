"""Load the diabetes dataset into SQLite, run every query in queries.sql, save results.

Usage:  python3 run_project.py
Output: diabetes.db (database) and results.md (all query results)
"""
import re
import sqlite3
from pathlib import Path

import pandas as pd

HERE = Path(__file__).parent
DB = HERE / "diabetes.db"
XLSX = HERE / "synthetic_diabetes_dataset.xlsx"

COLS = {
    "Patient_ID": "patient_id", "Age": "age", "Height_cm": "height_cm", "Weight_kg": "weight_kg",
    "BMI": "bmi", "Blood_Pressure": "blood_pressure", "Insulin": "insulin",
    "Diabetes_Pedigree_Function": "diabetes_pedigree_function", "Outcome": "outcome",
}


def main():
    df = pd.read_excel(XLSX, sheet_name="Patient Data").rename(columns=COLS)[list(COLS.values())]
    con = sqlite3.connect(DB)
    con.executescript((HERE / "schema.sql").read_text())
    df.to_sql("patients", con, if_exists="append", index=False)
    print(f"Loaded {len(df)} rows into {DB.name}")

    text = (HERE / "queries.sql").read_text()
    blocks = re.split(r"^-- (Q\d+): ", text, flags=re.M)[1:]
    out = ["# Query results\n"]
    for name, body in zip(blocks[::2], blocks[1::2]):
        question, _, sql = body.partition("\n")
        result = pd.read_sql_query(sql.strip().rstrip(";"), con)
        out += [f"## {name}: {question}\n", "```sql", sql.strip(), "```\n", result.to_markdown(index=False), "\n"]
        print(f"{name}: {len(result)} row(s)")
    (HERE / "results.md").write_text("\n".join(out))
    con.close()
    print("Saved results.md")


if __name__ == "__main__":
    main()
