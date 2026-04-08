import 'dart:async';
import '../../data/models/announcement.dart';
import '../../data/models/stock_quote.dart';
import '../../data/models/user_stock_config.dart';
import '../../data/datasources/stock_datasource.dart';
import '../scheduler/announcement_scheduler.dart';
import '../storage/hive_storage.dart';
import 'price_monitor.dart';
import 'sector_monitor.dart';
import 'index_monitor.dart';
import 'auction_monitor.dart';
import 'volume_monitor.dart';
import '../../constants/announcement_types.dart';


/// 市场监控总入口
/// 协调各子监控器，统一向调度器发送播报事件
class MarketMonitor {
  final StockDataSource _dataSource;
  final AnnouncementScheduler _scheduler;
  final HiveStorage _storage;

  late final PriceMonitor _priceMonitor;
  late final SectorMonitor _sectorMonitor;
  late final IndexMonitor _indexMonitor;
  late final AuctionMonitor _auctionMonitor;
  late final VolumeMonitor _volumeMonitor;

  StreamSubscription? _quoteSubscription;
  StreamSubscription? _sectorSubscription;
  StreamSubscription? _indexSubscription;

  // 用户自选股配置
  final Map<String, UserStockConfig> _userConfigs = {};

  MarketMonitor(this._dataSource, this._scheduler, this._storage) {
    _priceMonitor = PriceMonitor(_onAlert);
    _sectorMonitor = SectorMonitor(_onAlert);
    _indexMonitor = IndexMonitor(_onAlert);
    _auctionMonitor = AuctionMonitor(_onAlert);
    _volumeMonitor = VolumeMonitor(_onAlert);
  }

  /// 启动监控
  Future<void> start() async {
    // 加载用户自选股配置
    _loadUserConfigs();

    // 订阅全市场行情
    _quoteSubscription = _dataSource.streamAllQuotes().listen(_onQuotes);

    // 订阅板块行情
    _sectorSubscription = _dataSource.streamSectorQuotes().listen(_onSectorQuotes);

    // 订阅指数行情
    _indexSubscription = _dataSource.streamIndexQuotes().listen(_onIndexQuotes);

    // 启动数据源连接
    if (_dataSource is dynamic) {
      try {
        await (_dataSource as dynamic).connect();
      } catch (_) {}
    }
  }

  void _loadUserConfigs() {
    final stocks = _storage.getUserStocks();
    for (final stock in stocks) {
      _userConfigs[stock['code']] = UserStockConfig.fromJson(stock);
    }
  }

  void _onQuotes(List<StockQuote> quotes) {
    // 更新价格监控
    _priceMonitor.updateQuotes(quotes);

    // 检查止盈止损
    for (final quote in quotes) {
      final config = _userConfigs[quote.code];
      if (config != null) {
        _priceMonitor.checkProfitLoss(quote, config);
      }
    }

    // 更新成交量监控
    for (final quote in quotes) {
      _volumeMonitor.updateVolume(quote);
    }

    // 更新集合竞价监控
    for (final quote in quotes) {
      _auctionMonitor.processAuctionQuote(quote);
    }
  }

  void _onSectorQuotes(Map<String, dynamic> data) {
    _sectorMonitor.updateSectorQuotes(data);
  }

  void _onIndexQuotes(Map<String, dynamic> data) {
    _indexMonitor.updateIndexQuotes(data);
  }

  void _onAlert(Announcement alert) {
    // 检查该播报类型是否开启
    if (!_storage.isAlertEnabled(alert.type)) return;
    // 发送到调度器
    _scheduler.enqueue(alert);
  }

  /// 添加用户自选股
  Future<void> addUserStock(UserStockConfig config) async {
    _userConfigs[config.code] = config;
    await _storage.addUserStock(config.toJson());
  }

  /// 移除用户自选股
  Future<void> removeUserStock(String code) async {
    _userConfigs.remove(code);
    await _storage.removeUserStock(code);
  }

  /// 停止监控
  void stop() {
    _quoteSubscription?.cancel();
    _sectorSubscription?.cancel();
    _indexSubscription?.cancel();
    _priceMonitor.clear();
    _sectorMonitor.clear();
    _indexMonitor.clear();
    _auctionMonitor.clear();
    _volumeMonitor.clear();
  }

  /// 释放资源
  void dispose() {
    stop();
    _dataSource.dispose();
  }
}
