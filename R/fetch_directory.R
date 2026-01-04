# ==============================================================================
# School Directory Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading school directory data from the
# Oregon Department of Education website.
#
# Data source: https://www.ode.state.or.us/data/ReportCard/Reports/GetInstitutions
#
# Note: This API provides institution ID, name, type, parent district, and
# location (city). For complete contact information including addresses and
# phone numbers, refer to the Oregon School Directory PDF:
# https://www.oregon.gov/ode/about-us/Pages/School-Directory.aspx
#
# ==============================================================================

#' Fetch Oregon school directory data
#'
#' Downloads and processes school directory data from the Oregon Department
#' of Education Report Card system. This includes public schools, districts,
#' and programs with their names, types, and locations.
#'
#' @param end_year Currently unused. The directory data represents current
#'   institutions and is not year-specific. Included for API consistency with
#'   other fetch functions.
#' @param tidy If TRUE (default), returns data in a standardized format with
#'   consistent column names. If FALSE, returns raw column names from ODE.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from ODE.
#' @return A tibble with school directory data. Columns include:
#'   \itemize{
#'     \item \code{state_school_id}: Oregon institution ID
#'     \item \code{state_district_id}: Parent district institution ID (for schools)
#'     \item \code{school_name}: Institution name
#'     \item \code{district_name}: Parent district name (for schools)
#'     \item \code{school_type}: Type of institution (School, District, Program)
#'     \item \code{city}: City location
#'     \item \code{state}: State (always "OR")
#'     \item \code{agg_level}: Aggregation level ("S" = School, "D" = District, "P" = Program)
#'   }
#' @details
#' The directory data is retrieved via the ODE Report Card API, which provides
#' a JSON list of all institutions receiving report cards. This data is updated
#' periodically by ODE.
#'
#' Note: This API does not include full addresses, phone numbers, or
#' administrator names. For complete contact information, download the
#' Oregon School Directory PDF from
#' \url{https://www.oregon.gov/ode/about-us/Pages/School-Directory.aspx}
#'
#' @export
#' @examples
#' \dontrun{
#' # Get school directory data
#' dir_data <- fetch_directory()
#'
#' # Get raw format (original ODE column names)
#' dir_raw <- fetch_directory(tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' dir_fresh <- fetch_directory(use_cache = FALSE)
#'
#' # Filter to schools only
#' library(dplyr)
#' schools_only <- dir_data |>
#'   filter(agg_level == "S")
#'
#' # Find all schools in a district
#' portland_schools <- dir_data |>
#'   filter(district_name == "Portland SD 1J", agg_level == "S")
#' }
fetch_directory <- function(end_year = NULL, tidy = TRUE, use_cache = TRUE) {

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "directory_tidy" else "directory_raw"

  # Check cache first
  if (use_cache && cache_exists_directory(cache_type)) {
    message("Using cached school directory data")
    return(read_cache_directory(cache_type))
  }

  # Get raw data from ODE
  raw <- get_raw_directory()

  # Process to standard schema
  if (tidy) {
    result <- process_directory(raw)
  } else {
    result <- raw
  }

  # Cache the result
  if (use_cache) {
    write_cache_directory(result, cache_type)
  }

  result
}


#' Get raw school directory data from ODE
#'
#' Downloads the raw school directory data from the Oregon Department of
#' Education Report Card API.
#'
#' @return Raw data frame as downloaded from ODE
#' @keywords internal
get_raw_directory <- function() {

  # Build download URL
  url <- build_directory_url()

  message("Downloading school directory data from ODE...")

  # Make API request
  response <- httr::GET(
    url,
    httr::timeout(120),
    httr::user_agent("Mozilla/5.0 (compatible; orschooldata R package)"),
    httr::add_headers(Accept = "application/json")
  )

  # Check for HTTP errors
  if (httr::http_error(response)) {
    stop(paste(
      "Failed to download school directory data from ODE.",
      "HTTP status:", httr::status_code(response),
      "\nURL:", url
    ))
  }

  # Parse JSON response
  content <- httr::content(response, as = "text", encoding = "UTF-8")
  data <- jsonlite::fromJSON(content, flatten = TRUE)

  # Check for valid data
  if (!is.data.frame(data) || nrow(data) == 0) {
    stop("No data returned from ODE directory API")
  }

  message(paste("Downloaded", nrow(data), "institution records"))

  # Convert to tibble for consistency
  dplyr::as_tibble(data)
}


#' Build ODE school directory API URL
#'
#' Constructs the API URL for the school directory data.
#'
#' @return URL string
#' @keywords internal
build_directory_url <- function() {
  # ODE Report Card API - empty text parameter returns all institutions
  "https://www.ode.state.or.us/data/ReportCard/Reports/GetInstitutions?text="
}


#' Process raw school directory data to standard schema
#'
#' Takes raw school directory data from ODE and standardizes column names,
#' types, and adds derived columns.
#'
#' @param raw_data Raw data frame from get_raw_directory()
#' @return Processed data frame with standard schema
#' @keywords internal
process_directory <- function(raw_data) {

  # Build the standardized result data frame
  n_rows <- nrow(raw_data)
  result <- dplyr::tibble(.rows = n_rows)

  # Institution ID - use as school/district ID
  # Preserve as character to handle any future format changes
  result$state_school_id <- as.character(raw_data$InstID)

  # Parent institution ID (district for schools)
  result$state_district_id <- ifelse(
    raw_data$PrntInstID > 0,
    as.character(raw_data$PrntInstID),
    NA_character_
  )

  # Institution name
  result$school_name <- trimws(raw_data$InstNm)

  # Parent institution name (district name for schools)
  result$district_name <- ifelse(
    raw_data$PrntInstID > 0,
    trimws(raw_data$PrntInstNm),
    NA_character_
  )

  # Institution type
  result$school_type <- trimws(raw_data$InstTyp)

  # Location - parse city from "City, OR" format
  if ("Location" %in% names(raw_data)) {
    location <- raw_data$Location
    # Extract city (everything before ", OR" or the whole string if no state)
    result$city <- gsub(",\\s*OR$", "", trimws(location))
    result$city <- ifelse(result$city == "", NA_character_, result$city)
  } else {
    result$city <- NA_character_
  }

  # State is always Oregon

  result$state <- "OR"

  # Aggregation level based on institution type
  result$agg_level <- dplyr::case_when(
    result$school_type == "District" ~ "D",
    result$school_type == "School" ~ "S",
    result$school_type == "Program" ~ "P",
    TRUE ~ NA_character_
  )

  # Grade range (if available)
  if ("GradeRange" %in% names(raw_data)) {
    result$grades_served <- trimws(raw_data$GradeRange)
    result$grades_served <- ifelse(
      result$grades_served == "",
      NA_character_,
      result$grades_served
    )
  }

  # Reorder columns for consistency
  preferred_order <- c(
    "state_school_id", "state_district_id",
    "school_name", "district_name",
    "school_type", "agg_level", "grades_served",
    "city", "state"
  )

  existing_cols <- preferred_order[preferred_order %in% names(result)]
  other_cols <- setdiff(names(result), preferred_order)

  result <- result |>
    dplyr::select(dplyr::all_of(c(existing_cols, other_cols)))

  result
}


# ==============================================================================
# Directory-specific cache functions
# ==============================================================================

#' Build cache file path for directory data
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return File path string
#' @keywords internal
build_cache_path_directory <- function(cache_type) {
  cache_dir <- get_cache_dir()
  file.path(cache_dir, paste0(cache_type, ".rds"))
}


#' Check if cached directory data exists
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @param max_age Maximum age in days (default 30). Set to Inf to ignore age.
#' @return Logical indicating if valid cache exists
#' @keywords internal
cache_exists_directory <- function(cache_type, max_age = 30) {
  cache_path <- build_cache_path_directory(cache_type)

  if (!file.exists(cache_path)) {
    return(FALSE)
  }

  # Check age
  file_info <- file.info(cache_path)
  age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))

  age_days <= max_age
}


#' Read directory data from cache
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return Cached data frame
#' @keywords internal
read_cache_directory <- function(cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  readRDS(cache_path)
}


#' Write directory data to cache
#'
#' @param data Data frame to cache
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return Invisibly returns the cache path
#' @keywords internal
write_cache_directory <- function(data, cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  cache_dir <- dirname(cache_path)

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  saveRDS(data, cache_path)
  invisible(cache_path)
}


#' Clear school directory cache
#'
#' Removes cached school directory data files.
#'
#' @return Invisibly returns the number of files removed
#' @export
#' @examples
#' \dontrun{
#' # Clear cached directory data
#' clear_directory_cache()
#' }
clear_directory_cache <- function() {
  cache_dir <- get_cache_dir()

  if (!dir.exists(cache_dir)) {
    message("Cache directory does not exist")
    return(invisible(0))
  }

  files <- list.files(cache_dir, pattern = "^directory_", full.names = TRUE)

  if (length(files) > 0) {
    file.remove(files)
    message(paste("Removed", length(files), "cached directory file(s)"))
  } else {
    message("No cached directory files to remove")
  }

  invisible(length(files))
}
