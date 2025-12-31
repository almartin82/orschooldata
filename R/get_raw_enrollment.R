# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from ODE.
# Oregon provides Fall Membership Reports as Excel files.
#
# Format Eras:
# - Era 1 (2010-2014): .xls format with older column structure
# - Era 2 (2015-present): .xlsx format with standardized columns
#
# ==============================================================================

#' Download raw enrollment data from ODE
#'
#' Downloads the Fall Membership Report for the specified school year.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return Data frame with raw enrollment data
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year
  available_years <- get_available_years()
  if (!end_year %in% available_years) {
    stop(paste0(
      "end_year must be between ", min(available_years), " and ", max(available_years),
      ". Year ", end_year, " is not available."
    ))
  }

  message(paste("Downloading Oregon enrollment data for", end_year, "..."))

  # Build URL
  url <- build_enrollment_url(end_year)

  # Determine file extension
  ext <- if (end_year <= 2014) ".xls" else ".xlsx"

  # Create temp file
  temp_file <- tempfile(
    pattern = paste0("or_enr_", end_year, "_"),
    tmpdir = tempdir(),
    fileext = ext
  )

  # Download file with retry logic and proper headers
  max_retries <- 3
  download_success <- FALSE

  for (attempt in 1:max_retries) {
    tryCatch({
      response <- httr::GET(
        url,
        httr::write_disk(temp_file, overwrite = TRUE),
        httr::timeout(600),  # 10 minute timeout for slow Oregon servers
        httr::user_agent("Mozilla/5.0 (compatible; orschooldata R package)"),
        httr::add_headers(Accept = "*/*")
      )

      # Check for HTTP errors
      if (httr::http_error(response)) {
        if (attempt < max_retries) {
          message(paste("  Attempt", attempt, "failed, retrying..."))
          Sys.sleep(2 * attempt)  # Exponential backoff
          next
        }
        stop(paste("HTTP error:", httr::status_code(response), "for URL:", url))
      }

      # Check file size
      file_info <- file.info(temp_file)
      if (file_info$size < 1000) {
        content <- readLines(temp_file, n = 5, warn = FALSE)
        if (any(grepl("error|not found|404", content, ignore.case = TRUE))) {
          stop(paste("Error page received instead of data for year", end_year))
        }
      }

      download_success <- TRUE
      break

    }, error = function(e) {
      if (attempt == max_retries) {
        stop(paste(
          "Failed to download Oregon enrollment data for year", end_year,
          "\nURL:", url,
          "\nError:", e$message,
          "\n\nThe Oregon ODE website may be slow or temporarily unavailable.",
          "\nPlease try again later or check your internet connection."
        ))
      }
      message(paste("  Attempt", attempt, "failed:", e$message))
      Sys.sleep(2 * attempt)
    })
  }

  # Read Excel file
  # Oregon files typically have multiple sheets; we want the main data sheet
  df <- read_ode_excel(temp_file, end_year)

  # Clean up temp file
  unlink(temp_file)

  # Add end_year column
  df$end_year <- end_year

  df
}


#' Read ODE Excel file with appropriate method for format era
#'
#' @param file_path Path to downloaded Excel file
#' @param end_year School year end
#' @return Data frame with raw data
#' @keywords internal
read_ode_excel <- function(file_path, end_year) {

  # Read sheet names
  sheets <- readxl::excel_sheets(file_path)

  # Find the main data sheet
  # Oregon files typically have multiple sheets - we want the one with enrollment data
  data_sheet <- NULL

  # Priority 1: Look for sheets with common data names (excluding notes/info sheets)
  data_patterns <- c("^data$", "^fall.*membership", "^enrollment", "^school", "^district")
  for (pattern in data_patterns) {
    matched <- grep(pattern, sheets, ignore.case = TRUE, value = TRUE)
    # Exclude sheets that are clearly not data
    matched <- matched[!grepl("note|info|about|readme|legend|key", matched, ignore.case = TRUE)]
    if (length(matched) > 0) {
      data_sheet <- matched[1]
      break
    }
  }

  # Priority 2: Find the sheet with most columns (likely the data sheet)
  if (is.null(data_sheet)) {
    sheet_cols <- sapply(sheets, function(s) {
      tryCatch({
        preview <- readxl::read_excel(file_path, sheet = s, n_max = 2, col_names = FALSE, .name_repair = "minimal")
        ncol(preview)
      }, error = function(e) 0)
    })
    # Pick sheet with most columns, but skip if it looks like notes
    candidates <- sheets[order(-sheet_cols)]
    candidates <- candidates[!grepl("note|info|about|readme|legend|key", candidates, ignore.case = TRUE)]
    if (length(candidates) > 0) {
      data_sheet <- candidates[1]
    }
  }

  # Priority 3: Fall back to first sheet that is not Notes
  if (is.null(data_sheet)) {
    non_notes <- sheets[!grepl("note", sheets, ignore.case = TRUE)]
    data_sheet <- if (length(non_notes) > 0) non_notes[1] else sheets[1]
  }

  message(paste("  Reading sheet:", data_sheet))

  # Read the Excel file
  # Era-specific handling for column types
  if (end_year <= 2014) {
    # Era 1: Older format
    df <- read_ode_era1(file_path, data_sheet, end_year)
  } else {
    # Era 2: Modern format
    df <- read_ode_era2(file_path, data_sheet, end_year)
  }

  df
}


#' Read Era 1 ODE Excel file (2010-2014)
#'
#' @param file_path Path to Excel file
#' @param sheet_name Name of sheet to read
#' @param end_year School year end
#' @return Data frame
#' @keywords internal
read_ode_era1 <- function(file_path, sheet_name, end_year) {

  # Era 1 files may have header rows that need skipping
  # Read first few rows to detect header
  preview <- readxl::read_excel(
    file_path,
    sheet = sheet_name,
    n_max = 10,
    col_names = FALSE,
    .name_repair = "minimal"
  )

  # Find the header row (contains "District" or "Institution")
  header_row <- 1
  for (i in 1:nrow(preview)) {
    row_vals <- as.character(preview[i, ])
    if (any(grepl("District|Institution|School", row_vals, ignore.case = TRUE))) {
      header_row <- i
      break
    }
  }

  # Read the full file starting from header row
  df <- readxl::read_excel(
    file_path,
    sheet = sheet_name,
    skip = header_row - 1,
    col_types = "text",
    .name_repair = "unique"
  )

  # Standardize column names
  names(df) <- standardize_col_names(names(df))

  df
}


#' Read Era 2 ODE Excel file (2015-present)
#'
#' @param file_path Path to Excel file
#' @param sheet_name Name of sheet to read
#' @param end_year School year end
#' @return Data frame
#' @keywords internal
read_ode_era2 <- function(file_path, sheet_name, end_year) {

  # Era 2 files typically have a clean header row
  # Read first few rows to detect any header offset
  preview <- readxl::read_excel(
    file_path,
    sheet = sheet_name,
    n_max = 5,
    col_names = FALSE,
    .name_repair = "minimal"
  )

  # Find the header row
  header_row <- 1
  for (i in 1:nrow(preview)) {
    row_vals <- as.character(preview[i, ])
    if (any(grepl("District|Institution|School", row_vals, ignore.case = TRUE))) {
      header_row <- i
      break
    }
  }

  # Read the full file
  df <- readxl::read_excel(
    file_path,
    sheet = sheet_name,
    skip = header_row - 1,
    col_types = "text",
    .name_repair = "unique"
  )

  # Standardize column names
  names(df) <- standardize_col_names(names(df))

  df
}
