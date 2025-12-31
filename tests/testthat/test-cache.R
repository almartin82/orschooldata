# Tests for caching functions

test_that("cache directory creation works", {
  cache_dir <- get_cache_dir()

  # Should return a path

  expect_true(is.character(cache_dir))
  expect_true(nchar(cache_dir) > 0)

  # Should contain package name
  expect_true(grepl("orschooldata", cache_dir))

  # Directory should exist after calling get_cache_dir
  expect_true(dir.exists(cache_dir))
})

test_that("cache path generation is consistent", {
  path1 <- get_cache_path(2024, "tidy")
  path2 <- get_cache_path(2024, "tidy")

  expect_equal(path1, path2)

  # Different years/types should have different paths
  path_wide <- get_cache_path(2024, "wide")
  path_2023 <- get_cache_path(2023, "tidy")

  expect_false(path1 == path_wide)
  expect_false(path1 == path_2023)
})

test_that("cache_exists returns FALSE for non-existent files", {
  # Very unlikely to have cached data for year 9999
  expect_false(cache_exists(9999, "tidy"))
  expect_false(cache_exists(9999, "wide"))
})

test_that("cache read/write roundtrip works", {
  # Create a test data frame
  test_df <- data.frame(
    end_year = 9998,
    district_id = "TEST",
    n_students = 100
  )

  # Write to cache
  cache_path <- write_cache(test_df, 9998, "test")

  # Check file was created
  expect_true(file.exists(cache_path))

  # Check cache_exists returns TRUE
  expect_true(cache_exists(9998, "test"))

  # Read back
  result <- read_cache(9998, "test")

  # Check roundtrip
  expect_equal(test_df, result)

  # Clean up
  file.remove(cache_path)
})

test_that("clear_cache removes files", {
  # Create test cache files
  test_df <- data.frame(x = 1)

  write_cache(test_df, 9997, "tidy")
  write_cache(test_df, 9997, "wide")
  write_cache(test_df, 9996, "tidy")

  # Clear specific year
  expect_message(clear_cache(9997), "Removed")
  expect_false(cache_exists(9997, "tidy"))
  expect_false(cache_exists(9997, "wide"))
  expect_true(cache_exists(9996, "tidy"))

  # Clean up remaining
  clear_cache(9996)
})

test_that("cache_status returns data frame", {
  # Create a test cache entry
  test_df <- data.frame(x = 1)
  write_cache(test_df, 9995, "tidy")

  # Get status
  status <- cache_status()

  # Should be a data frame
  expect_true(is.data.frame(status))

  # Should have expected columns
  expect_true("year" %in% names(status))
  expect_true("type" %in% names(status))
  expect_true("size_mb" %in% names(status))
  expect_true("age_days" %in% names(status))

  # Clean up
  clear_cache(9995)
})
