# 🛡️ Insurance Claim Fraud Detection

> End-to-end data analytics project — from raw dirty data to an interactive Power BI fraud dashboard.  
> Built using **Python · SQL · Power BI · Claude AI** on a synthetic group health insurance dataset.

---

## 📌 Project Overview

Group health insurance fraud is a growing challenge for TPAs (Third Party Administrators) and insurers in India. This project simulates a **real-world fraud detection pipeline** for 5 Indian corporates enrolled under a group mediclaim policy managed by **Medi Assist Insurance TPA Pvt. Ltd.**

The dataset covers **13,397 insured members** and **6,170 claims** across companies including Bharat Steel & Power Ltd, Sunrise Pharma Industries Ltd, IndoAgro Foods Pvt Ltd, Narmada Infrastructure Corp, and Deccan Textiles Ltd.

---

## 🏗️ Project Architecture

```
Raw Dirty Data
      │
      ▼
Claude AI ──── Data profiling, fraud pattern explanation, data dictionary
      │
      ▼
Python (pandas) ── Data cleaning, EDA, fraud scoring, visualisation
      │
      ▼
SQL (SQLite / SQL Server) ── Validation queries, fraud VIEW, window functions
      │
      ▼
Power BI ── 5-page interactive dashboard, DAX measures, conditional formatting
      │
      ▼
Insights & Recommendations
```

---

## 📁 Repository Structure

```
Insurance-Claim-Fraud-Detection/
│
├── data/
│   ├── claim_dirty.csv           # Raw uncleaned claim data (6,232 rows · intentional issues)
│   ├── member_dirty.csv          # Raw uncleaned member data (13,531 rows)
│   ├── claim_clean.csv           # Cleaned claim data (output of Python notebook)
│   └── member_clean.csv          # Cleaned member data
│
├── notebooks/
│   └── Claim_Fraud.ipynb         # Full Python EDA + cleaning + fraud analysis notebook
│
├── sql/
│   └── Claims_Fraud.sql          # All SQL queries — cleaning, fraud detection, VIEW creation
│
├── powerbi/
│   └── dashboard_screenshots/    # Screenshots of all 5 Power BI dashboard pages
│
├── assets/
│   └── Fraud_Detection_Dashboard.pdf   # Full presentation with insights (10 slides)
│
└── README.md
```

---

## 📊 Dataset Description

### claim_dirty.csv — 44 columns · 6,232 rows

| Column | Description |
|--------|-------------|
| `claim_id` | Unique claim identifier |
| `member_id` | Links to member table |
| `member_name` | Insured person's name |
| `gender` | Gender (contains dirty values: M/F/male/MALE — cleaned in Python) |
| `relation` | Relationship to employee (Self, Spouse, Son, Daughter, Father, Mother, etc.) |
| `age` | Age of insured (contains negative/zero values — cleaned) |
| `age_band` | Age group bucket: 0-18, 19-35, 36-50, 51-60, 61+ |
| `company_name` | Corporate employer name (one of 5 companies) |
| `grade` | Employee grade (G1–G5, determines sum insured) |
| `sum_insured` | Total insured amount for the policy year |
| `policy_number` | Group policy reference |
| `policy_start` | Policy start date |
| `policy_end` | Policy end date |
| `claim_type` | Cashless / Reimbursement / Domiciliary |
| `claim_status` | Settled / Denied / Pending / Under Investigation / Closed |
| `mode_of_receipt` | How claim was received |
| `date_of_admission` | Hospital admission date |
| `date_of_discharge` | Hospital discharge date |
| `length_of_stay` | Days in hospital (contains negatives — cleaned) |
| `hospital_name` | Treating hospital |
| `hospital_city` | City of hospital |
| `hospital_state` | State of hospital |
| `hospital_network` | Network / Non_Network |
| `treatment_type` | Surgical / Non-Surgical |
| `primary_icd_group` | ICD-10 disease category |
| `primary_ailment_name` | Specific diagnosis |
| `primary_ailment_code` | ICD-10 code |
| `billed_amount` | Amount billed by hospital (contains nulls — imputed with median) |
| `approved_amount` | Amount approved by TPA (contains logical errors: approved > billed — fixed) |
| `deduction_amount` | Amount deducted |
| `copay_deduction` | Co-payment deducted |
| `room_category` | General Ward / Semi-Private / Single Private / ICU / Deluxe |
| `claim_received_date` | Date TPA received the claim |
| `processed_date` | Date claim was processed |
| `payment_date` | Date payment was made (null for non-settled claims) |
| `processing_tat_days` | Days from receipt to processing |
| `payment_tat_days` | Days from processing to payment |
| `is_fraud_flag` | 0 = Clean · 1 = Fraud Flagged |
| `fraud_score` | 0–100 risk score |
| `fraud_reason` | Pipe-separated fraud triggers |
| `insurer` | Insurance company name |
| `tpa_name` | TPA managing the claims |

### member_dirty.csv — 21 columns · 13,531 rows

| Column | Description |
|--------|-------------|
| `member_id` | Unique member identifier |
| `employee_code` | Employee code of primary beneficiary |
| `member_name` | Member's full name |
| `relation` | Relationship to employee |
| `gender` | Gender |
| `age` | Current age |
| `dob` | Date of birth |
| `member_status` | ACTIVE / INACTIVE (contains nulls — cleaned) |
| `sum_insured` | Insured amount |
| `floater_si` | Floater sum insured shared across family |
| `grade` | Employee grade |
| `company_name` | Employer |
| `policy_number` | Policy reference |
| `policy_start` | Policy start |
| `policy_end` | Policy end |
| `effective_from` | Member effective date (late additions = fraud signal) |
| `effective_to` | Member effective end date |
| `add_date` | Date member was added to policy |
| `tpa_name` | TPA name |
| `insurer` | Insurance company |
| `email` | Member email (71% null — dependents don't have email) |

---

## 🔴 Intentional Data Quality Issues (For Practice)

The `_dirty` files contain these planted issues — clean them as part of the exercise:

| Issue | Column | Fix Applied |
|-------|--------|-------------|
| Inconsistent gender values | `gender` | Map M→Male, F→Female, male→Male |
| Negative / zero ages | `age` | Flag and impute with median |
| Duplicate rows (~1%) | All | `drop_duplicates(subset=['claim_id'])` |
| Null member status | `member_status` | Fill with 'ACTIVE' |
| Null billed_amount | `billed_amount` | Fill with column median |
| Approved > Billed (logical error) | `approved_amount` | Cap at billed_amount |
| Negative Length of Stay | `length_of_stay` | Set to 0 |
| Inconsistent claim_type casing | `claim_type` | `.str.title()` |
| Mixed date formats | `date_of_admission` | `pd.to_datetime(errors='coerce')` |
| Duplicate claims | `claim_id` | Deduplicate keeping first |

---

## 🐍 Python — What the Notebook Covers

**File:** `notebooks/Claim_Fraud.ipynb`

### Phase 1 — Data Loading & Inspection
- Load both dirty CSVs
- `.info()`, `.describe()`, `.shape`
- Missing value audit

### Phase 2 — Data Cleaning
- Fix gender inconsistencies with mapping dictionary
- Remove duplicate claim IDs
- Impute null `billed_amount` with median
- Fix logical error: `approved_amount > billed_amount`
- Fix negative `length_of_stay`
- Standardise `claim_type` casing
- Parse dates with `pd.to_datetime(errors='coerce')`
- Export cleaned CSV

### Phase 3 — Fraud Analysis & EDA
- Fraud rate by company (GroupBy + agg)
- Utilisation ratio: `billed_amount / sum_insured`
- Repeat claimant detection (same member, within 60 days)
- Scatter plot: Billed vs Approved — red dots = fraud flagged

---

## 🗄️ SQL — What the Queries Cover

**File:** `sql/Claims_Fraud.sql`

| Query | Purpose |
|-------|---------|
| `SELECT * FROM claim_clean` | Full data inspection |
| Duplicate detection | `GROUP BY claim_id HAVING COUNT(*) > 1` |
| Logical error check | `WHERE approved_amount > billed_amount` |
| Fraud pattern — late addition | `JOIN member` + `DATEDIFF < 15 AND billed > 50000` |
| `CREATE VIEW vw_fraud_candidates` | High/Medium/Low risk classification using CASE WHEN |

---

## 📈 Fraud Patterns Detected

| # | Pattern | Description |
|---|---------|-------------|
| 1 | Claim shortly after policy start | Filed within 30 days of policy effective date |
| 2 | Late member addition before high claim | Dependent added <15 days before large claim |
| 3 | Domiciliary without doctor certificate | No supporting document for home treatment |
| 4 | Approved > 90% of sum insured | Near-total utilisation in a single claim |
| 5 | Inflated bill amount | Billed amount significantly above typical range |
| 6 | Duplicate claim submission | Same claim submitted more than once |
| 7 | Repeat claimant within 60 days | Same member claiming for same ailment twice |
| 8 | Non-network premium pricing | Non-empanelled hospital billing at premium rates |

---

## 📊 Power BI Dashboard — 5 Pages

| Page | Visuals |
|------|---------|
| **Executive Summary** | KPI cards · Claims by corporate (bar) · Claim type (donut) |
| **Fraud Analysis** | Fraud rate by company · ICD treemap · Fraud reason bar · Score gauge |
| **Member & Trend** | Company × relation matrix · Monthly trend (line) · Gender pie |
| **TAT Analysis** | Processing TAT by company · Claim type · Billed vs TAT scatter · Detail table |
| **Hospital Analysis** | State-wise billed (treemap) · Hospital network bar · Disease × treatment |

### DAX Measures Used
```dax
Fraud Rate = DIVIDE(
    COUNTROWS(FILTER('claim', 'claim'[is_fraud_flag] = 1)),
    COUNTROWS('claim')
)

Total Flagged Amount = SUMX(
    FILTER('claim', 'claim'[is_fraud_flag] = 1),
    'claim'[billed_amount]
)

Approval Rate = DIVIDE(
    SUM('claim'[approved_amount]),
    SUM('claim'[billed_amount])
)
```

---

## 🔍 Key Insights

- **Bharat Steel & Power** leads with 1,806 claims — proportional to its largest workforce (1,100 employees)
- **Fraud Rate is 3.5%** — 219 flagged claims representing ₹12L+ in suspicious billed amounts
- **IndoAgro Foods** has the highest fraud rate (4.3%) — likely driven by unverified domiciliary claims
- **Domiciliary claims** account for 29.5% of all claims — highest fraud-prone category, no mandatory certificate gate
- **August peaks** at ₹113.7M billed — seasonal spike warrants a targeted fraud audit
- **Non-network hospitals** bill 35–45% higher than network hospitals for comparable treatments
- **Cashless TAT** equals Reimbursement TAT (25K days total) — Cashless processing pipeline needs SLA enforcement

---

## ✅ Recommendations

1. **Mandate doctor certificate** for all Domiciliary claims before processing — biggest single control gap
2. **Quarterly fraud audit** for IndoAgro Foods — consistently highest fraud rate (4.3%)
3. **Set 7-day SLA** for Cashless claims with auto-escalation for breaches
4. **Negotiate PPN rates** with Zynova Heart Care & Woodlands Hospital — top non-network billers
5. **Senior dependent wellness benefit** — preventive checkups to reduce high-cost in-law hospitalisations
6. **August spike investigation** — run fraud-pattern audit on all claims filed in July–August

---

## 🛠️ Tools & Technologies

| Tool | Usage |
|------|-------|
| **Claude AI** | Data profiling, fraud pattern explanation, data dictionary generation |
| **Python 3** | Data cleaning, EDA, fraud scoring, visualisation (pandas, seaborn, matplotlib, scikit-learn) |
| **SQL** | Data validation, null checks, fraud VIEW, window functions (SQLite / SQL Server compatible) |
| **Power BI** | 5-page interactive dashboard, DAX measures, conditional formatting |
| **GitHub** | Version control, project documentation |

---

## 🚀 How to Run

### Python Notebook
```bash
# Install dependencies
pip install pandas numpy matplotlib seaborn scikit-learn

# Open notebook
jupyter notebook notebooks/Claim_Fraud.ipynb
```

### SQL
```bash
# Option 1: SQLite (no server needed)
sqlite3 fraud.db
.import data/claim_clean.csv claim_clean
.read sql/Claims_Fraud.sql

# Option 2: SQL Server
# Import claim_clean.csv and member_clean.csv as tables
# Run sql/Claims_Fraud.sql in SSMS
```

### Power BI
```
1. Open Power BI Desktop
2. Get Data → Text/CSV → select claim_clean.csv and member_clean.csv
3. Create relationship: claim[member_id] → member[member_id]
4. Import the DAX measures listed above
5. Rebuild or reference the dashboard from screenshots in powerbi/dashboard_screenshots/
```

---

## 👤 Author

**Aamir**  
Data Analytics | Insurance TPA Domain | Stock Market TA  
📌 Twitter / X: [@a4aamir_](https://twitter.com/a4aamir_)  
📌 GitHub: [a4aamirsohail](https://github.com/a4aamirsohail)

---

## 📄 License

This project uses a synthetic dataset built from real TPA data structures. No real personal data is included. Free to use for learning and portfolio purposes.
