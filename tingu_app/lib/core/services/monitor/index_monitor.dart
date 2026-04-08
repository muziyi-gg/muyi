import '../../data/models/announcement.dart';
import '../../../constants/announcement_types.dart';
import '../../../constants/market_constants.dart';

/// 大盘监控器：检测沪深300/上证/深证异动
class IndexMonitor {
  final void Function(Announcement) _onAlert;
  final Map<String, double> _prevIndexChange = {};
  final Set<String> _watchedIndices = {'sh000001', 'sz399001', 'sh000300'};

  IndexMonitor(this._onAlert);

  /// 更新指数行情
  void updateIndexQuotes(Map<String, dynamic> indexData) {
    final code = indexData['code'] as String?;
    final changePercent = (indexData['changePercent'] as num?)?.toDouble() ?? 0.0;

    if (code == null) return;

    // 只监控主要指数
    if (!_watchedIndices.contains(code)) return;

    final prevChange = _prevIndexChange[code];
    _prevIndexChange[code] = changePercent;

    // 大盘异动检测
    if (prevChange != null) {
      if (changePercent.abs() - prevChange.abs() >= MarketConstants.marketAlertThreshold) {
        _emit(Announcement(
          type: AnnouncementType.marketAlert,
          value: changePercent,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      }
    }

    // 直接检查指数涨跌幅是否超过阈值
    if (changePercent.abs() >= MarketConstants.marketAlertThreshold) {
      _emit(Announcement(
        type: AnnouncementType.marketAlert,
        value: changePercent,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  void _emit(Announcement alert) => _onAlert(alert);

  void clear() => _prevIndexChange.clear();
}
