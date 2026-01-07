# orschooldata Enrollment Data Tidyness Audit

**Date:** 2026-01-05
**Auditor:** Claude Code
**Package:** orschooldata

---

## Rating: 3/10

The package has serious issues preventing it from producing correct tidy format output.

---

## Critical Issues

### 1. **Year 2023-2024 Data Completely Broken** (CRITICAL)

**Problem:** Years 2023 and 2024 return 0 rows of data.

**Root Cause:** Year prefix pattern mismatch in `process_enr_era2()`.

The Oregon ODE changed their column naming convention:
- **Old pattern (2020-2022):** `202122_grade_one` (6 digits: start_year % 100 + end_year)
- **New pattern (2023-2024):** `202324_grade_one` (6 digits: start_year without leading century + end_year)

The code generates:
- `year_prefix_long = "20232024"` (8 digits) - **WRONG**
- `year_prefix_short = "2324"` (4 digits) - **WRONG**

Expected for 2024:
- Actual column name: `202324_grade_one`
- Code looks for: `^2324_grade_one$` or `^20232024_grade_one$`
- Neither pattern matches, so all grade columns are skipped

**Evidence:**
```r
fetch_enr(2024, tidy=TRUE)
# Returns: data.frame with 0 rows
```

**Impact:** Complete data loss for 2023-2024 school years.

---

### 2. **Grade-Level Data Not Extracted (ALL YEARS)** (CRITICAL)

**Problem:** Grade-level breakdowns (K-12, PK, UG) are NOT included in tidy output.

**Expected:** Each entity (state, district, campus) should have 15 grade_level rows:
- TOTAL, PK, K, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, UG

**Actual:** Only 1 row per entity with grade_level = "TOTAL"

**Evidence:**
```r
data_2022 <- fetch_enr(2022, tidy=TRUE)
table(data_2022$grade_level)
# TOTAL
#  1649

# Expected: 24,735 rows = 1649 entities * 15 grade_levels
# Actual: 1,649 rows = 1649 entities * 1 grade_level (TOTAL only)
```

**Root Cause:** The `tidy_enr()` function only creates:
1. A TOTAL row (from `row_total`)
2. Grade-level rows (from grade columns)

But since the grade columns aren't being extracted from the raw Excel (due to pattern matching issues in process_enr_era2), only the TOTAL row exists.

**Raw Data Verification:**
```r
# Raw Excel files DO contain grade columns
# 2022: "202122_kindergarten", "202122_grade_one", etc.
# 2024: "202324_kindergarten", "202324_grade_one", etc.
```

But `process_enr_era2()` doesn't extract them because the year prefix patterns don't match.

**Impact:** Users cannot analyze enrollment trends by grade level. This is a core feature of school enrollment data.

---

### 3. **Demographic Subgroups Not Extracted** (CRITICAL)

**Problem:** Oregon's raw Excel files contain demographic breakdowns (race/ethnicity), but these are completely ignored.

**Evidence from 2024 raw Excel:**
```
"202324_american_indianalaska_native"
"202324_asian"
"202324_blackafrican_american"
"202324_hispanic_latino"
"202324_white"
"202324_multiracial"
"202324_native_hawaiian_pacific_islander"
```

**Current output:**
```r
unique(data_2022$subgroup)
# [1] "total_enrollment"
```

**Impact:** Cannot analyze enrollment by race/ethnicity, which is critical for equity analyses.

---

## Secondary Issues

### 4. **Missing Pre-K and Ungraded Data**

Even if grade columns were extracted, the code looks for:
- Pre-K patterns: `^202122_pre_k$`, `^202122_prek$`, etc.
- Ungraded patterns: `^202122_ug$`, `^202122_ungraded$`

But Oregon's Excel files don't use these column names. Pre-K data may not exist at all, and ungraded students likely aren't tracked separately.

**Impact:** Incomplete grade-level coverage if/when grade extraction is fixed.

---

### 5. **No Test Coverage for Grade-Level Data**

Tests verify:
- State total enrollment exists
- Correct number of districts and campuses
- Column names exist

But tests do NOT verify:
- That grade-level breakdowns are present in tidy output
- That grade sums match row totals
- That specific grade values match raw data

**Impact:** This major regression (missing all grade-level data) was not caught by tests.

---

## Data Completeness Analysis

### Working Years (2020-2022)

✅ **State totals**: Present and accurate
✅ **District records**: Correct count (~210)
✅ **Campus records**: Correct count (~1400)
❌ **Grade-level breakdowns**: Missing (only TOTAL grade_level)
❌ **Demographic subgroups**: Missing (only total_enrollment subgroup)

### Broken Years (2023-2024)

❌ **Any data at all**: 0 rows returned

---

## Target Format Comparison

### Expected Columns (from alschooldata standard):
```r
c("end_year", "type", "district_id", "campus_id",
  "district_name", "campus_name", "county", "grade_level",
  "subgroup", "n_students", "pct",
  "is_state", "is_district", "is_campus")
```

### Actual Columns (orschooldata):
✅ All expected columns present

### Expected Subgroups:
- total_enrollment
- male, female (if available)
- race/ethnicity subgroups (if available)

### Actual Subgroups:
❌ Only "total_enrollment" (demographics exist in raw data but not extracted)

### Expected Grade Levels:
- TOTAL, PK, K, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, UG

### Actual Grade Levels:
❌ Only "TOTAL" (grade columns exist in raw data but not extracted)

---

## Required Fixes

### Fix 1: Correct Year Prefix Calculation (CRITICAL)

**File:** `R/process_enrollment.R`

**Function:** `process_enr_era2()`

**Current code (line 244-245):**
```r
year_prefix_long <- paste0(start_year, end_year)  # "20232024" - WRONG
year_prefix_short <- paste0(substr(start_year, 3, 4), substr(end_year, 3, 4))  # "2324" - WRONG
```

**Fix for 2023-2024 pattern:**
```r
# Oregon uses 6-digit format: start_year_without_century + end_year
# Example: 2023-24 becomes "202324" (not "2324" and not "20232024")
year_prefix_6digit <- paste0(substr(start_year, 3, 4), end_year)  # "232024" -> wait, this is still wrong

# Actually need: start_year % 100 (gives 23 for 2023) + end_year (gives 24)
year_prefix_correct <- paste0(start_year %% 100, end_year)  # "2324" for 2023-24

# But wait, 2024 uses "202324", not "2324"
# Let me recalculate: 202324 = "2023" truncated + "2024"
# That's: substr(start_year, 1, 4) gives "2023", then paste with "24"
# No wait, "202324" has 6 digits: 2023 + 24
year_prefix_6digit <- paste0(substr(start_year, 1, 4), substr(end_year, 3, 4))
# For 2024: "2023" + "24" = "202324" ✓
# For 2023: "2022" + "23" = "202223" ✓
# For 2022: "2021" + "22" = "202122" ✓
```

**Wait, let me verify:**
- 2022 data: columns are `202122_*` ✓ (matches "2021" + "22")
- 2023 data: columns are `202223_*` ✓ (matches "2022" + "23")
- 2024 data: columns are `202324_*` ✓ (matches "2023" + "24")

**Correct fix:**
```r
# Line ~244 in process_enr_era2()
year_prefix <- paste0(substr(start_year, 1, 4), substr(end_year, 3, 4))
# Results: "202122", "202223", "202324" (6 digits)

# Then update all grade patterns to use this:
patterns <- c(
  paste0("^", year_prefix, "_grade_", word, "$"),
  paste0("grade_", word, "$"),
  # ... fallback patterns
)
```

### Fix 2: Extract Demographic Subgroups (HIGH PRIORITY)

**File:** `R/process_enrollment.R`

**New function needed:** Extract race/ethnicity columns from raw data

Oregon Excel files have these demographic columns:
- `202324_american_indianalaska_native`
- `202324_asian`
- `202324_blackafrican_american`
- `202324_hispanic_latino`
- `202324_white`
- `202324_multiracial`
- `202324_native_hawaiian_pacific_islander`

These need to be:
1. Extracted in `process_enr_era2()` (similar to grade columns)
2. Added to wide format as separate columns
3. Pivoted to long format in `tidy_enr()` as additional subgroup rows

### Fix 3: Add Grade-Level Fidelity Tests (HIGH PRIORITY)

**File:** `tests/testthat/test-enrollment.R`

Add tests to verify:
```r
test_that("grade-level breakdowns exist in tidy output", {
  data <- fetch_enr(2022, tidy=TRUE)

  # Each campus should have multiple grade_levels
  campus_grades <- data |>
    filter(is_campus == TRUE) |>
    count(campus_id) |>
    pull(n)

  expect_true(all(campus_grades > 1),
             info = "Each campus should have multiple grade_level rows")
})

test_that("grade sums match row_total", {
  wide <- fetch_enr(2022, tidy=FALSE)

  # For each campus, sum of grades should equal row_total
  grade_cols <- c("grade_k", "grade_01", ..., "grade_12")
  # Verify: sum(grade_cols) == row_total (within tolerance)
})
```

---

## Summary

**Current State:**
- Years 2020-2022: Partially working (state/district/campus totals only)
- Years 2023-2024: Completely broken (0 rows)

**Missing Critical Features:**
1. Grade-level breakdowns (K-12)
2. Demographic subgroups (race/ethnicity)

**Root Cause:**
Year prefix pattern matching fails to extract grade and demographic columns from raw Excel files.

**Recommendation:**
This is a **3/10** rating because while the infrastructure is in place, the core data extraction is broken for recent years and missing grade-level detail for all years. The package needs significant fixes to match the target tidy format used by other state packages.

---

## Files Requiring Changes

1. **R/process_enrollment.R**
   - Fix year prefix calculation (line ~244)
   - Add grade column extraction verification
   - Add demographic column extraction

2. **tests/testthat/test-enrollment.R**
   - Add grade-level coverage tests
   - Add demographic subgroup tests
   - Add raw data fidelity tests for grades

3. **R/tidy_enrollment.R**
   - Consider adding demographic subgroup pivoting (if implemented in process)

