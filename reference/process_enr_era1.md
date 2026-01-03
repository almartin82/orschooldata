# Process Era 1 data (2010-2014)

Era 1 files (.xls format) use the same year-prefixed column naming as
Era 2, but with some differences in ID column naming conventions:

- attnd_distinstid, attnd_schlinstid (2010)

- attending_district_institution_id (2011+)

## Usage

``` r
process_enr_era1(df, end_year)
```

## Arguments

- df:

  Raw data frame

- end_year:

  School year end

## Value

Processed data frame
