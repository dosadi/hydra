VENV ?= .venv
PYTHON ?= python

.PHONY: install test lint run clean

install:
	$(PYTHON) -m pip install -e .[dev]

test:
	$(PYTHON) -m pytest

lint:
	$(PYTHON) -m compileall src

run:
	$(PYTHON) -m codex_lock_broker.server

clean:
	rm -rf $(VENV) *.egg-info .pytest_cache .mypy_cache
