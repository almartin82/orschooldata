# Process Era 2 data (2015-present)

Oregon ODE Fall Membership Reports use year-prefixed column names. For
example, 2023-24 data uses columns like:

- 20232024_total_enrollment (for the current year total)

- 202324_kindergarten, 202324_grade_one, etc. (for grade breakdowns)

## Usage

``` r
process_enr_era2(df, end_year)
```

## Arguments

- df:

  Raw data frame

- end_year:

  School year end

## Value

Processed data frame

## Details

The column naming conventions vary slightly between years:

- District ID: district_institution_id,
  attending_district_institution_id

- School ID: school_institution_id, attending_school_institution_id,
  attending_school_id

- District name: district_name, district

- School name: school_name, school
