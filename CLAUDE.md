### CONCURRENT TASK LIMIT
- **Maximum 5 background tasks running simultaneously**
- When launching multiple agents (e.g., for mass audits), batch them in groups of 5
- Wait for the current batch to complete before launching the next batch

---

## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source** — the entire point of these packages is to provide STATE-LEVEL data directly from state DOEs. Federal sources aggregate/transform data differently and lose state-specific details. If a state DOE source is broken, FIX IT or find an alternative STATE source — do not fall back to federal data.

---


# Claude Code Instructions

### GIT COMMIT POLICY
- Commits are allowed
- NO Claude Code attribution, NO Co-Authored-By trailers, NO emojis
- Write normal commit messages as if a human wrote them

---

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally BEFORE opening a PR:

### CI Checks That Must Pass

| Check | Local Command | What It Tests |
|-------|---------------|---------------|
| R-CMD-check | `devtools::check()` | Package builds, tests pass, no errors/warnings |
| Python tests | `pytest tests/test_pyorschooldata.py -v` | Python wrapper works correctly |
| pkgdown | `pkgdown::build_site()` | Documentation and vignettes render |

### Quick Commands

```r
# R package check (required)
devtools::check()

# Python tests (required)
system("pip install -e ./pyorschooldata && pytest tests/test_pyorschooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

Before opening a PR, verify:
- [ ] `devtools::check()` — 0 errors, 0 warnings
- [ ] `pytest tests/test_pyorschooldata.py` — all tests pass
- [ ] `pkgdown::build_site()` — builds without errors
- [ ] Vignettes render (no `eval=FALSE` hacks)

---

## Package Overview

orschooldata provides access to Oregon Department of Education Fall Membership Reports.

## Available Years

Data is available for school years 2009-10 through 2023-24:
- **2010-2014** (Era 1): .xls format files
- **2015-2024** (Era 2): .xlsx format files

All years use year-prefixed column names (e.g., `202324_kindergarten`, `20232024_total_enrollment`).

## Data Sources

Oregon ODE Fall Membership Reports:
- URL pattern: `https://www.oregon.gov/ode/reports-and-data/students/Documents/fallmembershipreport_YYYYYYYY.xlsx`
- Example: `fallmembershipreport_20232024.xlsx` for 2023-24

## Column Name Variations by Year

The ODE data has inconsistent column naming across years:

### District ID columns:
- 2010: `attnd_distinstid`
- 2011: `attending_district_instid`
- 2012-2018, 2020+: `attending_district_institution_id`
- 2019: `attending_district_institutional_id` (typo in ODE data)
- 2022-2024: `district_institution_id`

### School ID columns:
- 2010: `attnd_schlinstid`
- 2011: `attending_school_instid`
- 2012-2018: `attending_school_institution_id`
- 2019: `attending_school_institutional_id` (typo in ODE data)
- 2020: `attending_school_id`
- 2022-2024: `school_institution_id`

## Test Coverage

Tests verify:

### Year Coverage (all 15 years: 2010-2024)
- Valid state totals (400k-800k students)
- Correct number of districts (~200-250) and campuses (~1400-1700)
- Complete grade columns (K-12)

### Data Fidelity
- **CRITICAL**: tidy=TRUE output MUST maintain fidelity to raw, unprocessed file
- Processed enrollment counts match raw data exactly
- Grade sums match row totals (within 5% for ungraded students)
- District totals match sum of campus totals
- State totals match sum of district totals

### Data Quality
- No impossible zeros in state totals
- No Inf or NaN values in tidy output
- All enrollment counts are non-negative
- All percentages are between 0 and 1

## Key Functions

- `fetch_enr(end_year, tidy=TRUE)` - Main function for single year
- `fetch_enr_multi(end_years, tidy=TRUE)` - Multiple years combined
- `get_raw_enr(end_year)` - Raw data before processing (internal)
- `get_available_years()` - Returns 2010:2024

## Processing Pipeline

1. `get_raw_enr()` - Downloads Excel file from ODE
2. `read_ode_excel()` - Reads appropriate sheet, handles era differences
3. `process_enr()` - Normalizes column names, extracts enrollment data
4. `create_district_aggregate()` - Sums campus data to district level
5. `create_state_aggregate()` - Sums district data to state level
6. `tidy_enr()` - Pivots to long format (optional)
7. `id_enr_aggs()` - Adds is_state, is_district, is_campus flags

## Common Issues and Fixes

### "Minimal output" for a year
Usually caused by column name pattern not matching. Check:
1. Raw data column names: `names(get_raw_enr(year))`
2. Year prefix format (e.g., "2324" vs "202324")
3. Column spelling variations (e.g., "institutional" vs "institution")


---

## LIVE Pipeline Testing

This package includes `tests/testthat/test-pipeline-live.R` with LIVE network tests.

### Test Categories:
1. URL Availability - HTTP 200 checks
2. File Download - Verify actual file (not HTML error)
3. File Parsing - readxl/readr succeeds
4. Column Structure - Expected columns exist
5. get_raw_enr() - Raw data function works
6. Data Quality - No Inf/NaN, non-negative counts
7. Aggregation - State total > 0
8. Output Fidelity - tidy=TRUE matches raw

### Running Tests:
```r
devtools::test(filter = "pipeline-live")
```

See `state-schooldata/CLAUDE.md` for complete testing framework documentation.


---

## Git Workflow (REQUIRED)

### Feature Branch + PR + Auto-Merge Policy

**NEVER push directly to main.** All changes must go through PRs with auto-merge:

```bash
# 1. Create feature branch
git checkout -b fix/description-of-change

# 2. Make changes, commit
git add -A
git commit -m "Fix: description of change"

# 3. Push and create PR with auto-merge
git push -u origin fix/description-of-change
gh pr create --title "Fix: description" --body "Description of changes"
gh pr merge --auto --squash

# 4. Clean up stale branches after PR merges
git checkout main && git pull && git fetch --prune origin
```

### Branch Cleanup (REQUIRED)

**Clean up stale branches every time you touch this package:**

```bash
# Delete local branches merged to main
git branch --merged main | grep -v main | xargs -r git branch -d

# Prune remote tracking branches
git fetch --prune origin
```

### Auto-Merge Requirements

PRs auto-merge when ALL CI checks pass:
- R-CMD-check (0 errors, 0 warnings)
- Python tests (if py{st}schooldata exists)
- pkgdown build (vignettes must render)

If CI fails, fix the issue and push - auto-merge triggers when checks pass.

---

## README Images from Vignettes (REQUIRED)

**NEVER use `man/figures/` or `generate_readme_figs.R` for README images.**

README images MUST come from pkgdown-generated vignette output so they auto-update on merge:

```markdown
![Chart name](https://almartin82.github.io/{package}/articles/{vignette}_files/figure-html/{chunk-name}-1.png)
```

**Why:** Vignette figures regenerate automatically when pkgdown builds. Manual `man/figures/` requires running a separate script and is easy to forget, causing stale/broken images.

---

## README and Vignette Code Matching (REQUIRED)

**CRITICAL RULE (as of 2026-01-08):** ALL code blocks in the README MUST match code in a vignette EXACTLY (1:1 correspondence).

### Why This Matters

The Idaho fix revealed critical bugs when README code didn't match vignettes:
- Wrong district names (lowercase vs ALL CAPS)
- Text claims that contradicted actual data  
- Missing data output in examples

### README Story Structure (REQUIRED)

Every story/section in the README MUST follow this structure:

1. **Claim**: A factual statement about the data
2. **Explication**: Brief explanation of why this matters
3. **Code**: R code that fetches and analyzes the data (MUST exist in a vignette)
4. **Code Output**: Data table/print statement showing actual values (REQUIRED)
5. **Visualization**: Chart from vignette (auto-generated from pkgdown)

### Enforcement

The `state-deploy` skill verifies this before deployment:
- Extracts all README code blocks
- Searches vignettes for EXACT matches
- Fails deployment if code not found in vignettes
- Randomly audits packages for claim accuracy

### What This Prevents

- ❌ Wrong district/entity names (case sensitivity, typos)
- ❌ Text claims that contradict data
- ❌ Broken code that fails silently
- ❌ Missing data output
- ✅ Verified, accurate, reproducible examples

### Example

```markdown
### 1. State enrollment grew 28% since 2002

State added 68,000 students from 2002 to 2026, bucking national trends.

```r
library(arschooldata)
library(dplyr)

enr <- fetch_enr_multi(2002:2026)

enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students) %>%
  filter(end_year %in% c(2002, 2026)) %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
# Prints: 2002=XXX, 2026=YYY, change=ZZZ, pct=PP.P%
```

![Chart](https://almartin82.github.io/arschooldata/articles/...)
```
