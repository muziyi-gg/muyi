import 'dart:async';
import '../../data/models/announcement.dart';
import '../../data/models/stock_quote.dart';
import '../../data/models/user_stock_config.dart';
import '../../../constants/announcement_types.dart';
import '../../../constants/market_constants.dart';

/// 价格监控器：检测涨停、跌停、炸板、拉升、下跌
class PriceMonitor {
  final void Function(Announcement) _onAlert;
  final Map<String, StockQuote> _prevQuotes = {};
  final Map<String, StockQuote> _quotes = {};

  PriceMonitor(this._onAlert);

  /// 更新行情数据
  void updateQuotes(List<StockQuote> quotes) {
    for (final quote in quotes) {
      final prev = _prevQuotes[quote.code];
      if (prev != null) {
        _checkAlerts(prev, quote);
      }
      _prevQuotes[quote.code] = _quotes[quote.code];
      _quotes[quote.code] = quote;
    }
  }

  /// 检查单只股票的价格异动
  void _checkAlerts(StockQuote prev, StockQuote current) {
    // 涨停检测
    if (current.isLimitUp && !prev.isLimitUp) {
      _emit(Announcement(
        type: AnnouncementType.limitUp,
        stock: current,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    // 跌停检测
    if (current.isLimitDown && !prev.isLimitDown) {
      _emit(Announcement(
        type: AnnouncementType.limitDown,
        stock: current,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    // 炸板检测：曾涨停但现在打开了
    // 判断条件：上一时刻触及涨停 且 当前价格 < 涨停价 × 0.998
    if (prev.isLimitUp && !current.isLimitUp && current.price < prev.limitUpPrice * 0.998) {
      _emit(Announcement(
        type: AnnouncementType.burstBoard,
        stock: current,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    // 快速拉升/下跌检测（基于当日高低点变化）
    final changeFromHigh = (current.price - prev.high) / prev.high * 100;
    if (changeFromHigh >= MarketConstants.quickRiseThreshold) {
      _emit(Announcement(
        type: AnnouncementType.quickRise,
        stock: current,
        value: changeFromHigh,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    } else if (changeFromHigh <= -MarketConstants.quickRiseThreshold.abs()) {
      _emit(Announcement(
        type: AnnouncementType.quickFall,
        stock: current,
        value: changeFromHigh,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  /// 检查止盈止损（用户自选股）
  void checkProfitLoss(StockQuote quote, UserStockConfig config) {
    // 止盈止损基于成本价和配置百分比计算
    // 暂时跳过，profitTarget/lossStop 是百分比而非价格
    // 如需实现需结合 UserStockConfig 中的 costPrice 字段
  }

  void _emit(Announcement alert) => _onAlert(alert);

  void clear() {
    _prevQuotes.clear();
    _quotes.clear();
  }
}
