import '../../data/models/announcement.dart';
import '../../data/models/stock_quote.dart';
import '../../core/constants/announcement_types.dart';


/// 集合竞价监控器：检测 9:15-9:25 竞价异动
class AuctionMonitor {
  final void Function(Announcement) _onAlert;
  final Map<String, double> _auctionPrices = {};

  AuctionMonitor(this._onAlert);

  /// 检查是否在集合竞价时间（9:15-9:25）
  bool isAuctionTime() {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return timeStr.compareTo('09:15') >= 0 && timeStr.compareTo('09:25') < 0;
  }

  /// 处理竞价阶段行情
  void processAuctionQuote(StockQuote quote) {
    if (!isAuctionTime()) return;

    final prevAuctionPrice = _auctionPrices[quote.code];
    _auctionPrices[quote.code] = quote.price;

    // 竞价高开/低开检测：开盘价与昨收价的偏离
    if (prevAuctionPrice == null && quote.open != quote.lastClose) {
      final openChangePercent = (quote.open - quote.lastClose) / quote.lastClose * 100;
      if (openChangePercent.abs() >= 3.0) {
        _emit(Announcement(
          type: AnnouncementType.auctionAlert,
          stock: quote,
          value: openChangePercent,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      }
    }

    // 竞价价格大幅变动
    if (prevAuctionPrice != null && prevAuctionPrice != 0) {
      final changePercent = (quote.price - prevAuctionPrice) / prevAuctionPrice * 100;
      if (changePercent.abs() >= 5.0) {
        _emit(Announcement(
          type: AnnouncementType.auctionAlert,
          stock: quote,
          value: (quote.price - quote.lastClose) / quote.lastClose * 100,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      }
    }
  }

  /// 竞价结束后清空（9:25 后）
  void clearAuctionCache() {
    final now = DateTime.now();
    if (now.hour > 9 || (now.hour == 9 && now.minute >= 25)) {
      _auctionPrices.clear();
    }
  }

  void _emit(Announcement alert) => _onAlert(alert);

  void clear() => _auctionPrices.clear();
}
