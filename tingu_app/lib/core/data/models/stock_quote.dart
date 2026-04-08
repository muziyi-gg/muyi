/// 股票行情数据模型
import '../../core/constants/announcement_types.dart';
class StockQuote {
  final String code;
  final String name;
  final double price;
  final double lastClose;
  final double open;
  final double high;
  final double low;
  final int volume;
  final double amount;
  final int timestamp;
  final StockMarket market;

  StockQuote({
    required this.code,
    required this.name,
    required this.price,
    required this.lastClose,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.amount,
    required this.timestamp,
    this.market = StockMarket.shanghai,
  });

  /// 涨跌额
  double get changeAmount => price - lastClose;

  /// 涨跌幅（%）
  double get changePercent {
    if (lastClose == 0) return 0;
    return (changeAmount / lastClose) * 100;
  }

  /// 成交额（万元）
  double get amountWan => amount / 10000;

  /// 成交量（手）
  int get volumeHand => volume ~/ 100;

  /// 是否涨停（主板±10%，科创/创业±20%）
  bool get isLimitUp {
    final limitRatio = _isLimit20Percent() ? 1.20 : 1.10;
    final limitUpPrice = lastClose * limitRatio;
    // 容错 ±0.5%，防止精度问题导致漏报
    return (price - limitUpPrice).abs() / limitUpPrice < 0.005;
  }

  /// 是否跌停（主板±10%，科创/创业±20%）
  bool get isLimitDown {
    final limitRatio = _isLimit20Percent() ? 0.80 : 0.90;
    final limitDownPrice = lastClose * limitRatio;
    return (price - limitDownPrice).abs() / limitDownPrice < 0.005;
  }

  /// 判断所属市场是否±20%涨跌幅（科创板/创业板）
  bool _isLimit20Percent() {
    return market == StockMarket.shanghai_kcb ||
        market == StockMarket.shenzhen_cyb;
  }

  /// 涨停价
  double get limitUpPrice {
    final limitRatio = _isLimit20Percent() ? 1.20 : 1.10;
    return lastClose * limitRatio;
  }

  /// 跌停价
  double get limitDownPrice {
    final limitRatio = _isLimit20Percent() ? 0.80 : 0.90;
    return lastClose * limitRatio;
  }

  factory StockQuote.fromJson(Map<String, dynamic> json) {
    return StockQuote(
      code: json['code'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      lastClose: (json['lastClose'] as num).toDouble(),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      volume: json['volume'] as int,
      amount: (json['amount'] as num).toDouble(),
      timestamp: json['timestamp'] as int,
      market: StockMarket.fromString(json['market'] as String? ?? 'shanghai'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'price': price,
      'lastClose': lastClose,
      'open': open,
      'high': high,
      'low': low,
      'volume': volume,
      'amount': amount,
      'timestamp': timestamp,
      'market': market.name,
    };
  }

  StockQuote copyWith({
    String? code,
    String? name,
    double? price,
    double? lastClose,
    double? open,
    double? high,
    double? low,
    int? volume,
    double? amount,
    int? timestamp,
    StockMarket? market,
  }) {
    return StockQuote(
      code: code ?? this.code,
      name: name ?? this.name,
      price: price ?? this.price,
      lastClose: lastClose ?? this.lastClose,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      volume: volume ?? this.volume,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      market: market ?? this.market,
    );
  }
}

/// 股票市场枚举
enum StockMarket {
  shanghai('shanghai', '上证'),
  shanghai_kcb('shanghai_kcb', '科创板'),
  shanghai_opt('shanghai_opt', '上证期权'),
  shenzhen('shenzhen', '深证'),
  shenzhen_cyb('shenzhen_cyb', '创业板'),
  shenzhen_zxb('shenzhen_zxb', '中小板'),
  beijing('beijing', '北交所'),
  ;

  final String name;
  final String displayName;

  const StockMarket(this.name, this.displayName);

  static StockMarket fromString(String value) {
    return StockMarket.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StockMarket.shanghai,
    );
  }

  bool get isShanghai =>
      this == StockMarket.shanghai ||
      this == StockMarket.shanghai_kcb ||
      this == StockMarket.shanghai_opt;

  bool get isShenzhen =>
      this == StockMarket.shenzhen ||
      this == StockMarket.shenzhen_cyb ||
      this == StockMarket.shenzhen_zxb;
}
