import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/stock_quote.dart';
import 'stock_datasource.dart';

/// 东方财富数据源实现
/// WebSocket 地址：wss://push2.eastmoney.com
/// HTTP 降级方案：3秒无响应切换 HTTP
class EastMoneyDataSource implements StockDataSource {
  WebSocketChannel? _channel;
  final _quoteController = StreamController<List<StockQuote>>.broadcast();
  final _sectorController = StreamController<Map<String, dynamic>>.broadcast();
  final _indexController = StreamController<Map<String, dynamic>>.broadcast();
  final Map<String, StockQuote> _latestQuotes = {};
  Timer? _reconnectTimer;
  Timer? _httpFallbackTimer;
  bool _wsConnected = false;
  StreamSubscription? _wsSubscription;

  EastMoneyDataSource();

  @override
  Stream<List<StockQuote>> streamAllQuotes() => _quoteController.stream;

  @override
  Stream<StockQuote> streamQuote(String code) {
    return streamAllQuotes().map(
      (quotes) => quotes.firstWhere(
        (q) => q.code == code,
        orElse: () => throw Exception('Stock $code not found'),
      ),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getSectorList() async {
    return [
      {'code': 'bk0415', 'name': '人工智能'},
      {'code': 'bk0488', 'name': '半导体'},
      {'code': 'bk0428', 'name': '新能源车'},
      {'code': 'bk0027', 'name': '医疗器械'},
      {'code': 'bk0440', 'name': '光伏设备'},
      {'code': 'bk0472', 'name': '白酒'},
      {'code': 'bk0430', 'name': '银行'},
      {'code': 'bk0432', 'name': '证券'},
      {'code': 'bk0448', 'name': '军工'},
      {'code': 'bk0451', 'name': '医药'},
    ];
  }

  @override
  Stream<Map<String, dynamic>> streamSectorQuotes() => _sectorController.stream;

  @override
  Stream<Map<String, dynamic>> streamIndexQuotes() => _indexController.stream;

  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('wss://push2.eastmoney.com'));
      _wsConnected = false;
      _wsSubscription?.cancel();
      _wsSubscription = _channel!.stream.listen(_onMessage, onError: _onError, onDone: _onDone);
      _httpFallbackTimer?.cancel();
      _httpFallbackTimer = Timer(const Duration(seconds: 3), () {
        if (!_wsConnected) _switchToHttpFallback();
      });
      _subscribe(['sh000001', 'sz399001', 'sh000300']);
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _subscribe(List<String> codes) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode({'action': 'subscribe', 'codes': codes, 'type': '1'}));
  }

  Future<void> _switchToHttpFallback() async {
    Timer.periodic(const Duration(seconds: 3), (timer) => _fetchViaHttp());
  }

  Future<void> _fetchViaHttp() async {
    // HTTP 降级：使用东方财富 HTTP 接口轮询
    // 示例 API: https://push2.eastmoney.com/api/qt/stock/get?secid=1.000001
  }

  void _onMessage(dynamic data) {
    try {
      if (data is! String) return;
      _wsConnected = true;
      _httpFallbackTimer?.cancel();
      final parsed = jsonDecode(data);
      if (parsed is List && parsed.isNotEmpty) {
        final quote = _parseQuote(parsed);
        if (quote != null) {
          _latestQuotes[quote.code] = quote;
          _quoteController.add(_latestQuotes.values.toList());
        }
      }
    } catch (_) {}
  }

  StockQuote? _parseQuote(List<dynamic> data) {
    try {
      if (data.length < 10) return null;
      final rawCode = data[0].toString();
      final code = rawCode.replaceAll('sh', '').replaceAll('sz', '');
      final name = data[1].toString();
      final lastClose = double.tryParse(data[2].toString()) ?? 0.0;
      final price = double.tryParse(data[3].toString()) ?? 0.0;
      final high = double.tryParse(data[4].toString()) ?? price;
      final low = double.tryParse(data[5].toString()) ?? price;
      final open = double.tryParse(data[6].toString()) ?? price;
      final volume = int.tryParse(data[7].toString()) ?? 0;
      final amount = double.tryParse(data[8].toString()) ?? 0.0;
      return StockQuote(
        code: code, name: name, price: price, lastClose: lastClose,
        open: open, high: high, low: low, volume: volume,
        amount: amount, timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) { return null; }
  }

  void _onError(dynamic error) => _scheduleReconnect();
  void _onDone() => _scheduleReconnect();
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () => connect());
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _httpFallbackTimer?.cancel();
    _wsSubscription?.cancel();
    _channel?.sink.close();
    _quoteController.close();
    _sectorController.close();
    _indexController.close();
  }
}
