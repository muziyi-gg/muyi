import 'dart:async';
import 'package:flutter/foundation.dart';

/// 后台保活服务（Phase 2 实现）
/// 用于在 App 进入后台时保持行情监控
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Timer? _heartbeatTimer;
  bool _isRunning = false;

  /// 启动后台服务
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    // 心跳保活（每分钟）
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _heartbeat(),
    );

    debugPrint('[BackgroundService] Started');
  }

  /// 停止后台服务
  Future<void> stop() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _isRunning = false;

    debugPrint('[BackgroundService] Stopped');
  }

  void _heartbeat() {
    debugPrint('[BackgroundService] Heartbeat at ${DateTime.now()}');
  }

  /// 是否正在运行
  bool get isRunning => _isRunning;
}
