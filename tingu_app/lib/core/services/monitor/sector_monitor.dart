import '../../data/models/announcement.dart';

import '../../constants/market_constants.dart';
import '../../core/constants/announcement_types.dart';

/// 板块监控器：检测板块异动
class SectorMonitor {
  final void Function(Announcement) _onAlert;
  final Map<String, double> _prevSectorChange = {};

  SectorMonitor(this._onAlert);

  /// 更新板块行情
  void updateSectorQuotes(Map<String, dynamic> sectorData) {
    final code = sectorData['code'] as String?;
    final name = sectorData['name'] as String?;
    final changePercent = (sectorData['changePercent'] as num?)?.toDouble() ?? 0.0;

    if (code == null || name == null) return;

    final prevChange = _prevSectorChange[code];
    _prevSectorChange[code] = changePercent;

    // 板块异动检测：从正常涨幅变为异常涨幅
    if (prevChange != null) {
      final changeDelta = changePercent - prevChange;
      if (changeDelta.abs() >= MarketConstants.sectorAlertThreshold) {
        _emit(Announcement(
          type: AnnouncementType.sectorAlert,
          sectorName: name,
          value: changePercent,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      }
    }

    // 直接检查板块涨幅是否超过阈值
    if (changePercent.abs() >= MarketConstants.sectorAlertThreshold) {
      _emit(Announcement(
        type: AnnouncementType.sectorAlert,
        sectorName: name,
        value: changePercent,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  void _emit(Announcement alert) => _onAlert(alert);

  void clear() => _prevSectorChange.clear();
}
