-- ============================================================
-- Insurance Claim Fraud Detection — SQL Queries
-- Author  : Aamir (@a4aamir_)
-- Project : Group Health Insurance Fraud Analysis
-- Tables  : claim_clean, member_clean
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- SECTION 1: DATA INSPECTION
-- ────────────────────────────────────────────────────────────

-- 1.1 Full table preview
SELECT * FROM claim_clean;

-- 1.2 Row count
SELECT COUNT(*) AS total_rows FROM claim_clean;

-- 1.3 Distinct values in key categorical columns
SELECT DISTINCT claim_status  FROM claim_clean;
SELECT DISTINCT claim_type    FROM claim_clean;
SELECT DISTINCT company_name  FROM claim_clean;
SELECT DISTINCT hospital_network FROM claim_clean;


-- ────────────────────────────────────────────────────────────
-- SECTION 2: DATA QUALITY CHECKS (CLEANING VALIDATION)
-- ────────────────────────────────────────────────────────────

-- 2.1 NULL counts per key column
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN billed_amount   IS NULL THEN 1 ELSE 0 END) AS null_billed,
    SUM(CASE WHEN approved_amount IS NULL THEN 1 ELSE 0 END) AS null_approved,
    SUM(CASE WHEN gender          IS NULL THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN claim_status    IS NULL THEN 1 ELSE 0 END) AS null_status,
    SUM(CASE WHEN length_of_stay  IS NULL THEN 1 ELSE 0 END) AS null_los
FROM claim_clean;

-- 2.2 Duplicate claim detection
SELECT claim_id, COUNT(*) AS cnt
FROM claim_clean
GROUP BY claim_id
HAVING COUNT(*) > 1;

-- 2.3 Logical error: approved_amount > billed_amount
SELECT claim_id, billed_amount, approved_amount,
       (approved_amount - billed_amount) AS excess_approved
FROM claim_clean
WHERE approved_amount > billed_amount
ORDER BY excess_approved DESC;

-- 2.4 Negative length of stay
SELECT claim_id, member_name, length_of_stay
FROM claim_clean
WHERE length_of_stay < 0;

-- 2.5 Claims with zero or null billed amount
SELECT claim_id, member_name, claim_status, billed_amount
FROM claim_clean
WHERE billed_amount IS NULL OR billed_amount = 0;

-- 2.6 Inconsistent gender values (pre-cleaning check)
SELECT gender, COUNT(*) AS cnt
FROM claim_clean
GROUP BY gender
ORDER BY cnt DESC;


-- ────────────────────────────────────────────────────────────
-- SECTION 3: FRAUD DETECTION QUERIES
-- ────────────────────────────────────────────────────────────

-- 3.1 Late member addition before high claim (KEY FRAUD PATTERN)
--     Member added to policy within 15 days of admission
--     AND billed amount is over ₹50,000
SELECT
    c.claim_id,
    c.member_id,
    c.member_name,
    c.company_name,
    m.effective_from,
    c.date_of_admission,
    DATEDIFF(DAY, m.effective_from, c.date_of_admission) AS days_gap,
    c.billed_amount,
    c.claim_status
FROM claim_clean c
JOIN member_clean m ON c.member_id = m.member_id
WHERE DATEDIFF(DAY, m.effective_from, c.date_of_admission) < 15
  AND c.billed_amount > 50000
ORDER BY days_gap ASC;

-- 3.2 Claims filed within 30 days of policy start
SELECT
    claim_id, member_name, company_name,
    policy_start, date_of_admission,
    DATEDIFF(DAY, policy_start, date_of_admission) AS days_from_policy_start,
    billed_amount, claim_status
FROM claim_clean
WHERE DATEDIFF(DAY, policy_start, date_of_admission) < 30
ORDER BY days_from_policy_start ASC;

-- 3.3 Domiciliary claims (highest fraud risk type)
SELECT
    claim_id, member_name, company_name,
    billed_amount, approved_amount, fraud_score, fraud_reason
FROM claim_clean
WHERE claim_type = 'Domiciliary'
  AND is_fraud_flag = 1
ORDER BY fraud_score DESC;

-- 3.4 Claims where approved_amount > 90% of sum_insured
SELECT
    claim_id, member_name, company_name,
    sum_insured, billed_amount, approved_amount,
    ROUND(CAST(approved_amount AS FLOAT) / sum_insured * 100, 1) AS pct_of_si
FROM claim_clean
WHERE approved_amount > sum_insured * 0.9
ORDER BY pct_of_si DESC;

-- 3.5 Members who claimed more than once (repeat claimants)
SELECT
    member_id, member_name, company_name,
    COUNT(*) AS claim_count,
    SUM(billed_amount) AS total_billed,
    MIN(date_of_admission) AS first_claim,
    MAX(date_of_admission) AS last_claim
FROM claim_clean
GROUP BY member_id, member_name, company_name
HAVING COUNT(*) > 1
ORDER BY claim_count DESC;

-- 3.6 Non-network hospital — high billing
SELECT
    hospital_name, hospital_state,
    COUNT(*) AS claim_count,
    ROUND(AVG(billed_amount), 0) AS avg_billed,
    ROUND(AVG(approved_amount), 0) AS avg_approved,
    SUM(is_fraud_flag) AS fraud_flags
FROM claim_clean
WHERE hospital_network = 'Non_Network'
GROUP BY hospital_name, hospital_state
HAVING COUNT(*) >= 3
ORDER BY avg_billed DESC;

-- 3.7 Fraud rate by company
SELECT
    company_name,
    COUNT(*) AS total_claims,
    SUM(is_fraud_flag) AS fraud_count,
    ROUND(CAST(SUM(is_fraud_flag) AS FLOAT) / COUNT(*) * 100, 2) AS fraud_rate_pct,
    SUM(billed_amount) AS total_billed,
    SUM(CASE WHEN is_fraud_flag = 1 THEN billed_amount ELSE 0 END) AS fraud_billed
FROM claim_clean
GROUP BY company_name
ORDER BY fraud_rate_pct DESC;

-- 3.8 Fraud by relation type
SELECT
    relation,
    COUNT(*) AS total_claims,
    SUM(is_fraud_flag) AS fraud_count,
    ROUND(CAST(SUM(is_fraud_flag) AS FLOAT) / COUNT(*) * 100, 2) AS fraud_rate_pct,
    ROUND(AVG(billed_amount), 0) AS avg_billed
FROM claim_clean
GROUP BY relation
ORDER BY fraud_rate_pct DESC;

-- 3.9 Top fraud reasons
SELECT
    fraud_reason,
    COUNT(*) AS occurrence_count
FROM claim_clean
WHERE is_fraud_flag = 1
  AND fraud_reason IS NOT NULL
GROUP BY fraud_reason
ORDER BY occurrence_count DESC;

-- 3.10 High fraud score claims — action table
SELECT TOP 20
    claim_id, member_name, company_name,
    claim_type, claim_status,
    billed_amount, approved_amount,
    fraud_score, fraud_reason
FROM claim_clean
WHERE fraud_score >= 50
ORDER BY fraud_score DESC;


-- ────────────────────────────────────────────────────────────
-- SECTION 4: AGGREGATION & KPI QUERIES
-- ────────────────────────────────────────────────────────────

-- 4.1 Overall KPIs
SELECT
    COUNT(*)                                    AS total_claims,
    ROUND(SUM(billed_amount), 0)                AS total_billed,
    ROUND(SUM(approved_amount), 0)              AS total_approved,
    ROUND(AVG(billed_amount), 0)                AS avg_billed,
    ROUND(AVG(length_of_stay), 1)               AS avg_los,
    ROUND(AVG(processing_tat_days), 1)          AS avg_processing_tat,
    SUM(is_fraud_flag)                          AS total_fraud_flagged,
    ROUND(CAST(SUM(is_fraud_flag) AS FLOAT)
          / COUNT(*) * 100, 2)                  AS fraud_rate_pct
FROM claim_clean;

-- 4.2 Claims and amount by status
SELECT
    claim_status,
    COUNT(*) AS claim_count,
    ROUND(SUM(billed_amount), 0) AS total_billed,
    ROUND(SUM(approved_amount), 0) AS total_approved,
    ROUND(AVG(billed_amount), 0) AS avg_billed
FROM claim_clean
GROUP BY claim_status
ORDER BY claim_count DESC;

-- 4.3 Monthly claim trend
SELECT
    YEAR(date_of_admission)  AS yr,
    MONTH(date_of_admission) AS mth,
    COUNT(*)                 AS claim_count,
    ROUND(SUM(billed_amount), 0) AS total_billed
FROM claim_clean
WHERE date_of_admission IS NOT NULL
GROUP BY YEAR(date_of_admission), MONTH(date_of_admission)
ORDER BY yr, mth;

-- 4.4 Top 10 diseases by total approved amount
SELECT TOP 10
    primary_icd_group,
    COUNT(*) AS claim_count,
    ROUND(SUM(approved_amount), 0) AS total_approved,
    ROUND(AVG(approved_amount), 0) AS avg_approved,
    ROUND(AVG(length_of_stay), 1)  AS avg_los
FROM claim_clean
WHERE approved_amount > 0
GROUP BY primary_icd_group
ORDER BY total_approved DESC;

-- 4.5 Claim type performance
SELECT
    claim_type,
    COUNT(*) AS total_claims,
    ROUND(AVG(billed_amount), 0)     AS avg_billed,
    ROUND(AVG(approved_amount), 0)   AS avg_approved,
    ROUND(AVG(processing_tat_days),1) AS avg_tat
FROM claim_clean
GROUP BY claim_type
ORDER BY total_claims DESC;

-- 4.6 State-wise billed amount
SELECT
    hospital_state,
    COUNT(*) AS claim_count,
    ROUND(SUM(billed_amount), 0) AS total_billed,
    ROUND(AVG(billed_amount), 0) AS avg_billed
FROM claim_clean
WHERE hospital_state IS NOT NULL
GROUP BY hospital_state
ORDER BY total_billed DESC;


-- ────────────────────────────────────────────────────────────
-- SECTION 5: WINDOW FUNCTIONS
-- ────────────────────────────────────────────────────────────

-- 5.1 Rank claims within each company by billed amount
SELECT
    claim_id, member_name, company_name, billed_amount,
    RANK() OVER (PARTITION BY company_name ORDER BY billed_amount DESC) AS rank_in_company
FROM claim_clean;

-- 5.2 Running total of approved amount by date
SELECT
    date_of_admission,
    approved_amount,
    SUM(approved_amount) OVER (ORDER BY date_of_admission
                               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM claim_clean
WHERE date_of_admission IS NOT NULL
  AND claim_status = 'Settled';

-- 5.3 LAG — days between consecutive claims for same member
SELECT
    member_id, member_name, date_of_admission,
    billed_amount,
    LAG(date_of_admission) OVER (PARTITION BY member_id ORDER BY date_of_admission) AS prev_claim_date,
    DATEDIFF(DAY,
        LAG(date_of_admission) OVER (PARTITION BY member_id ORDER BY date_of_admission),
        date_of_admission
    ) AS days_since_prev_claim
FROM claim_clean;

-- 5.4 Top 3 claims per disease group (ROW_NUMBER trick)
SELECT * FROM (
    SELECT
        claim_id, member_name, primary_icd_group,
        billed_amount,
        ROW_NUMBER() OVER (PARTITION BY primary_icd_group
                           ORDER BY billed_amount DESC) AS rn
    FROM claim_clean
    WHERE billed_amount > 0
) ranked
WHERE rn <= 3
ORDER BY primary_icd_group, rn;


-- ────────────────────────────────────────────────────────────
-- SECTION 6: JOINS
-- ────────────────────────────────────────────────────────────

-- 6.1 Claim joined with member details
SELECT
    c.claim_id, c.member_name, c.company_name,
    c.claim_status, c.billed_amount,
    m.member_status, m.grade, m.effective_from
FROM claim_clean c
LEFT JOIN member_clean m ON c.member_id = m.member_id
WHERE c.billed_amount > 100000
ORDER BY c.billed_amount DESC;

-- 6.2 Members with NO claims (anti-join)
SELECT
    m.member_id, m.member_name,
    m.company_name, m.member_status
FROM member_clean m
LEFT JOIN claim_clean c ON m.member_id = c.member_id
WHERE c.member_id IS NULL
ORDER BY m.company_name;

-- 6.3 Members with claims + fraud details
SELECT
    m.employee_code, m.member_name AS member,
    m.company_name, m.grade,
    COUNT(c.claim_id) AS total_claims,
    SUM(c.billed_amount) AS total_billed,
    SUM(c.is_fraud_flag) AS fraud_flags,
    MAX(c.fraud_score) AS max_fraud_score
FROM member_clean m
INNER JOIN claim_clean c ON m.member_id = c.member_id
GROUP BY m.employee_code, m.member_name, m.company_name, m.grade
HAVING SUM(c.is_fraud_flag) > 0
ORDER BY fraud_flags DESC;


-- ────────────────────────────────────────────────────────────
-- SECTION 7: VIEWS & REPORTING OBJECTS
-- ────────────────────────────────────────────────────────────

-- 7.1 Fraud candidate view with risk classification
CREATE VIEW vw_fraud_candidates AS
SELECT *,
    CASE
        WHEN fraud_score >= 75 THEN 'High Risk'
        WHEN fraud_score >= 50 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM claim_clean
WHERE is_fraud_flag = 1;

-- 7.2 Use the view
SELECT risk_category, COUNT(*) AS count,
       ROUND(SUM(billed_amount), 0) AS total_billed
FROM vw_fraud_candidates
GROUP BY risk_category
ORDER BY count DESC;

-- 7.3 Company summary view
CREATE VIEW vw_company_summary AS
SELECT
    company_name,
    COUNT(*) AS total_claims,
    ROUND(SUM(billed_amount), 0) AS total_billed,
    ROUND(SUM(approved_amount), 0) AS total_approved,
    SUM(is_fraud_flag) AS fraud_count,
    ROUND(CAST(SUM(is_fraud_flag) AS FLOAT) / COUNT(*) * 100, 2) AS fraud_rate_pct,
    ROUND(AVG(processing_tat_days), 1) AS avg_tat
FROM claim_clean
GROUP BY company_name;

-- 7.4 Use company summary view
SELECT * FROM vw_company_summary ORDER BY fraud_rate_pct DESC;


-- ────────────────────────────────────────────────────────────
-- SECTION 8: SUBQUERIES & CTEs
-- ────────────────────────────────────────────────────────────

-- 8.1 CTE: Fraud rate per company, then filter above average
WITH company_fraud AS (
    SELECT
        company_name,
        COUNT(*) AS total_claims,
        SUM(is_fraud_flag) AS fraud_count,
        CAST(SUM(is_fraud_flag) AS FLOAT) / COUNT(*) AS fraud_rate
    FROM claim_clean
    GROUP BY company_name
)
SELECT *
FROM company_fraud
WHERE fraud_rate > (SELECT AVG(fraud_rate) FROM company_fraud)
ORDER BY fraud_rate DESC;

-- 8.2 CTE: Members who have both fraud and clean claims
WITH member_claim_summary AS (
    SELECT
        member_id, member_name,
        COUNT(*) AS total_claims,
        SUM(is_fraud_flag) AS fraud_claims,
        SUM(CASE WHEN is_fraud_flag = 0 THEN 1 ELSE 0 END) AS clean_claims
    FROM claim_clean
    GROUP BY member_id, member_name
)
SELECT *
FROM member_claim_summary
WHERE fraud_claims > 0 AND clean_claims > 0
ORDER BY fraud_claims DESC;

-- 8.3 Subquery: Claims above the average billed amount per disease group
SELECT claim_id, member_name, primary_icd_group, billed_amount
FROM claim_clean c
WHERE billed_amount > (
    SELECT AVG(billed_amount)
    FROM claim_clean
    WHERE primary_icd_group = c.primary_icd_group
)
ORDER BY primary_icd_group, billed_amount DESC;

-- ============================================================
-- END OF FILE
-- Insurance Claim Fraud Detection — SQL Queries
-- @a4aamir_ | github.com/a4aamirsohail
-- ============================================================
