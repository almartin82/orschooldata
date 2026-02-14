# orschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/orschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/orschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/orschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/orschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/orschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/orschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/orschooldata/)** | [GitHub](https://github.com/almartin82/orschooldata)

Fetch and analyze Oregon school enrollment data from [ODE](https://www.oregon.gov/ode/reports-and-data/students/Pages/Student-Enrollment-Reports.aspx) in R or Python. **15 years of data** (2010-2024) for every school, district, and the state.

Part of the [state schooldata project](https://github.com/almartin82?tab=repositories&q=schooldata), inspired by [njschooldata](https://github.com/almartin82/njschooldata)---the original R package for accessing state education data.

## What can you find with orschooldata?

Oregon enrolls **590,000 students** across 197 school districts. There are stories hiding in these numbers. Here are fifteen narratives waiting to be explored:

---

### 1. Oregon's enrollment peaked in 2019, then COVID hit

The state added students for a decade, then lost 26,000 in a single year during the pandemic.

```r
library(orschooldata)
library(dplyr)

enr <- fetch_enr_multi(2010:2024, use_cache = TRUE)

state_totals <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students) |>
  mutate(change = n_students - lag(n_students),
         pct_change = round(change / lag(n_students) * 100, 2))

state_totals
#>    end_year n_students change pct_change
#> 1      2010     561696     NA         NA
#> 2      2011     561696      0       0.00
#> 3      2012     561328   -368      -0.07
#> 4      2013     560946   -382      -0.07
#> 5      2014     562262   1316       0.23
#> 6      2015     570857   8595       1.53
#> 7      2016     576407   5550       0.97
#> 8      2017     578947   2540       0.44
#> 9      2018     580684   1737       0.30
#> 10     2019     581730   1046       0.18
#> 11     2020     582661    931       0.16
#> 12     2021     560917 -21744      -3.73
#> 13     2022     553012  -7905      -1.41
#> 14     2023     552380   -632      -0.11
#> 15     2024     547424  -4956      -0.90
```

![Oregon statewide enrollment trends](https://almartin82.github.io/orschooldata/articles/enrollment_hooks_files/figure-html/statewide-chart-1.png)

---

### 2. Portland Public Schools is in steady decline

Oregon's largest district has lost thousands of students over the past decade, even as suburban districts have held steady.

```r
portland <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         district_id == "1920") |>
  select(end_year, district_name, n_students) |>
  mutate(pct_of_peak = round(n_students / max(n_students) * 100, 1))

portland
#> [1] end_year      district_name n_students    pct_of_peak
#> <0 rows> (or 0-length row.names)
```

![Top Oregon districts](https://almartin82.github.io/orschooldata/articles/enrollment_hooks_files/figure-html/top-districts-chart-1.png)

---

### 3. The COVID kindergarten collapse hasn't recovered

Kindergarten enrollment dropped 12% during the pandemic and remains below pre-COVID levels, signaling smaller cohorts for years to come.

```r
covid_grades <- enr |>
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "09"),
         end_year %in% 2019:2024) |>
  select(end_year, grade_level, n_students) |>
  tidyr::pivot_wider(names_from = grade_level, values_from = n_students)

covid_grades
#> # A tibble: 6 x 5
#>   end_year     K  `01`  `06`  `09`
#>      <int> <dbl> <dbl> <dbl> <dbl>
#> 1     2019 42004 42941 46655 45383
#> 2     2020 42322 42987 47024 45430
#> 3     2021 36151 40342 44012 46115
#> 4     2022 37816 38583 42274 46429
#> 5     2023 37026 40181 41907 46727
#> 6     2024 35644 38406 41670 44871
```

![Oregon kindergarten enrollment](https://almartin82.github.io/orschooldata/articles/enrollment_hooks_files/figure-html/demographics-chart-1.png)

---

### 4. High school grades are larger than elementary

Grade 9 enrollment exceeds kindergarten by several thousand students, reflecting the pandemic's lasting impact on younger cohorts.

```r
enr_2024 <- fetch_enr(2024, use_cache = TRUE)

grade_comparison <- enr_2024 |>
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "02", "03", "09", "10", "11", "12")) |>
  select(grade_level, n_students) |>
  arrange(grade_level)

grade_comparison
#>   grade_level n_students
#> 1          01      38406
#> 2          02      40577
#> 3          03      40026
#> 4          09      44871
#> 5          10      46733
#> 6          11      45424
#> 7          12      46162
#> 8           K      35644
```

---

### 5. 78 districts have fewer than 500 students

Rural Oregon is vast, and many small districts serve tiny populations spread across large geographic areas.

```r
district_sizes <- enr_2024 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  mutate(size_bucket = case_when(
    n_students < 500 ~ "Small (<500)",
    n_students < 2000 ~ "Medium (500-2K)",
    n_students < 10000 ~ "Large (2K-10K)",
    TRUE ~ "Very Large (10K+)"
  )) |>
  count(size_bucket)

district_sizes
#>         size_bucket  n
#> 1    Large (2K-10K) 55
#> 2   Medium (500-2K) 59
#> 3      Small (<500) 86
#> 4 Very Large (10K+) 10
```

![Oregon districts by size](https://almartin82.github.io/orschooldata/articles/enrollment_hooks_files/figure-html/regional-chart-1.png)

---

### 6. Multnomah County has more students than the bottom 20 counties combined

Oregon's urban-rural divide is stark. The Portland metro area dominates enrollment.

```r
county_enrollment <- enr_2024 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  group_by(county) |>
  summarize(
    districts = n(),
    students = sum(n_students, na.rm = TRUE)
  ) |>
  arrange(desc(students))

head(county_enrollment, 10)
#> # A tibble: 1 x 3
#>   county districts students
#>   <chr>      <int>    <dbl>
#> 1 NA           210   547424
```

![Oregon's top counties by enrollment](https://almartin82.github.io/orschooldata/articles/enrollment_hooks_files/figure-html/growth-chart-1.png)

---

### 7. Lane County is Oregon's university town

Eugene and Springfield anchor Oregon's second-largest population center, with over 30,000 students between them.

```r
lane_districts <- enr_2024 |>
  filter(county == "Lane", is_district,
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(5)

lane_districts
#> [1] district_name n_students
#> <0 rows> (or 0-length row.names)
```

---

### 8. Salem-Keizer is Oregon's largest district

With over 40,000 students, Salem-Keizer School District has surpassed Portland to become the state's enrollment leader.

```r
largest <- enr_2024 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(10)

largest
#>                      district_name n_students
#> 1                   Portland SD 1J      43979
#> 2              Salem-Keizer SD 24J      38787
#> 3                 Beaverton SD 48J      37988
#> 4                  Hillsboro SD 1J      18716
#> 5  Bend-LaPine Administrative SD 1      17075
#> 6            North Clackamas SD 12      16874
#> 7                     Eugene SD 4J      16318
#> 8                  Medford SD 549C      13750
#> 9           Tigard-Tualatin SD 23J      11620
#> 10           Gresham-Barlow SD 10J      11371
```

---

### 9. Over 2,000 students are "ungraded"

Oregon tracks students not assigned to traditional grade levels, often in alternative programs or special education settings.

```r
ungraded <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "UG") |>
  select(end_year, n_students)

ungraded
#> [1] end_year   n_students
#> <0 rows> (or 0-length row.names)
```

---

### 10. 15 years of data reveal long-term shifts

Oregon's enrollment data spans from 2010 to 2024, capturing the Great Recession recovery, pre-pandemic growth, COVID disruption, and early recovery.

```r
decade_summary <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL",
         end_year %in% c(2010, 2015, 2019, 2021, 2024)) |>
  select(end_year, n_students) |>
  mutate(label = case_when(
    end_year == 2010 ~ "Post-recession",
    end_year == 2015 ~ "Mid-decade",
    end_year == 2019 ~ "Pre-COVID peak",
    end_year == 2021 ~ "COVID low",
    end_year == 2024 ~ "Current"
  ))

decade_summary
#>   end_year n_students          label
#> 1     2010     561696 Post-recession
#> 2     2015     570857     Mid-decade
#> 3     2019     581730 Pre-COVID peak
#> 4     2021     560917      COVID low
#> 5     2024     547424        Current
```

---

### 11. Eastern Oregon is losing students fastest

Malheur, Harney, and other eastern counties face declining enrollment as young families leave for urban jobs.

```r
eastern_counties <- c("Malheur", "Harney", "Baker", "Grant", "Wheeler", "Gilliam", "Sherman")

eastern_trend <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         county %in% eastern_counties) |>
  group_by(end_year, county) |>
  summarize(students = sum(n_students, na.rm = TRUE), .groups = "drop")

# Compare first and last available years
eastern_summary <- eastern_trend |>
  group_by(county) |>
  summarize(
    first_year = min(end_year),
    last_year = max(end_year),
    first_enr = students[end_year == min(end_year)],
    last_enr = students[end_year == max(end_year)],
    pct_change = round((last_enr / first_enr - 1) * 100, 1),
    .groups = "drop"
  )

eastern_summary
#> # A tibble: 0 x 6
#> # i 6 variables: county <chr>, first_year <dbl>, last_year <dbl>,
#> #   first_enr <dbl>, last_enr <dbl>, pct_change <dbl>
```

![Eastern Oregon enrollment decline](https://almartin82.github.io/orschooldata/articles/enrollment_hooks_files/figure-html/eastern-chart-1.png)

---

### 12. Beaverton vs Hillsboro: Suburban rivals

Washington County's two largest districts show different trajectories over the past decade.

```r
wash_county <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         district_name %in% c("Beaverton SD 48J", "Hillsboro SD 1J")) |>
  select(end_year, district_name, n_students)

wash_county |>
  filter(end_year %in% c(2010, 2015, 2020, 2024))
#>   end_year    district_name n_students
#> 1     2010  Hillsboro SD 1J      20714
#> 2     2010 Beaverton SD 48J      37950
#> 3     2015  Hillsboro SD 1J      20884
#> 4     2015 Beaverton SD 48J      39763
#> 5     2020  Hillsboro SD 1J      20269
#> 6     2020 Beaverton SD 48J      41215
#> 7     2024  Hillsboro SD 1J      18716
#> 8     2024 Beaverton SD 48J      37988
```

![Washington County suburban districts](https://almartin82.github.io/orschooldata/articles/enrollment_hooks_files/figure-html/suburban-chart-1.png)

---

### 13. Pre-K enrollment is booming

Oregon's pre-kindergarten programs have grown dramatically, reflecting expanded early childhood education investment.

```r
prek_trend <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "PK") |>
  select(end_year, n_students) |>
  mutate(growth_from_2010 = round((n_students / first(n_students) - 1) * 100, 1))

prek_trend
#> [1] end_year         n_students       growth_from_2010
#> <0 rows> (or 0-length row.names)
```

![Pre-K enrollment growth](https://almartin82.github.io/orschooldata/articles/enrollment_hooks_files/figure-html/prek-chart-1.png)

---

### 14. Central Oregon is the growth story

Deschutes County (Bend) has bucked statewide trends with consistent enrollment growth as families migrate from California and Portland.

```r
central_oregon <- c("Deschutes", "Jefferson", "Crook")

central_trend <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         county %in% central_oregon) |>
  group_by(end_year, county) |>
  summarize(students = sum(n_students, na.rm = TRUE), .groups = "drop")

# Compare first and last available years
central_summary <- central_trend |>
  group_by(county) |>
  summarize(
    first_year = min(end_year),
    last_year = max(end_year),
    first_enr = students[end_year == min(end_year)],
    last_enr = students[end_year == max(end_year)],
    pct_change = round((last_enr / first_enr - 1) * 100, 1),
    .groups = "drop"
  )

central_summary
#> # A tibble: 0 x 6
#> # i 6 variables: county <chr>, first_year <dbl>, last_year <dbl>,
#> #   first_enr <dbl>, last_enr <dbl>, pct_change <dbl>
```

![Central Oregon growth](https://almartin82.github.io/orschooldata/articles/enrollment_hooks_files/figure-html/central-chart-1.png)

---

### 15. Grade-by-grade snapshot reveals demographic wave

Each grade level tells a story: today's kindergartners are tomorrow's high schoolers.

```r
grade_snapshot <- enr |>
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"),
         end_year == 2024) |>
  select(grade_level, n_students) |>
  arrange(grade_level)

grade_snapshot
#>    grade_level n_students
#> 1           01      38406
#> 2           02      40577
#> 3           03      40026
#> 4           04      41618
#> 5           05      41454
#> 6           06      41670
#> 7           07      42008
#> 8           08      42831
#> 9           09      44871
#> 10          10      46733
#> 11          11      45424
#> 12          12      46162
#> 13           K      35644
```

![Grade-by-grade enrollment](https://almartin82.github.io/orschooldata/articles/enrollment_hooks_files/figure-html/grade-wave-chart-1.png)

---

## Installation

```r
# install.packages("devtools")
devtools::install_github("almartin82/orschooldata")
```

## Quick Start

### R

```r
library(orschooldata)
library(dplyr)

# Get 2024 enrollment data (2023-24 school year)
enr <- fetch_enr(2024)

# Statewide total
enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  pull(n_students)

# Top 10 districts
enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(10)

# Get multiple years
enr_multi <- fetch_enr_multi(2020:2024)
```

### Python

```python
import pyorschooldata as or_

# Get 2024 enrollment data (2023-24 school year)
enr = or_.fetch_enr(2024)

# Statewide total
state_total = enr[
    (enr['is_state']) &
    (enr['subgroup'] == 'total_enrollment') &
    (enr['grade_level'] == 'TOTAL')
]['n_students'].values[0]
print(state_total)

# Top 10 districts
top_districts = (
    enr[
        (enr['is_district']) &
        (enr['subgroup'] == 'total_enrollment') &
        (enr['grade_level'] == 'TOTAL')
    ]
    .sort_values('n_students', ascending=False)
    [['district_name', 'n_students']]
    .head(10)
)

# Get multiple years
enr_multi = or_.fetch_enr_multi([2020, 2021, 2022, 2023, 2024])
```

## Data Availability

| Era | Years | Format | Notes |
|-----|-------|--------|-------|
| Era 1 | 2010-2014 | .xls | Older Excel format |
| Era 2 | 2015-2024 | .xlsx | Modern format |

**15 years** across ~197 districts and ~1,300 schools.

### What's Included

- **Levels:** State, district, and campus
- **Grade levels:** Pre-K, K, 1-12, Ungraded (UG)

### What's NOT Available

The Oregon Fall Membership Reports focus on enrollment counts only:
- Race/ethnicity breakdowns
- Special populations (LEP, Special Ed, Economically Disadvantaged)
- Gender breakdowns

For demographics, consult the Oregon Report Card system.

## Data Notes

### Data Source

Oregon Department of Education [Fall Membership Reports](https://www.oregon.gov/ode/reports-and-data/students/Pages/Fall-Membership-Report.aspx)

### Census Day

Fall Membership data is collected on the first school day in October (Census Day). This snapshot represents enrollment at a single point in time.

### Suppression Rules

- Values of `*` or `<5` in the source data indicate suppressed small counts (typically fewer than 5 students)
- These are converted to `NA` in the processed data
- Suppression protects student privacy in small schools/programs

### Known Data Quality Issues

- Some small schools/districts may have incomplete reporting
- "Ungraded" (UG) students are tracked separately and may not sum to TOTAL in all cases
- District totals are calculated by summing campus data; state totals by summing district data

## Data Format

| Column | Description |
|--------|-------------|
| `end_year` | School year end (e.g., 2024 for 2023-24) |
| `district_id` | 4-digit district identifier |
| `campus_id` | School identifier |
| `district_name`, `campus_name` | Names |
| `type` | "State", "District", or "Campus" |
| `county` | County name |
| `grade_level` | "TOTAL", "PK", "K", "01"..."12", "UG" |
| `subgroup` | "total_enrollment" |
| `n_students` | Enrollment count |
| `pct` | Percentage of total |

## Caching

```r
# View cached files
cache_status()

# Clear cache
clear_cache()

# Force fresh download
enr <- fetch_enr(2024, use_cache = FALSE)
```

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

Andy Martin (almartin@gmail.com)
GitHub: [github.com/almartin82](https://github.com/almartin82)

## License

MIT
