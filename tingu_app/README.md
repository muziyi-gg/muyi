# 听股通 🎧

> 盲人炒股神器 — 让你用耳朵听行情

---

## 🚀 快速开始

### 第一步：克隆项目到本地

```bash
git clone <你的仓库地址>
cd tingu_app
```

### 第二步：安装依赖

```bash
flutter pub get
```

### 第三步：打出 APK

```bash
# Debug 版本（开发测试用）
flutter build apk --debug

# Release 版本（发布用，需要签名）
flutter build apk --release
```

APK 输出路径：
```
build/app/outputs/flutter-apk/app-debug.apk
```

---

## 📱 手机安装 APK

1. 把 APK 文件传到手机（微信/QQ/网盘均可）
2. 手机设置 → 安全 → 允许「安装未知来源应用」
3. 找到 APK，点击安装

---

## 🏗️ 项目结构

```
tingu_app/
├── lib/
│   ├── main.dart                         # App 入口
│   └── core/
│       ├── constants/                    # 常量（市场规则、播报类型）
│       ├── data/models/                  # 数据模型
│       ├── data/datasources/             # 东方财富 WebSocket
│       ├── services/
│       │   ├── scheduler/               # 核心调度器
│       │   ├── monitor/                 # 6个监控器
│       │   ├── storage/                  # Hive 持久化
│       │   └── tts/                     # TTS 语音
│       └── ui/pages/                    # 4个页面
├── pubspec.yaml                         # Flutter 依赖配置
├── .github/workflows/build.yml           # 自动构建 APK
├── CHANGELOG.md                        # 版本变更记录
└── VERSION.md                          # 版本管理规范
```

---

## 🏗️ 技术栈

| 组件 | 方案 |
|------|------|
| 框架 | Flutter 3.x |
| 状态管理 | Riverpod |
| 数据持久化 | Hive CE |
| 实时行情 | 东方财富 WebSocket |
| 语音播报 | flutter_tts（系统TTS）|
| 后台服务 | flutter_background_service |

---

## 📋 功能清单（Phase 1）

| 功能 | 状态 |
|------|------|
| 自选股行情播报 | ✅ 完成 |
| 快速拉升预警 | ✅ 完成 |
| 快速下跌预警 | ✅ 完成 |
| 涨停预警 | ✅ 完成 |
| 跌停预警 | ✅ 完成 |
| 炸板预警 | ✅ 完成 |
| 板块异动 | ✅ 完成 |
| 大盘异动 | ✅ 完成 |
| 成交量异常 | ✅ 完成 |
| 集合竞价异动 | ✅ 完成 |
| 止盈止损提醒 | ✅ 完成 |
| 播报优先级调度器 | ✅ 完成 |
| 独立开关控制 | ✅ 完成 |
| 后台运行 | 🔧 待集成 |
| 东方财富真实数据 | 🔧 待接入 |

---

## ⚙️ 播报优先级体系

```
P0（最高）：涨停 / 跌停 / 炸板 / 止盈止损
    ↓ 可打断一切
P1（紧急）：快速拉升 / 快速下跌 / 大盘异动
    ↓ 可打断 P2/P3
P2（中等）：板块异动 / 集合竞价异动
P3（例行）：自选股行情 / 成交量异常
```

---

## 📌 常见问题

**Q: 编译时报错 `pub get` 失败？**
```bash
flutter pub cache repair
flutter pub get
```

**Q: 真机调试看不到日志？**
```bash
flutter run -v
```

**Q: 如何清理构建缓存？**
```bash
flutter clean
flutter pub get
```
