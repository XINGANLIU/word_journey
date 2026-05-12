"""
Generate word books for CET-4, CET-6, Kaoyan, Gaokao from ECDICT.
Output: assets/data/word_books/{book_id}.json
"""
from __future__ import annotations

import csv
import json
import re
from pathlib import Path

CACHE_PATH = Path("tool/cache/ecdict.csv")
OUTPUT_DIR = Path("assets/data/word_books")

# Tag definitions in ECDICT
BOOK_CONFIGS = {
    "cet4": {
        "name": "四级核心词",
        "tags": ["cet4"],
        "extra_tags": ["gk", "zk"],  # Also include high school and middle school words
        "max_words": 4500,
    },
    "cet6": {
        "name": "六级核心词",
        "tags": ["cet6"],
        "extra_tags": [],
        "max_words": 6000,
    },
    "kaoyan": {
        "name": "考研词汇",
        "tags": ["ky"],
        "extra_tags": [],
        "max_words": 5500,
    },
    "gaokao": {
        "name": "高考词汇",
        "tags": ["gk"],
        "extra_tags": ["zk"],
        "max_words": 3500,
    },
    "ielts": {
        "name": "雅思词汇",
        "tags": ["ielts"],
        "extra_tags": [],
        "max_words": 8000,
    },
    "toefl": {
        "name": "托福词汇",
        "tags": ["toefl"],
        "extra_tags": [],
        "max_words": 8000,
    },
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


def frequency_value(value: str) -> int:
    try:
        parsed = int(value)
        return parsed if parsed > 0 else 999999
    except Exception:
        return 999999


def clean_definition(text: str) -> str:
    """Clean definition text, limit length."""
    if not text:
        return ""
    # Replace \n with actual newlines, then take first few lines
    text = text.replace("\\n", "\n")
    lines = [l.strip() for l in text.split("\n") if l.strip()]
    if not lines:
        return ""
    # Take first 2 lines, limit total length
    result = " ".join(lines[:2])
    if len(result) > 200:
        result = result[:200] + "..."
    return result


def clean_translation(text: str) -> str:
    if not text:
        return ""
    segments = [s.strip() for s in text.split("\\n") if s.strip()]
    if not segments:
        segments = [s.strip() for s in text.split("/") if s.strip()]
    glosses = []
    for seg in segments:
        seg = re.sub(r"^[a-z.]+\s*", "", seg, flags=re.IGNORECASE)
        for piece in re.split(r"[;,\uFF1B\uFF0C]", seg):
            piece = piece.strip()
            if piece and piece not in glosses:
                glosses.append(piece)
        if len(glosses) >= 3:
            break
    return "；".join(glosses[:3])


def clean_phonetic(text: str) -> str:
    if not text:
        return ""
    # Keep phonetic format like: həˈloʊ
    return text.strip()


def extract_examples(word: str, definition: str) -> list[dict]:
    """Extract example sentences from definition field."""
    examples = []
    if not definition:
        return examples
    
    # Split by newlines and look for sentences containing the word
    lines = definition.replace("\\n", "\n").split("\n")
    pattern = re.compile(rf"\b{re.escape(word)}\b", re.IGNORECASE)
    
    for line in lines:
        line = line.strip()
        # Look for lines that look like sentences (contain the word and are reasonably long)
        if pattern.search(line) and len(line) > 15 and len(line) < 150:
            # Clean up the line
            line = re.sub(r"^[a-z.]+\s*", "", line, flags=re.IGNORECASE)
            if line and len(line) > 10:
                examples.append({
                    "en": line,
                    "zh": "",
                    "source": "ECDICT",
                })
                if len(examples) >= 2:
                    break
    
    return examples


def extract_pos(word: str, pos: str, translation: str) -> str:
    haystack = f"{pos} {translation}".lower()
    for pattern, label in POS_PATTERNS:
        if pattern.search(haystack):
            return label
    return "词汇"


def load_ecdict() -> list[dict]:
    """Load all rows from ECDICT CSV."""
    print(f"Loading ECDICT from {CACHE_PATH}...")
    rows = []
    with open(CACHE_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
    print(f"Loaded {len(rows)} entries")
    return rows


def should_include(row: dict, config: dict) -> bool:
    """Check if a word should be included in this book."""
    word = row.get("word", "").strip().lower()
    if not re.fullmatch(r"[a-z]{2,15}", word):
        return False
    
    translation = row.get("translation", "").strip()
    if not translation:
        return False
    
    tag = row.get("tag", "").strip()
    tags_in_word = set(tag.split())
    
    # Check if word has any of the required tags
    required_tags = set(config["tags"] + config["extra_tags"])
    if not tags_in_word.intersection(required_tags):
        return False
    
    banned = {"etc", "mr", "mrs", "ms", "dr", "tv", "ok", "cd", "id"}
    if word in banned:
        return False
    
    return True


def build_book(book_id: str, config: dict, all_rows: list[dict]) -> dict:
    """Build a word book from ECDICT rows."""
    print(f"\nBuilding {config['name']} ({book_id})...")
    
    candidates = []
    for row in all_rows:
        if should_include(row, config):
            word = row["word"].strip().lower()
            candidates.append({
                "word": word,
                "phonetic": clean_phonetic(row.get("phonetic", "")),
                "meaning": clean_translation(row.get("translation", "")),
                "definition": row.get("definition", "").strip(),
                "pos": extract_pos(word, row.get("pos", ""), row.get("translation", "")),
                "frq": frequency_value(row.get("frq", "")),
            })
    
    # Sort by frequency (lower = more common)
    candidates.sort(key=lambda x: x["frq"])
    
    # Remove duplicates
    seen = set()
    words = []
    for item in candidates:
        if item["word"] not in seen:
            seen.add(item["word"])
            words.append(item)
            if len(words) >= config["max_words"]:
                break
    
    print(f"  Selected {len(words)} words")
    
    # Format output
    formatted_words = []
    for i, w in enumerate(words):
        examples = extract_examples(w["word"], w["definition"])
        formatted_words.append({
            "id": w["word"],
            "word": w["word"],
            "phonetic": w["phonetic"],
            "meaning": w["meaning"],
            "definition": clean_definition(w["definition"]),
            "note": w["pos"],
            "level": config["name"],
            "tags": [config["name"], w["pos"]],
            "examples": examples,
        })
    
    return {
        "bookId": book_id,
        "bookName": config["name"],
        "wordCount": len(formatted_words),
        "words": formatted_words,
    }


def main():
    if not CACHE_PATH.exists():
        print("ERROR: ECDICT cache not found!")
        print(f"Expected at: {CACHE_PATH}")
        print("Please download ECDICT first or run build_full_dictionary.py")
        return
    
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    all_rows = load_ecdict()
    
    for book_id, config in BOOK_CONFIGS.items():
        book = build_book(book_id, config, all_rows)
        
        output_path = OUTPUT_DIR / f"{book_id}.json"
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(book, f, ensure_ascii=False, indent=2)
        
        print(f"  Saved to {output_path}")
    
    print("\nDone! Generated all word books.")
    print(f"Output directory: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
