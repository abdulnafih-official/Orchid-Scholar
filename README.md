# Orchid Scholar

**Orchid Scholar** is a local AI research assistant that searches academic papers on arXiv and answers questions using only the retrieved paper text.

Choose a topic, such as `supercapacitor`, `quantum battery`, or `graphene`. The app downloads matching papers, turns them into searchable text, and produces answers with citations.

## What it does

- Downloads academic PDFs from arXiv for a topic you choose
- Searches papers by keyword and meaning
- Combines BM25 keyword search with vector search
- Generates an answer using an OpenAI-compatible AI model
- Shows which paper passages support the answer
- Provides a simple chat interface in Streamlit

## Quick start

### 1. Requirements

- Python 3.11 or 3.12
- Git
- An API key for an OpenAI-compatible service
- Internet access for downloading papers and installing dependencies

### 2. Download and set up the project

```bash
git clone https://github.com/abdulnafih-official/Orchid-Scholar.git
make setup
make env
```

`make setup` creates a virtual environment and installs the project dependencies.
`make env` creates a `.env` configuration file.

The project uses [pyproject.toml](pyproject.toml) as the single source for package metadata and Python dependencies.

### 3. Add your API settings

Open `.env` and replace `your_api_key_here` with your API key:

```dotenv
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL_NAME=gpt-4o-mini
OPENAI_API_KEY=your_api_key_here
HF_TOKEN=your_huggingface_read_token_here
RESEARCH_KEYWORD=supercapacitor
```

| Setting | What it does |
|---|---|
| `OPENAI_BASE_URL` | API endpoint of an OpenAI-compatible service |
| `OPENAI_MODEL_NAME` | Name of the chat model used to answer questions |
| `OPENAI_API_KEY` | Your API key |
| `HF_TOKEN` | Optional Hugging Face token for model downloads |
| `RESEARCH_KEYWORD` | Topic used to find arXiv papers |

> Keep `.env` private. Never add your real API key to GitHub or share it publicly.

### 4. Download papers, build the indexes, and run

For the topic in `.env`:

```bash
make all
```

To choose a topic on the command line:

```bash
make all KEYWORD="quantum battery"
```

When setup finishes, Streamlit prints a local address such as `http://localhost:8501`. Open that address in your browser and ask a question.

## Change the research topic

You can change the topic in `.env`:

```dotenv
RESEARCH_KEYWORD=graphene
```

Then rebuild and run the project:

```bash
make all
```

Or specify the topic for a single run:

```bash
make all KEYWORD="graphene" MAX_PAPERS=50
```

Changing the topic replaces the downloaded PDF corpus and rebuilds the search indexes.

## Run after the first setup

If the papers and indexes already exist, start the app without rebuilding them:

```bash
make app
```

To start with a different topic that is already downloaded and indexed:

```bash
make app KEYWORD="quantum battery"
```

## How retrieval works

1. **Arxiv download:** Finds and downloads PDFs matching the selected topic.
2. **Chunking:** Splits PDF text into smaller sections.
3. **BM25 search:** Finds passages with matching keywords.
4. **Vector search:** Uses text embeddings to find passages with similar meanings.
5. **Reciprocal Rank Fusion:** Combines both search results.
6. **Answer generation:** Sends the best passages to the configured chat model.
7. **Citations:** Links the answer to the exact retrieved chunks.

## Useful commands

| Command | Purpose |
|---|---|
| `make setup` | Create `.venv` and install dependencies |
| `make env` | Create `.env` from `.env.example` |
| `make all` | Download papers, build indexes, and start the app |
| `make app` | Start the Streamlit app |
| `make download KEYWORD="topic"` | Download papers for a topic |
| `make index` | Rebuild metadata and search indexes |
| `make clean` | Remove generated indexes and extracted text |
| `make query` | Ask a sample question in the terminal |
| `make eval` | Evaluate retrieval quality |

## Manual setup

Use these commands if you do not want to use the Makefile:

```bash
python3.12 -m venv .venv
source .venv/bin/activate
pip install -e .
cp .env.example .env
make download KEYWORD="supercapacitor"
make index
streamlit run src/research_rag/app.py
```

On Windows, activate the virtual environment with:

```powershell
.venv\Scripts\Activate.ps1
```

## Project structure

```text
src/research_rag/
  ingestion/            Download, extract, and chunk arXiv PDFs
  indexing/             BM25, ChromaDB, and result fusion
  app.py                Streamlit interface
  query.py              Search and answer generation
  evaluate.py           Retrieval evaluation
  config.py             Paths and model settings

papers/                 Downloaded academic PDFs
eval/                   Hand-labeled test questions
chroma_db/              Generated vector index
metadata.json           Generated paper metadata
chunks.jsonl            Generated text chunks
bm25_index.pkl          Generated BM25 index
```

## Troubleshooting

### `make setup` says Python 3.11 or 3.12 is required

Install Python 3.11 or 3.12 and try again. The Makefile automatically looks for `python3.12`, `python3.11`, or `python`.

### The app cannot connect to the model

Check these values in `.env`:

- `OPENAI_BASE_URL` is the correct API endpoint
- `OPENAI_MODEL_NAME` is a model available to your account
- `OPENAI_API_KEY` contains a valid key

### The app does not find enough papers

Try a more common topic or increase `MAX_PAPERS`:

```bash
make all KEYWORD="quantum battery" MAX_PAPERS=50
```

### A package or model download fails

Make sure internet access is available. If Hugging Face authentication is required, set `HF_TOKEN` in `.env`.

## Evaluation

Run:

```bash
make eval
```

The evaluation compares dense-only retrieval with hybrid retrieval using `Hit@5`.

To add test cases, update `eval/test_queries.json` with a question and the expected `chunk_id` values.

### Latest result

The latest run used the **supercapacitor** arXiv paper corpus and 30 hand-labeled queries:

| Retrieval method | Hit@5 |
|---|---:|
| Dense-only | 25/30 (83%) |
| Hybrid (BM25 + dense with RRF) | 27/30 (90%) |

Hybrid retrieval correctly answered 2 additional queries that dense-only retrieval missed.

## License

Orchid Scholar is licensed under the [MIT License](LICENSE).
