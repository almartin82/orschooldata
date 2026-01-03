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
