""" simple test app """
import pandas as pd


def get_pandas_version() -> str:
    """
    returns pandas version as string
    """
    return pd.__version__


print(get_pandas_version())
