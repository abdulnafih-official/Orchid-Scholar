from pathlib import Path

from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_ROOT / ".env")

PAPERS_DIR = PROJECT_ROOT / "papers"
METADATA_PATH = PROJECT_ROOT / "metadata.json"
CHUNKS_PATH = PROJECT_ROOT / "chunks.jsonl"
BM25_INDEX_PATH = PROJECT_ROOT / "bm25_index.pkl"
CHROMA_DIR = PROJECT_ROOT / "chroma_db"
EVAL_PATH = PROJECT_ROOT / "eval" / "test_queries.json"

COLLECTION_NAME = "research_chunks"
EMBED_MODEL_NAME = "BAAI/bge-small-en-v1.5"
