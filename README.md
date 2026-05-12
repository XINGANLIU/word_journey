<!-- omit in toc -->
<p align="center">
  <img src="https://img.shields.io/badge/Words-30,000+-success?style=for-the-badge" alt="30000+ Words">
  <img src="https://img.shields.io/badge/Windows-✓-0078D6?style=for-the-badge&logo=windows" alt="Windows">
  <img src="https://img.shields.io/badge/Android-✓-3DDC84?style=for-the-badge&logo=android" alt="Android">
</p>

<h1 align="center">
  词旅背单词<br>
  <sub>Word Journey</sub>
</h1>

<p align="center">
  <b>把 3 万个单词装进脑子。</b><br>
  一个真正能帮你长期坚持背单词的跨平台工具。
</p>

<p align="center">
  <a href="https://github.com/XINGANLIU/word_journey/releases/latest"><img src="https://img.shields.io/badge/⬇ 立即下载-Windows%20|%20Android-blue?style=for-the-badge" alt="下载"></a>
</p>

---

## ✨ 为什么用词旅？

<p align="center">
  <table>
    <tr>
      <td align="center" width="25%"><b>🧠 艾宾浩斯算法</b><br><small>1天→3天→7天→15天→30天<br>科学间隔，记得更牢</small></td>
      <td align="center" width="25%"><b>📚 3万词库</b><br><small>高考/四级/六级/考研<br>雅思/托福/10000常见词</small></td>
      <td align="center" width="25%"><b>🔊 真人发音</b><br><small>点击喇叭自动朗读<br>支持连续播放</small></td>
      <td align="center" width="25%"><b>📱 全平台</b><br><small>一套代码<br>Windows + Android</small></td>
    </tr>
  </table>
</p>

### 🎯 不只是"背"单词

| 功能 | 是什么 | 为什么有用 |
|------|--------|-----------|
| 听写模式 | 听发音拼写单词，错了告诉你正确答案 | 听力+拼写双提升，比单纯眼看记忆深 3 倍 |
| 拼写测试 | 看中文释义输入英文 | 检查是否真的记住了，而不只是"眼熟" |
| 词根词缀 | 自动识别 un-/re-/-tion 等 | 理解构词法，举一反三记一串 |
| 同反义词 | 每个词关联同义词和反义词 | 构建词汇网络，写作时不再词穷 |
| 剑桥词典 | 一键跳转剑桥中英词典 | 专业释义，随时深挖 |

### 📊 数据帮你坚持

| 功能 | 
|------|
| 每日复习量 + 保留率 + 连续学习天数 |
| 7 天学习趋势图 |
| 未来待复习单词数量预览 |
| 导出/恢复备份，换设备不丢数据 |

---

## 🚀 直接下载使用

<p align="center">
  <a href="https://github.com/XINGANLIU/word_journey/releases/latest">
    <img src="https://img.shields.io/badge/📥 Windows 下载-0078D6?style=for-the-badge&logo=windows" alt="Windows">
  </a>
  &nbsp;
  <a href="https://github.com/XINGANLIU/word_journey/releases/latest">
    <img src="https://img.shields.io/badge/📥 Android 下载-3DDC84?style=for-the-badge&logo=android" alt="Android">
  </a>
</p>

> 无需安装 Flutter，解压即用（Windows）/ 直接安装 APK（Android）

---

## 🛠 开发者

### 环境
- Flutter ≥ 3.41 | Windows: Visual Studio | Android: Android Studio

### 运行
```bash
git clone https://github.com/XINGANLIU/word_journey.git
cd word_journey && flutter pub get
flutter run -d windows   # 或 -d android
```

### 打包
```bash
flutter build windows --release   # → build/windows/x64/runner/Release/
flutter build apk --release       # → build/app/outputs/flutter-apk/
```

---

## 📦 项目结构

```
lib/
├── main.dart / app.dart              # 入口 + 4 标签主界面
├── controllers/study_controller.dart # 核心：调度/进度/收藏/备份
├── data/                             # 词库加载 + 词根分析数据
├── pages/                            # 引导/选词/听写/单词详情
├── services/                         # TTS 发音 + 每日提醒
assets/data/word_books/              # 7 本词书 JSON
tool/                                 # Python 词库生成脚本
```

---

## 📋 词库

| 词书 | 词数 | 
|------|------|
| 高考 | 3,500 |
| 四级 | 4,500 |
| 六级 | 5,394 |
| 考研 | 4,800 |
| 雅思 | 5,010 |
| 托福 | 6,937 |
| 10000 常见词 | 10,000 |
| **去重合计** | **~30,000** |

> 数据来源 [ECDICT](https://github.com/skywind3000/ECDICT) MIT 协议

---

<p align="center">
  <sub>MIT © <a href="https://github.com/XINGANLIU">XINGANLIU</a></sub>
</p>
