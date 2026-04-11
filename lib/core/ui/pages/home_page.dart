import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/announcement.dart';
import '../../data/models/user_stock_config.dart';
import '../../../main.dart';

import '../widgets/stock_card.dart';
import '../widgets/alert_badge.dart';
import 'settings_page.dart';
import 'watchlist_page.dart';
import '../../constants/announcement_types.dart';

/// 首页 Dashboard
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  List<Announcement> _todayAlerts = [];
  bool _isMonitoring = true;
  Completer<void>? _settingsNav; // 防重入Completer，确保push完成后才解锁
  late AnimationController _pulseController;
  StreamSubscription? _announcementSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStreams();
    });
  }

  void _initStreams() {
    try {
      final services = ref.read(appServicesProvider);
      if (services == null) {
        debugPrint('[HomePage] _initStreams: appServicesProvider is null, skipping');
        return;
      }
      _announcementSub = services.scheduler.announcementStream.listen(
        (announcement) {
          if (!mounted) return;
          setState(() {
            _todayAlerts.insert(0, announcement);
            if (_todayAlerts.length > 100) {
              _todayAlerts = _todayAlerts.sublist(0, 100);
            }
          });
        },
      );
    } catch (e) {
      debugPrint('HomePage _initStreams failed: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _announcementSub?.cancel();
    super.dispose();
  }

  void _openSettings() {
    // Completer防重入：push()完成前（Future完成前）不允许再次触发
    if (_settingsNav != null || !mounted) return;
    _settingsNav = Completer<void>();

    // defer到下一帧，确保Navigator状态干净
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) { _settingsNav?.complete(); _settingsNav = null; return; }
      try {
        Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        ).then((_) {
          // 页面真正关闭时才清守卫，动画期间重入都会被挡住
          _settingsNav?.complete();
          _settingsNav = null;
        });
        debugPrint('[HomePage] Navigator.push started');
      } catch (e) {
        debugPrint('[HomePage] Navigator.push FAILED: $e');
        _settingsNav?.complete();
        _settingsNav = null;
        if (mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('无法打开设置页: $e'), backgroundColor: Colors.red),
            );
          } catch (_) {}
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('听股通'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // 监控状态横幅
          _buildMonitorBanner(),

          // 今日播报记录
          Expanded(
            child: _todayAlerts.isEmpty
                ? _buildEmptyState()
                : _buildAlertList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleMonitor,
        backgroundColor: _isMonitoring ? Colors.red : Colors.grey,
        child: Icon(
          _isMonitoring ? Icons.volume_up : Icons.volume_off,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMonitorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isMonitoring
              ? [Colors.red.shade400, Colors.red.shade600]
              : [Colors.grey.shade400, Colors.grey.shade600],
        ),
      ),
      child: Row(
        children: [
          ListenableBuilder(
            listenable: _pulseController,
            builder: (context, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isMonitoring
                      ? Colors.white.withOpacity(0.5 + _pulseController.value * 0.5)
                      : Colors.grey,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isMonitoring ? '实时监控中' : '监控已暂停',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _isMonitoring
                      ? '听股通正在监听市场动态'
                      : '点击右下角按钮开启监控',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_todayAlerts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_todayAlerts.length} 条预警',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无预警播报',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '自选股触及预警条件时将自动播报',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _todayAlerts.length,
      itemBuilder: (context, index) {
        final alert = _todayAlerts[index];
        return _buildAlertItem(alert);
      },
    );
  }

  Widget _buildAlertItem(Announcement alert) {
    Color badgeColor;
    IconData icon;

    switch (alert.type) {
      case AnnouncementType.limitUp:
        badgeColor = Colors.red;
        icon = Icons.arrow_upward;
        break;
      case AnnouncementType.limitDown:
        badgeColor = Colors.green;
        icon = Icons.arrow_downward;
        break;
      case AnnouncementType.burstBoard:
        badgeColor = Colors.orange;
        icon = Icons.warning;
        break;
      case AnnouncementType.quickRise:
        badgeColor = Colors.red;
        icon = Icons.trending_up;
        break;
      case AnnouncementType.quickFall:
        badgeColor = Colors.blue;
        icon = Icons.trending_down;
        break;
      default:
        badgeColor = Colors.grey;
        icon = Icons.notifications;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: badgeColor),
        ),
        title: Text(
          alert.content,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          _formatTime(alert.timestamp),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: AlertBadge(type: alert.type),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  void _toggleMonitor() {
    setState(() {
      _isMonitoring = !_isMonitoring;
    });

    try {
      final services = ref.read(appServicesProvider);
      if (services == null) return;
      if (_isMonitoring) {
        services.marketMonitor.start();
      } else {
        services.marketMonitor.stop();
        services.ttsService.stop();
      }
    } catch (e) {
      debugPrint('toggleMonitor failed: $e');
    }
  }
}
