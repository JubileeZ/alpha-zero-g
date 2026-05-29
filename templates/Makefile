# Makefile — Works on macOS, Linux, and Windows (with make installed)
.PHONY: setup install lint format type-check test test-cov test-unit check clean

# Detect OS for cleanup command
ifeq ($(OS),Windows_NT)
    RM = rmdir /s /q
    CP = copy
else
    RM = rm -rf
    CP = cp
endif

## Setup & Installation
setup:
	uv sync
	uv run pre-commit install
	$(CP) .env.example .env 2>/dev/null || $(CP) .env.example .env
	@echo "✅ Setup complete. Edit .env with your values."

install:
	uv sync

## Quality Gates
lint:
	uv run ruff check src/ tests/
	@echo "✅ Lint passed"

format:
	uv run ruff format src/ tests/
	@echo "✅ Format applied"

type-check:
	uv run mypy src/
	@echo "✅ Type check passed"

## Testing
test:
	uv run pytest tests/ -v

test-cov:
	uv run pytest tests/ --cov=src --cov-report=term-missing --cov-report=html

test-unit:
	uv run pytest tests/ -v

## Combined checks (run before committing)
check: lint type-check test
	@echo "✅ All checks passed"

## Cleanup
clean:
	-$(RM) .pytest_cache 2>/dev/null || true
	-$(RM) htmlcov 2>/dev/null || true
	-$(RM) .mypy_cache 2>/dev/null || true
	-$(RM) .ruff_cache 2>/dev/null || true
	-$(RM) .venv 2>/dev/null || true
