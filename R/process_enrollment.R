# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw ODE enrollment data into a
# clean, standardized format.
#
# Oregon Fall Membership Reports contain school-level enrollment data with:
# - Institution identification (district, school)
# - Total enrollment
# - Grade-level breakdowns (K-12, plus UG for ungraded)
# - Limited demographic data in some years
#
# ==============================================================================

#' Process raw ODE enrollment data
#'
#' Transforms raw Fall Membership Report data into a standardized schema.
#'
#' @param raw_data Data frame from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Use era-specific processing
  if (end_year <= 2014) {
    processed <- process_enr_era1(raw_data, end_year)
  } else {
    processed <- process_enr_era2(raw_data, end_year)
  }

  # Create district-level aggregates from school data
  district_agg <- create_district_aggregate(processed, end_year)

  # Create state-level aggregate
  state_agg <- create_state_aggregate(district_agg, end_year)

  # Combine all levels
  result <- dplyr::bind_rows(state_agg, district_agg, processed)

  result
}


#' Process Era 1 data (2010-2014)
#'
#' Era 1 files (.xls format) use the same year-prefixed column naming as Era 2,
#' but with some differences in ID column naming conventions:
#' - attnd_distinstid, attnd_schlinstid (2010)
#' - attending_district_institution_id (2011+)
#'
#' @param df Raw data frame
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_enr_era1 <- function(df, end_year) {

  cols <- names(df)
  n_rows <- nrow(df)

  # Build year prefix patterns for this year
  # Oregon uses YYYY format for the short prefix (e.g., "0910" for 2009-10)
  start_year <- end_year - 1
  year_prefix_short <- paste0(substr(start_year, 3, 4), substr(end_year, 3, 4))

  # Helper to find column by pattern
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result data frame
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("Campus", n_rows),
    stringsAsFactors = FALSE
  )

  # District ID - Oregon uses various column names across years
  # attnd_distinstid (2010), attending_district_instid (2011), attending_district_institution_id (2012+)
  dist_id_col <- find_col(c(
    "^attnd_distinstid$",
    "^attending_district_instid$",
    "^attending_district_institution_id$",
    "^district_institution_id$",
    "^district_id$",
    "^dist_id$",
    "distinstid"
  ))
  if (!is.null(dist_id_col)) {
    result$district_id <- trimws(as.character(df[[dist_id_col]]))
  }

  # District name
  dist_name_col <- find_col(c(
    "^district_name$",
    "^district$",
    "^distname$"
  ))
  if (!is.null(dist_name_col)) {
    result$district_name <- trimws(as.character(df[[dist_name_col]]))
  }

  # School/Campus ID - attnd_schlinstid (2010), attending_school_instid (2011), attending_school_institution_id (2012+)
  school_id_col <- find_col(c(
    "^attnd_schlinstid$",
    "^attending_school_instid$",
    "^attending_school_institution_id$",
    "^school_institution_id$",
    "^school_id$",
    "^schoolid$",
    "schlinstid"
  ))
  if (!is.null(school_id_col)) {
    result$campus_id <- trimws(as.character(df[[school_id_col]]))
  }

  # School/Campus name
  school_name_col <- find_col(c(
    "^school_name$",
    "^school$",
    "^schoolname$"
  ))
  if (!is.null(school_name_col)) {
    result$campus_name <- trimws(as.character(df[[school_name_col]]))
  }

  # County
  county_col <- find_col(c("^county$", "^countyname$", "^county_name$"))
  if (!is.null(county_col)) {
    result$county <- trimws(as.character(df[[county_col]]))
  }

  # Total enrollment - year-prefixed (e.g., 200910_total_enrollment)
  total_patterns <- c(
    paste0("^", year_prefix_short, "_total_enrollment$"),
    "total_enrollment$",
    "^total$",
    "^enrollment$"
  )
  total_col <- find_col(total_patterns)
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Grade levels - Oregon uses year-prefixed columns
  # Format: YYYY_kindergarten, YYYY_grade_one, YYYY_grade_two, etc.

  # Kindergarten patterns
  k_patterns <- c(
    paste0("^", year_prefix_short, "_kindergarten$"),
    "kindergarten$",
    "^k$",
    "^grade_k$"
  )
  k_col <- find_col(k_patterns)
  if (!is.null(k_col)) {
    result$grade_k <- safe_numeric(df[[k_col]])
  }

  # Grades 1-12 use spelled-out names: grade_one, grade_two, etc.
  grade_words <- c(
    "one", "two", "three", "four", "five", "six",
    "seven", "eight", "nine", "ten", "eleven", "twelve"
  )
  grade_nums <- sprintf("%02d", 1:12)

  for (i in 1:12) {
    grade_name <- paste0("grade_", grade_nums[i])
    word <- grade_words[i]

    # Build patterns for this grade
    patterns <- c(
      paste0("^", year_prefix_short, "_grade_", word, "$"),
      paste0("grade_", word, "$"),
      paste0("^grade_", i, "$"),
      paste0("^gr_", i, "$")
    )

    col <- find_col(patterns)
    if (!is.null(col)) {
      result[[grade_name]] <- safe_numeric(df[[col]])
    }
  }

  # Pre-K (not always present)
  pk_patterns <- c(
    paste0("^", year_prefix_short, "_pre_k$"),
    paste0("^", year_prefix_short, "_prek$"),
    "^pre_k$", "^prek$", "^pk$"
  )
  pk_col <- find_col(pk_patterns)
  if (!is.null(pk_col)) {
    result$grade_pk <- safe_numeric(df[[pk_col]])
  }

  # Ungraded students
  ug_patterns <- c(
    paste0("^", year_prefix_short, "_ug$"),
    paste0("^", year_prefix_short, "_ungraded$"),
    "^ug$", "ungraded$"
  )
  ug_col <- find_col(ug_patterns)
  if (!is.null(ug_col)) {
    result$grade_ug <- safe_numeric(df[[ug_col]])
  }

  # Filter out any rows that don't look like school data
  result <- result[!is.na(result$district_id) | !is.na(result$campus_id), ]

  result
}


#' Process Era 2 data (2015-present)
#'
#' Oregon ODE Fall Membership Reports use year-prefixed column names.
#' For example, 2023-24 data uses columns like:
#' - 20232024_total_enrollment (for the current year total)
#' - 202324_kindergarten, 202324_grade_one, etc. (for grade breakdowns)
#'
#' The column naming conventions vary slightly between years:
#' - District ID: district_institution_id, attending_district_institution_id
#' - School ID: school_institution_id, attending_school_institution_id, attending_school_id
#' - District name: district_name, district
#' - School name: school_name, school
#'
#' @param df Raw data frame
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_enr_era2 <- function(df, end_year) {

  cols <- names(df)
  n_rows <- nrow(df)

  # Build year prefix patterns for this year
  # Oregon uses two formats: YYYYYYYY (e.g., 20232024) and YYYY (e.g., 202324)
  start_year <- end_year - 1
  year_prefix_long <- paste0(start_year, end_year)  # e.g., "20232024"
  year_prefix_short <- paste0(substr(start_year, 3, 4), substr(end_year, 3, 4))  # e.g., "2324"

  # Helper to find column by pattern
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result data frame
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("Campus", n_rows),
    stringsAsFactors = FALSE
  )

  # District ID - Oregon uses various column names across years
  # Note: 2019 uses "institutional" instead of "institution" (typo in ODE data)
  dist_id_col <- find_col(c(
    "^district_institution_id$",
    "^attending_district_institution_id$",
    "^attending_district_institutional_id$",
    "^district_id$",
    "^dist_id$",
    "^districtinstid$"
  ))
  if (!is.null(dist_id_col)) {
    result$district_id <- trimws(as.character(df[[dist_id_col]]))
  }

  # District name - various patterns
  dist_name_col <- find_col(c(
    "^district_name$",
    "^district$",
    "^distname$",
    "^attending_district_name$"
  ))
  if (!is.null(dist_name_col)) {
    result$district_name <- trimws(as.character(df[[dist_name_col]]))
  }

  # School ID - various patterns
  # Note: 2019 uses "institutional" instead of "institution" (typo in ODE data)
  school_id_col <- find_col(c(
    "^school_institution_id$",
    "^attending_school_institution_id$",
    "^attending_school_institutional_id$",
    "^attending_school_id$",
    "^school_inst_id$",
    "^schoolinstid$",
    "^school_id$",
    "^schoolid$",
    "^institution_id$"
  ))
  if (!is.null(school_id_col)) {
    result$campus_id <- trimws(as.character(df[[school_id_col]]))
  }

  # School name - various patterns
  school_name_col <- find_col(c(
    "^school_name$",
    "^school$",
    "^schoolname$",
    "^attending_school_name$",
    "^institution_name$"
  ))
  if (!is.null(school_name_col)) {
    result$campus_name <- trimws(as.character(df[[school_name_col]]))
  }

  # County
  county_col <- find_col(c("^county$", "^countyname$", "^county_name$"))
  if (!is.null(county_col)) {
    result$county <- trimws(as.character(df[[county_col]]))
  }

  # Total enrollment - look for year-prefixed columns first, then generic
  # Format: YYYYYYYY_total_enrollment (e.g., 20232024_total_enrollment)
  total_patterns <- c(
    paste0("^", year_prefix_long, "_total_enrollment$"),
    paste0("^", year_prefix_short, "_total_enrollment$"),
    "total_enrollment$",
    "^total$",
    "^enrollment$",
    "^total_students$",
    "^all_students$"
  )
  total_col <- find_col(total_patterns)
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Grade levels - Oregon uses year-prefixed columns
  # Format: YYYY_kindergarten, YYYY_grade_one, YYYY_grade_two, etc.
  # The short year prefix (e.g., 2324) is used for grade columns

  # Kindergarten patterns
  k_patterns <- c(
    paste0("^", year_prefix_short, "_kindergarten$"),
    paste0("^", year_prefix_long, "_kindergarten$"),
    "kindergarten$",
    "^k$",
    "^grade_k$"
  )
  k_col <- find_col(k_patterns)
  if (!is.null(k_col)) {
    result$grade_k <- safe_numeric(df[[k_col]])
  }

  # Grades 1-12 use spelled-out names: grade_one, grade_two, etc.
  grade_words <- c(
    "one", "two", "three", "four", "five", "six",
    "seven", "eight", "nine", "ten", "eleven", "twelve"
  )
  grade_nums <- sprintf("%02d", 1:12)

  for (i in 1:12) {
    grade_name <- paste0("grade_", grade_nums[i])
    word <- grade_words[i]

    # Build patterns for this grade
    patterns <- c(
      paste0("^", year_prefix_short, "_grade_", word, "$"),
      paste0("^", year_prefix_long, "_grade_", word, "$"),
      paste0("grade_", word, "$"),
      paste0("^grade_", i, "$"),
      paste0("^gr_", i, "$"),
      paste0("^", grade_nums[i], "$")
    )

    col <- find_col(patterns)
    if (!is.null(col)) {
      result[[grade_name]] <- safe_numeric(df[[col]])
    }
  }

  # Pre-K (not always present)
  pk_patterns <- c(
    paste0("^", year_prefix_short, "_pre_k$"),
    paste0("^", year_prefix_short, "_prek$"),
    paste0("^", year_prefix_short, "_prekindergarten$"),
    "^pre_k$", "^prek$", "^pk$", "^pre-k$", "prekindergarten$"
  )
  pk_col <- find_col(pk_patterns)
  if (!is.null(pk_col)) {
    result$grade_pk <- safe_numeric(df[[pk_col]])
  }

  # Ungraded students
  ug_patterns <- c(
    paste0("^", year_prefix_short, "_ug$"),
    paste0("^", year_prefix_short, "_ungraded$"),
    "^ug$", "ungraded$", "^ungraded$"
  )
  ug_col <- find_col(ug_patterns)
  if (!is.null(ug_col)) {
    result$grade_ug <- safe_numeric(df[[ug_col]])
  }

  # Filter out rows without valid identifiers
  result <- result[!is.na(result$district_id) | !is.na(result$campus_id), ]

  # Filter out aggregate rows if they exist in the data
  # These are typically rows with school ID containing "TOTAL" or similar
  if ("campus_id" %in% names(result)) {
    result <- result[!grepl("TOTAL|ALL|DISTRICT", result$campus_id, ignore.case = TRUE), ]
  }

  result
}


#' Create district-level aggregate from school data
#'
#' @param school_df Processed school data frame
#' @param end_year School year end
#' @return Data frame with district totals
#' @keywords internal
create_district_aggregate <- function(school_df, end_year) {

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12",
    "grade_ug"
  )

  # Filter to columns that exist
  sum_cols <- sum_cols[sum_cols %in% names(school_df)]

  if (!"district_id" %in% names(school_df)) {
    return(data.frame())
  }

  # Check if county column exists
  has_county <- "county" %in% names(school_df)

  # Aggregate by district
  district_agg <- school_df |>
    dplyr::filter(!is.na(district_id)) |>
    dplyr::group_by(district_id) |>
    dplyr::summarize(
      district_name = dplyr::first(district_name[!is.na(district_name)]),
      dplyr::across(dplyr::all_of(sum_cols), ~sum(.x, na.rm = TRUE)),
      .groups = "drop"
    )

  # Add county if it exists
  if (has_county) {
    county_lookup <- school_df |>
      dplyr::filter(!is.na(district_id), !is.na(county)) |>
      dplyr::group_by(district_id) |>
      dplyr::summarize(county = dplyr::first(county), .groups = "drop")
    district_agg <- dplyr::left_join(district_agg, county_lookup, by = "district_id")
  } else {
    district_agg$county <- NA_character_
  }

  district_agg <- district_agg |>
    dplyr::mutate(
      end_year = end_year,
      type = "District",
      campus_id = NA_character_,
      campus_name = NA_character_
    )

  # Reorder columns
  col_order <- c("end_year", "type", "district_id", "campus_id",
                 "district_name", "campus_name", "county")
  col_order <- c(col_order, setdiff(names(district_agg), col_order))
  district_agg <- district_agg[, col_order]

  district_agg
}


#' Create state-level aggregate from district data
#'
#' @param district_df Processed district data frame
#' @param end_year School year end
#' @return Single-row data frame with state totals
#' @keywords internal
create_state_aggregate <- function(district_df, end_year) {

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12",
    "grade_ug"
  )

  # Filter to columns that exist
  sum_cols <- sum_cols[sum_cols %in% names(district_df)]

  # Create state row
  state_row <- data.frame(
    end_year = end_year,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = NA_character_,
    campus_name = NA_character_,
    county = NA_character_,
    stringsAsFactors = FALSE
  )

  # Sum each column
  for (col in sum_cols) {
    if (col %in% names(district_df)) {
      state_row[[col]] <- sum(district_df[[col]], na.rm = TRUE)
    }
  }

  state_row
}
