# 更新日志

所有重要版本更新都会记录在此。

---

## [v0.1.0] — 2026-04-07

### 首次发布

**Phase 1 MVP Demo 框架**

#### 新增
- `lib/core/constants/announcement_types.dart` — 11种播报类型枚举 + 优先级映射
- `lib/core/constants/market_constants.dart` — 市场常量（涨停比例、东方财富接口地址）
- `lib/core/data/models/stock_quote.dart` — 股票行情模型（已修复科创/创业±20% Bug）
- `lib/core/data/models/announcement.dart` — 播报实体（content 语音文案自动生成）
- `lib/core/data/models/user_stock_config.dart` — 用户自选股配置（止盈止损成本价）
- `lib/core/data/models/sector_quote.dart` — 板块行情模型
- `lib/core/data/models/index_quote.dart` — 指数行情模型
- `lib/core/data/datasources/stock_datasource.dart` — 数据源抽象接口
- `lib/core/data/datasources/eastmoney_datasource.dart` — 东方财富 WebSocket 实现
- `lib/core/data/repositories/stock_repository_impl.dart` — Repository 实现
- `lib/core/services/scheduler/announcement_scheduler.dart` — **核心调度器**（P0/P1打断逻辑）
- `lib/core/services/scheduler/deduplication_service.dart` — 去重服务（11种去重规则）
- `lib/core/services/scheduler/interruption_manager.dart` — 打断管理器（断点续播）
- `lib/core/services/monitor/price_monitor.dart` — 涨停/跌停/炸板/拉升/下跌检测
- `lib/core/services/monitor/sector_monitor.dart` — 板块异动检测
- `lib/core/services/monitor/index_monitor.dart` - 大盘异动检测
- `lib/core/services/monitor/auction_monitor.dart` — 集合竞价监控
- `lib/core/services/monitor/volume_monitor.dart` — 成交量异常检测
- `lib/core/services/monitor/market_monitor.dart` — 监控总入口
- `lib/core/services/storage/hive_storage.dart` — Hive 持久化封装
- `lib/core/services/tts/tts_service.dart` — TTS 语音服务
- `lib/core/services/background/background_service.dart` — 后台保活服务
- `lib/core/ui/pages/home_page.dart` — 首页 Dashboard（涨停预警横幅、行情卡片）
- `lib/core/ui/pages/settings_page.dart` — 监控设置（11种播报开关）
- `lib/core/ui/pages/watchlist_page.dart` — 自选股管理（搜索/添加/删除）
- `lib/core/ui/pages/profile_page.dart` — 个人中心
- `lib/core/ui/widgets/stock_card.dart` — 股票卡片组件
- `lib/core/ui/widgets/alert_badge.dart` — 预警气泡组件
- `lib/core/ui/widgets/toggle_card.dart` — 开关卡片组件
- `lib/core/ui/widgets/slider_setting.dart` — 阈值滑块组件
- `lib/main.dart` — App 入口（Riverpod + Hive 初始化）
- `pubspec.yaml` — Flutter 依赖配置
- `.github/workflows/build.yml` — CI/CD 自动构建 APK

#### Bug 修复
- **涨停价计算 Bug**：`isLimitUp/isLimitDown` 原硬编码 ±10%，现已区分科创/创业板（±20%）和主板（±10%），并增加 ±0.5% 容错防止精度漏报

#### 技术指标
- Dart 文件：34 个
- 代码行数：~3,400 行
- TODO/FIXME：0 个
