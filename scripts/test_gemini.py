import argparse
import base64
import json
import mimetypes
import os
import sys
import time
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


DEFAULT_MODEL = "gemini-3.5-flash"
API_URL_TEMPLATE = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"


def main() -> int:
    parser = argparse.ArgumentParser(description="Smoke-test the Gemini API key.")
    parser.add_argument(
        "--model",
        default=os.getenv("GEMINI_MODEL", DEFAULT_MODEL),
        help=f"Gemini model to test. Default: {DEFAULT_MODEL}",
    )
    parser.add_argument(
        "--prompt",
        default="Reply with exactly: GEMINI_OK",
        help="Prompt to send to Gemini.",
    )
    parser.add_argument(
        "--image",
        type=Path,
        help="Optional image path to test image understanding.",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=30,
        help="Request timeout in seconds. Default: 30",
    )
    args = parser.parse_args()

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("GEMINI_API_KEY is not set.", file=sys.stderr)
        print("Example: export GEMINI_API_KEY='your_key_here'", file=sys.stderr)
        return 2

    payload = _build_payload(prompt=args.prompt, image_path=args.image)
    url = API_URL_TEMPLATE.format(model=args.model)
    request = Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "x-goog-api-key": api_key,
        },
        method="POST",
    )

    started_at = time.perf_counter()
    try:
        with urlopen(request, timeout=args.timeout) as response:
            data = json.loads(response.read().decode("utf-8"))
    except HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        print(f"Gemini request failed: HTTP {exc.code}", file=sys.stderr)
        print(body, file=sys.stderr)
        return 1
    except URLError as exc:
        print(f"Gemini request failed: {exc.reason}", file=sys.stderr)
        return 1

    elapsed_ms = int((time.perf_counter() - started_at) * 1000)
    text = _extract_text(data)
    print(f"model={args.model}")
    print(f"elapsed_ms={elapsed_ms}")
    print("response:")
    print(text or json.dumps(data, indent=2))
    return 0 if text else 1


def _build_payload(prompt: str, image_path: Path | None) -> dict:
    parts = [{"text": prompt}]
    if image_path is not None:
        image_bytes = image_path.read_bytes()
        mime_type = mimetypes.guess_type(image_path.name)[0] or "image/jpeg"
        parts.append(
            {
                "inline_data": {
                    "mime_type": mime_type,
                    "data": base64.b64encode(image_bytes).decode("ascii"),
                }
            }
        )

    return {
        "contents": [{"parts": parts}],
        "generationConfig": {
            "temperature": 0,
            "maxOutputTokens": 80,
        },
    }


def _extract_text(data: dict) -> str:
    texts: list[str] = []
    for candidate in data.get("candidates") or []:
        content = candidate.get("content") or {}
        for part in content.get("parts") or []:
            text = part.get("text")
            if isinstance(text, str):
                texts.append(text)
    return "\n".join(texts).strip()


if __name__ == "__main__":
    raise SystemExit(main())
