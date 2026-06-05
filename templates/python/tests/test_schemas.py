import pytest
import pandas as pd
import pandera as pa
from {{PACKAGE_NAME}}.schemas import ExampleSchema

def test_example_schema_valid():
    """Test that a valid dataframe passes schema validation."""
    df = pd.DataFrame({
        "id": [1, 2, 3],
        "name": ["Alice", "Bob", "Charlie"],
        "value": [0.1, 0.5, 0.9]
    })
    
    # Should not raise an exception
    validated_df = ExampleSchema.validate(df)
    assert not validated_df.empty

def test_example_schema_invalid():
    """Test that an invalid dataframe fails schema validation."""
    df = pd.DataFrame({
        "id": [-1, 2, 3],  # id must be >= 0
        "name": ["Alice", "Bob", None],  # name cannot be null
        "value": [1.5, 0.5, 0.9]  # value must be <= 1.0
    })
    
    with pytest.raises(pa.errors.SchemaErrors):
        # Using lazy validation to catch all errors
        ExampleSchema.validate(df, lazy=True)