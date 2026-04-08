import '../../data/models/announcement.dart';
import '../../data/models/stock_quote.dart';
import '../../../constants/announcement_types.dart';
import '../../../constants/market_constants.dart';

/// 成交量异常监控器
class VolumeMonitor {
  final void Function(Announcement) _onAlert;
  final Map<String, int> _lastVolume = {};
  final Map<String, int> _avgVolume = {};

  VolumeMonitor(this._onAlert);

  /// 更新成交量数据
  void updateVolume(StockQuote quote) {
    final last = _lastVolume[quote.code];

    if (last != null && last > 0) {
      // 计算5分钟成交量
      final volumeIn5Min = quote.volume - last;

      // 与昨日均量对比（这里用前一分钟均量估算）
      final avgVol = _avgVolume[quote.code] ?? (quote.volume ~/ 60);
      if (avgVol > 0) {
        final ratio = volumeIn5Min / avgVol;
        if (ratio >= MarketConstants.volumeAlertMultiplier) {
          _emit(Announcement(
            type: AnnouncementType.volumeAlert,
            stock: quote,
            value: ratio,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ));
        }
      }

      // 更新均量估算
      _avgVolume[quote.code] = (_avgVolume[quote.code]! * 59 + volumeIn5Min) ~/ 60;
    }

    _lastVolume[quote.code] = quote.volume;
  }

  void _emit(Announcement alert) => _onAlert(alert);

  void clear() {
    _lastVolume.clear();
    _avgVolume.clear();
  }
}
