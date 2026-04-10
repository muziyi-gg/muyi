import '../models/stock_quote.dart';

/// 数据源抽象接口
abstract class StockDataSource {
  /// 全市场行情流
  Stream<List<StockQuote>> streamAllQuotes();

  /// 单股行情流
  Stream<StockQuote> streamQuote(String code);

  /// 获取板块列表
  Future<List<Map<String, dynamic>>> getSectorList();

  /// 板块行情流
  Stream<Map<String, dynamic>> streamSectorQuotes();

  /// 指数行情流
  Stream<Map<String, dynamic>> streamIndexQuotes();

  /// 断开连接
  void dispose();
}
