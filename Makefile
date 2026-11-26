PYTHON ?= $(shell command -v python3.12 2>/dev/null || command -v python3.11 2>/dev/null || command -v python 2>/dev/null)
VENV := .venv
VENV_PYTHON := $(VENV)/bin/python
VENV_PIP := $(VENV)/bin/pip
MAX_PAPERS ?= 30
ENV_KEYWORD := $(shell sed -n 's/^RESEARCH_KEYWORD=//p' .env 2>/dev/null)
KEYWORD ?= $(if $(strip $(ENV_KEYWORD)),$(ENV_KEYWORD),supercapacitor)

.PHONY: help all setup env index metadata chunks bm25 dense app query eval download clean

help:
	@printf "Available targets:\n"
	@printf "  make all KEYWORD=\"quantum battery\"  Download, set up, build indexes, and start the app\n"
	@printf "  make setup       Create .venv and install dependencies\n"
	@printf "  make env         Create .env from .env.example\n"
	@printf "  make metadata    Fetch paper metadata\n"
	@printf "  make chunks      Extract text and build chunks.jsonl\n"
	@printf "  make bm25        Build the BM25 index\n"
	@printf "  make dense       Build the ChromaDB dense index\n"
	@printf "  make index       Build all retrieval indexes\n"
	@printf "  make app         Start the Streamlit application\n"
	@printf "  make query       Run sample CLI queries\n"
	@printf "  make eval        Evaluate dense and hybrid retrieval\n"
	@printf "  make download KEYWORD=\"quantum battery\"  Download 30 matching arXiv papers\n"
	@printf "  make clean       Remove generated indexes and extracted data\n"

all: setup env download index app

setup:
	@set -e; \
	version=$$($(PYTHON) --version 2>&1 | awk '{print $$2}'); \
	major=$$(printf '%s' "$$version" | cut -d. -f1); \
	minor=$$(printf '%s' "$$version" | cut -d. -f2); \
	if [ "$$major" -ne 3 ] || [ "$$minor" -lt 11 ] || [ "$$minor" -gt 12 ]; then \
		printf "Python 3.11 or 3.12 is required; found $$version\n"; \
		exit 1; \
	fi; \
	rm -rf $(VENV); \
	$(PYTHON) -m venv $(VENV)
	$(VENV_PIP) install --upgrade pip
	$(VENV_PIP) install -r requirements.txt

env:
	@if [ -f .env ]; then printf ".env already exists\n"; else cp .env.example .env; printf "Created .env - add your GEMINI_API_KEY\n"; fi

metadata:
	$(VENV_PYTHON) src/build_metadata.py

chunks:
	$(VENV_PYTHON) src/chunk.py

bm25:
	$(VENV_PYTHON) src/build_bm25.py

dense:
	$(VENV_PYTHON) src/build_dense.py

index: clean metadata chunks bm25 dense

app:
	$(VENV)/bin/streamlit run src/app.py

query:
	$(VENV_PYTHON) src/query.py

eval:
	$(VENV_PYTHON) src/evaluate.py

download:
	$(VENV_PYTHON) src/arxiv_download.py --keyword "$(KEYWORD)" --max $(MAX_PAPERS) --out papers

clean:
	rm -rf chroma_db
	rm -f metadata.json chunks.jsonl bm25_index.pkl
