#' orschooldata: Fetch and Process Oregon School Data
#'
#' Downloads and processes school data from the Oregon Department of Education
#' (ODE). Provides functions for fetching enrollment data from the Fall Membership
#' Reports and transforming it into tidy format for analysis.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Fetch enrollment data for a school year}
#'   \item{\code{\link{fetch_enr_multi}}}{Fetch enrollment data for multiple years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide data to tidy (long) format}
#'   \item{\code{\link{id_enr_aggs}}}{Add aggregation level flags}
#'   \item{\code{\link{enr_grade_aggs}}}{Create grade-level aggregations}
#'   \item{\code{\link{get_available_years}}}{Get list of available data years}
#' }
#'
#' @section Cache functions:
#' \describe{
#'   \item{\code{\link{cache_status}}}{View cached data files}
#'   \item{\code{\link{clear_cache}}}{Remove cached data files}
#' }
#'
#' @section ID System:
#' Oregon uses the following ID structure:
#' \itemize{
#'   \item District IDs: 4-digit numeric codes (e.g., 0001 = Baker SD)
#'   \item School IDs: Variable length numeric codes
#'   \item Institution IDs: Combined district + school identifier
#' }
#'
#' @section Data Sources:
#' Data is sourced from the Oregon Department of Education's Fall Membership Reports:
#' \itemize{
#'   \item Fall Membership: \url{https://www.oregon.gov/ode/reports-and-data/students/Pages/Student-Enrollment-Reports.aspx}
#'   \item ODE Home: \url{https://www.oregon.gov/ode}
#' }
#'
#' @section Format Eras:
#' Oregon enrollment data has two distinct format eras:
#' \describe{
#'   \item{Era 1: 2010-2014}{.xls format with older column structure}
#'   \item{Era 2: 2015-present}{.xlsx format with standardized columns}
#' }
#'
#' @docType package
#' @name orschooldata-package
#' @aliases orschooldata
#' @keywords internal
"_PACKAGE"

#' Pipe operator
#'
#' See \code{magrittr::\link[magrittr:pipe]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom dplyr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
NULL
