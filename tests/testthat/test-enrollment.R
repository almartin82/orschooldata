# Tests for enrollment functions
# Note: Most tests are marked as skip_on_cran since they require network access

test_that("safe_numeric handles various inputs", {
  # Normal numbers
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("1,234"), 1234)

  # Suppressed values
  expect_true(is.na(safe_numeric("*")))
  expect_true(is.na(safe_numeric("-1")))
  expect_true(is.na(safe_numeric("<5")))
  expect_true(is.na(safe_numeric("<10")))
  expect_true(is.na(safe_numeric("")))

  # Whitespace handling
  expect_equal(safe_numeric("  100  "), 100)
})

test_that("get_available_years returns expected range", {
  years <- get_available_years()

  expect_true(is.integer(years) || is.numeric(years))
  expect_true(2010 %in% years)
  expect_true(2024 %in% years)
  expect_false(2009 %in% years)
  expect_false(2025 %in% years)
})

test_that("build_enrollment_url constructs valid URLs", {
  # Era 1 (xls)
  url_2014 <- build_enrollment_url(2014)
  expect_true(grepl("oregon.gov", url_2014))
  expect_true(grepl("20132014", url_2014))
  expect_true(grepl("\\.xls$", url_2014))

  # Era 2 (xlsx)
  url_2024 <- build_enrollment_url(2024)
  expect_true(grepl("oregon.gov", url_2024))
  expect_true(grepl("20232024", url_2024))
  expect_true(grepl("\\.xlsx$", url_2024))
})

test_that("fetch_enr validates year parameter", {
  expect_error(fetch_enr(2000), "end_year must be between")
  expect_error(fetch_enr(2030), "end_year must be between")
})

test_that("get_cache_dir returns valid path", {
  cache_dir <- get_cache_dir()
  expect_true(is.character(cache_dir))
  expect_true(grepl("orschooldata", cache_dir))
})

test_that("cache functions work correctly", {
  # Test cache path generation
  path <- get_cache_path(2024, "tidy")
  expect_true(grepl("enr_tidy_2024.rds", path))

  # Test cache_exists returns FALSE for non-existent cache
  expect_false(cache_exists(9999, "tidy"))
})

# Integration tests (require network access)
test_that("fetch_enr downloads and processes data for Era 2 (2015+)", {
  skip_on_cran()
  skip_if_offline()

  # Use a recent year
  result <- fetch_enr(2023, tidy = FALSE, use_cache = FALSE)

  # Check structure
  expect_true(is.data.frame(result))
  expect_true("district_id" %in% names(result))
  expect_true("campus_id" %in% names(result))
  expect_true("row_total" %in% names(result))
  expect_true("type" %in% names(result))

  # Check we have all levels
  expect_true("State" %in% result$type)
  expect_true("District" %in% result$type)
  expect_true("Campus" %in% result$type)

  # Check state total is reasonable (Oregon has ~580k students)
  state_total <- result$row_total[result$type == "State"]
  expect_true(state_total > 400000)
  expect_true(state_total < 800000)
})

test_that("fetch_enr downloads and processes data for Era 1 (2010-2014)", {
  skip_on_cran()
  skip_if_offline()

  # Use an Era 1 year
  result <- fetch_enr(2014, tidy = FALSE, use_cache = FALSE)

  # Check structure
  expect_true(is.data.frame(result))
  expect_true("district_id" %in% names(result) || "campus_id" %in% names(result))
  expect_true("type" %in% names(result))

  # Check we have data
  expect_true(nrow(result) > 0)
})

test_that("tidy_enr produces correct long format", {
  skip_on_cran()
  skip_if_offline()

  # Get wide data
  wide <- fetch_enr(2023, tidy = FALSE, use_cache = TRUE)

  # Tidy it
  tidy_result <- tidy_enr(wide)

  # Check structure
  expect_true("grade_level" %in% names(tidy_result))
  expect_true("subgroup" %in% names(tidy_result))
  expect_true("n_students" %in% names(tidy_result))
  expect_true("pct" %in% names(tidy_result))

  # Check subgroups include expected values
  subgroups <- unique(tidy_result$subgroup)
  expect_true("total_enrollment" %in% subgroups)

  # Check grade levels
  grade_levels <- unique(tidy_result$grade_level)
  expect_true("TOTAL" %in% grade_levels)
  expect_true("K" %in% grade_levels || "01" %in% grade_levels)
})

test_that("id_enr_aggs adds correct flags", {
  skip_on_cran()
  skip_if_offline()

  # Get tidy data with aggregation flags
  result <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  # Check flags exist
  expect_true("is_state" %in% names(result))
  expect_true("is_district" %in% names(result))
  expect_true("is_campus" %in% names(result))

  # Check flags are boolean
  expect_true(is.logical(result$is_state))
  expect_true(is.logical(result$is_district))
  expect_true(is.logical(result$is_campus))

  # Check mutual exclusivity (each row is only one type)
  type_sums <- result$is_state + result$is_district + result$is_campus
  expect_true(all(type_sums == 1))
})

test_that("fetch_enr_multi works for multiple years", {
  skip_on_cran()
  skip_if_offline()

  # Fetch 2 years
  result <- fetch_enr_multi(c(2022, 2023), tidy = TRUE, use_cache = TRUE)

  # Check we got both years
  years <- unique(result$end_year)
  expect_true(2022 %in% years)
  expect_true(2023 %in% years)
})

test_that("enr_grade_aggs creates grade aggregates", {
  skip_on_cran()
  skip_if_offline()

  # Get tidy data
  tidy_data <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  # Create aggregates
  grade_aggs <- enr_grade_aggs(tidy_data)

  # Check structure
  expect_true(is.data.frame(grade_aggs))
  expect_true("grade_level" %in% names(grade_aggs))

  # Check aggregate levels
  agg_levels <- unique(grade_aggs$grade_level)
  expect_true("K8" %in% agg_levels)
  expect_true("HS" %in% agg_levels)
  expect_true("K12" %in% agg_levels)
})


# ==============================================================================
# Comprehensive Year Coverage Tests
# These tests verify that EVERY available year processes correctly
# ==============================================================================

test_that("all available years have valid state totals", {
  skip_on_cran()
  skip_if_offline()

  years <- get_available_years()

  for (yr in years) {
    result <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)

    # Check state row exists and has valid total
    state_row <- result[which(result$type == "State"), ]
    expect_equal(nrow(state_row), 1, info = paste("Year", yr, "should have exactly 1 state row"))

    state_total <- state_row$row_total
    expect_false(is.na(state_total), info = paste("Year", yr, "state total should not be NA"))
    expect_true(state_total > 400000, info = paste("Year", yr, "state total should be > 400k"))
    expect_true(state_total < 800000, info = paste("Year", yr, "state total should be < 800k"))
  }
})

test_that("all years have districts and campuses", {
  skip_on_cran()
  skip_if_offline()

  years <- get_available_years()

  for (yr in years) {
    result <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)

    n_districts <- sum(result$type == "District")
    n_campuses <- sum(result$type == "Campus")

    # Oregon has about 200 districts and 1400+ campuses
    expect_true(n_districts >= 200, info = paste("Year", yr, "should have >= 200 districts"))
    expect_true(n_districts <= 250, info = paste("Year", yr, "should have <= 250 districts"))
    expect_true(n_campuses >= 1400, info = paste("Year", yr, "should have >= 1400 campuses"))
    expect_true(n_campuses <= 1700, info = paste("Year", yr, "should have <= 1700 campuses"))
  }
})

test_that("all years have complete grade columns", {
  skip_on_cran()
  skip_if_offline()

  years <- get_available_years()

  for (yr in years) {
    result <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)
    grade_cols <- grep("^grade_", names(result), value = TRUE)

    # All years should have K-12 (13 grade columns)
    expect_true(length(grade_cols) >= 13, info = paste("Year", yr, "should have >= 13 grade columns"))
    expect_true("grade_k" %in% names(result), info = paste("Year", yr, "should have kindergarten"))
    expect_true("grade_12" %in% names(result), info = paste("Year", yr, "should have grade 12"))
  }
})


# ==============================================================================
# Data Fidelity Tests
# These tests verify that tidy output maintains FIDELITY to raw data
# ==============================================================================

test_that("tidy output maintains fidelity to raw data for 2024", {
  skip_on_cran()
  skip_if_offline()

  # Get both raw and processed data
  raw <- get_raw_enr(2024)
  processed <- fetch_enr(2024, tidy = FALSE, use_cache = FALSE)

  # Get campus-level data (exclude aggregates)
  campus_processed <- processed[which(processed$type == "Campus"), ]

  # Verify row counts match (should have same number of schools)
  expect_equal(nrow(raw), nrow(campus_processed),
               info = "Number of schools should match between raw and processed")

  # Test a specific school for exact match
  test_school_id <- "498"  # Adel Elementary
  raw_school <- raw[which(raw$school_institution_id == test_school_id), ]
  processed_school <- campus_processed[which(campus_processed$campus_id == test_school_id), ]

  # Compare total enrollment
  raw_total <- as.numeric(raw_school[["20232024_total_enrollment"]])
  expect_equal(processed_school$row_total, raw_total,
               info = "Total enrollment should match raw data")

  # Compare grade-level counts
  raw_k <- as.numeric(raw_school[["202324_kindergarten"]])
  expect_equal(processed_school$grade_k, raw_k,
               info = "Kindergarten count should match raw data")
})

test_that("grade totals sum correctly to row_total", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  # Get campus rows (excludes state/district aggregates)
  campus_data <- result[which(result$type == "Campus"), ]

  # Check a sample of schools
  set.seed(42)
  sample_idx <- sample(nrow(campus_data), min(50, nrow(campus_data)))
  sample_schools <- campus_data[sample_idx, ]

  grade_cols <- c("grade_k", paste0("grade_", sprintf("%02d", 1:12)))
  grade_cols <- grade_cols[grade_cols %in% names(sample_schools)]

  for (i in 1:nrow(sample_schools)) {
    school <- sample_schools[i, ]
    grade_sum <- sum(sapply(grade_cols, function(col) {
      val <- school[[col]]
      if (is.na(val)) 0 else val
    }))
    row_total <- school$row_total

    # Allow small tolerance for rounding or ungraded students
    if (!is.na(row_total) && row_total > 0) {
      diff <- abs(grade_sum - row_total)
      expect_true(diff <= row_total * 0.05,
                  info = paste("School", school$campus_id, "grade sum differs from total by more than 5%"))
    }
  }
})


# ==============================================================================
# Data Quality Tests
# Check for improbable/impossible values
# ==============================================================================

test_that("no impossible zero values in state totals", {
  skip_on_cran()
  skip_if_offline()

  years <- get_available_years()

  for (yr in years) {
    result <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)
    state_row <- result[which(result$type == "State"), ]

    # State total should never be zero
    expect_true(state_row$row_total > 0,
                info = paste("Year", yr, "state total should not be zero"))

    # Grade columns should not all be zero at state level
    grade_cols <- grep("^grade_", names(state_row), value = TRUE)
    grade_sum <- sum(sapply(grade_cols, function(col) {
      val <- state_row[[col]]
      if (is.na(val)) 0 else val
    }))
    expect_true(grade_sum > 0,
                info = paste("Year", yr, "state grade sum should not be zero"))
  }
})

test_that("no Inf or NaN values in tidy output", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Check n_students for Inf/NaN
  expect_false(any(is.infinite(result$n_students)),
               info = "n_students should have no Inf values")
  expect_false(any(is.nan(result$n_students[!is.na(result$n_students)])),
               info = "n_students should have no NaN values")

  # Check pct for Inf/NaN (can have NaN from 0/0 divisions)
  expect_false(any(is.infinite(result$pct)),
               info = "pct should have no Inf values")
})

test_that("district totals match sum of campus totals", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  # Get a sample of districts to check
  district_data <- result[which(result$type == "District"), ]
  campus_data <- result[which(result$type == "Campus"), ]

  # Check first 10 districts
  for (i in 1:min(10, nrow(district_data))) {
    dist <- district_data[i, ]
    dist_id <- dist$district_id

    # Sum campus totals for this district
    dist_campuses <- campus_data[which(campus_data$district_id == dist_id), ]
    campus_sum <- sum(dist_campuses$row_total, na.rm = TRUE)

    # District total should match sum of campuses
    expect_equal(dist$row_total, campus_sum,
                 info = paste("District", dist_id, "total should match sum of campuses"))
  }
})

test_that("state totals match sum of district totals", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  state_row <- result[which(result$type == "State"), ]
  district_data <- result[which(result$type == "District"), ]

  district_sum <- sum(district_data$row_total, na.rm = TRUE)

  expect_equal(state_row$row_total, district_sum,
               info = "State total should match sum of districts")
})

test_that("enrollment counts are non-negative", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # All n_students values should be >= 0
  non_na_counts <- result$n_students[!is.na(result$n_students)]
  expect_true(all(non_na_counts >= 0),
              info = "All enrollment counts should be non-negative")
})

test_that("percentages are between 0 and 1", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Filter to valid percentages (not NA, not NaN)
  valid_pct <- result$pct[!is.na(result$pct) & !is.nan(result$pct)]

  expect_true(all(valid_pct >= 0),
              info = "All percentages should be >= 0")
  expect_true(all(valid_pct <= 1),
              info = "All percentages should be <= 1")
})


# ==============================================================================
# Tidy Format Verification
# ==============================================================================

test_that("tidy format has all expected grade levels", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  grade_levels <- unique(result$grade_level)

  # Should have K-12 plus TOTAL
  expected_grades <- c("TOTAL", "K", sprintf("%02d", 1:12))
  for (grade in expected_grades) {
    expect_true(grade %in% grade_levels,
                info = paste("Grade level", grade, "should be present"))
  }
})

test_that("tidy format has correct subgroup", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  subgroups <- unique(result$subgroup)

  # Current implementation only has total_enrollment
  expect_true("total_enrollment" %in% subgroups,
              info = "total_enrollment subgroup should be present")
})
