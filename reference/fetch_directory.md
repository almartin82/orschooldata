# Fetch Oregon school directory data

Downloads and processes school directory data from the Oregon Department
of Education Report Card system. This includes public schools,
districts, and programs with their names, types, and locations.

## Usage

``` r
fetch_directory(end_year = NULL, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  Currently unused. The directory data represents current institutions
  and is not year-specific. Included for API consistency with other
  fetch functions.

- tidy:

  If TRUE (default), returns data in a standardized format with
  consistent column names. If FALSE, returns raw column names from ODE.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from ODE.

## Value

A tibble with school directory data. Columns include:

- `state_school_id`: Oregon institution ID

- `state_district_id`: Parent district institution ID (for schools)

- `school_name`: Institution name

- `district_name`: Parent district name (for schools)

- `school_type`: Type of institution (School, District, Program)

- `city`: City location

- `state`: State (always "OR")

- `agg_level`: Aggregation level ("S" = School, "D" = District, "P" =
  Program)

## Details

The directory data is retrieved via the ODE Report Card API, which
provides a JSON list of all institutions receiving report cards. This
data is updated periodically by ODE.

Note: This API does not include full addresses, phone numbers, or
administrator names. For complete contact information, download the
Oregon School Directory PDF from
<https://www.oregon.gov/ode/about-us/Pages/School-Directory.aspx>

## Examples

``` r
if (FALSE) { # \dontrun{
# Get school directory data
dir_data <- fetch_directory()

# Get raw format (original ODE column names)
dir_raw <- fetch_directory(tidy = FALSE)

# Force fresh download (ignore cache)
dir_fresh <- fetch_directory(use_cache = FALSE)

# Filter to schools only
library(dplyr)
schools_only <- dir_data |>
  filter(agg_level == "S")

# Find all schools in a district
portland_schools <- dir_data |>
  filter(district_name == "Portland SD 1J", agg_level == "S")
} # }
```
