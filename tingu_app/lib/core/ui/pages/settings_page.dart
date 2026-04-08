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
  late Map<String, bool> _alertConfig;

  @override
  void initState() {
    super.initState();
    final services = ref.read(appServicesProvider);
    _alertConfig = Map.from(services.hiveStorage.getAlertConfig());
  }

  @override
  Widget build(BuildContext context) {
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
          // 数据源信息
          _buildDataSourceCard(),
          const SizedBox(height: 16),

          // 播报开关
          const Text(
            '播报类型开关',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
    final services = ref.read(appServicesProvider);
    await services.hiveStorage.saveAlertConfig(_alertConfig);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存')),
      );
      Navigator.pop(context);
    }
  }
}
