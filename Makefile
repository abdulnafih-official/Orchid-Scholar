PYTHON ?= $(shell command -v python3.12 2>/dev/null || command -v python3.11 2>/dev/null || command -v python 2>/dev/null)
VENV := .venv
VENV_PYTHON := $(VENV)/bin/python
SETUP_STAMP := $(VENV)/.install-stamp
MAX_PAPERS ?= 30
ENV_KEYWORD := $(shell sed -n 's/^RESEARCH_KEYWORD=//p' .env 2>/dev/null | sed -e 's/^"//' -e 's/"$$//' -e "s/^'//" -e "s/'$$//")
KEYWORD ?= $(if $(strip $(ENV_KEYWORD)),$(ENV_KEYWORD),supercapacitor)

.PHONY: help all setup env index metadata chunks bm25 dense app query eval download clean

help:
	@printf "Available targets:\n"
	@printf "  make all [KEYWORD=topic]         Run the pipeline using .env's keyword by default\n"
	@printf "  make setup       Create .venv and install dependencies\n"
	@printf "  make env         Create .env from .env.example\n"
	@printf "  make metadata    Fetch paper metadata\n"
	@printf "  make chunks      Extract and chunk PDF text\n"
	@printf "  make bm25        Build the BM25 index\n"
	@printf "  make dense       Build the ChromaDB dense index\n"
	@printf "  make index       Rebuild all retrieval indexes\n"
	@printf "  make app         Start the Streamlit application\n"
	@printf "  make query       Run sample CLI queries\n"
	@printf "  make eval        Evaluate dense and hybrid retrieval\n"
	@printf "  make download [KEYWORD=topic]    Download matching arXiv papers\n"
	@printf "  make clean       Remove generated indexes and extracted data\n"

all: setup env
	$(MAKE) download KEYWORD="$(KEYWORD)"
	$(MAKE) index
	$(MAKE) app KEYWORD="$(KEYWORD)"

setup:
	@set -e; \
	recreate=0; \
	if [ -x "$(VENV_PYTHON)" ]; then \
		version=$$($(VENV_PYTHON) -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")'); \
		case "$$version" in 3.11|3.12) ;; *) recreate=1 ;; esac; \
	else \
		recreate=1; \
	fi; \
	if [ "$$recreate" -eq 1 ]; then \
		if [ -z "$(PYTHON)" ]; then printf "Python 3.11 or 3.12 is required\n"; exit 1; fi; \
		version=$$("$(PYTHON)" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")'); \
		case "$$version" in 3.11|3.12) ;; *) printf "Python 3.11 or 3.12 is required; found $$version\n"; exit 1 ;; esac; \
		rm -rf $(VENV); \
		"$(PYTHON)" -m venv $(VENV); \
	fi; \
	if [ "$$recreate" -eq 1 ] || [ ! -f "$(SETUP_STAMP)" ] || [ requirements.txt -nt "$(SETUP_STAMP)" ] || [ pyproject.toml -nt "$(SETUP_STAMP)" ]; then \
		$(VENV_PYTHON) -m pip install -e .; \
		touch $(SETUP_STAMP); \
	fi

env:
	@if [ -f .env ]; then printf ".env already exists\n"; else cp .env.example .env; printf "Created .env - add your GEMINI_API_KEY\n"; fi

metadata: setup
	$(VENV_PYTHON) -m research_rag.ingestion.metadata

chunks: metadata
	$(VENV_PYTHON) -m research_rag.ingestion.chunk

bm25: chunks
	$(VENV_PYTHON) -m research_rag.indexing.bm25

dense: chunks
	$(VENV_PYTHON) -m research_rag.indexing.dense

index: setup
	$(MAKE) clean
	$(VENV_PYTHON) -m research_rag.ingestion.metadata
	$(VENV_PYTHON) -m research_rag.ingestion.chunk
	$(VENV_PYTHON) -m research_rag.indexing.bm25
	$(VENV_PYTHON) -m research_rag.indexing.dense

app: setup
	TOPIC="$(KEYWORD)" $(VENV_PYTHON) -m streamlit run src/research_rag/app.py

query: setup
	$(VENV_PYTHON) -m research_rag.query

eval: setup
	$(VENV_PYTHON) -m research_rag.evaluate

download: setup
	$(VENV_PYTHON) -m research_rag.ingestion.arxiv_download --keyword "$(KEYWORD)" --max $(MAX_PAPERS) --out papers

clean:
	rm -rf chroma_db
	rm -f metadata.json chunks.jsonl bm25_index.pkl
