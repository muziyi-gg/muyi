import '../datasources/stock_datasource.dart';
import '../models/stock_quote.dart';

/// 股票数据仓库接口
abstract class StockRepository {
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

/// 股票数据仓库实现
class StockRepositoryImpl implements StockRepository {
  final StockDataSource _dataSource;

  StockRepositoryImpl(this._dataSource);

  @override
  Stream<List<StockQuote>> streamAllQuotes() => _dataSource.streamAllQuotes();

  @override
  Stream<StockQuote> streamQuote(String code) => _dataSource.streamQuote(code);

  @override
  Future<List<Map<String, dynamic>>> getSectorList() => _dataSource.getSectorList();

  @override
  Stream<Map<String, dynamic>> streamSectorQuotes() => _dataSource.streamSectorQuotes();

  @override
  Stream<Map<String, dynamic>> streamIndexQuotes() => _dataSource.streamIndexQuotes();

  @override
  void dispose() => _dataSource.dispose();
}
