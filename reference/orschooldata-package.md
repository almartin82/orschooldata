# orschooldata: Fetch and Process Oregon School Data

Downloads and processes school data from the Oregon Department of
Education (ODE). Provides functions for fetching enrollment data from
the Fall Membership Reports and transforming it into tidy format for
analysis.

## Main functions

- [`fetch_enr`](https://almartin82.github.io/orschooldata/reference/fetch_enr.md):

  Fetch enrollment data for a school year

- [`fetch_enr_multi`](https://almartin82.github.io/orschooldata/reference/fetch_enr_multi.md):

  Fetch enrollment data for multiple years

- [`tidy_enr`](https://almartin82.github.io/orschooldata/reference/tidy_enr.md):

  Transform wide data to tidy (long) format

- [`id_enr_aggs`](https://almartin82.github.io/orschooldata/reference/id_enr_aggs.md):

  Add aggregation level flags

- [`enr_grade_aggs`](https://almartin82.github.io/orschooldata/reference/enr_grade_aggs.md):

  Create grade-level aggregations

- [`get_available_years`](https://almartin82.github.io/orschooldata/reference/get_available_years.md):

  Get list of available data years

## Cache functions

- [`cache_status`](https://almartin82.github.io/orschooldata/reference/cache_status.md):

  View cached data files

- [`clear_cache`](https://almartin82.github.io/orschooldata/reference/clear_cache.md):

  Remove cached data files

## ID System

Oregon uses the following ID structure:

- District IDs: 4-digit numeric codes (e.g., 0001 = Baker SD)

- School IDs: Variable length numeric codes

- Institution IDs: Combined district + school identifier

## Data Sources

Data is sourced from the Oregon Department of Education's Fall
Membership Reports:

- Fall Membership:
  <https://www.oregon.gov/ode/reports-and-data/students/Pages/Student-Enrollment-Reports.aspx>

- ODE Home: <https://www.oregon.gov/ode>

## Format Eras

Oregon enrollment data has two distinct format eras:

- Era 1: 2010-2014:

  .xls format with older column structure

- Era 2: 2015-present:

  .xlsx format with standardized columns

## See also

Useful links:

- <https://github.com/almartin82/orschooldata>

- Report bugs at <https://github.com/almartin82/orschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
