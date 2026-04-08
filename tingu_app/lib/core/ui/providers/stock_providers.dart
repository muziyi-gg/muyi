import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/stock_quote.dart';
import '../../data/models/user_stock_config.dart';
import '../../../main.dart';
import '../../core/constants/announcement_types.dart';

/// 自选股列表 Provider
final watchlistProvider = StateNotifierProvider<WatchlistNotifier, List<UserStockConfig>>((ref) {
  final services = ref.watch(appServicesProvider);
  return WatchlistNotifier(services);
});

class WatchlistNotifier extends StateNotifier<List<UserStockConfig>> {
  final dynamic _services;

  WatchlistNotifier(this._services) : super([]) {
    _load();
  }

  void _load() {
    final stocks = _services.hiveStorage.getUserStocks();
    state = stocks.map((s) => UserStockConfig.fromJson(s)).toList();
  }

  Future<void> add(UserStockConfig config) async {
    await _services.marketMonitor.addUserStock(config);
    _load();
  }

  Future<void> remove(String code) async {
    await _services.marketMonitor.removeUserStock(code);
    _load();
  }
}

/// 当前行情 Provider
final quotesProvider = StateNotifierProvider<QuotesNotifier, Map<String, StockQuote>>((ref) {
  final services = ref.watch(appServicesProvider);
  return QuotesNotifier(services);
});

class QuotesNotifier extends StateNotifier<Map<String, StockQuote>> {
  final dynamic _services;

  QuotesNotifier(this._services) : super({}) {
    _listen();
  }

  void _listen() {
    _services.scheduler.announcementStream.listen((announcement) {
      if (announcement.stock != null) {
        state = {...state, announcement.stock!.code: announcement.stock!};
      }
    });
  }
}
