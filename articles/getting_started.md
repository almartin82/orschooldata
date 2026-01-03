# Getting Started with orschooldata

The orschooldata package provides easy access to Oregon Department of
Education Fall Membership Reports, covering school years 2009-10 through
2023-24.

## Installation

``` r
# Install from GitHub
remotes::install_github("your-username/orschooldata")
```

## Quick Start

``` r
library(orschooldata)
library(dplyr)
```

### Check available years

``` r
get_available_years()
#>  [1] 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024
```

### Fetch single year

``` r
# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# View structure
glimpse(enr_2024)
#> Rows: 22,876
#> Columns: 14
#> $ end_year      <int> 2024, 2024, 2024, 2024, 2024, 2024, 2024, 2024, 2024, 20…
#> $ type          <chr> "State", "District", "District", "District", "District",…
#> $ district_id   <chr> NA, "1894", "1895", "1896", "1897", "1898", "1899", "190…
#> $ campus_id     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ district_name <chr> NA, "Baker SD 5J", "Huntington SD 16J", "Burnt River SD …
#> $ campus_name   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ county        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ grade_level   <chr> "TOTAL", "TOTAL", "TOTAL", "TOTAL", "TOTAL", "TOTAL", "T…
#> $ subgroup      <chr> "total_enrollment", "total_enrollment", "total_enrollmen…
#> $ n_students    <dbl> 547424, 4829, 85, 46, 219, 382, 281, 1667, 6118, 193, 90…
#> $ pct           <dbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,…
#> $ is_state      <lgl> TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ is_district   <lgl> FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, T…
#> $ is_campus     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
```

### Understanding the output

The tidy output contains:

- **end_year**: School year end (2024 = 2023-24)
- **type**: “State”, “District”, or “Campus”
- **district_id/campus_id**: Oregon ODE institution IDs
- **grade_level**: “TOTAL”, “K”, “01”-“12”
- **subgroup**: Currently only “total_enrollment”
- **n_students**: Enrollment count
- **pct**: Proportion of total
- **is_state/is_district/is_campus**: Boolean flags

### Filter by type

``` r
# State-level totals
state_total <- enr_2024 |>
  filter(is_state, grade_level == "TOTAL")

state_total$n_students
#> [1] 547424
```

``` r
# District-level data
districts <- enr_2024 |>
  filter(is_district, grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(10)

districts
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

### Wide format

For analysis that needs grade columns side-by-side, use `tidy = FALSE`:

``` r
enr_wide <- fetch_enr(2024, tidy = FALSE)
names(enr_wide)
#>  [1] "end_year"      "type"          "district_id"   "campus_id"    
#>  [5] "district_name" "campus_name"   "county"        "row_total"    
#>  [9] "grade_k"       "grade_01"      "grade_02"      "grade_03"     
#> [13] "grade_04"      "grade_05"      "grade_06"      "grade_07"     
#> [17] "grade_08"      "grade_09"      "grade_10"      "grade_11"     
#> [21] "grade_12"
```

## Multi-year Analysis

### Fetch multiple years

``` r
# Get 5 years of data
enr_multi <- fetch_enr_multi(2020:2024)

# State totals over time
state_trend <- enr_multi |>
  filter(is_state, grade_level == "TOTAL") |>
  select(end_year, n_students)

state_trend
#>   end_year n_students
#> 1     2020     581730
#> 2     2021     582661
#> 3     2022     560904
#> 4     2023     552990
#> 5     2024     547424
```

### Calculate year-over-year changes

``` r
state_trend |>
  mutate(
    change = n_students - lag(n_students),
    pct_change = round(change / lag(n_students) * 100, 2)
  )
#>   end_year n_students change pct_change
#> 1     2020     581730     NA         NA
#> 2     2021     582661    931       0.16
#> 3     2022     560904 -21757      -3.73
#> 4     2023     552990  -7914      -1.41
#> 5     2024     547424  -5566      -1.01
```

## Grade Aggregations

Create K-8, high school (9-12), and K-12 aggregates:

``` r
grade_aggs <- enr_grade_aggs(enr_2024)

# View state-level aggregates
grade_aggs |>
  filter(is_state) |>
  select(grade_level, n_students)
#> # A tibble: 3 × 2
#>   grade_level n_students
#>   <chr>            <dbl>
#> 1 K8              364234
#> 2 HS              183190
#> 3 K12             547424
```

## Caching

The package automatically caches downloaded data to speed up repeated
requests:

``` r
# First call downloads and caches
enr1 <- fetch_enr(2024)

# Second call uses cache (much faster)
enr2 <- fetch_enr(2024)

# Force fresh download
enr3 <- fetch_enr(2024, use_cache = FALSE)
```

### Manage cache

``` r
# List cached files
list_cache()

# Clear all cache
clear_cache()
```

## Common Patterns

### Find largest schools in a district

``` r
# Find schools in Portland (district_id = 1920)
portland_schools <- enr_2024 |>
  filter(is_campus, district_id == "1920", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(campus_name, n_students) |>
  head(10)

portland_schools
#> [1] campus_name n_students 
#> <0 rows> (or 0-length row.names)
```

### Compare grade distributions

``` r
# Elementary vs high school at state level
enr_2024 |>
  filter(is_state, grade_level %in% c("K", "01", "05", "09", "12")) |>
  select(grade_level, n_students)
#>   grade_level n_students
#> 1           K      35644
#> 2          01      38406
#> 3          05      41454
#> 4          09      44871
#> 5          12      46162
```

### Track a district over time

``` r
# Salem-Keizer (district_id = 2178) over 5 years
fetch_enr_multi(2020:2024) |>
  filter(is_district, district_id == "2178", grade_level == "TOTAL") |>
  select(end_year, district_name, n_students)
#> [1] end_year      district_name n_students   
#> <0 rows> (or 0-length row.names)
```

## Data Quality Notes

- Some schools report suppressed values (shown as `*` or `<5`) which
  become NA
- “Ungraded” (UG) students are tracked separately when present
- District totals are calculated by summing campus data
- State totals are calculated by summing district data

## Next Steps

- See
  [`vignette("enrollment_hooks")`](https://almartin82.github.io/orschooldata/articles/enrollment_hooks.md)
  for 10 insights from Oregon enrollment data
- Explore the raw data with `get_raw_enr(year)` to see original ODE
  columns
- Check
  [`?fetch_enr`](https://almartin82.github.io/orschooldata/reference/fetch_enr.md)
  for full documentation
