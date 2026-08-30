#!/usr/bin/env python3
"""fw ask — synchronous RAG+LLM wrapper for framework agents.

T-264: Keystone CLI integration. Enables programmatic Q&A access for
agents (healing, briefing, precedent mining) without requiring the
web server's streaming endpoint.

Usage:
    python3 lib/ask.py "How do I create a task?"
    python3 lib/ask.py --json "What is the healing loop?"
    python3 lib/ask.py --concise "List enforcement tiers"
"""
from __future__ import annotations

import argparse
import json
import os
import sys

# Add project root to path so web modules are importable
# T-644: the __file__-derived value below was written as the FALLBACK and was the
# correct one all along — it resolves to FRAMEWORK_ROOT, which is where web/ lives.
# lib/ask.sh exports PROJECT_ROOT unconditionally (ask.sh:32), so the env var always
# won, and in a VENDORED install (framework at <project>/.agentic-framework/) it points
# somewhere with no web/ at all. Measured before the fix, on the real entry point:
#     $ fw ask "what is a task"
#     ModuleNotFoundError: No module named 'web'
# Insert both. PROJECT_ROOT stays first-searched so a project may still shadow a module
# deliberately; FRAMEWORK_ROOT is the backstop that makes the env var unable to render
# `fw ask` unrunnable. Sibling of T-643 (same class, bin/fw, silent instead of loud).
FRAMEWORK_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT_ROOT = os.environ.get("PROJECT_ROOT", FRAMEWORK_ROOT)
for _root in (FRAMEWORK_ROOT, PROJECT_ROOT):
    if _root and _root not in sys.path:
        sys.path.insert(0, _root)

from web.embeddings import rag_retrieve, build_index
from web.ask import get_model, should_think, SYSTEM_PROMPT, format_rag_context

import ollama


CONCISE_ADDENDUM = "\n\nBe extremely concise — answer in 2-3 sentences maximum."


def ask(query: str, limit: int = 10, concise: bool = False, think: bool | None = None) -> dict:
    """Synchronous RAG+LLM query.

    Args:
        query: The question to answer.
        limit: Max chunks to retrieve.
        concise: If True, request brief answers.
        think: Override thinking mode. None = auto-detect.

    Returns:
        dict with keys: answer, model, sources, thinking_used
    """
    # Retrieve context
    chunks = rag_retrieve(query, limit=limit)

    # Format context
    context = format_rag_context(chunks)
    prompt = SYSTEM_PROMPT
    if concise:
        prompt += CONCISE_ADDENDUM

    user_message = f"{context}\n\n## Question\n\n{query}"

    # Determine thinking mode
    model = get_model()
    use_thinking = think if think is not None else should_think(query)

    # Non-streaming call
    response = ollama.chat(
        model=model,
        messages=[
            {"role": "system", "content": prompt},
            {"role": "user", "content": user_message},
        ],
        think=use_thinking,
    )

    answer = response.message.content or ""
    thinking = getattr(response.message, "thinking", None) or ""

    # Build source list
    sources = []
    for i, c in enumerate(chunks, 1):
        sources.append({
            "num": i,
            "title": c.get("title", ""),
            "path": c.get("path", ""),
            "category": c.get("category", ""),
            "score": c.get("score", 0),
        })

    return {
        "answer": answer,
        "model": model,
        "thinking_used": use_thinking,
        "thinking": thinking,
        "sources": sources,
    }


def main():
    parser = argparse.ArgumentParser(description="Ask the framework knowledge base")
    parser.add_argument("query", help="Question to ask")
    parser.add_argument("--json", action="store_true", dest="json_output", help="Output as JSON")
    parser.add_argument("--concise", action="store_true", help="Request brief answers")
    parser.add_argument("--think", action="store_true", default=None, help="Force thinking mode")
    parser.add_argument("--no-think", action="store_true", help="Disable thinking mode")
    parser.add_argument("--limit", type=int, default=10, help="Max chunks to retrieve")
    args = parser.parse_args()

    think = None
    if args.think:
        think = True
    elif args.no_think:
        think = False

    result = ask(args.query, limit=args.limit, concise=args.concise, think=think)

    if args.json_output:
        print(json.dumps(result, indent=2))
    else:
        print(result["answer"])
        if result["sources"]:
            print(f"\n--- Sources ({len(result['sources'])} chunks) ---")
            for s in result["sources"][:5]:
                print(f"  [{s['num']}] {s['title']} ({s['path']})")


if __name__ == "__main__":
    main()
