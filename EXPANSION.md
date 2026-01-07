# Oregon School Data Expansion Research

**Last Updated:** 2026-01-04 **Theme Researched:** Graduation Rates
(Cohort Graduation and Dropout Data)

## Current Package Status

- **R-CMD-check:** Passing
- **Python tests:** Passing
- **pkgdown:** Passing
- **Current functionality:** Enrollment data only (Fall Membership
  Reports 2010-2024)

## Data Sources Found

### Source 1: Cohort Graduation Rate Media Files

- **Main Page:**
  <https://www.oregon.gov/ode/reports-and-data/students/pages/cohort-graduation-rate.aspx>
- **Format:** Excel files (.xlsx for 2013+, .xls for 2009-2012)
- **Years Available:** 2008-09 through 2023-24 (16 years)
- **Access:** Direct download, no authentication required
- **All URLs return HTTP 200**

#### File URL Patterns

**Modern Format (2013-2024) - .xlsx:**

    https://www.oregon.gov/ode/reports-and-data/students/Documents/cohortmediafile{YYYY}-{YYYY}.xlsx

**Legacy Format (2009-2012) - .xls:**

    https://www.oregon.gov/ode/reports-and-data/students/Documents/cohortmediafile{YYYY}-{YYYY}.xls

#### Verified URLs (All HTTP 200)

| Year    | Filename                              | Format                         |
|---------|---------------------------------------|--------------------------------|
| 2023-24 | cohortmediafile2023-2024.xlsx         | xlsx                           |
| 2022-23 | cohortmediafile2022-2023.xlsx         | xlsx                           |
| 2021-22 | cohortmediafile2021-2022.xlsx         | xlsx                           |
| 2020-21 | cohortmediafile2020-2021.xlsx         | xlsx                           |
| 2019-20 | cohortmediafile2019-2020_revised.xlsx | xlsx (note: `_revised` suffix) |
| 2018-19 | cohortmediafile2018-2019.xlsx         | xlsx                           |
| 2017-18 | cohortmediafile2017-2018.xlsx         | xlsx                           |
| 2016-17 | cohortmediafile2016-2017.xlsx         | xlsx                           |
| 2015-16 | cohortmediafile2015-2016.xlsx         | xlsx                           |
| 2014-15 | cohortmediafile2014-2015.xlsx         | xlsx                           |
| 2013-14 | cohortmediafile2013-2014.xlsx         | xlsx                           |
| 2012-13 | cohortmediafile2012-2013.xlsx         | xlsx                           |
| 2011-12 | cohortmediafile2011-2012.xls          | xls                            |
| 2010-11 | cohortmediafile2010-2011_revised.xls  | xls (note: `_revised` suffix)  |
| 2009-10 | cohortmediafile2009-2010.xls          | xls                            |
| 2008-09 | cohortmediafile2008-2009.xls          | xls                            |

#### Trend Files (Also Available)

    cohortmediafile{YYYY}-{YYYY}trends.xlsx

Contains multi-year comparison data.

### Source 2: Dropout/Pushout Rate Tables

- **Main Page:**
  <https://www.oregon.gov/ode/reports-and-data/students/Pages/Dropout-Rates.aspx>
- **Format:** Excel files (.xlsx for 2020+, .xls for earlier)
- **Years Available:** 2000-01 through 2023-24 (24 years)
- **Access:** Direct download, no authentication required

#### Verified URLs

| Year    | Filename                              |
|---------|---------------------------------------|
| 2023-24 | dropouttables2023-2024.xlsx           |
| 2022-23 | dropout-pushout-tables2022-2023.xlsx  |
| 2021-22 | dropout-pushout-tables-2021-2022.xlsx |
| 2020-21 | dropouttables2020-2021.xlsx           |
| 2019-20 | dropouttables2019-2020.xlsx           |
| 2018-19 | dropouttables2018-2019.xls            |
| …       | (files available back to 2000-01)     |

------------------------------------------------------------------------

## Schema Analysis

### Sheet Structure by Era

#### Era 1: 2008-09 to 2012-13 (Legacy .xls)

**Sheets:** - `Four Year Cohort Totals` - `Five Year Cohort Totals` -
`Subgroup Definitions`

**Header:** Multi-row header (skip=2 required)

**Columns (2011-12 example):** \| Column \| Description \|
\|——–\|————-\| \| County \| County name or “State of Oregon” \| \|
District ID \| 4-digit numeric ID \| \| District Name \| Full district
name \| \| School ID \| 4-digit numeric ID \| \| School Name \| Full
school name \| \| Subgroup \| 2-6 letter code (Tot, M, F, AM, ASN, etc.)
\| \| Unadjusted Cohort \| Starting cohort count \| \| Transfer Out… \|
Removed from cohort \| \| Deceased \| Removed from cohort \| \| Adjusted
Cohort \| Final cohort count \| \| Regular High School Diploma \|
Graduates \| \| 4-year Cohort Grad Rate \| Percentage \| \| Adult HS
Diploma \| Alternative completion \| \| Modified Diploma \| Alternative
completion \| \| Extended Diploma \| Alternative completion \| \| GED \|
Alternative completion \| \| Completer Rate \| Percentage \| \|
Continuing Enrollment \| Still enrolled \| \| Other Non-Completers \|
Dropouts/other \| \| Prior Year Grad Rate \| Year-over-year comparison
\| \| Institution Level \| “State”, “District”, “School” \|

**Subgroup Codes (Era 1):** \| Code \| Meaning \| \|——\|———\| \| Tot \|
All Students \| \| M \| Male \| \| F \| Female \| \| AM \| American
Indian/Alaska Native \| \| ASO \| Asian/Pacific Islander (combined) \|
\| PAC \| Pacific Islander \| \| ASN \| Asian \| \| BL \| Black/African
American \| \| HI \| Hispanic/Latino \| \| MU \| Multi-Racial \| \| WH
\| White \| \| USETH \| Underserved Races/Ethnicities \| \| ECODIS \|
Economically Disadvantaged \| \| WDIS \| Students with Disabilities \|
\| LEP \| Limited English Proficient \| \| TAG \| Talented and Gifted \|
\| CDIS \| Combined Disadvantaged \|

#### Era 2: 2013-14 to 2018-19 (Transitional .xlsx)

**Sheets:** - `Notes` - `4-Year Cohort Rates` - `5-Year Cohort Rates` -
`4-Year Cohort Trends` - `5-Year Cohort Trends`

**Columns have embedded line breaks () in headers** - requires cleaning.

**Column names include year prefix in rates columns** (e.g.,
`2018-19 Four-year Cohort Graduation Rate`)

**Student Group values changed from codes to full names:** - “All
Students” instead of “Tot” - “Male” instead of “M” - etc.

#### Era 3: 2019-20 to Present (Modern .xlsx)

**Sheets:** - `Notes` - `4YR State and County` -
`5YR State and County` - `4YR District and School` -
`5YR District and School`

**Clean column headers (no embedded line breaks)**

**Columns (2023-24 example):** \| Column \| Description \|
\|——–\|————-\| \| County \| County name or “State of Oregon” \| \|
District ID \| 4-8 digit numeric ID (99999905 for state) \| \| District
Name \| “State Level” for state, district name otherwise \| \| School ID
\| 4-8 digit numeric ID \| \| School Name \| School name \| \| Student
Group \| Full text (30 categories) \| \| Adjusted Cohort \| Final cohort
count \| \| Oregon Diploma Awarded \| Standard diploma graduates \| \|
Participating in Post Graduate Scholars \| Post-grad program \| \|
Modified Diploma Awarded \| Alternative completion \| \| Graduates \|
Total graduates \| \| {Year} Four-year Cohort Graduation Rate \|
Percentage \| \| Adult High School Diploma \| Alternative completion \|
\| Extended Diploma \| Alternative completion \| \| GED \| GED
completers \| \| Other Completers \| Other completion types \| \| {Year}
Four-year Cohort Completer Rate \| Percentage \| \| Alternative
Certificate \| Non-diploma completion \| \| Continuing Enrollment \|
Still enrolled \| \| Other Non-Completers \| Dropouts/other \| \|
Institution Level \| “District” or “High School” \| \| Prior Year Grad
Rate \| Year-over-year comparison \|

### Student Groups by Year

| Era               | Count     | Notable Differences                                                                                 |
|-------------------|-----------|-----------------------------------------------------------------------------------------------------|
| Era 1 (2009-2013) | 21 codes  | Uses abbreviation codes                                                                             |
| Era 2 (2014-2019) | 23 groups | Full names, Asian/Pacific Islander still combined                                                   |
| Era 3 (2020-2024) | 30 groups | Added: Non-Binary, Foster Care, Military Connected, Currently/Formerly Incarcerated, Recent Arriver |

### ID System

**District ID:** - 4-digit numeric (e.g., 2063, 2243) - State level uses
9999 (Era 1-2) or 99999905 (Era 3) - Should be stored as character to
match enrollment data

**School ID:** - 4-digit numeric (e.g., 708, 1186) - Same ID may appear
under different districts (charter schools)

### Known Data Issues

1.  **Embedded line breaks in Era 2 headers** - Column names contain
    `\r\n` characters
2.  **Multi-row headers in Era 1** - Requires skip=2 when reading
3.  **Column name variation** - Rate column names include year prefix
4.  **Suppressed values** - Small counts may show `*` or `-`
5.  **State ID changed** - 9999 in Era 1-2, 99999905 in Era 3

------------------------------------------------------------------------

## Time Series Heuristics

### State-Level Cohort and Graduation Data

| Year    | Adjusted Cohort | 4-Year Grad Rate |
|---------|-----------------|------------------|
| 2023-24 | 47,430          | 81.75%           |
| 2018-19 | 46,162          | 80.01%           |
| 2011-12 | 46,704          | 68.44%           |

### Expected Ranges

| Metric                       | Expected Range  | Red Flag If    |
|------------------------------|-----------------|----------------|
| State adjusted cohort        | 42,000 - 52,000 | Outside range  |
| 4-year graduation rate       | 65% - 90%       | \<60% or \>95% |
| Year-over-year cohort change | \< 5%           | \>10% change   |
| Year-over-year rate change   | \< 3%           | \>5% change    |
| District count               | 180 - 210       | Sudden change  |
| High school count            | 450 - 600       | Sudden change  |

### Major Districts to Verify (Portland Metro)

| District                | ID   | Expected Cohort |
|-------------------------|------|-----------------|
| Portland Public Schools | 2180 | 3,000 - 4,000   |
| Beaverton SD            | 2243 | 2,500 - 3,500   |
| Salem-Keizer SD         | 2151 | 3,000 - 4,000   |
| Hillsboro SD            | 2246 | 1,500 - 2,500   |
| Eugene 4J               | 2097 | 1,000 - 1,500   |

------------------------------------------------------------------------

## Recommended Implementation

### Priority: HIGH

This is a commonly requested data type that complements enrollment data
well.

### Complexity: MEDIUM

- Multiple file format eras (similar to enrollment)
- Subgroup code evolution requires mapping
- Column name cleaning required for Era 2
- 4-year vs 5-year rates in separate sheets

### Estimated Files to Modify/Create

| File                                     | Action                                  |
|------------------------------------------|-----------------------------------------|
| R/get_raw_graduation.R                   | Create - download and parse Excel files |
| R/process_graduation.R                   | Create - normalize schema across eras   |
| R/tidy_graduation.R                      | Create - pivot to long format           |
| R/fetch_graduation.R                     | Create - user-facing wrapper            |
| R/utils.R                                | Modify - add grad-specific helpers      |
| tests/testthat/test-pipeline-grad-live.R | Create - LIVE pipeline tests            |
| tests/testthat/test-raw-grad-fidelity.R  | Create - raw data fidelity tests        |

### Implementation Steps

1.  **Create URL building function**
    - Handle year suffix variations (`_revised`)
    - Handle format change (.xls vs .xlsx)
2.  **Create raw data download function**
    - Similar structure to get_raw_enr()
    - Era detection based on year
    - Sheet selection (4YR vs 5YR, State/County vs District/School)
3.  **Create schema normalization**
    - Standardize column names across eras
    - Map subgroup codes to full names
    - Handle embedded line breaks in Era 2
    - Standardize Institution Level values
4.  **Create tidy transformation**
    - Long format with: end_year, type, district_id, campus_id, names,
      student_group, cohort_type (4yr/5yr), adjusted_cohort, graduates,
      graduation_rate, etc.
5.  **Create fetch_grad() wrapper**
    - Similar API to fetch_enr()
    - Optional cohort_type parameter (4yr, 5yr, both)
    - tidy/wide format options
    - Caching support

------------------------------------------------------------------------

## Test Requirements

### Raw Data Fidelity Tests Needed

| Year | Entity               | Metric           | Expected Value |
|------|----------------------|------------------|----------------|
| 2024 | State (All Students) | Adjusted Cohort  | 47,430         |
| 2024 | State (All Students) | Graduates        | 38,773         |
| 2024 | State (All Students) | 4-Year Grad Rate | 81.75%         |
| 2019 | State (All Students) | Adjusted Cohort  | 46,162         |
| 2019 | State (All Students) | 4-Year Grad Rate | 80.01%         |
| 2012 | State (Tot)          | Adjusted Cohort  | 46,704         |
| 2012 | State (Tot)          | 4-Year Grad Rate | 68.44%         |

### Data Quality Checks

``` r
# Graduation rates should be 0-100
expect_true(all(data$graduation_rate >= 0 & data$graduation_rate <= 100))

# Graduates should not exceed adjusted cohort
expect_true(all(data$graduates <= data$adjusted_cohort))

# Completer rate should be >= graduation rate
expect_true(all(data$completer_rate >= data$graduation_rate, na.rm = TRUE))

# State totals should exist for all years
expect_equal(length(unique(state_data$end_year)), 16)
```

### LIVE Pipeline Tests

1.  **URL Availability** - All 16 cohort media file URLs return HTTP 200
2.  **File Download** - Files download completely, correct file type
3.  **File Parsing** - readxl succeeds, correct sheets found
4.  **Column Structure** - Required columns exist per era
5.  **Year Filtering** - Single year extraction works
6.  **Aggregation** - State = sum(districts) within tolerance
7.  **Data Quality** - No Inf/NaN, valid percentage ranges
8.  **Output Fidelity** - tidy=TRUE matches raw data

------------------------------------------------------------------------

## Additional Notes

### Related Data: Dropout Tables

The dropout tables could be implemented as a separate function or
combined with graduation data. They provide: - Annual dropout counts
(not cohort-based) - Available back to 2000-01 - Different granularity
than cohort graduation rates

Consider implementing as `fetch_dropout()` separately.

### Intersectional Data (2023-24+)

Recent years include intersectional-level cohort files that break down
by multiple demographic combinations. This is a potential future
enhancement.

### Policy Manual

Oregon publishes an annual Cohort Graduation Rate Policy and Technical
Manual (PDF) that documents methodology. Consider linking to this in
package documentation.
