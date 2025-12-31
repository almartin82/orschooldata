# ==============================================================================
# Utility Functions
# ==============================================================================

#' Convert to numeric, handling suppression markers
#'
#' Oregon uses various markers for suppressed data (*, <, >, etc.)
#' and may use commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)

  # Handle common suppression markers
  x[x %in% c("*", ".", "-", "-1", "<5", "<10", ">", "<", "N/A", "NA", "")] <- NA_character_

  # Handle ranges like "<5" or ">95"

  x[grepl("^[<>]\\d", x)] <- NA_character_

  suppressWarnings(as.numeric(x))
}


#' Get available years for Oregon enrollment data
#'
#' Returns the range of years for which enrollment data is available.
#'
#' @return Integer vector of available years
#' @export
#' @examples
#' get_available_years()
get_available_years <- function() {
  # Oregon ODE provides Fall Membership Reports from 2009-10 through present

  # But 2009-10 is an amended file with inconsistent format, so we start at 2010
  2010:2025
}


#' Build URL for Oregon Fall Membership Report
#'
#' Constructs the download URL for a given school year's enrollment data.
#' Oregon uses YYYYYYY format (e.g., 20242025 for the 2024-25 school year).
#'
#' @param end_year School year end (e.g., 2025 for 2024-25)
#' @return Character string URL
#' @keywords internal
build_enrollment_url <- function(end_year) {
  # Determine file extension based on year
  # 2010-2014: .xls format (older Excel)
  # 2015+: .xlsx format (newer Excel)
  ext <- if (end_year <= 2014) "xls" else "xlsx"

  # Build year string: YYYYYYY format
  start_year <- end_year - 1
  year_str <- paste0(start_year, end_year)

  # Build URL
  base_url <- "https://www.oregon.gov/ode/reports-and-data/students/Documents"
  paste0(base_url, "/fallmembershipreport_", year_str, ".", ext)
}


#' Standardize column names
#'
#' Converts Oregon column names to a standard format for processing.
#'
#' @param names Character vector of column names
#' @return Character vector of standardized names
#' @keywords internal
standardize_col_names <- function(names) {
  names <- tolower(names)
  names <- gsub("\\s+", "_", names)
  names <- gsub("[^a-z0-9_]", "", names)
  names
}
