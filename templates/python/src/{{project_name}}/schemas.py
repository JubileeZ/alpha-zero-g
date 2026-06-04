import pandera as pa
from pandera.typing import Series, DataFrame


class ExampleSchema(pa.SchemaModel):
    """
    Example Pandera schema for data validation.
    Usage:
        validated_df = ExampleSchema.validate(raw_df)
    """

    id: Series[int] = pa.Field(ge=0)
    name: Series[str] = pa.Field(nullable=False)
    value: Series[float] = pa.Field(ge=0.0, le=1.0)
    
    class Config:
        strict = True
