""" tests for app.py """
from app import get_pandas_version


def test_sample():
    """
    simple test of app function
    """
    pandas_version = get_pandas_version()
    assert isinstance(pandas_version, str)
