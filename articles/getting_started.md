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
#> Rows: 34,314
#> Columns: 15
#> $ end_year         <int> 2024, 2024, 2024, 2024, 2024, 2024, 2024, 2024, 2024,…
#> $ type             <chr> "State", "District", "District", "District", "Distric…
#> $ district_id      <chr> NA, "1894", "1895", "1896", "1897", "1898", "1899", "…
#> $ campus_id        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ district_name    <chr> NA, "Baker SD 5J", "Huntington SD 16J", "Burnt River …
#> $ campus_name      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ county           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ grade_level      <chr> "TOTAL", "TOTAL", "TOTAL", "TOTAL", "TOTAL", "TOTAL",…
#> $ subgroup         <chr> "total_enrollment", "total_enrollment", "total_enroll…
#> $ n_students       <dbl> 547424, 4829, 85, 46, 219, 382, 281, 1667, 6118, 193,…
#> $ pct              <dbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,…
#> $ aggregation_flag <chr> "state", "district", "district", "district", "distric…
#> $ is_state         <lgl> TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ is_district      <lgl> FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE…
#> $ is_campus        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
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
#> [1] 547424   6150  22288   4720  13114 141060 319798  40294
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
#> 4                   Portland SD 1J      24276
#> 5                  Hillsboro SD 1J      18716
#> 6              Salem-Keizer SD 24J      18050
#> 7  Bend-LaPine Administrative SD 1      17075
#> 8            North Clackamas SD 12      16874
#> 9                     Eugene SD 4J      16318
#> 10                Beaverton SD 48J      15716
```

### Wide format

For analysis that needs grade columns side-by-side, use `tidy = FALSE`:

``` r
enr_wide <- fetch_enr(2024, tidy = FALSE)
names(enr_wide)
#>  [1] "end_year"         "type"             "district_id"      "campus_id"       
#>  [5] "district_name"    "campus_name"      "county"           "row_total"       
#>  [9] "grade_k"          "grade_01"         "grade_02"         "grade_03"        
#> [13] "grade_04"         "grade_05"         "grade_06"         "grade_07"        
#> [17] "grade_08"         "grade_09"         "grade_10"         "grade_11"        
#> [21] "grade_12"         "native_american"  "asian"            "pacific_islander"
#> [25] "black"            "hispanic"         "white"            "multiracial"
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
#>    end_year n_students
#> 1      2020     582661
#> 2      2020       7010
#> 3      2020      23208
#> 4      2020       4431
#> 5      2020      13176
#> 6      2020     138273
#> 7      2020     358257
#> 8      2020      38306
#> 9      2021     560917
#> 10     2021       6570
#> 11     2021      22733
#> 12     2021       4335
#> 13     2021      13021
#> 14     2021     137101
#> 15     2021     338528
#> 16     2021      38629
#> 17     2022     553012
#> 18     2022       6357
#> 19     2022      22145
#> 20     2022       4454
#> 21     2022      12731
#> 22     2022     138112
#> 23     2022     329994
#> 24     2022      39219
#> 25     2023     552380
#> 26     2023       6532
#> 27     2023      22181
#> 28     2023       4633
#> 29     2023      12982
#> 30     2023     139928
#> 31     2023     326100
#> 32     2023      40024
#> 33     2024     547424
#> 34     2024       6150
#> 35     2024      22288
#> 36     2024       4720
#> 37     2024      13114
#> 38     2024     141060
#> 39     2024     319798
#> 40     2024      40294
```

### Calculate year-over-year changes

``` r
state_trend |>
  mutate(
    change = n_students - lag(n_students),
    pct_change = round(change / lag(n_students) * 100, 2)
  )
#>    end_year n_students  change pct_change
#> 1      2020     582661      NA         NA
#> 2      2020       7010 -575651     -98.80
#> 3      2020      23208   16198     231.07
#> 4      2020       4431  -18777     -80.91
#> 5      2020      13176    8745     197.36
#> 6      2020     138273  125097     949.43
#> 7      2020     358257  219984     159.09
#> 8      2020      38306 -319951     -89.31
#> 9      2021     560917  522611    1364.31
#> 10     2021       6570 -554347     -98.83
#> 11     2021      22733   16163     246.01
#> 12     2021       4335  -18398     -80.93
#> 13     2021      13021    8686     200.37
#> 14     2021     137101  124080     952.92
#> 15     2021     338528  201427     146.92
#> 16     2021      38629 -299899     -88.59
#> 17     2022     553012  514383    1331.60
#> 18     2022       6357 -546655     -98.85
#> 19     2022      22145   15788     248.36
#> 20     2022       4454  -17691     -79.89
#> 21     2022      12731    8277     185.83
#> 22     2022     138112  125381     984.85
#> 23     2022     329994  191882     138.93
#> 24     2022      39219 -290775     -88.12
#> 25     2023     552380  513161    1308.45
#> 26     2023       6532 -545848     -98.82
#> 27     2023      22181   15649     239.57
#> 28     2023       4633  -17548     -79.11
#> 29     2023      12982    8349     180.21
#> 30     2023     139928  126946     977.86
#> 31     2023     326100  186172     133.05
#> 32     2023      40024 -286076     -87.73
#> 33     2024     547424  507400    1267.74
#> 34     2024       6150 -541274     -98.88
#> 35     2024      22288   16138     262.41
#> 36     2024       4720  -17568     -78.82
#> 37     2024      13114    8394     177.84
#> 38     2024     141060  127946     975.64
#> 39     2024     319798  178738     126.71
#> 40     2024      40294 -279504     -87.40
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
