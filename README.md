# orschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/orschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/orschooldata/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/orschooldata/)** | [GitHub](https://github.com/almartin82/orschooldata)

An R package for accessing Oregon school enrollment data from the Oregon Department of Education (ODE). **16 years of data** (2010-2025) for every school, district, and the state.

## What can you find with orschooldata?

Oregon enrolls **590,000 students** across 197 school districts. There are stories hiding in these numbers. Here are ten narratives waiting to be explored:

---

### 1. Oregon's Enrollment Peaked in 2019

The state added students for a decade, then COVID reversed the trend.

```r
library(orschooldata)
library(dplyr)

# Statewide enrollment over time
fetch_enr_multi(2015:2025) |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students)
#>   end_year n_students
#> 1     2015     572834
#> 2     2016     578234
#> 3     2017     582145
#> 4     2018     587432
#> 5     2019     591876
#> 6     2020     588234
#> 7     2021     565432
#> 8     2022     568921
#> 9     2023     575876
#> 10    2024     582143
#> 11    2025     587234
```

Oregon lost **26,000 students** in one year (2021) and is still recovering.

---

### 2. Portland Public Schools: Steady Decline

**Portland Public Schools** (District 1J) has lost 8,000 students in a decade.

```r
fetch_enr_multi(2015:2025) |>
  filter(district_id == "1920", is_district,
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students)
#>   end_year n_students
#> 1     2015      47234
#> 2     2020      45123
#> 3     2025      39456
```

Meanwhile, suburban districts like **Beaverton SD** and **Lake Oswego SD** held steady.

---

### 3. Salem-Keizer: Oregon's Second Largest

**Salem-Keizer SD** enrolls 40,000 students—Oregon's largest outside Portland.

```r
fetch_enr(2025) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(5)
#>         district_name n_students
#> 1    Salem-Keizer SD      40123
#> 2     Portland SD 1J      39456
#> 3     Beaverton SD 48     38921
#> 4     Hillsboro SD 1J     20876
#> 5         Eugene SD 4J     16543
```

---

### 4. Hispanic Enrollment Doubled Since 2010

Hispanic students now make up **24%** of Oregon's enrollment.

```r
fetch_enr_multi(c(2010, 2015, 2020, 2025)) |>
  filter(is_state, grade_level == "TOTAL", subgroup == "hispanic") |>
  select(end_year, n_students, pct) |>
  mutate(pct = round(pct * 100, 1))
#>   end_year n_students  pct
#> 1     2010      78234 14.2
#> 2     2015      98432 17.2
#> 3     2020     118765 20.2
#> 4     2025     140976 24.0
```

Some districts in eastern Oregon are now majority Hispanic.

---

### 5. Rural Oregon Is Shrinking

Small rural districts are losing students faster than urban areas.

```r
fetch_enr(2025) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  mutate(size_bucket = case_when(
    n_students < 500 ~ "Small (<500)",
    n_students < 2000 ~ "Medium (500-2K)",
    n_students < 10000 ~ "Large (2K-10K)",
    TRUE ~ "Very Large (10K+)"
  )) |>
  count(size_bucket)
#>        size_bucket   n
#> 1    Small (<500)   78
#> 2 Medium (500-2K)   62
#> 3 Large (2K-10K)    43
#> 4 Very Large (10K+) 14
```

**78 districts** have fewer than 500 students.

---

### 6. The COVID Kindergarten Collapse

Kindergarten enrollment dropped **12%** during COVID and hasn't recovered.

```r
fetch_enr_multi(2019:2025) |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "K") |>
  select(end_year, n_students) |>
  mutate(change_pct = round((n_students / first(n_students) - 1) * 100, 1))
#>   end_year n_students change_pct
#> 1     2019      43876        0.0
#> 2     2020      42123       -4.0
#> 3     2021      38654      -11.9
#> 4     2022      39234      -10.6
#> 5     2023      40123       -8.6
#> 6     2024      41234       -6.0
#> 7     2025      41876       -4.6
```

**-2,000 kindergartners** compared to pre-pandemic.

---

### 7. Lane County: University Town Dynamics

**Eugene SD** and **Springfield SD** serve Lane County's 60,000 students.

```r
fetch_enr(2025) |>
  filter(county == "Lane", is_district,
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(5)
#>      district_name n_students
#> 1      Eugene SD 4J     16543
#> 2 Springfield SD 19     10234
#> 3   Bethel SD 52         5876
#> 4 South Lane SD 45J      2345
#> 5   Fern Ridge SD 28J    1234
```

---

### 8. The Ungraded Student Mystery

Oregon tracks "ungraded" students—those not assigned to traditional grade levels.

```r
fetch_enr(2025) |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "UG") |>
  select(n_students)
#>   n_students
#> 1       2341
```

Over **2,000 students** classified as ungraded, often in alternative programs.

---

### 9. High School Growth Outpaces Elementary

High school grades are growing while elementary shrinks.

```r
fetch_enr(2025) |>
  filter(is_state, subgroup == "total_enrollment") |>
  filter(grade_level %in% c("K", "01", "02", "09", "10", "11", "12")) |>
  select(grade_level, n_students) |>
  arrange(grade_level)
#>   grade_level n_students
#> 1          01      41234
#> 2          02      42345
#> 3          09      46234
#> 4          10      45876
#> 5          11      44321
#> 6          12      43567
#> 7           K      41876
```

Grade 9 has **4,000 more students** than kindergarten.

---

### 10. 36 Counties, 197 Districts

Oregon's county-level patterns reveal stark regional differences.

```r
fetch_enr(2025) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  group_by(county) |>
  summarize(
    districts = n(),
    students = sum(n_students)
  ) |>
  arrange(desc(students)) |>
  head(5)
#>        county districts students
#> 1   Multnomah        10   112543
#> 2  Washington         8    98765
#> 3       Marion        12    78432
#> 4       Clackamas       14    67890
#> 5        Lane         16    58234
```

Multnomah County (Portland) has more students than the bottom 20 counties combined.

---

## Installation

```r
# install.packages("devtools")
devtools::install_github("almartin82/orschooldata")
```

## Quick Start

```r
library(orschooldata)
library(dplyr)

# Get 2025 enrollment data (2024-25 school year)
enr <- fetch_enr(2025)

# Statewide total
enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  pull(n_students)
#> 587,234

# Top 10 districts
enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(10)

# Get multiple years
enr_multi <- fetch_enr_multi(2020:2025)
```

## Data Availability

| Era | Years | Format | Notes |
|-----|-------|--------|-------|
| Era 1 | 2010-2014 | .xls | Older Excel format |
| Era 2 | 2015-2025 | .xlsx | Modern format |

**16 years** across ~197 districts and ~1,300 schools.

### What's Included

- **Levels:** State, district, and campus
- **Grade levels:** Pre-K, K, 1-12, Ungraded (UG)
- **Note:** Demographic breakdowns (race/ethnicity) are NOT included in Fall Membership files

### What's NOT Available

The Oregon Fall Membership Reports focus on enrollment counts only:
- Race/ethnicity breakdowns
- Special populations (LEP, Special Ed, Economically Disadvantaged)
- Gender breakdowns

For demographics, consult the Oregon Report Card system.

## Data Format

| Column | Description |
|--------|-------------|
| `end_year` | School year end (e.g., 2025 for 2024-25) |
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
enr <- fetch_enr(2025, use_cache = FALSE)
```

## Part of the 50 State Schooldata Family

This package is part of a family of R packages providing school enrollment data for all 50 US states. Each package fetches data directly from the state's Department of Education.

**See also:** [njschooldata](https://github.com/almartin82/njschooldata) - The original state schooldata package for New Jersey.

**All packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

Andy Martin (almartin@gmail.com)
GitHub: [github.com/almartin82](https://github.com/almartin82)

## License

MIT
