import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../../data/models/user_stock_config.dart';

/// 自选股管理页
class WatchlistPage extends ConsumerStatefulWidget {
  const WatchlistPage({super.key});

  @override
  ConsumerState<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends ConsumerState<WatchlistPage> {
  List<Map<String, dynamic>> _stocks = [];

  @override
  void initState() {
    super.initState();
    _loadStocks();
  }

  void _loadStocks() {
    final services = ref.read(appServicesProvider);
    setState(() {
      _stocks = services.hiveStorage.getUserStocks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自选股管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddStockDialog,
          ),
        ],
      ),
      body: _stocks.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _stocks.length,
              itemBuilder: (context, index) {
                final stock = _stocks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade100,
                      child: Text(
                        stock['code']?.toString().substring(0, 1) ?? '?',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    title: Text(stock['name'] ?? '未知'),
                    subtitle: Text(
                      '${stock['code']} · 播报间隔 ${stock['intervalSeconds'] ?? 60}s',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteStock(stock['code']),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '暂无自选股',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _showAddStockDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加自选股'),
          ),
        ],
      ),
    );
  }

  void _showAddStockDialog() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加自选股'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: '股票代码',
                hintText: '如: 600519',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '股票名称',
                hintText: '如: 贵州茅台',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              _addStock(codeController.text, nameController.text);
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _addStock(String code, String name) async {
    if (code.isEmpty || name.isEmpty) return;

    final config = UserStockConfig(
      code: code,
      name: name,
      market: StockMarket.shanghai,
      addedAt: DateTime.now(),
      alertConfig: StockAlertConfig(),
    );
    final services = ref.read(appServicesProvider);
    await services.marketMonitor.addUserStock(config);
    _loadStocks();
  }

  Future<void> _deleteStock(String code) async {
    final services = ref.read(appServicesProvider);
    await services.marketMonitor.removeUserStock(code);
    _loadStocks();
  }
}
