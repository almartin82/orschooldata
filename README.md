# orschooldata

<!-- badges: start -->
<!-- badges: end -->

An R package for fetching, processing, and analyzing school enrollment data from Oregon's Department of Education. It provides a programmatic interface to public school data, enabling researchers, analysts, and education policy professionals to easily access Oregon public school data across the full historical record.

## Installation

You can install the development version of orschooldata from GitHub:
```r
# install.packages("devtools")
devtools::install_github("almartin82/orschooldata")
```

## Quick Start

```r
library(orschooldata)

# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# Get wide format (one row per school)
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Get multiple years
enr_multi <- fetch_enr_multi(2020:2024)

# Check available years
get_available_years()
```

## Data Availability

### Coverage
- **Years Available**: 2010 to 2025 (16 school years)
- **Aggregation Levels**: State, District, School (Campus)
- **Primary Metric**: Student enrollment counts

### Format Eras

Oregon enrollment data has two distinct format eras:

| Era | Years | File Format | Notes |
|-----|-------|-------------|-------|
| Era 1 | 2010-2014 | .xls | Older Excel format, column names may vary |
| Era 2 | 2015-present | .xlsx | Modern Excel format, standardized columns |

### Available Data Elements

| Element | 2010-2014 | 2015-present |
|---------|-----------|--------------|
| Total Enrollment | Yes | Yes |
| Grade K-12 | Yes | Yes |
| Pre-K | Varies | Yes |
| Ungraded (UG) | Varies | Yes |
| District ID | Yes | Yes |
| School ID | Yes | Yes |

### What's NOT Available

The Oregon Fall Membership Reports focus on enrollment counts and do not include:

- **Demographics**: Race/ethnicity breakdowns are not included in the Fall Membership files
- **Special Populations**: LEP, Special Education, Economically Disadvantaged counts
- **Gender**: Male/Female breakdowns
- **Staff Data**: Teacher counts, etc.

For demographic data, users should consult the Oregon Report Card system.

### Known Caveats

1. **Pre-2010 Data**: Data before 2009-10 requires contacting ODE directly. The 2009-10 file is an amended version with inconsistent formatting.

2. **Column Name Variations**: Earlier years (2010-2014) may have slightly different column naming conventions that are normalized during processing.

3. **Ungraded Students**: The "UG" (Ungraded) category appears in some years for students not assigned to a specific grade level.

4. **Charter Schools**: Charter schools are included in the data but are not flagged separately in all years.

## Data Source

Data is sourced from the Oregon Department of Education's Fall Membership Reports:

- **Main Page**: [Student Enrollment Reports](https://www.oregon.gov/ode/reports-and-data/students/Pages/Student-Enrollment-Reports.aspx)
- **Report Description**: The Fall Membership Report details K-12 students enrolled on the first school day in October each year.

## ID System

Oregon uses the following identifier structure:

| ID Type | Format | Example |
|---------|--------|---------|
| District ID | 4-digit numeric | 1920 (Portland SD) |
| School/Institution ID | Variable length | Combined district + school |

## Output Schema

### Wide Format (`tidy = FALSE`)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end (2024 = 2023-24) |
| type | character | "State", "District", or "Campus" |
| district_id | character | Oregon district identifier |
| campus_id | character | Oregon school identifier |
| district_name | character | District name |
| campus_name | character | School name |
| county | character | County name |
| row_total | integer | Total enrollment |
| grade_pk through grade_12 | integer | Grade-level enrollment |
| grade_ug | integer | Ungraded students |

### Tidy Format (`tidy = TRUE`, default)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end |
| type | character | Aggregation level |
| district_id | character | District identifier |
| campus_id | character | School identifier |
| district_name | character | District name |
| campus_name | character | School name |
| county | character | County name |
| grade_level | character | "TOTAL", "PK", "K", "01"-"12", "UG" |
| subgroup | character | "total_enrollment" |
| n_students | integer | Student count |
| pct | numeric | Percentage of total (0-1 scale) |
| is_state | logical | TRUE for state-level rows |
| is_district | logical | TRUE for district-level rows |
| is_campus | logical | TRUE for school-level rows |

## Caching

Downloaded data is cached locally to avoid repeated downloads:

```r
# Check cache status
cache_status()

# Clear all cached data
clear_cache()

# Clear specific year
clear_cache(2024)
```

Cache location: `rappdirs::user_cache_dir("orschooldata")`

## License

MIT

## See Also

- [Oregon Department of Education](https://www.oregon.gov/ode)
- [Oregon Report Card](https://www.ode.state.or.us/data/reportcard/reports.aspx)
- [NCES Common Core of Data](https://nces.ed.gov/ccd/) for federal education statistics
