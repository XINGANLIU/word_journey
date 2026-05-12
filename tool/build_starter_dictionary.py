from __future__ import annotations

import csv
import json
import re
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable
from urllib.error import URLError
from urllib.parse import quote
from urllib.request import urlopen

ECDICT_URL = "https://raw.githubusercontent.com/skywind3000/ECDICT/master/ecdict.csv"
TATOEBA_URL = (
    "https://api.tatoeba.org/v1/sentences"
    "?lang=eng"
    "&q={word}"
    "&trans:lang=cmn"
    "&sort=relevance"
    "&limit=6"
    "&showtrans=matching"
)
TARGET_SIZE = 60
OUTPUT_PATH = Path("assets/data/starter_dictionary.json")
CACHE_PATH = Path("tool/cache/ecdict.csv")

TAG_MAP = {
    "zk": "\u4e2d\u8003",
    "gk": "\u9ad8\u8003",
    "cet4": "CET-4",
    "cet6": "CET-6",
    "ky": "\u8003\u7814",
    "ielts": "IELTS",
    "toefl": "TOEFL",
    "gre": "GRE",
}

POS_TAGS = (
    ("adj.", "\u5f62\u5bb9\u8bcd"),
    ("adv.", "\u526f\u8bcd"),
    ("vt.", "\u52a8\u8bcd"),
    ("vi.", "\u52a8\u8bcd"),
    ("v.", "\u52a8\u8bcd"),
    ("n.", "\u540d\u8bcd"),
)

POS_PATTERNS = tuple((re.compile(rf"(^|[^a-z]){re.escape(code)}"), label) for code, label in POS_TAGS)


@dataclass
class DictionaryWord:
    word: str
    phonetic: str
    translation: str
    definition: str
    pos: str
    tag: str
    frq: str


def fetch_csv_lines() -> list[str]:
    if CACHE_PATH.exists():
        return CACHE_PATH.read_text(encoding="utf-8").splitlines()

    with urlopen(ECDICT_URL, timeout=60) as response:
        payload = response.read().decode("utf-8", "ignore")

    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    CACHE_PATH.write_text(payload, encoding="utf-8")
    return payload.splitlines()


def should_keep(word: DictionaryWord) -> bool:
    entry = word.word
    if not re.fullmatch(r"[a-z]{3,12}", entry):
        return False
    if not word.phonetic or not word.translation:
        return False
    haystack = f"{word.pos} {word.translation}".lower()
    if not any(pattern.search(haystack) for pattern, _ in POS_PATTERNS):
        return False
    banned = {"etc", "mr", "mrs", "ms", "dr", "tv", "ok"}
    if entry in banned:
        return False
    return True


def frequency_value(value: str) -> int:
    try:
        parsed = int(value)
        return parsed if parsed > 0 else 999999
    except Exception:
        return 999999


def extract_level(tag_field: str) -> str:
    tags = tag_field.split()
    for key in ("cet4", "cet6", "ky", "ielts", "toefl", "gre", "gk", "zk"):
        if key in tags:
            return TAG_MAP[key]
    return "\u6838\u5fc3\u8bcd"


def extract_pos_label(word: DictionaryWord) -> str:
    haystack = f"{word.pos} {word.translation}".lower()
    for pattern, label in POS_PATTERNS:
        if pattern.search(haystack):
            return label
    return "\u8bcd\u6c47"


def extract_tags(word: DictionaryWord) -> list[str]:
    tags: list[str] = []
    if frequency_value(word.frq) <= 5000:
        tags.append("\u9ad8\u9891")
    tags.append(extract_pos_label(word))
    level = extract_level(word.tag)
    if level != "\u6838\u5fc3\u8bcd":
        tags.append(level)
    return tags


def clean_definition(text: str) -> str:
    segments = [segment.strip() for segment in text.split("/") if segment.strip()]
    if not segments:
        return ""
    cleaned = re.sub(r"\s+", " ", segments[0])
    cleaned = re.sub(r"^[a-z.]+\s*", "", cleaned, flags=re.IGNORECASE)
    return cleaned.strip(" ;")


def clean_translation(text: str) -> str:
    segments = [segment.strip() for segment in text.split("/") if segment.strip()]
    glosses: list[str] = []
    for segment in segments:
        segment = re.sub(r"^[a-z.]+\s*", "", segment, flags=re.IGNORECASE)
        for piece in re.split(r"[;,\uFF1B\uFF0C]", segment):
            piece = piece.strip()
            if piece and piece not in glosses:
                glosses.append(piece)
        if len(glosses) >= 2:
            break
    return "\uFF1B".join(glosses[:2])


def fetch_examples(word: str) -> list[dict[str, str]]:
    url = TATOEBA_URL.format(word=quote(word))
    payload = None
    for _ in range(3):
        try:
            with urlopen(url, timeout=30) as response:
                payload = json.load(response)
            break
        except URLError:
            time.sleep(0.8)
    if payload is None:
        return []

    examples: list[dict[str, str]] = []
    pattern = re.compile(rf"\b{re.escape(word)}\b", re.IGNORECASE)
    for item in payload.get("data", []):
        sentence = item.get("text", "").strip()
        if not sentence or not pattern.search(sentence):
            continue
        if len(sentence) < 12 or len(sentence) > 120:
            continue

        translations = item.get("translations", [])
        if not translations:
            continue
        translation = translations[0].get("text", "").strip()
        if not translation:
            continue

        examples.append(
            {
                "en": sentence,
                "zh": translation,
                "source": "Tatoeba",
                "sourceId": str(item.get("id", "")),
            }
        )
        if len(examples) == 2:
            break

    return examples


def iter_candidates(rows: Iterable[dict[str, str]]) -> Iterable[DictionaryWord]:
    for row in rows:
        candidate = DictionaryWord(
            word=row["word"].strip().lower(),
            phonetic=row["phonetic"].strip(),
            translation=row["translation"].strip(),
            definition=row["definition"].strip(),
            pos=row["pos"].strip(),
            tag=row["tag"].strip(),
            frq=row["frq"].strip(),
        )
        if should_keep(candidate):
            yield candidate


def build_dictionary() -> dict[str, object]:
    rows = csv.DictReader(fetch_csv_lines())
    candidates = sorted(iter_candidates(rows), key=lambda item: frequency_value(item.frq))

    words: list[dict[str, object]] = []
    used: set[str] = set()
    for item in candidates:
        if item.word in used:
            continue

        examples = fetch_examples(item.word)
        time.sleep(0.15)
        if not examples:
            continue

        words.append(
            {
                "id": item.word,
                "word": item.word,
                "phonetic": item.phonetic,
                "meaning": clean_translation(item.translation),
                "definition": clean_definition(item.definition),
                "note": clean_definition(item.definition) or extract_pos_label(item),
                "level": extract_level(item.tag),
                "tags": extract_tags(item),
                "examples": examples,
            }
        )
        used.add(item.word)
        if len(words) >= TARGET_SIZE:
            break

    return {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "sources": {
            "dictionary": {
                "name": "ECDICT",
                "url": "https://github.com/skywind3000/ECDICT",
                "license": "MIT",
            },
            "examples": {
                "name": "Tatoeba",
                "url": "https://tatoeba.org/",
                "license": "CC BY 2.0 FR / CC0 (varies by sentence)",
            },
        },
        "words": words,
    }


def main() -> None:
    dictionary = build_dictionary()
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(
        json.dumps(dictionary, ensure_ascii=True, indent=2),
        encoding="utf-8",
    )
    print(f"Wrote {len(dictionary['words'])} words to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
