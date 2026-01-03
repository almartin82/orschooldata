"""
Tests for pyorschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pyorschooldata
    assert pyorschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pyorschooldata
    assert hasattr(pyorschooldata, 'fetch_enr')
    assert callable(pyorschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pyorschooldata
    assert hasattr(pyorschooldata, 'get_available_years')
    assert callable(pyorschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pyorschooldata
    assert hasattr(pyorschooldata, '__version__')
    assert isinstance(pyorschooldata.__version__, str)
