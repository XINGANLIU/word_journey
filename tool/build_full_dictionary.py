from __future__ import annotations

import csv
import json
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

ECDICT_URL = "https://raw.githubusercontent.com/skywind3000/ECDICT/master/ecdict.csv"
TARGET_SIZE = 10000
OUTPUT_PATH = Path("assets/data/full_dictionary.json")
CACHE_PATH = Path("tool/cache/ecdict.csv")

TAG_MAP = {
    "zk": "中考",
    "gk": "高考",
    "cet4": "CET-4",
    "cet6": "CET-6",
    "ky": "考研",
    "ielts": "IELTS",
    "toefl": "TOEFL",
    "gre": "GRE",
}

POS_TAGS = (
    ("adj.", "形容词"),
    ("adv.", "副词"),
    ("vt.", "动词"),
    ("vi.", "动词"),
    ("v.", "动词"),
    ("n.", "名词"),
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
        print(f"Using cached ECDICT from {CACHE_PATH}")
        return CACHE_PATH.read_text(encoding="utf-8").splitlines()

    print("Downloading ECDICT... (this may take a few minutes)")
    from urllib.request import urlopen
    with urlopen(ECDICT_URL, timeout=120) as response:
        payload = response.read().decode("utf-8", "ignore")

    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    CACHE_PATH.write_text(payload, encoding="utf-8")
    print(f"Saved ECDICT cache to {CACHE_PATH}")
    return payload.splitlines()


def should_keep(word: DictionaryWord) -> bool:
    entry = word.word
    if not re.fullmatch(r"[a-z]{2,15}", entry):
        return False
    if not word.translation:
        return False
    banned = {"etc", "mr", "mrs", "ms", "dr", "tv", "ok", "cd", "id", "am", "pm"}
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
    return "核心词"


def extract_pos_label(word: DictionaryWord) -> str:
    haystack = f"{word.pos} {word.translation}".lower()
    for pattern, label in POS_PATTERNS:
        if pattern.search(haystack):
            return label
    return "词汇"


def extract_tags(word: DictionaryWord) -> list[str]:
    tags: list[str] = []
    if frequency_value(word.frq) <= 3000:
        tags.append("高频")
    elif frequency_value(word.frq) <= 6000:
        tags.append("中频")
    tags.append(extract_pos_label(word))
    level = extract_level(word.tag)
    if level != "核心词":
        tags.append(level)
    return tags


def clean_translation(text: str) -> str:
    if not text:
        return ""
    segments = [segment.strip() for segment in text.split("\\n") if segment.strip()]
    if not segments:
        segments = [segment.strip() for segment in text.split("/") if segment.strip()]
    glosses: list[str] = []
    for segment in segments:
        segment = re.sub(r"^[a-z.]+\s*", "", segment, flags=re.IGNORECASE)
        for piece in re.split(r"[;,\uFF1B\uFF0C]", segment):
            piece = piece.strip()
            if piece and piece not in glosses:
                glosses.append(piece)
        if len(glosses) >= 3:
            break
    return "；".join(glosses[:3])


def clean_definition(text: str) -> str:
    if not text:
        return ""
    segments = [segment.strip() for segment in text.split("\\n") if segment.strip()]
    if not segments:
        segments = [segment.strip() for segment in text.split("/") if segment.strip()]
    if not segments:
        return ""
    cleaned = re.sub(r"\s+", " ", segments[0])
    cleaned = re.sub(r"^[a-z.]+\s*", "", cleaned, flags=re.IGNORECASE)
    return cleaned.strip(" ;")[:200]


def iter_candidates(rows: Iterable[dict[str, str]]) -> Iterable[DictionaryWord]:
    for row in rows:
        candidate = DictionaryWord(
            word=row["word"].strip().lower(),
            phonetic=row.get("phonetic", "").strip(),
            translation=row.get("translation", "").strip(),
            definition=row.get("definition", "").strip(),
            pos=row.get("pos", "").strip(),
            tag=row.get("tag", "").strip(),
            frq=row.get("frq", "").strip(),
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

        meaning = clean_translation(item.translation)
        if not meaning:
            continue

        words.append(
            {
                "id": item.word,
                "word": item.word,
                "phonetic": item.phonetic or "",
                "meaning": meaning,
                "definition": clean_definition(item.definition),
                "note": clean_definition(item.definition) or extract_pos_label(item),
                "level": extract_level(item.tag),
                "tags": extract_tags(item),
                "examples": [],
            }
        )
        used.add(item.word)

        if len(words) % 1000 == 0:
            print(f"Progress: {len(words)} words...")

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
        },
        "words": words,
    }


def main() -> None:
    print(f"Building dictionary with {TARGET_SIZE} words...")
    dictionary = build_dictionary()
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(
        json.dumps(dictionary, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"Done! Wrote {len(dictionary['words'])} words to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
