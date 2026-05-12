"""Build a combined 10000 common words dictionary from ECDICT."""
import csv
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from add_examples import extract_examples_enhanced, match_pos

CACHE_PATH = Path("tool/cache/ecdict.csv")
OUTPUT_PATH = Path("assets/data/word_books/common_10000.json")
TARGET = 10000

def frequency_value(value: str) -> int:
    try:
        parsed = int(value)
        return parsed if parsed > 0 else 999999
    except:
        return 999999

def clean_translation(text: str) -> str:
    if not text: return ""
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
        if len(glosses) >= 3: break
    return "\uff1b".join(glosses[:3])

def main():
    print("Loading ECDICT...")
    with open(CACHE_PATH, "r", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    print(f"Loaded {len(rows)} entries, filtering...")

    candidates = []
    banned = {"etc", "mr", "mrs", "ms", "dr", "tv", "ok", "cd", "id", "am", "pm"}
    
    for row in rows:
        word = row.get("word", "").strip().lower()
        translation = row.get("translation", "").strip()
        if not re.fullmatch(r"[a-z]{2,15}", word): continue
        if not translation: continue
        if word in banned: continue
        
        candidates.append({
            "word": word,
            "phonetic": row.get("phonetic", "").strip(),
            "meaning": clean_translation(translation),
            "definition": row.get("definition", "").strip(),
            "note": "",
            "tags": [],
            "frq": frequency_value(row.get("frq", "")),
        })
    
    candidates.sort(key=lambda x: x["frq"])
    
    seen = set()
    words = []
    for c in candidates:
        if c["word"] not in seen:
            seen.add(c["word"])
            words.append(c)
            if len(words) >= TARGET: break
    
    print(f"Selected {len(words)} words, adding examples...")
    
    formatted = []
    for w in words:
        examples = extract_examples_enhanced(w["word"], w["definition"], w["tags"])
        formatted.append({
            "id": w["word"],
            "word": w["word"],
            "phonetic": w["phonetic"],
            "meaning": w["meaning"],
            "definition": w["definition"],
            "note": w["note"],
            "level": "\u5e38\u89c110000\u8bcd",
            "tags": ["\u5e38\u89c1\u8bcd"],
            "examples": examples,
        })
        if len(formatted) % 1000 == 0:
            print(f"  {len(formatted)}...")
    
    book = {
        "bookId": "common_10000",
        "bookName": "\u5e38\u89c110000\u8bcd",
        "wordCount": len(formatted),
        "words": formatted,
    }
    
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(book, f, ensure_ascii=False, indent=2)
    print(f"Done! {len(formatted)} words written to {OUTPUT_PATH}")

if __name__ == "__main__":
    main()
