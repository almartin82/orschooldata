"""
Tests for pyorschooldata Python wrapper.

Uses pytest to test the Python interface to Oregon school enrollment data.
Oregon enrolls approximately 580,000 students across ~197 districts.
"""

import pytest
import pandas as pd
import pyorschooldata as or_


# Cache available years to avoid repeated R calls
_available_years = None


def get_test_years():
    """Get available years for testing, cached."""
    global _available_years
    if _available_years is None:
        _available_years = or_.get_available_years()
    return _available_years


class TestImport:
    """Test that the package imports correctly."""

    def test_import_module(self):
        """Module should import without errors."""
        import pyorschooldata
        assert pyorschooldata is not None

    def test_import_alias(self):
        """Module should import with or_ alias."""
        import pyorschooldata as or_
        assert or_ is not None

    def test_version_exists(self):
        """Package should have a version string."""
        assert hasattr(or_, "__version__")
        assert isinstance(or_.__version__, str)

    def test_exported_functions(self):
        """Package should export expected functions."""
        assert hasattr(or_, "fetch_enr")
        assert hasattr(or_, "fetch_enr_multi")
        assert hasattr(or_, "get_available_years")
        assert callable(or_.fetch_enr)
        assert callable(or_.fetch_enr_multi)
        assert callable(or_.get_available_years)


class TestGetAvailableYears:
    """Test get_available_years function."""

    def test_returns_dict(self):
        """Should return a dictionary."""
        years = or_.get_available_years()
        assert isinstance(years, dict)

    def test_has_required_keys(self):
        """Should have min_year and max_year keys."""
        years = or_.get_available_years()
        assert "min_year" in years
        assert "max_year" in years

    def test_years_are_integers(self):
        """Year values should be integers."""
        years = or_.get_available_years()
        assert isinstance(years["min_year"], int)
        assert isinstance(years["max_year"], int)

    def test_year_range_valid(self):
        """Min year should be less than max year."""
        years = or_.get_available_years()
        assert years["min_year"] < years["max_year"]

    def test_reasonable_year_range(self):
        """Years should be in reasonable range (2010-2030)."""
        years = or_.get_available_years()
        assert 2010 <= years["min_year"] <= 2015
        assert 2020 <= years["max_year"] <= 2030


class TestFetchEnr:
    """Test fetch_enr function for single year."""

    def test_returns_dataframe(self):
        """Should return a pandas DataFrame."""
        years = get_test_years()
        df = or_.fetch_enr(years['max_year'])
        assert isinstance(df, pd.DataFrame)

    def test_dataframe_not_empty(self):
        """DataFrame should contain data."""
        years = get_test_years()
        df = or_.fetch_enr(years['max_year'])
        assert len(df) > 0

    def test_has_required_columns(self):
        """DataFrame should have expected columns."""
        years = get_test_years()
        df = or_.fetch_enr(years['max_year'])
        required_cols = [
            "end_year",
            "district_id",
            "district_name",
            "n_students",
            "grade_level",
        ]
        for col in required_cols:
            assert col in df.columns, f"Missing column: {col}"

    def test_end_year_matches_request(self):
        """end_year column should match requested year."""
        years = get_test_years()
        df = or_.fetch_enr(years['max_year'])
        unique_years = df["end_year"].unique()
        assert len(unique_years) == 1
        assert unique_years[0] == years['max_year']

    def test_has_state_level_data(self):
        """Should include state-level aggregation."""
        years = get_test_years()
        df = or_.fetch_enr(years['max_year'])
        assert "is_state" in df.columns
        state_rows = df[df["is_state"] == True]
        assert len(state_rows) > 0

    def test_has_district_level_data(self):
        """Should include district-level data."""
        years = get_test_years()
        df = or_.fetch_enr(years['max_year'])
        assert "is_district" in df.columns
        district_rows = df[df["is_district"] == True]
        assert len(district_rows) > 0


class TestFetchEnrMulti:
    """Test fetch_enr_multi function for multiple years."""

    def test_returns_dataframe(self):
        """Should return a pandas DataFrame."""
        years = get_test_years()
        df = or_.fetch_enr_multi([years['max_year']])
        assert isinstance(df, pd.DataFrame)

    def test_contains_requested_year(self):
        """DataFrame should contain the requested year."""
        years = get_test_years()
        test_year = years['max_year']
        df = or_.fetch_enr_multi([test_year])
        result_years = df["end_year"].unique()
        assert test_year in result_years, f"Missing year: {test_year}"

    def test_multi_matches_single(self):
        """Single-element multi-year fetch matches single fetch."""
        years = get_test_years()
        df_single = or_.fetch_enr(years['max_year'])
        df_multi = or_.fetch_enr_multi([years['max_year']])
        # Row counts should match
        assert len(df_single) == len(df_multi)

    def test_single_year_list(self):
        """Should work with single year in list."""
        years = get_test_years()
        df = or_.fetch_enr_multi([years['max_year']])
        assert isinstance(df, pd.DataFrame)
        assert len(df) > 0


class TestDataIntegrity:
    """Test data integrity and reasonable values."""

    def test_statewide_enrollment_reasonable(self):
        """Statewide enrollment should be around 580,000."""
        years = get_test_years()
        df = or_.fetch_enr(years['max_year'])
        state_total = df[
            (df["is_state"] == True)
            & (df["subgroup"] == "total_enrollment")
            & (df["grade_level"] == "TOTAL")
        ]["n_students"].values[0]
        # Oregon has approximately 580,000 students
        assert 400000 < state_total < 800000, f"State total {state_total} outside expected range"

    def test_district_count_reasonable(self):
        """Should have approximately 197 districts."""
        years = get_test_years()
        df = or_.fetch_enr(years['max_year'])
        districts = df[
            (df["is_district"] == True)
            & (df["subgroup"] == "total_enrollment")
            & (df["grade_level"] == "TOTAL")
        ]
        n_districts = len(districts)
        # Oregon has ~197 school districts
        assert 150 < n_districts < 250, f"District count {n_districts} outside expected range"

    def test_no_negative_enrollment(self):
        """Enrollment counts should not be negative."""
        years = get_test_years()
        df = or_.fetch_enr(years['max_year'])
        assert (df["n_students"] >= 0).all(), "Found negative enrollment values"

    def test_portland_exists(self):
        """Portland Public Schools should exist in data."""
        years = get_test_years()
        df = or_.fetch_enr(years['max_year'])
        portland = df[df["district_name"].str.contains("Portland", case=False, na=False)]
        assert len(portland) > 0, "Portland not found in data"

    def test_grade_levels_present(self):
        """Should have multiple grade levels."""
        years = get_test_years()
        df = or_.fetch_enr(years['max_year'])
        grade_levels = df["grade_level"].unique()
        assert len(grade_levels) > 5, "Too few grade levels"
        assert "TOTAL" in grade_levels, "Missing TOTAL grade level"


class TestEdgeCases:
    """Test edge cases and error handling."""

    def test_oldest_available_year(self):
        """Should be able to fetch oldest available year."""
        years = or_.get_available_years()
        df = or_.fetch_enr(years["min_year"])
        assert isinstance(df, pd.DataFrame)
        assert len(df) > 0

    def test_newest_available_year(self):
        """Should be able to fetch newest available year."""
        years = or_.get_available_years()
        df = or_.fetch_enr(years["max_year"])
        assert isinstance(df, pd.DataFrame)
        assert len(df) > 0

    def test_empty_years_list(self):
        """Empty years list should raise an error or return empty."""
        # R function may return empty df or raise - just verify it doesn't crash unexpectedly
        try:
            result = or_.fetch_enr_multi([])
            # If it returns, should be a DataFrame (possibly empty)
            assert isinstance(result, pd.DataFrame)
        except Exception:
            # Raising an exception is also acceptable
            pass

    def test_invalid_year_type(self):
        """String year should raise an error."""
        with pytest.raises((TypeError, Exception)):
            or_.fetch_enr("2023")
