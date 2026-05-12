<!-- omit in toc -->
# 词旅背单词 · Word Journey

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.11-blue?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Android-brightgreen" alt="Platform">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</p>

> **English** | A cross-platform vocabulary trainer built with Flutter. 30,000+ words, SM-2 spaced repetition, dictation mode, word root analysis. Runs on Windows & Android.
>
> **中文** | Flutter 跨平台背单词应用。内置 3 万词汇、间隔重复算法、听写模式、词根词缀分析。

<p align="center">
  <img src="screenshots/review.png" width="24%" alt="复习">
  <img src="screenshots/books.png" width="24%" alt="词书">
  <img src="screenshots/dictation.png" width="24%" alt="听写">
  <img src="screenshots/stats.png" width="24%" alt="统计">
  <br>
  <sup>⬆ 截图占位，运行后替换为实际截图</sup>
</p>

---

<!-- omit in toc -->
## 目录

- [功能概览](#功能概览)
- [快速开始](#快速开始)
- [项目结构](#项目结构)
- [词库说明](#词库说明)
- [打包发布](#打包发布)
- [技术栈](#技术栈)
- [License](#license)

---

## 功能概览

### 📖 学习模式

| 功能 | 说明 |
|------|------|
| 间隔复习 | SM-2 算法，根据记忆反馈自动调整复习间隔 |
| 三档评级 | 不认识 / 有点模糊 / 认识，科学调度 |
| 单词发音 | 点击喇叭或自动播放，支持 TTS |
| 卡片释义 | 点击展开释义、例句、标签 |
| 滑动手势 | 左滑「忘记」、右滑「认识」 |

### 📚 词库管理

| 功能 | 说明 |
|------|------|
| 多词书 | 高考 · 四级 · 六级 · 考研 · 雅思 · 托福 · 10000 常见词 |
| 词书选择 | 首次启动自由勾选，随时可更换 |
| 词典搜索 | 搜索英文、中文、标签，跨全部词书 |
| 单词详情 | 点击单词查看词根词缀、同义词、反义词 |

### 🎧 听写 & 拼写

| 功能 | 说明 |
|------|------|
| 听写模式 | 听发音 → 拼写单词 → 即时反馈 |
| 拼写测试 | 看中文释义 → 输入英文 → 检查 |
| 正确率统计 | 实时显示正确率 |

### 📊 数据 & 设置

| 功能 | 说明 |
|------|------|
| 学习统计 | 复习量、保留率、连击天数、7 天趋势图 |
| 收藏单词 | 收藏夹独立标签页 |
| 每日新词上限 | 5~30 可调 |
| 导出/恢复备份 | JSON 文件，跨设备同步 |

---

## 快速开始

### 环境要求

- **Flutter** ≥ 3.41
- **Windows**：Visual Studio + Developer Mode
- **Android**：Android Studio + SDK 36

### 运行

```bash
git clone https://github.com/XINGANLIU/word_journey.git
cd word_journey
flutter pub get

# Windows
flutter run -d windows

# Android
flutter run -d android
```

---

## 项目结构

```
lib/
├── main.dart                          # 入口，首次引导逻辑
├── app.dart                           # 主界面、复习页、词书页、统计页、设置页
├── controllers/
│   └── study_controller.dart          # 核心控制器：调度、进度、收藏、备份
├── models/
│   └── study_models.dart              # 数据模型：单词、进度、统计
├── data/
│   ├── dictionary_repository.dart     # 词库加载（多词书 + 自定义导入）
│   └── word_analysis.dart             # 词根词缀、同义词、反义词数据库
├── pages/
│   ├── onboarding_page.dart           # 首次启动词书选择页
│   ├── add_words_page.dart            # 词典搜索 / 单词添加页
│   ├── dictation_page.dart            # 听写模式页
│   ├── word_detail_page.dart          # 单词详情页（词根/同反义词）
├── services/
│   ├── pronunciation_service.dart     # TTS 发音服务
│   └── notification_service.dart      # 每日学习提醒
assets/data/word_books/               # 词库 JSON 文件
tool/                                  # Python 词库生成脚本
```

---

## 词库说明

| 词书 | 单词数 | 来源 |
|------|--------|------|
| 高考词汇 | 3,500 | ECDICT |
| 四级核心词 | 4,500 | ECDICT |
| 六级核心词 | 5,394 | ECDICT |
| 考研词汇 | 4,800 | ECDICT |
| 雅思词汇 | 5,010 | ECDICT |
| 托福词汇 | 6,937 | ECDICT |
| 常见 10000 词 | 10,000 | ECDICT |
| **去重总计** | **~30,000** | |

> 词义来自 [ECDICT](https://github.com/skywind3000/ECDICT)，例句由 ECDICT 定义字段提取 + 模板生成。

### 重新生成词库

```bash
# 确保已下载 ECDICT（首次运行自动下载）
python tool/build_word_books.py     # 生成分类词书
python tool/build_common_10000.py   # 生成 10000 常见词
python tool/add_examples.py         # 补充例句
```

---

## 打包发布

```bash
# Windows exe
flutter build windows --release
# 产物: build\windows\x64\runner\Release\

# Android APK
flutter build apk --release
# 产物: build\app\outputs\flutter-apk\app-release.apk
```

---

## 技术栈

| 技术 | 用途 |
|------|------|
| Flutter 3 | 跨平台 UI 框架 |
| shared_preferences | 本地数据持久化 |
| flutter_tts | TTS 语音朗读 |
| flutter_local_notifications | 每日学习提醒 |
| file_picker | 文件导入/导出 |
| ECDICT | 词库数据源 |

---

## License

MIT © [XINGANLIU](https://github.com/XINGANLIU)
