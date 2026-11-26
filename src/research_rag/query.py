"""Retrieve relevant paper chunks and generate cited answers via an OpenAI-compatible API."""
import os

import chromadb
from openai import OpenAI
from sentence_transformers import SentenceTransformer

from research_rag.config import CHROMA_DIR, COLLECTION_NAME, EMBED_MODEL_NAME
from research_rag.indexing.bm25 import load_index as load_bm25
from research_rag.indexing.hybrid import (
    bm25_ranking,
    dense_ranking,
    reciprocal_rank_fusion,
)

SYSTEM_INSTRUCTION = """You are a research assistant answering questions about
the requested research topic using only the provided excerpts from academic papers.

Rules:
- Answer only using the provided context. If the context doesn't contain the
  answer, say so explicitly rather than guessing.
- After each claim, cite the source using the format [chunk_id].
- Be concise and technical, matching the register of the source material.
"""


def retrieve(bm25, chunks, chunk_lookup, embed_model, collection, query_text, top_k=5):
    bm25_ranked = bm25_ranking(bm25, chunks, query_text)
    dense_ranked = dense_ranking(embed_model, collection, query_text)
    fused = reciprocal_rank_fusion([bm25_ranked, dense_ranked])
    return [chunk_lookup[cid] for cid in fused[:top_k]]


def build_prompt(query_text, retrieved_chunks):
    context_blocks = []
    for c in retrieved_chunks:
        context_blocks.append(
            f"[{c['chunk_id']}] (from \"{c['title']}\")\n{c['text']}"
        )
    context = "\n\n---\n\n".join(context_blocks)
    return f"Context:\n{context}\n\nQuestion: {query_text}\n\nAnswer:"


def load_llm_settings():
    settings = {
        "base_url": os.getenv("OPENAI_BASE_URL", "").strip(),
        "model_name": os.getenv("OPENAI_MODEL_NAME", "").strip(),
        "api_key": os.getenv("OPENAI_API_KEY", "").strip(),
    }
    missing = [key for key, value in settings.items() if not value]
    if missing:
        names = ", ".join(f"OPENAI_{key.upper()}" for key in missing)
        raise RuntimeError(f"Configure the following values in .env: {names}")
    return settings


def create_llm_client():
    settings = load_llm_settings()
    return OpenAI(base_url=settings["base_url"], api_key=settings["api_key"])


def answer(client, query_text, retrieved_chunks):
    settings = load_llm_settings()
    response = client.chat.completions.create(
        model=settings["model_name"],
        messages=[
            {"role": "system", "content": SYSTEM_INSTRUCTION},
            {"role": "user", "content": build_prompt(query_text, retrieved_chunks)},
        ],
    )
    if not response.choices:
        raise RuntimeError("The language-model API returned no choices.")
    content = response.choices[0].message.content
    if not isinstance(content, str) or not content.strip():
        raise RuntimeError("The language-model API returned an empty answer.")
    return content


if __name__ == "__main__":
    bm25, chunks = load_bm25()
    chunk_lookup = {c["chunk_id"]: c for c in chunks}

    embed_model = SentenceTransformer(EMBED_MODEL_NAME)
    chroma_client = chromadb.PersistentClient(path=str(CHROMA_DIR))
    collection = chroma_client.get_collection(COLLECTION_NAME)

    llm_client = create_llm_client()
    topic = os.getenv("RESEARCH_KEYWORD", "the research topic")

    test_queries = [
        f"What are the main findings about {topic}?",
        f"Which materials or methods are compared in studies of {topic}?",
        f"What limitations or open questions are reported about {topic}?",
    ]

    for q in test_queries:
        print(f"\n=== Query: {q!r} ===")
        retrieved = retrieve(bm25, chunks, chunk_lookup, embed_model, collection, q, top_k=5)
        print("Retrieved chunks:", [c["chunk_id"] for c in retrieved])
        result = answer(llm_client, q, retrieved)
        print(f"\nAnswer:\n{result}")
