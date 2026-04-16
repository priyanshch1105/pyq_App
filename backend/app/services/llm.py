from __future__ import annotations

from typing import Any

import httpx

from app.core.config import settings


async def generate_tutor_completion(message: str, exam: str | None = None) -> str | None:
    provider = (settings.llm_provider or "stub").lower()
    if provider != "openai":
        return None

    if not settings.openai_api_key:
        return None

    system_prompt = (
        f"You are an expert {exam or 'competitive exam'} tutor. "
        "Solve step-by-step, explain concept, and highlight likely mistakes."
    )

    payload: dict[str, Any] = {
        "model": settings.openai_model,
        "input": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": message},
        ],
        "temperature": 0.2,
    }

    headers = {
        "Authorization": f"Bearer {settings.openai_api_key}",
        "Content-Type": "application/json",
    }

    async with httpx.AsyncClient(timeout=40.0) as client:
        res = await client.post("https://api.openai.com/v1/responses", headers=headers, json=payload)
        if res.status_code >= 400:
            return None
        data = res.json()

    output = data.get("output", [])
    for block in output:
        for item in block.get("content", []):
            text = item.get("text")
            if text:
                return str(text).strip()
    return None
