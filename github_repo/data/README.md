# Data Files

| File | Rows | Columns | Description |
|------|------|---------|-------------|
| `claim_dirty.csv` | 6,232 | 44 | Raw uncleaned claim data with intentional data quality issues |
| `member_dirty.csv` | 13,531 | 21 | Raw uncleaned member data |
| `claim_clean.csv` | 6,170 | 44 | Cleaned output after running `notebooks/Claim_Fraud.ipynb` |
| `member_clean.csv` | 13,397 | 21 | Cleaned member data |

## How to Generate Clean Files

Run `notebooks/Claim_Fraud.ipynb` from top to bottom.  
The notebook reads `claim_dirty.csv` and writes `claim_clean.csv` in the same folder.

## Data Dictionary

See the full column-by-column data dictionary in the main [README.md](../README.md#-dataset-description).
