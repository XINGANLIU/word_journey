# Word Journey | 词旅背单词

一个用 Flutter 实现的跨平台背单词 MVP，目标是用一套代码同时覆盖 Android 和 Windows，并逐步迭代成接近“墨墨背单词”体验的开源项目。

## 当前已经完成

- Android + Windows 跨端工程骨架
- 今日复习页：单词卡片、释义展开、三档记忆反馈
- 英语发音播放：点击单词旁边的喇叭即可朗读
- 自动发音：切到新复习单词时可自动播放读音
- 简化版间隔复习调度：`不认识 / 有点模糊 / 认识`
- 本地学习记录持久化：使用 `shared_preferences`
- 词书总览页：查看新词、复习中、已掌握状态
- 词书搜索与筛选：可按英文、中文释义、标签和学习状态查找
- 统计页：最近 7 天复习量、今日保留率、学习连击
- 设置页：每日新词上限、重置本地数据

## 技术方案

- Flutter 3
- Dart 3
- 本地存储：`shared_preferences`
- 当前数据源：本地 starter 词库资产
- 词义来源：ECDICT
- 例句来源：Tatoeba

这样选型的原因很直接：

- Android 和 Windows 都能共用一套 UI 和业务逻辑
- 后面可以继续扩展 Web、macOS
- 很适合个人项目先做 MVP，再逐步接入云同步和账号系统

## 项目结构

```text
lib/
  app.dart                     # 应用壳、页面与主要 UI
  controllers/study_controller.dart
  data/dictionary_repository.dart
  models/study_models.dart     # 单词、进度、统计模型
assets/data/
  starter_dictionary.json      # ECDICT + Tatoeba 生成的本地词库
tool/
  build_starter_dictionary.py  # 重新生成 starter 词库的脚本
test/
  widget_test.dart
```

## 本地运行

```bash
flutter pub get
flutter run -d android
flutter run -d windows
```

## 你这台机器当前需要补的环境

根据 `flutter doctor -v` 的结果，今天也就是 2026-05-10，这台机器还有两处环境需要补，之后才能顺利打包：

- Windows 桌面端缺少 `Visual Studio` 和 `Desktop development with C++`
- Android 端缺少 `cmdline-tools`，并且还没有接受 Android licenses

另外，`shared_preferences` 这类插件在 Windows 上开发时通常还要求打开系统的 `Developer Mode`，否则 Flutter 生成插件符号链接时会报错。

## 词库说明

- `assets/data/starter_dictionary.json` 当前内置 60 个 starter 词条
- 每个词条包含：英文、中文释义、音标、1 到 2 条英文例句、中文例句
- 词义来自 [ECDICT](https://github.com/skywind3000/ECDICT)
- 例句来自 [Tatoeba](https://tatoeba.org/)

如果你想扩充词量，可以重新运行：

```bash
python tool/build_starter_dictionary.py
```

## 下一步最值得做的功能

如果你想把它继续做成真正能长期使用的软件，我建议按这个顺序往下走：

1. 自定义词库导入
2. 账号登录与云同步
3. 搜索、收藏、生词本
4. 发音播放与拼写测试
5. 学习计划与遗忘曲线可视化
6. GitHub Actions 自动构建 Android APK 和 Windows 安装包

## 发布到 GitHub

在项目目录执行：

```bash
git init
git add .
git commit -m "feat: initialize word journey MVP"
```

然后在 GitHub 创建新仓库，再执行：

```bash
git remote add origin <你的仓库地址>
git branch -M main
git push -u origin main
```

## 适合继续迭代的方向

这个仓库现在更像一个稳固的起点，而不是最终产品。你如果愿意，我下一步可以继续直接帮你做下面任意一项：

- 接入你自己的真实词书
- 做登录和云同步
- 做更像墨墨背单词的 UI 和交互
- 配好 GitHub Actions 自动打包发布
