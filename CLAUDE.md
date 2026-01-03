# Claude Code Instructions

## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source**
— the entire point of these packages is to provide STATE-LEVEL data
directly from state DOEs. Federal sources aggregate/transform data
differently and lose state-specific details. If a state DOE source is
broken, FIX IT or find an alternative STATE source — do not fall back to
federal data.

------------------------------------------------------------------------

## Git Commits and PRs

- NEVER reference Claude, Claude Code, or AI assistance in commit
  messages
- NEVER reference Claude, Claude Code, or AI assistance in PR
  descriptions
- NEVER add Co-Authored-By lines mentioning Claude or Anthropic
- Keep commit messages focused on what changed, not how it was written

------------------------------------------------------------------------

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally
BEFORE opening a PR:

### CI Checks That Must Pass

| Check        | Local Command                                                                  | What It Tests                                  |
|--------------|--------------------------------------------------------------------------------|------------------------------------------------|
| R-CMD-check  | `devtools::check()`                                                            | Package builds, tests pass, no errors/warnings |
| Python tests | `pytest tests/test_pyorschooldata.py -v`                                       | Python wrapper works correctly                 |
| pkgdown      | [`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html) | Documentation and vignettes render             |

### Quick Commands

``` r
# R package check (required)
devtools::check()

# Python tests (required)
system("pip install -e ./pyorschooldata && pytest tests/test_pyorschooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

Before opening a PR, verify: - \[ \] `devtools::check()` — 0 errors, 0
warnings - \[ \] `pytest tests/test_pyorschooldata.py` — all tests
pass - \[ \]
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
— builds without errors - \[ \] Vignettes render (no `eval=FALSE` hacks)

------------------------------------------------------------------------

## Package Overview

orschooldata provides access to Oregon Department of Education Fall
Membership Reports.

## Available Years

Data is available for school years 2009-10 through 2023-24: -
**2010-2014** (Era 1): .xls format files - **2015-2024** (Era 2): .xlsx
format files

All years use year-prefixed column names (e.g., `202324_kindergarten`,
`20232024_total_enrollment`).

## Data Sources

Oregon ODE Fall Membership Reports: - URL pattern:
`https://www.oregon.gov/ode/reports-and-data/students/Documents/fallmembershipreport_YYYYYYYY.xlsx` -
Example: `fallmembershipreport_20232024.xlsx` for 2023-24

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

- **CRITICAL**: tidy=TRUE output MUST maintain fidelity to raw,
  unprocessed file
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
- [`get_available_years()`](https://almartin82.github.io/orschooldata/reference/get_available_years.md) -
  Returns 2010:2024

## Processing Pipeline

1.  [`get_raw_enr()`](https://almartin82.github.io/orschooldata/reference/get_raw_enr.md) -
    Downloads Excel file from ODE
2.  [`read_ode_excel()`](https://almartin82.github.io/orschooldata/reference/read_ode_excel.md) -
    Reads appropriate sheet, handles era differences
3.  [`process_enr()`](https://almartin82.github.io/orschooldata/reference/process_enr.md) -
    Normalizes column names, extracts enrollment data
4.  [`create_district_aggregate()`](https://almartin82.github.io/orschooldata/reference/create_district_aggregate.md) -
    Sums campus data to district level
5.  [`create_state_aggregate()`](https://almartin82.github.io/orschooldata/reference/create_state_aggregate.md) -
    Sums district data to state level
6.  [`tidy_enr()`](https://almartin82.github.io/orschooldata/reference/tidy_enr.md) -
    Pivots to long format (optional)
7.  [`id_enr_aggs()`](https://almartin82.github.io/orschooldata/reference/id_enr_aggs.md) -
    Adds is_state, is_district, is_campus flags

## Common Issues and Fixes

### “Minimal output” for a year

Usually caused by column name pattern not matching. Check: 1. Raw data
column names: `names(get_raw_enr(year))` 2. Year prefix format (e.g.,
“2324” vs “202324”) 3. Column spelling variations (e.g., “institutional”
vs “institution”)

------------------------------------------------------------------------

## LIVE Pipeline Testing

This package includes `tests/testthat/test-pipeline-live.R` with LIVE
network tests.

### Test Categories:

1.  URL Availability - HTTP 200 checks
2.  File Download - Verify actual file (not HTML error)
3.  File Parsing - readxl/readr succeeds
4.  Column Structure - Expected columns exist
5.  get_raw_enr() - Raw data function works
6.  Data Quality - No Inf/NaN, non-negative counts
7.  Aggregation - State total \> 0
8.  Output Fidelity - tidy=TRUE matches raw

### Running Tests:

``` r
devtools::test(filter = "pipeline-live")
```

See `state-schooldata/CLAUDE.md` for complete testing framework
documentation.
