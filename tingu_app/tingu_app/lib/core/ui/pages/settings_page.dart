import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../../constants/announcement_types.dart';

/// 监控设置页
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  /// 立即初始化默认值，确保 build() 首次执行时 map 已就绪
  Map<String, bool> _alertConfig = {
    for (final type in AnnouncementType.values) type.name: true,
  };
  bool _configLoaded = false;
  bool _initError = false;
  String? _initErrorMsg;

  @override
  void initState() {
    super.initState();
    _initConfig();
  }

  Future<void> _initConfig() async {
    debugPrint('[SettingsPage] _initConfig starting...');

    for (int i = 0; i < 30; i++) {
      if (!mounted) {
        debugPrint('[SettingsPage] _initConfig: not mounted, exiting');
        return;
      }

      try {
        final services = ref.read(appServicesProvider);
        if (services != null) {
          debugPrint('[SettingsPage] _initConfig: services found on attempt $i');
          try {
            final loadedConfig = Map<String, bool>.from(
              services.hiveStorage.getAlertConfig(),
            );
            if (!mounted) return;
            setState(() {
              _alertConfig = loadedConfig;
              _configLoaded = true;
            });
            debugPrint('[SettingsPage] _initConfig: config loaded successfully');
            return;
          } catch (configErr) {
            debugPrint('[SettingsPage] getAlertConfig failed: $configErr');
            // Use default config if reading fails
            if (!mounted) return;
            setState(() {
              _configLoaded = true;
              _initError = true;
              _initErrorMsg = '读取配置失败，使用默认设置';
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('[SettingsPage] _initConfig attempt $i failed: $e');
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Timeout: use defaults
    debugPrint('[SettingsPage] _initConfig: timeout, using defaults');
    if (mounted) {
      setState(() {
        _configLoaded = true;
        _initError = true;
        _initErrorMsg = '服务初始化超时，使用的默认设置';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[SettingsPage] build() called, _configLoaded=$_configLoaded');
    return Scaffold(
      appBar: AppBar(
        title: const Text('监控设置'),
        actions: [
          TextButton(
            onPressed: _saveConfig,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDataSourceCard(),
          if (_initError) ...[
            const SizedBox(height: 8),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _initErrorMsg ?? '初始化时出现问题，设置已使用默认值',
                        style: TextStyle(color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            '播报类型开关',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildAlertSwitches(),
        ],
      ),
    );
  }

  Widget _buildDataSourceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  '数据源',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Phase 1: 东方财富（WebSocket）'),
            const Text(
              'wss://push2.eastmoney.com',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Phase 2（规划中）: 万德 Wind',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSwitches() {
    return Card(
      child: Column(
        children: AnnouncementType.values.map((type) {
          final enabled = _alertConfig[type.name] ?? true;
          return SwitchListTile(
            title: Text(type.label),
            subtitle: Text('编号: ${type.code}'),
            value: enabled,
            onChanged: (value) {
              setState(() {
                _alertConfig[type.name] = value;
              });
            },
            secondary: _getAlertIcon(type),
          );
        }).toList(),
      ),
    );
  }

  Widget _getAlertIcon(AnnouncementType type) {
    IconData icon;
    Color color;

    switch (type) {
      case AnnouncementType.limitUp:
        icon = Icons.arrow_upward; color = Colors.red;
        break;
      case AnnouncementType.limitDown:
        icon = Icons.arrow_downward; color = Colors.green;
        break;
      case AnnouncementType.burstBoard:
        icon = Icons.warning; color = Colors.orange;
        break;
      case AnnouncementType.quickRise:
        icon = Icons.trending_up; color = Colors.red;
        break;
      case AnnouncementType.quickFall:
        icon = Icons.trending_down; color = Colors.blue;
        break;
      case AnnouncementType.marketAlert:
        icon = Icons.show_chart; color = Colors.purple;
        break;
      case AnnouncementType.sectorAlert:
        icon = Icons.pie_chart; color = Colors.teal;
        break;
      case AnnouncementType.auctionAlert:
        icon = Icons.access_time; color = Colors.amber;
        break;
      case AnnouncementType.stockQuote:
        icon = Icons.list; color = Colors.indigo;
        break;
      case AnnouncementType.volumeAlert:
        icon = Icons.bar_chart; color = Colors.cyan;
        break;
      case AnnouncementType.profitLoss:
        icon = Icons.attach_money; color = Colors.lime;
        break;
    }

    return Icon(icon, color: color);
  }

  Future<void> _saveConfig() async {
    try {
      final services = ref.read(appServicesProvider);
      if (services == null) {
        debugPrint('[SettingsPage] _saveConfig: services is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('服务未就绪，请稍后重试')),
          );
        }
        return;
      }
      await services.hiveStorage.saveAlertConfig(_alertConfig);
      debugPrint('[SettingsPage] _saveConfig: saved successfully');
    } catch (e) {
      debugPrint('[SettingsPage] _saveConfig failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存')),
      );
      Navigator.pop(context);
    }
  }
}
