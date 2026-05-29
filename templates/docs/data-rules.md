# Data Handling Rules — {{PROJECT_NAME}}

This document details the guidelines and constraints for managing data pipelines, schemas, and processing.

## What You MUST Do
- **Always validate schema** with `pandera` before writing any transformation.
- **Always define Pydantic models** for API responses before parsing them.
- **Always check for nulls/missing values** before modeling, and document the null handling decision.
- **Always use `.head(5)`, `.describe()`, `.dtypes`** when inspecting data in context.
- **Always reference file paths** in context rather than embedding full file content.

## What You MUST NEVER Do
- **NEVER load full DataFrame** content into context — use summaries and schemas only.
- **NEVER hardcode file paths** — always use `settings.{path_property}`.
- **NEVER assume API responses** have expected structure — always validate.
- **NEVER assume data types** — always check `.dtypes` first.
- **NEVER skip data validation** to "save time".
