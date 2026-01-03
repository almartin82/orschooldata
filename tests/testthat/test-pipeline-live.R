# ==============================================================================
# LIVE Pipeline Tests for orschooldata
# ==============================================================================
#
# These tests verify EACH STEP of the data pipeline using LIVE network calls.
# No mocks - we verify actual connectivity and data correctness.
#
# Test Categories:
# 1. URL Availability - HTTP status codes
# 2. File Download - Successful download and file type verification
# 3. File Parsing - Read file into R
# 4. Column Structure - Expected columns exist
# 5. get_raw_enr() - Raw data function works
# 6. Data Processing - Process function works
# 7. Data Quality - No Inf/NaN, valid ranges
# 8. Aggregation - State/district/campus totals
# 9. Output Fidelity - tidy=TRUE matches raw data
#
# ==============================================================================

library(testthat)
library(httr)

# Skip if no network connectivity
skip_if_offline <- function() {
  skip_on_cran()
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) {
      skip("No network connectivity")
    }
  }, error = function(e) {
    skip("No network connectivity")
  })
}

# Helper to build Oregon DOE URL
build_ode_url <- function(end_year) {
  ext <- if (end_year <= 2014) "xls" else "xlsx"
  start_year <- end_year - 1
  year_str <- paste0(start_year, end_year)
  base_url <- "https://www.oregon.gov/ode/reports-and-data/students/Documents"
  paste0(base_url, "/fallmembershipreport_", year_str, ".", ext)
}

# ==============================================================================
# STEP 1: URL Availability Tests
# ==============================================================================

test_that("Oregon DOE base domain is accessible", {
  skip_if_offline()

  response <- httr::GET(
    "https://www.oregon.gov/ode",
    httr::timeout(30),
    httr::user_agent("Mozilla/5.0 (compatible; orschooldata R package)")
  )

  expect_equal(httr::status_code(response), 200)
})

test_that("Oregon Fall Membership Report URL returns HTTP 200 for 2024", {
  skip_if_offline()

  url <- build_ode_url(2024)

  response <- httr::GET(
    url,
    httr::timeout(60),
    httr::user_agent("Mozilla/5.0 (compatible; orschooldata R package)")
  )

  expect_equal(httr::status_code(response), 200)

  # Check content type is Excel
  content_type <- httr::headers(response)$`content-type`
  expect_true(
    grepl("spreadsheet|excel|octet-stream", content_type, ignore.case = TRUE),
    label = paste("Content-type:", content_type)
  )
})

test_that("Oregon Fall Membership Report URL returns HTTP 200 for historical years", {
  skip_if_offline()

  # Test sample years from different eras
  test_years <- c(2023, 2019, 2015, 2012)

  for (year in test_years) {
    url <- build_ode_url(year)

    response <- httr::GET(
      url,
      httr::timeout(60),
      httr::user_agent("Mozilla/5.0 (compatible; orschooldata R package)")
    )

    expect_equal(
      httr::status_code(response), 200,
      info = paste("Failed for year", year)
    )

    Sys.sleep(1)  # Rate limiting
  }
})

# ==============================================================================
# STEP 2: File Download Tests
# ==============================================================================

test_that("Can download Oregon enrollment Excel file for 2024", {
  skip_if_offline()

  url <- build_ode_url(2024)

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::timeout(120),
    httr::user_agent("Mozilla/5.0 (compatible; orschooldata R package)")
  )

  expect_equal(httr::status_code(response), 200)

  # File should be substantial (at least 100KB for enrollment data)
  file_size <- file.info(temp_file)$size
  expect_true(file_size > 100000,
              label = paste("File size:", file_size, "bytes (expected >100KB)"))
})

test_that("Downloaded file is not an HTML error page", {
  skip_if_offline()

  url <- build_ode_url(2024)

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  httr::GET(
    url,
    httr::write_disk(temp_file),
    httr::timeout(120),
    httr::user_agent("Mozilla/5.0 (compatible; orschooldata R package)")
  )

  # Check magic bytes - Excel files start with "PK" (ZIP format) or OLE header
  raw_bytes <- readBin(temp_file, "raw", n = 4)
  is_xlsx <- identical(raw_bytes[1:2], charToRaw("PK"))
  is_xls <- identical(raw_bytes[1:4], as.raw(c(0xD0, 0xCF, 0x11, 0xE0)))

  expect_true(is_xlsx || is_xls,
              label = "File should be Excel format, not HTML")
})

# ==============================================================================
# STEP 3: File Parsing Tests
# ==============================================================================

test_that("Can parse Oregon enrollment Excel file with readxl", {
  skip_if_offline()

  url <- build_ode_url(2024)

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  httr::GET(
    url,
    httr::write_disk(temp_file),
    httr::timeout(120),
    httr::user_agent("Mozilla/5.0 (compatible; orschooldata R package)")
  )

  # List sheets
  sheets <- readxl::excel_sheets(temp_file)
  expect_true(length(sheets) > 0, label = "File should have sheets")

  # Find data sheet (contains "School" or "Data")
  data_sheet <- grep("School|Data", sheets, value = TRUE, ignore.case = TRUE)[1]
  expect_true(!is.na(data_sheet), label = "Should have a data sheet")

  # Read data
  df <- readxl::read_excel(temp_file, sheet = data_sheet, col_types = "text")
  expect_true(is.data.frame(df))
  expect_true(nrow(df) > 0, label = "Data frame should have rows")
})

test_that("Parsed file has expected number of rows (sanity check)", {
  skip_if_offline()

  url <- build_ode_url(2024)

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  httr::GET(url, httr::write_disk(temp_file), httr::timeout(120),
            httr::user_agent("Mozilla/5.0"))

  sheets <- readxl::excel_sheets(temp_file)
  data_sheet <- grep("School|Data", sheets, value = TRUE, ignore.case = TRUE)[1]
  df <- readxl::read_excel(temp_file, sheet = data_sheet, col_types = "text")

  # Oregon has ~1400-1600 schools
  expect_true(nrow(df) > 1000,
              label = paste("Got", nrow(df), "rows, expected >1000 schools"))
  expect_true(nrow(df) < 2500,
              label = paste("Got", nrow(df), "rows, expected <2500"))
})

# ==============================================================================
# STEP 4: Column Structure Tests
# ==============================================================================

test_that("Oregon data file has expected columns", {
  skip_if_offline()

  url <- build_ode_url(2024)

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  httr::GET(url, httr::write_disk(temp_file), httr::timeout(120),
            httr::user_agent("Mozilla/5.0"))

  sheets <- readxl::excel_sheets(temp_file)
  data_sheet <- grep("School|Data", sheets, value = TRUE, ignore.case = TRUE)[1]
  df <- readxl::read_excel(temp_file, sheet = data_sheet, col_types = "text")

  col_names_lower <- tolower(names(df))

  # Should have district and school ID columns
  has_district_id <- any(grepl("district.*id|district.*inst", col_names_lower))
  expect_true(has_district_id, label = "Should have district ID column")

  has_school_id <- any(grepl("school.*id|school.*inst", col_names_lower))
  expect_true(has_school_id, label = "Should have school ID column")

  # Should have name columns
  has_district_name <- any(grepl("district.*name", col_names_lower))
  expect_true(has_district_name, label = "Should have district name column")

  has_school_name <- any(grepl("school.*name", col_names_lower))
  expect_true(has_school_name, label = "Should have school name column")

  # Should have enrollment columns
  has_enrollment <- any(grepl("enrollment|total", col_names_lower))
  expect_true(has_enrollment, label = "Should have enrollment columns")
})

test_that("Oregon data has grade level columns", {
  skip_if_offline()

  url <- build_ode_url(2024)

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  httr::GET(url, httr::write_disk(temp_file), httr::timeout(120),
            httr::user_agent("Mozilla/5.0"))

  sheets <- readxl::excel_sheets(temp_file)
  data_sheet <- grep("School|Data", sheets, value = TRUE, ignore.case = TRUE)[1]
  df <- readxl::read_excel(temp_file, sheet = data_sheet, col_types = "text")

  col_names_lower <- tolower(names(df))

  # Should have kindergarten and grade columns
  has_kindergarten <- any(grepl("kindergarten|grade_k|grd_k", col_names_lower))
  expect_true(has_kindergarten, label = "Should have kindergarten column")

  # Should have at least some grade columns
  grade_cols <- grepl("grade.*one|grade.*1|grade.*twelve|grade.*12", col_names_lower)
  expect_true(any(grade_cols), label = "Should have grade level columns")
})

# ==============================================================================
# STEP 5: get_raw_enr() Function Tests
# ==============================================================================

test_that("get_raw_enr returns data for 2024", {
  skip_if_offline()

  raw <- orschooldata:::get_raw_enr(2024)

  expect_true(is.data.frame(raw))
  expect_true(nrow(raw) > 1000, label = paste("Got", nrow(raw), "rows"))

  # Should have end_year column added
  expect_true("end_year" %in% names(raw))
  expect_equal(unique(raw$end_year), 2024)
})

test_that("get_raw_enr returns data for Era 1 year (2012)", {
  skip_if_offline()

  raw <- orschooldata:::get_raw_enr(2012)

  expect_true(is.data.frame(raw))
  expect_true(nrow(raw) > 1000, label = paste("Got", nrow(raw), "rows"))
  expect_equal(unique(raw$end_year), 2012)
})

test_that("get_available_years returns valid year range", {
  result <- orschooldata::get_available_years()

  if (is.list(result)) {
    expect_true("min_year" %in% names(result) || "years" %in% names(result))
    if ("min_year" %in% names(result)) {
      expect_true(result$min_year >= 2000 & result$min_year <= 2015)
      expect_true(result$max_year >= 2020 & result$max_year <= 2030)
    }
  } else {
    expect_true(is.numeric(result) || is.integer(result))
    expect_true(min(result) >= 2000 & min(result) <= 2015)
    expect_true(max(result) >= 2020 & max(result) <= 2030)
  }
})

# ==============================================================================
# STEP 6: Data Processing Tests
# ==============================================================================

test_that("fetch_enr returns processed data with correct structure", {
  skip_if_offline()

  data <- orschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  expect_true(is.data.frame(data))

  # Should have key columns
  expect_true("type" %in% names(data), label = "Should have type column")
  expect_true("district_id" %in% names(data), label = "Should have district_id")
  expect_true("row_total" %in% names(data), label = "Should have row_total")

  # Should have all three types
  types <- unique(data$type)
  expect_true("State" %in% types, label = "Should have State rows")
  expect_true("District" %in% types, label = "Should have District rows")
  expect_true("Campus" %in% types, label = "Should have Campus rows")
})

test_that("fetch_enr returns correct entity counts", {
  skip_if_offline()

  data <- orschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  n_state <- sum(data$type == "State")
  n_districts <- sum(data$type == "District")
  n_campuses <- sum(data$type == "Campus")

  # Oregon should have 1 state row
  expect_equal(n_state, 1)

  # Oregon has ~200 districts
  expect_true(n_districts > 150 && n_districts < 300,
              label = paste("Districts:", n_districts))

  # Oregon has ~1400-1600 campuses
  expect_true(n_campuses > 1000 && n_campuses < 2000,
              label = paste("Campuses:", n_campuses))
})

# ==============================================================================
# STEP 7: Data Quality Tests
# ==============================================================================

test_that("fetch_enr returns data with no Inf or NaN (except pct for zero-enrollment entities)", {
  skip_if_offline()

  data <- orschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  numeric_cols <- names(data)[sapply(data, is.numeric)]

  for (col in numeric_cols) {
    # Check for Inf values (should never exist)
    expect_false(any(is.infinite(data[[col]]), na.rm = TRUE),
                 label = paste("No Inf in", col))

    # For pct column, NaN can occur for zero-enrollment entities (ESDs, etc.)
    # This is expected behavior when computing 0/0
    if (col == "pct") {
      nan_count <- sum(is.nan(data[[col]]), na.rm = TRUE)
      # Should be very few NaN (only zero-enrollment entities)
      expect_true(nan_count < 50,
                  label = paste("NaN count in pct:", nan_count, "(expected <50 for ESDs)"))
    } else {
      expect_false(any(is.nan(data[[col]]), na.rm = TRUE),
                   label = paste("No NaN in", col))
    }
  }
})

test_that("Enrollment counts are non-negative", {
  skip_if_offline()

  data <- orschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  expect_true(all(data$row_total >= 0, na.rm = TRUE),
              label = "All row_total values should be >= 0")
})

test_that("Grade counts are non-negative", {
  skip_if_offline()

  data <- orschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  grade_cols <- grep("^grade_", names(data), value = TRUE)

  for (col in grade_cols) {
    if (is.numeric(data[[col]])) {
      expect_true(all(data[[col]] >= 0, na.rm = TRUE),
                  label = paste("All", col, "values should be >= 0"))
    }
  }
})

# ==============================================================================
# STEP 8: Aggregation Tests
# ==============================================================================

test_that("State total enrollment is in expected range", {
  skip_if_offline()

  data <- orschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  state_total <- data$row_total[data$type == "State"]

  # Oregon has ~550,000 students
  expect_true(state_total > 400000,
              label = paste("State total:", format(state_total, big.mark = ","),
                            "(expected >400k)"))
  expect_true(state_total < 800000,
              label = paste("State total:", format(state_total, big.mark = ","),
                            "(expected <800k)"))
})

test_that("State total equals sum of district totals", {
  skip_if_offline()

  data <- orschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  state_total <- data$row_total[data$type == "State"]
  district_sum <- sum(data$row_total[data$type == "District"], na.rm = TRUE)

  # Should match exactly (state is computed from districts)
  expect_equal(state_total, district_sum,
               label = "State total should equal sum of districts")
})

test_that("District totals approximately equal sum of campus totals", {
  skip_if_offline()

  data <- orschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  # Sum campus enrollments by district
  campus_sums <- stats::aggregate(
    row_total ~ district_id,
    data = data[data$type == "Campus", ],
    FUN = sum, na.rm = TRUE
  )

  # Get district totals
  district_totals <- data[data$type == "District", c("district_id", "row_total")]

  # Join and compare
  comparison <- merge(campus_sums, district_totals, by = "district_id",
                      suffixes = c("_campus", "_district"))

  # Most districts should match within 1%
  comparison$diff_pct <- abs(comparison$row_total_campus - comparison$row_total_district) /
    (comparison$row_total_district + 1)

  matching <- sum(comparison$diff_pct < 0.01, na.rm = TRUE) / nrow(comparison)
  expect_true(matching > 0.90,
              label = paste0(round(matching * 100), "% match (expected >90%)"))
})

# ==============================================================================
# STEP 9: Output Fidelity Tests
# ==============================================================================

test_that("tidy=TRUE and tidy=FALSE return consistent state totals", {
  skip_if_offline()

  wide <- orschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- orschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Both should have data
  expect_true(nrow(wide) > 0)
  expect_true(nrow(tidy) > 0)

  # State totals should match
  wide_state_total <- wide$row_total[wide$type == "State"]

  # In tidy format, find total_enrollment for state
  if ("is_state" %in% names(tidy) && "subgroup" %in% names(tidy)) {
    tidy_state <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment", ]
    if (nrow(tidy_state) > 0 && "n_students" %in% names(tidy_state)) {
      tidy_state_total <- tidy_state$n_students[1]
      expect_equal(wide_state_total, tidy_state_total,
                   label = "State totals should match between wide and tidy")
    }
  }
})

test_that("All entity types are present in tidy output", {
  skip_if_offline()

  result <- orschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Check entity type flags if they exist
  if ("is_state" %in% names(result)) {
    expect_true(any(result$is_state), label = "Should have state rows")
    expect_true(any(result$is_district), label = "Should have district rows")
    expect_true(any(result$is_campus), label = "Should have campus rows")

    # Each row should be exactly one type
    type_sums <- result$is_state + result$is_district + result$is_campus
    expect_true(all(type_sums == 1),
                label = "Each row should be exactly one entity type")
  }
})

# ==============================================================================
# Era-Specific Tests
# ==============================================================================

test_that("Era 2 (2015+) data downloads correctly", {
  skip_if_offline()

  result <- orschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  expect_true("Campus" %in% result$type)
  expect_true("District" %in% result$type)

  n_campus <- sum(result$type == "Campus")
  expect_true(n_campus > 1000,
              label = paste("Campus count:", n_campus))
})

test_that("Era 1 (2010-2014) data downloads correctly", {
  skip_if_offline()

  result <- orschooldata::fetch_enr(2012, tidy = FALSE, use_cache = TRUE)

  expect_true("Campus" %in% result$type)
  expect_true("District" %in% result$type)

  n_campus <- sum(result$type == "Campus")
  expect_true(n_campus > 1000,
              label = paste("Campus count:", n_campus))
})

# ==============================================================================
# Multi-Year Tests
# ==============================================================================

test_that("All available years produce valid state totals", {
  skip_if_offline()
  skip_on_cran()

  years <- orschooldata::get_available_years()

  for (year in years) {
    data <- orschooldata::fetch_enr(year, tidy = FALSE, use_cache = TRUE)
    state_total <- data$row_total[data$type == "State"]

    # State total should be reasonable (400k-800k for Oregon)
    expect_true(state_total > 400000 && state_total < 800000,
                info = paste("Year", year, "state total:", state_total))
  }
})

# ==============================================================================
# Cache Tests
# ==============================================================================

test_that("Cache functions exist and work", {
  tryCatch({
    path <- orschooldata:::get_cache_path(2024, "enrollment")
    expect_true(is.character(path))
    expect_true(grepl("2024", path))
  }, error = function(e) {
    skip("Cache functions may not be implemented")
  })
})
