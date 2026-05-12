"""Generate example sentences for word books using various strategies."""
import re
import json
from pathlib import Path
from collections import defaultdict

# Common sentence templates grouped by topic/type
SENTENCE_TEMPLATES = {
    "people": [
        ("He is a very {} person.", "他是一个非常{}的人。"),
        ("I met a {} man yesterday.", "我昨天遇到一个{}的男人。"),
        ("She was {} about the news.", "她对这条消息感到{}。"),
        ("The {} crowd cheered loudly.", "{}的人群大声欢呼。"),
        ("Many people find it {}.", "很多人觉得这很{}。"),
        ("He looked at me with {} eyes.", "他用{}的眼神看着我。"),
        ("She has a {} personality.", "她有一个{}的个性。"),
    ],
    "action": [
        ("They need to {} this problem.", "他们需要{}这个问题。"),
        ("Can you {} me with this?", "你能帮我{}这个吗？"),
        ("We should {} our plan.", "我们应该{}我们的计划。"),
        ("He decided to {} the offer.", "他决定{}这个提议。"),
        ("Please {} the instructions carefully.", "请仔细{}说明。"),
        ("She tried to {} the situation.", "她试图{}这个情况。"),
    ],
    "description": [
        ("This is a very {} place.", "这是一个非常{}的地方。"),
        ("The room was {} and comfortable.", "房间很{}且舒适。"),
        ("We had a {} time at the party.", "我们在聚会上度过了{}的时光。"),
        ("It was a {} experience for everyone.", "对每个人来说都是一次{}的经历。"),
        ("The results were quite {}.", "结果相当{}。"),
    ],
    "study": [
        ("Learning new words is {} for students.", "学习新单词对学生来说很{}。"),
        ("The teacher explained the {} concept clearly.", "老师清楚地解释了{}的概念。"),
        ("This {} requires a lot of practice.", "这个{}需要大量练习。"),
        ("Many students find this subject {}.", "很多学生觉得这门学科很{}。"),
        ("The {} of English is becoming more popular.", "英语的{}变得越来越流行。"),
    ],
    "work": [
        ("He got a {} in a big company.", "他在一家大公司得到了一份{}。"),
        ("The company needs to {} its strategy.", "公司需要{}其策略。"),
        ("She has been working as a {} for years.", "她做{}已经很多年了。"),
        ("The project was a {} success.", "这个项目取得了{}的成功。"),
        ("They want to {} the business to a new level.", "他们想把业务{}到一个新水平。"),
    ],
    "life": [
        ("Good health is {} for a happy life.", "健康对幸福生活很{}。"),
        ("We should {} our time wisely.", "我们应该明智地{}我们的时间。"),
        ("The city has a {} history.", "这座城市有着{}的历史。"),
        ("Technology has made life more {}.", "科技让生活变得更加{}。"),
        ("It is important to {} a balanced lifestyle.", "{}平衡的生活方式很重要。"),
    ],
}

# Part of speech to template mapping
POS_TEMPLATES = {
    "\u5f62\u5bb9\u8bcd": ["people", "description", "life"],  # adjective
    "\u52a8\u8bcd": ["action", "work", "study"],  # verb
    "\u540d\u8bcd": ["study", "work", "life"],  # noun
    "\u526f\u8bcd": ["people", "description", "action"],  # adverb
}

def match_pos(word_tags: list[str]) -> str:
    """Determine word type from tags."""
    for tag in word_tags:
        if "\u52a8\u8bcd" in tag:
            return "\u52a8\u8bcd"
        if "\u540d\u8bcd" in tag:
            return "\u540d\u8bcd"
        if "\u5f62\u5bb9\u8bcd" in tag:
            return "\u5f62\u5bb9\u8bcd"
        if "\u526f\u8bcd" in tag:
            return "\u526f\u8bcd"
    return "\u540d\u8bcd"

def extract_examples_enhanced(word: str, definition: str, tags: list[str]) -> list[dict]:
    """Extract example sentences using multiple strategies."""
    examples = []
    
    # Strategy 1: Extract from definition
    if definition:
        lines = definition.replace("\\n", "\n").split("\n")
        pattern = re.compile(rf"\b{re.escape(word)}\b", re.IGNORECASE)
        
        for line in lines:
            line = line.strip()
            # Clean ECDICT format markers
            line = re.sub(r"^[a-z.]+\s*", "", line, flags=re.IGNORECASE)
            if pattern.search(line) and 15 < len(line) < 150:
                examples.append({
                    "en": line,
                    "zh": "",
                    "source": "ECDICT",
                })
                if len(examples) >= 2:
                    break
    
    # Strategy 2: Generate from templates
    if len(examples) < 2:
        pos = match_pos(tags)
        template_pools = POS_TEMPLATES.get(pos, ["people", "action"])
        
        for pool_name in template_pools:
            if len(examples) >= 2:
                break
            for en_tmpl, zh_tmpl in SENTENCE_TEMPLATES[pool_name]:
                en_sentence = en_tmpl.format(word)
                zh_sentence = zh_tmpl.format(word)
                # Skip if sentence doesn't make sense (word too long/short)
                if len(en_sentence) > 10 and len(en_sentence) < 120:
                    examples.append({
                        "en": en_sentence,
                        "zh": zh_sentence,
                        "source": "Generated",
                    })
                    break
    
    return examples


def generate_for_book(book_path: str) -> None:
    """Add examples to all words in a book."""
    with open(book_path, "r", encoding="utf-8") as f:
        book = json.load(f)
    
    words = book["words"]
    added_count = 0
    
    for word in words:
        if not word["examples"] or len(word["examples"]) == 0:
            examples = extract_examples_enhanced(
                word["word"],
                word.get("definition", ""),
                word.get("tags", [])
            )
            if examples:
                word["examples"] = examples
                added_count += 1
    
    with open(book_path, "w", encoding="utf-8") as f:
        json.dump(book, f, ensure_ascii=False, indent=2)
    
    print(f"{Path(book_path).name}: {added_count} words got examples (total {len(words)} words)")


def main():
    books_dir = Path("assets/data/word_books")
    for book_file in sorted(books_dir.glob("*.json")):
        generate_for_book(str(book_file))


if __name__ == "__main__":
    main()
