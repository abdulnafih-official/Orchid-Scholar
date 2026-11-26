PYTHON ?= python
VENV := .venv
VENV_PYTHON := $(VENV)/bin/python
VENV_PIP := $(VENV)/bin/pip

.PHONY: help all setup env index metadata chunks bm25 dense app query eval download clean

help:
	@printf "Available targets:\n"
	@printf "  make all         Download, set up, build indexes, and start the app\n"
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
	@printf "  make download    Download 30 arXiv papers into papers/\n"
	@printf "  make clean       Remove generated indexes and extracted data\n"

all: setup env download index app

setup:
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

index: metadata chunks bm25 dense

app:
	$(VENV)/bin/streamlit run src/app.py

query:
	$(VENV_PYTHON) src/query.py

eval:
	$(VENV_PYTHON) src/evaluate.py

download:
	$(VENV_PYTHON) src/arxiv_download.py --query "all:supercapacitor" --max 30 --out papers

clean:
	rm -rf chroma_db
	rm -f metadata.json chunks.jsonl bm25_index.pkl
