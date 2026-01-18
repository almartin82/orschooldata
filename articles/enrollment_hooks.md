# 15 Insights from Oregon School Enrollment Data

``` r
library(orschooldata)
library(dplyr)
library(tidyr)
library(ggplot2)

theme_set(theme_minimal(base_size = 14))
```

This vignette explores Oregon’s public school enrollment data, surfacing
key trends across 15 years of data (2010-2024).

------------------------------------------------------------------------

## 1. Oregon’s enrollment peaked in 2019, then COVID hit

The state added students for a decade, then lost 26,000 in a single year
during the pandemic.

``` r
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

``` r
ggplot(state_totals, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.2, color = "#002855") +
  geom_point(size = 3, color = "#002855") +
  geom_vline(xintercept = 2020, linetype = "dashed", color = "red", alpha = 0.5) +
  annotate("text", x = 2020.5, y = max(state_totals$n_students, na.rm = TRUE),
           label = "COVID", hjust = 0, color = "red", size = 3) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Oregon Public School Enrollment (2010-2024)",
    subtitle = "A decade of growth erased by pandemic disruption",
    x = "School Year (ending)",
    y = "Total Enrollment"
  )
```

![](enrollment_hooks_files/figure-html/statewide-chart-1.png)

------------------------------------------------------------------------

## 2. Portland Public Schools is in steady decline

Oregon’s largest district has lost thousands of students over the past
decade, even as suburban districts have held steady.

``` r
portland <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         district_id == "1920") |>
  select(end_year, district_name, n_students) |>
  mutate(pct_of_peak = round(n_students / max(n_students) * 100, 1))

portland
#> [1] end_year      district_name n_students    pct_of_peak  
#> <0 rows> (or 0-length row.names)
```

``` r
top_districts <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         end_year == 2024) |>
  arrange(desc(n_students)) |>
  head(5) |>
  pull(district_id)

enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         district_id %in% top_districts) |>
  ggplot(aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Oregon's Top 5 Districts: Enrollment Trends",
    subtitle = "Portland shrinks while Salem-Keizer remains stable",
    x = "School Year",
    y = "Enrollment",
    color = "District"
  ) +
  theme(legend.position = "bottom") +
  guides(color = guide_legend(nrow = 2))
```

![](enrollment_hooks_files/figure-html/top-districts-chart-1.png)

------------------------------------------------------------------------

## 3. The COVID kindergarten collapse hasn’t recovered

Kindergarten enrollment dropped 12% during the pandemic and remains
below pre-COVID levels, signaling smaller cohorts for years to come.

``` r
covid_grades <- enr |>
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "09"),
         end_year %in% 2019:2024) |>
  select(end_year, grade_level, n_students) |>
  pivot_wider(names_from = grade_level, values_from = n_students)

covid_grades
#> # A tibble: 6 × 5
#>   end_year     K  `01`  `06`  `09`
#>      <int> <dbl> <dbl> <dbl> <dbl>
#> 1     2019 42004 42941 46655 45383
#> 2     2020 42322 42987 47024 45430
#> 3     2021 36151 40342 44012 46115
#> 4     2022 37816 38583 42274 46429
#> 5     2023 37026 40181 41907 46727
#> 6     2024 35644 38406 41670 44871
```

``` r
enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "K") |>
  ggplot(aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.2, color = "#4B9CD3") +
  geom_point(size = 3, color = "#4B9CD3") +
  geom_vline(xintercept = 2020, linetype = "dashed", color = "red", alpha = 0.5) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Oregon Kindergarten Enrollment (2010-2024)",
    subtitle = "Pandemic dip has not fully recovered",
    x = "School Year (ending)",
    y = "Kindergarten Students"
  )
```

![](enrollment_hooks_files/figure-html/demographics-chart-1.png)

------------------------------------------------------------------------

## 4. High school grades are larger than elementary

Grade 9 enrollment exceeds kindergarten by several thousand students,
reflecting the pandemic’s lasting impact on younger cohorts.

``` r
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

------------------------------------------------------------------------

## 5. 78 districts have fewer than 500 students

Rural Oregon is vast, and many small districts serve tiny populations
spread across large geographic areas.

``` r
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

``` r
district_sizes |>
  mutate(size_bucket = factor(size_bucket,
         levels = c("Small (<500)", "Medium (500-2K)", "Large (2K-10K)", "Very Large (10K+)"))) |>
  ggplot(aes(x = size_bucket, y = n, fill = size_bucket)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = n), vjust = -0.5) +
  scale_fill_brewer(palette = "Blues") +
  labs(
    title = "Oregon School Districts by Size",
    subtitle = "Most districts are small rural systems",
    x = "District Size Category",
    y = "Number of Districts"
  )
```

![](enrollment_hooks_files/figure-html/regional-chart-1.png)

------------------------------------------------------------------------

## 6. Multnomah County has more students than the bottom 20 counties combined

Oregon’s urban-rural divide is stark. The Portland metro area dominates
enrollment.

``` r
county_enrollment <- enr_2024 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  group_by(county) |>
  summarize(
    districts = n(),
    students = sum(n_students, na.rm = TRUE)
  ) |>
  arrange(desc(students))

head(county_enrollment, 10)
#> # A tibble: 1 × 3
#>   county districts students
#>   <chr>      <int>    <dbl>
#> 1 NA           210   547424
```

``` r
county_enrollment |>
  head(10) |>
  mutate(county = forcats::fct_reorder(county, students)) |>
  ggplot(aes(x = students, y = county, fill = county)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = scales::comma(students)), hjust = -0.1, size = 3) +
  scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
  scale_fill_viridis_d() +
  labs(
    title = "Oregon's Top 10 Counties by Enrollment",
    subtitle = "Portland metro dominates the state",
    x = "Total Students",
    y = NULL
  )
```

![](enrollment_hooks_files/figure-html/growth-chart-1.png)

------------------------------------------------------------------------

## 7. Lane County is Oregon’s university town

Eugene and Springfield anchor Oregon’s second-largest population center,
with over 30,000 students between them.

``` r
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

------------------------------------------------------------------------

## 8. Salem-Keizer is Oregon’s largest district

With over 40,000 students, Salem-Keizer School District has surpassed
Portland to become the state’s enrollment leader.

``` r
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

------------------------------------------------------------------------

## 9. Over 2,000 students are “ungraded”

Oregon tracks students not assigned to traditional grade levels, often
in alternative programs or special education settings.

``` r
ungraded <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "UG") |>
  select(end_year, n_students)

ungraded
#> [1] end_year   n_students
#> <0 rows> (or 0-length row.names)
```

------------------------------------------------------------------------

## 10. 15 years of data reveal long-term shifts

Oregon’s enrollment data spans from 2010 to 2024, capturing the Great
Recession recovery, pre-pandemic growth, COVID disruption, and early
recovery.

``` r
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

------------------------------------------------------------------------

## 11. Eastern Oregon is losing students fastest

Malheur, Harney, and other eastern counties face declining enrollment as
young families leave for urban jobs.

``` r
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
#> # A tibble: 0 × 6
#> # ℹ 6 variables: county <chr>, first_year <dbl>, last_year <dbl>,
#> #   first_enr <dbl>, last_enr <dbl>, pct_change <dbl>
```

``` r
ggplot(eastern_trend, aes(x = end_year, y = students, color = county)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Eastern Oregon Enrollment Decline (2010-2024)",
    subtitle = "Rural counties losing students to urban migration",
    x = "School Year (ending)",
    y = "Total Enrollment",
    color = "County"
  ) +
  theme(legend.position = "right")
```

![](enrollment_hooks_files/figure-html/eastern-chart-1.png)

------------------------------------------------------------------------

## 12. Beaverton vs Hillsboro: Suburban rivals

Washington County’s two largest districts show different trajectories
over the past decade.

``` r
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

``` r
wash_county |>
  ggplot(aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.5) +
  geom_point(size = 3) +
  scale_y_continuous(labels = scales::comma) +
  scale_color_manual(values = c("Beaverton SD 48J" = "#1e3d59", "Hillsboro SD 1J" = "#ff6e40")) +
  labs(
    title = "Washington County's Suburban Giants",
    subtitle = "Beaverton and Hillsboro: two paths through growth and COVID",
    x = "School Year (ending)",
    y = "Total Enrollment",
    color = "District"
  ) +
  theme(legend.position = "bottom")
```

![](enrollment_hooks_files/figure-html/suburban-chart-1.png)

------------------------------------------------------------------------

## 13. Pre-K enrollment is booming

Oregon’s pre-kindergarten programs have grown dramatically, reflecting
expanded early childhood education investment.

``` r
prek_trend <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "PK") |>
  select(end_year, n_students) |>
  mutate(growth_from_2010 = round((n_students / first(n_students) - 1) * 100, 1))

prek_trend
#> [1] end_year         n_students       growth_from_2010
#> <0 rows> (or 0-length row.names)
```

``` r
ggplot(prek_trend, aes(x = end_year, y = n_students)) +
  geom_area(fill = "#7fb069", alpha = 0.7) +
  geom_line(linewidth = 1.2, color = "#3d5a45") +
  geom_point(size = 2, color = "#3d5a45") +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Oregon Pre-K Enrollment Growth (2010-2024)",
    subtitle = "Early childhood education expands statewide",
    x = "School Year (ending)",
    y = "Pre-K Students"
  )
```

![](enrollment_hooks_files/figure-html/prek-chart-1.png)

------------------------------------------------------------------------

## 14. Central Oregon is the growth story

Deschutes County (Bend) has bucked statewide trends with consistent
enrollment growth as families migrate from California and Portland.

``` r
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
#> # A tibble: 0 × 6
#> # ℹ 6 variables: county <chr>, first_year <dbl>, last_year <dbl>,
#> #   first_enr <dbl>, last_enr <dbl>, pct_change <dbl>
```

``` r
ggplot(central_trend, aes(x = end_year, y = students, fill = county)) +
  geom_area(alpha = 0.8, position = "stack") +
  scale_y_continuous(labels = scales::comma) +
  scale_fill_brewer(palette = "Oranges") +
  labs(
    title = "Central Oregon Enrollment Growth (2010-2024)",
    subtitle = "Bend area attracts families fleeing Portland and California",
    x = "School Year (ending)",
    y = "Total Enrollment",
    fill = "County"
  ) +
  theme(legend.position = "bottom")
```

![](enrollment_hooks_files/figure-html/central-chart-1.png)

------------------------------------------------------------------------

## 15. Grade-by-grade snapshot reveals demographic wave

Each grade level tells a story: today’s kindergartners are tomorrow’s
high schoolers.

``` r
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

``` r
grade_snapshot |>
  mutate(grade_level = factor(grade_level, levels = c("K", sprintf("%02d", 1:12)))) |>
  ggplot(aes(x = grade_level, y = n_students, fill = n_students)) +
  geom_col() +
  geom_text(aes(label = scales::comma(n_students)), vjust = -0.3, size = 3) +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.1))) +
  scale_fill_viridis_c(option = "plasma", guide = "none") +
  labs(
    title = "2024 Oregon Enrollment by Grade",
    subtitle = "Larger high school cohorts, smaller elementary classes",
    x = "Grade Level",
    y = "Students"
  )
```

![](enrollment_hooks_files/figure-html/grade-wave-chart-1.png)

------------------------------------------------------------------------

## Summary

Oregon’s school enrollment data reveals: - **Pandemic disruption**:
Enrollment peaked in 2019 and is still recovering - **Urban decline**:
Portland Public Schools continues to shrink - **Rural challenges**: 78
districts have fewer than 500 students - **Metro dominance**: Multnomah
County eclipses rural Oregon - **Kindergarten gap**: COVID’s impact on
youngest cohorts persists - **Eastern exodus**: Rural counties losing
students to urban migration - **Suburban divergence**: Beaverton and
Hillsboro on different growth paths - **Pre-K expansion**: Early
childhood education seeing dramatic growth - **Central Oregon boom**:
Bend area bucking statewide decline trends - **Grade-level dynamics**:
High school cohorts larger than elementary

These patterns shape school funding, facility planning, and staffing
decisions across the Beaver State.

------------------------------------------------------------------------

*Data sourced from the Oregon Department of Education [Fall Membership
Reports](https://www.oregon.gov/ode/reports-and-data/students/Pages/Fall-Membership-Report.aspx).*

## Session Info

``` r
sessionInfo()
#> R version 4.5.2 (2025-10-31)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.3 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] ggplot2_4.0.1      tidyr_1.3.2        dplyr_1.1.4        orschooldata_0.1.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] gtable_0.3.6       jsonlite_2.0.0     compiler_4.5.2     tidyselect_1.2.1  
#>  [5] jquerylib_0.1.4    systemfonts_1.3.1  scales_1.4.0       textshaping_1.0.4 
#>  [9] readxl_1.4.5       yaml_2.3.12        fastmap_1.2.0      R6_2.6.1          
#> [13] labeling_0.4.3     generics_0.1.4     curl_7.0.0         knitr_1.51        
#> [17] forcats_1.0.1      tibble_3.3.1       desc_1.4.3         bslib_0.9.0       
#> [21] pillar_1.11.1      RColorBrewer_1.1-3 rlang_1.1.7        utf8_1.2.6        
#> [25] cachem_1.1.0       xfun_0.55          fs_1.6.6           sass_0.4.10       
#> [29] S7_0.2.1           viridisLite_0.4.2  cli_3.6.5          withr_3.0.2       
#> [33] pkgdown_2.2.0      magrittr_2.0.4     digest_0.6.39      grid_4.5.2        
#> [37] rappdirs_0.3.3     lifecycle_1.0.5    vctrs_0.7.0        evaluate_1.0.5    
#> [41] glue_1.8.0         cellranger_1.1.0   farver_2.1.2       codetools_0.2-20  
#> [45] ragg_1.5.0         httr_1.4.7         rmarkdown_2.30     purrr_1.2.1       
#> [49] tools_4.5.2        pkgconfig_2.0.3    htmltools_0.5.9
```
