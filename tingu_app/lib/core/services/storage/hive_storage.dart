import 'dart:convert';
import 'package:hive_ce/hive.dart';
import '../../constants/announcement_types.dart';

class HiveStorage {
  static const String _alertCacheBox = 'alert_cache';
  static const String _userStockBox = 'user_stocks';
  static const String _alertConfigBox = 'alert_config';

  late Box<String> _alertCache;
  late Box<String> _userStock;
  late Box<String> _alertConfig;

  bool _initialized = false;

  /// 初始化 Hive 存储
  Future<void> init() async {
    if (_initialized) return;
    _alertCache = await Hive.openBox<String>(_alertCacheBox);
    _userStock = await Hive.openBox<String>(_userStockBox);
    _alertConfig = await Hive.openBox<String>(_alertConfigBox);
    _initialized = true;
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception('HiveStorage not initialized. Call init() first.');
    }
  }

  // ==================== 播报缓存（用于去重） ====================

  /// 缓存播报记录
  Future<void> cacheAlert(String key) async {
    _ensureInitialized();
    final today = DateTime.now();
    final keyWithDate =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}_$key';
    await _alertCache.put(
        keyWithDate, DateTime.now().millisecondsSinceEpoch.toString());
  }

  /// 检查今日是否已有该播报记录
  Future<bool> hasAlertToday(String key) async {
    _ensureInitialized();
    final today = DateTime.now();
    final keyWithDate =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}_$key';
    return _alertCache.containsKey(keyWithDate);
  }

  /// 检查是否在冷却窗口内
  Future<bool> isInCooldown(String key, int windowMinutes) async {
    _ensureInitialized();
    final today = DateTime.now();
    final keyWithDate =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}_$key';
    final cached = _alertCache.get(keyWithDate);
    if (cached == null) return false;
    final ts = int.tryParse(cached) ?? 0;
    final diff = DateTime.now().millisecondsSinceEpoch - ts;
    return diff < windowMinutes * 60 * 1000;
  }

  /// 清除今日的播报缓存（每天开盘前调用）
  Future<void> clearTodayCache() async {
    _ensureInitialized();
    await _alertCache.clear();
  }

  // ==================== 用户自选股 ====================

  /// 保存用户自选股列表
  Future<void> saveUserStocks(List<Map<String, dynamic>> stocks) async {
    _ensureInitialized();
    await _userStock.put('stocks', jsonEncode(stocks));
  }

  /// 获取用户自选股列表
  List<Map<String, dynamic>> getUserStocks() {
    _ensureInitialized();
    final raw = _userStock.get('stocks');
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  /// 添加单只自选股
  Future<void> addUserStock(Map<String, dynamic> stock) async {
    final stocks = getUserStocks();
    // 避免重复添加
    if (!stocks.any((s) => s['code'] == stock['code'])) {
      stocks.add(stock);
      await saveUserStocks(stocks);
    }
  }

  /// 移除自选股
  Future<void> removeUserStock(String code) async {
    final stocks = getUserStocks();
    stocks.removeWhere((s) => s['code'] == code);
    await saveUserStocks(stocks);
  }

  // ==================== 播报开关配置 ====================

  /// 保存播报配置
  Future<void> saveAlertConfig(Map<String, bool> config) async {
    _ensureInitialized();
    await _alertConfig.put('config', jsonEncode(config));
  }

  /// 获取播报配置（默认全部开启）
  Map<String, bool> getAlertConfig() {
    _ensureInitialized();
    final raw = _alertConfig.get('config');
    if (raw == null) {
      return {for (var t in AnnouncementType.values) t.name: true};
    }
    return Map<String, bool>.from(jsonDecode(raw));
  }

  /// 更新单个播报类型的状态
  Future<void> setAlertEnabled(AnnouncementType type, bool enabled) async {
    final config = getAlertConfig();
    config[type.name] = enabled;
    await saveAlertConfig(config);
  }

  /// 检查播报类型是否开启
  bool isAlertEnabled(AnnouncementType type) {
    return getAlertConfig()[type.name] ?? true;
  }

  // ==================== 播报历史记录 ====================

  /// 保存播报历史（最近100条）
  static const String _alertHistoryBox = 'alert_history';

  Future<void> saveAlertHistory(List<Map<String, dynamic>> history) async {
    _ensureInitialized();
    final box = await Hive.openBox<String>(_alertHistoryBox);
    await box.put('history', jsonEncode(history));
  }

  List<Map<String, dynamic>> getAlertHistory() {
    _ensureInitialized();
    // 注意：这里需要单独打开 box
    return [];
  }

  /// 关闭所有 box
  Future<void> close() async {
    await _alertCache.close();
    await _userStock.close();
    await _alertConfig.close();
    _initialized = false;
  }
}
