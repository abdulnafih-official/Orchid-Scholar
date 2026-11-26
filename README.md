# Topic Research RAG

A configurable retrieval-augmented generation (RAG) assistant for exploring
academic research on any arXiv topic. It indexes PDFs for a selected keyword,
combines sparse BM25 and dense vector retrieval with reciprocal rank fusion,
and generates cited answers with Google's Gemini API.

## Features

- Hybrid search using BM25 + dense embeddings
- Reciprocal Rank Fusion for robust retrieval
- Chunk-level citations in generated answers
- Streamlit chat-style interface
- Retrieval evaluation with `Hit@5`
- Configurable arXiv keyword or multi-word topic

## Project structure

```text
papers/                 Academic PDFs
src/
  arxiv_download.py     Download papers from arXiv
  build_metadata.py     Fetch canonical paper metadata
  chunk.py              Extract and chunk PDF text
  build_bm25.py         Build the sparse search index
  build_dense.py        Build the ChromaDB dense index
  build_hybrid.py       Combine rankings with RRF
  evaluate.py           Measure dense and hybrid retrieval
  query.py              Retrieve context and call Gemini
  app.py                Streamlit application
eval/test_queries.json  Hand-labeled retrieval queries
chroma_db/              Persistent vector index (generated)
Makefile                Common setup and build commands
```

## Setup

Python 3.11 or 3.12 is recommended.

```bash
git clone https://github.com/abdulnafih-official/RAG-Project.git
cd RAG-Project

python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env
```

Add a valid API key to `.env`:

```dotenv
GEMINI_API_KEY=your_gemini_api_key_here
RESEARCH_KEYWORD=supercapacitor
```

Set `RESEARCH_KEYWORD` to control the arXiv search topic, for example
`RESEARCH_KEYWORD=quantum battery`.

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
streamlit run src/app.py
```

The Makefile targets the virtual environment:

```bash
make app
```

Open the local URL printed by Streamlit, then ask about electrode materials,
electrolytes, cycling stability, capacitance, energy density, or charge
storage.

## Build the indexes

Run these commands from the project root:

```bash
python src/build_metadata.py
python src/chunk.py
python src/build_bm25.py
python src/build_dense.py
```

Or rebuild every index with:

```bash
make index
```

To download papers for a topic directly:

```bash
python src/arxiv_download.py --keyword "quantum battery" --max 30 --out papers
```

The same download is available through `make download`.

## Evaluate retrieval

```bash
python src/evaluate.py
```

The evaluation compares dense-only retrieval against hybrid retrieval using
`Hit@5`. Update `eval/test_queries.json` with queries and known `chunk_id`
values to add test cases.

## CLI usage

Test the hybrid query pipeline directly:

```bash
python src/query.py
```

## Data and generated files

The PDF corpus is stored in `papers/`. Generated artifacts such as
`metadata.json`, `chunks.jsonl`, `bm25_index.pkl`, and `chroma_db/` are
excluded by `.gitignore` and can be recreated from the source scripts.
