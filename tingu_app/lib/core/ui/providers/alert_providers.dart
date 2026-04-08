import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/announcement.dart';
import '../../../main.dart';
import '../../constants/announcement_types.dart';



/// 今日播报记录 Provider
final todayAlertsProvider = StateNotifierProvider<TodayAlertsNotifier, List<Announcement>>((ref) {
  final services = ref.watch(appServicesProvider);
  return TodayAlertsNotifier(services);
});

class TodayAlertsNotifier extends StateNotifier<List<Announcement>> {
  final dynamic _services;

  TodayAlertsNotifier(this._services) : super([]) {
    _listen();
  }

  void _listen() {
    _services.scheduler.announcementStream.listen((announcement) {
      state = [announcement, ...state].take(100).toList();
    });
  }
}

/// 播报开关配置 Provider
final alertConfigProvider = StateNotifierProvider<AlertConfigNotifier, Map<String, bool>>((ref) {
  final services = ref.watch(appServicesProvider);
  return AlertConfigNotifier(services);
});

class AlertConfigNotifier extends StateNotifier<Map<String, bool>> {
  final dynamic _services;

  AlertConfigNotifier(this._services) : super({}) {
    _load();
  }

  void _load() {
    state = _services.hiveStorage.getAlertConfig();
  }

  Future<void> setEnabled(AnnouncementType type, bool enabled) async {
    await _services.hiveStorage.setAlertEnabled(type, enabled);
    state = {...state, type.name: enabled};
  }
}
