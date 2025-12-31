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
#' @param df Raw data frame
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_enr_era1 <- function(df, end_year) {

  cols <- names(df)
  n_rows <- nrow(df)

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

  # District ID - Oregon uses various column names
  dist_id_col <- find_col(c("^district_id$", "^dist_id$", "^districtid$", "distid"))
  if (!is.null(dist_id_col)) {
    result$district_id <- trimws(as.character(df[[dist_id_col]]))
  } else {
    # Try to extract from institution ID or name
    inst_col <- find_col(c("institution_id", "inst_id", "instid"))
    if (!is.null(inst_col)) {
      # District ID is often first 4 characters
      result$district_id <- substr(trimws(as.character(df[[inst_col]])), 1, 4)
    }
  }

  # District name
  dist_name_col <- find_col(c("district_name", "distname", "district$"))
  if (!is.null(dist_name_col)) {
    result$district_name <- trimws(as.character(df[[dist_name_col]]))
  }

  # School/Campus ID
  school_id_col <- find_col(c("school_id", "schoolid", "institution_id", "instid", "inst_id"))
  if (!is.null(school_id_col)) {
    result$campus_id <- trimws(as.character(df[[school_id_col]]))
  }

  # School/Campus name
  school_name_col <- find_col(c("school_name", "schoolname", "school$", "institution_name", "instname"))
  if (!is.null(school_name_col)) {
    result$campus_name <- trimws(as.character(df[[school_name_col]]))
  }

  # County
  county_col <- find_col(c("county", "countyname", "county_name"))
  if (!is.null(county_col)) {
    result$county <- trimws(as.character(df[[county_col]]))
  }

  # Total enrollment
  total_col <- find_col(c("^total$", "total_enrollment", "enrollment", "total_students"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Grade levels - Oregon typically uses grade_k through grade_12 or similar
  grade_patterns <- list(
    grade_pk = c("pre_k", "prek", "^pk$", "pre-k"),
    grade_k = c("^k$", "^kinder", "grade_k$", "kindergarten"),
    grade_01 = c("^1$", "^grade_1$", "^gr_1$", "^01$"),
    grade_02 = c("^2$", "^grade_2$", "^gr_2$", "^02$"),
    grade_03 = c("^3$", "^grade_3$", "^gr_3$", "^03$"),
    grade_04 = c("^4$", "^grade_4$", "^gr_4$", "^04$"),
    grade_05 = c("^5$", "^grade_5$", "^gr_5$", "^05$"),
    grade_06 = c("^6$", "^grade_6$", "^gr_6$", "^06$"),
    grade_07 = c("^7$", "^grade_7$", "^gr_7$", "^07$"),
    grade_08 = c("^8$", "^grade_8$", "^gr_8$", "^08$"),
    grade_09 = c("^9$", "^grade_9$", "^gr_9$", "^09$"),
    grade_10 = c("^10$", "^grade_10$", "^gr_10$"),
    grade_11 = c("^11$", "^grade_11$", "^gr_11$"),
    grade_12 = c("^12$", "^grade_12$", "^gr_12$")
  )

  for (grade_name in names(grade_patterns)) {
    col <- find_col(grade_patterns[[grade_name]])
    if (!is.null(col)) {
      result[[grade_name]] <- safe_numeric(df[[col]])
    }
  }

  # Filter out any rows that don't look like school data
  # (e.g., header rows, totals, footnotes)
  result <- result[!is.na(result$district_id) | !is.na(result$campus_id), ]

  result
}


#' Process Era 2 data (2015-present)
#'
#' @param df Raw data frame
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_enr_era2 <- function(df, end_year) {

  cols <- names(df)
  n_rows <- nrow(df)

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

  # District ID
  dist_id_col <- find_col(c("^district_id$", "^dist_id$", "^districtinstid$", "attending_district_institution_id"))
  if (!is.null(dist_id_col)) {
    result$district_id <- trimws(as.character(df[[dist_id_col]]))
  }

  # District name
  dist_name_col <- find_col(c("district_name", "distname", "district$", "attending_district_name"))
  if (!is.null(dist_name_col)) {
    result$district_name <- trimws(as.character(df[[dist_name_col]]))
  }

  # School ID
  school_id_col <- find_col(c("^school_inst_id$", "school_institution_id", "attending_school_institution_id",
                              "schoolinstid", "school_id", "schoolid", "institution_id"))
  if (!is.null(school_id_col)) {
    result$campus_id <- trimws(as.character(df[[school_id_col]]))
  }

  # School name
  school_name_col <- find_col(c("school_name", "schoolname", "attending_school_name", "school$", "institution_name"))
  if (!is.null(school_name_col)) {
    result$campus_name <- trimws(as.character(df[[school_name_col]]))
  }

  # County
  county_col <- find_col(c("county", "countyname", "county_name"))
  if (!is.null(county_col)) {
    result$county <- trimws(as.character(df[[county_col]]))
  }

  # Total enrollment
  total_col <- find_col(c("^total$", "total_enrollment", "^enrollment$", "total_students", "^all_students$"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Grade levels
  grade_patterns <- list(
    grade_pk = c("^pre_k$", "^prek$", "^pk$", "^pre-k$", "prekindergarten"),
    grade_k = c("^k$", "^kindergarten$", "^grade_k$"),
    grade_01 = c("^grade_1$", "^gr_1$", "^1st$", "^01$", "^_1$"),
    grade_02 = c("^grade_2$", "^gr_2$", "^2nd$", "^02$", "^_2$"),
    grade_03 = c("^grade_3$", "^gr_3$", "^3rd$", "^03$", "^_3$"),
    grade_04 = c("^grade_4$", "^gr_4$", "^4th$", "^04$", "^_4$"),
    grade_05 = c("^grade_5$", "^gr_5$", "^5th$", "^05$", "^_5$"),
    grade_06 = c("^grade_6$", "^gr_6$", "^6th$", "^06$", "^_6$"),
    grade_07 = c("^grade_7$", "^gr_7$", "^7th$", "^07$", "^_7$"),
    grade_08 = c("^grade_8$", "^gr_8$", "^8th$", "^08$", "^_8$"),
    grade_09 = c("^grade_9$", "^gr_9$", "^9th$", "^09$", "^_9$"),
    grade_10 = c("^grade_10$", "^gr_10$", "^10th$", "^_10$"),
    grade_11 = c("^grade_11$", "^gr_11$", "^11th$", "^_11$"),
    grade_12 = c("^grade_12$", "^gr_12$", "^12th$", "^_12$")
  )

  for (grade_name in names(grade_patterns)) {
    col <- find_col(grade_patterns[[grade_name]])
    if (!is.null(col)) {
      result[[grade_name]] <- safe_numeric(df[[col]])
    }
  }

  # Ungraded students
  ug_col <- find_col(c("^ug$", "ungraded", "^ungraded$"))
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

  # Aggregate by district
  district_agg <- school_df %>%
    dplyr::filter(!is.na(district_id)) %>%
    dplyr::group_by(district_id) %>%
    dplyr::summarize(
      district_name = dplyr::first(district_name[!is.na(district_name)]),
      county = dplyr::first(county[!is.na(county)]),
      dplyr::across(dplyr::all_of(sum_cols), ~sum(.x, na.rm = TRUE)),
      .groups = "drop"
    ) %>%
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
