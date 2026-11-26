# Topic Research RAG

A configurable retrieval-augmented generation (RAG) assistant for exploring
academic research on any arXiv topic. It indexes PDFs for a selected keyword,
combines sparse BM25 and dense vector retrieval with reciprocal rank fusion,
and generates cited answers through an OpenAI-compatible chat completions API.

## Features

- Hybrid search using BM25 + dense embeddings
- Reciprocal Rank Fusion for robust retrieval
- Chunk-level citations in generated answers
- Streamlit chat-style interface
- Retrieval evaluation with `Hit@5`
- Configurable arXiv keyword or multi-word topic

## Project structure

```text
src/research_rag/
  ingestion/            arXiv download, metadata, PDF extraction/chunking
  indexing/             BM25, ChromaDB, and rank-fusion implementations
  query.py              Retrieval and OpenAI-compatible answer generation
  evaluate.py           Dense vs hybrid retrieval evaluation
  app.py                Streamlit interface
  config.py             Shared paths and model/index settings
papers/                 Downloaded academic PDFs
eval/                   Hand-labeled retrieval queries
chroma_db/              Persistent vector index (generated)
pyproject.toml          Package metadata and dependencies
Makefile                Setup and workflow shortcuts
```

## Setup

Python 3.11 or 3.12 is required. `make setup` automatically uses Python 3.12
or 3.11 when available and recreates `.venv` for the compatible runtime.
It invokes virtualenv tools through Python modules, so setup and app launch
also work when the project path contains spaces.

```bash
git clone https://github.com/abdulnafih-official/RAG-Project.git
cd RAG-Project

python3.12 -m venv .venv
source .venv/bin/activate
pip install -e .

cp .env.example .env
```

Configure the endpoint, model, and API key in `.env`:

```dotenv
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL_NAME=gpt-4o-mini
OPENAI_API_KEY=your_api_key_here
HF_TOKEN=your_huggingface_read_token_here
RESEARCH_KEYWORD=supercapacitor
```

Use values provided by your OpenAI-compatible service. `OPENAI_BASE_URL`,
`OPENAI_MODEL_NAME`, and `OPENAI_API_KEY` are read from `.env`;
`RESEARCH_KEYWORD` controls the arXiv search topic.
`HF_TOKEN` is optional and lets Hugging Face model downloads authenticate to
the Hub, which can help avoid anonymous rate limits.

Or use the Makefile shortcuts:

```bash
make setup
make env
```

To download papers, set up the environment, build every index, and start the
app in one command:

```bash
make all
```

Choose a different research topic:

```bash
make all KEYWORD="quantum battery"
make download KEYWORD="graphene" MAX_PAPERS=50
```

The keyword is used for the arXiv search and to rank matching papers. Changing
the keyword replaces the previous PDF corpus and rebuilds the indexes.

## Run the app

```bash
streamlit run src/research_rag/app.py
```

The Makefile targets the virtual environment:

```bash
make app
```

Open the local URL printed by Streamlit, then ask about electrode materials,
electrolytes, cycling stability, capacitance, energy density, or charge
storage.

## Build the indexes

After `make setup` (or `pip install -e .`), run these commands from the project
root:

```bash
python -m research_rag.ingestion.metadata
python -m research_rag.ingestion.chunk
python -m research_rag.indexing.bm25
python -m research_rag.indexing.dense
```

Or rebuild every index with:

```bash
make index
```

To download papers for a topic directly:

```bash
python -m research_rag.ingestion.arxiv_download --keyword "quantum battery" --max 30 --out papers
```

The same download is available through `make download`.

## Evaluate retrieval

```bash
python -m research_rag.evaluate
```

The evaluation compares dense-only retrieval against hybrid retrieval using
`Hit@5`. Update `eval/test_queries.json` with queries and known `chunk_id`
values to add test cases.

## CLI usage

Test the hybrid query pipeline directly:

```bash
python -m research_rag.query
```

## Data and generated files

The PDF corpus is stored in `papers/`. Generated artifacts such as
`metadata.json`, `chunks.jsonl`, `bm25_index.pkl`, and `chroma_db/` can be
recreated with `make index`. `make clean` removes those generated artifacts
but preserves the downloaded PDFs.
