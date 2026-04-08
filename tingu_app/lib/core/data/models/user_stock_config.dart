import '../../constants/announcement_types.dart';
/// 用户自选股配置模型

class UserStockConfig {
  final String code;
  final String name;
  final StockMarket market;
  final DateTime addedAt;
  final StockAlertConfig alertConfig;
  final bool isEnabled;

  UserStockConfig({
    required this.code,
    required this.name,
    required this.market,
    required this.addedAt,
    required this.alertConfig,
    this.isEnabled = true,
  });

  factory UserStockConfig.fromJson(Map<String, dynamic> json) {
    return UserStockConfig(
      code: json['code'] as String,
      name: json['name'] as String,
      market: StockMarket.fromString(json['market'] as String? ?? 'shanghai'),
      addedAt: DateTime.parse(json['addedAt'] as String),
      alertConfig: StockAlertConfig.fromJson(
          json['alertConfig'] as Map<String, dynamic>? ?? {}),
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'market': market.name,
      'addedAt': addedAt.toIso8601String(),
      'alertConfig': alertConfig.toJson(),
      'isEnabled': isEnabled,
    };
  }

  UserStockConfig copyWith({
    String? code,
    String? name,
    StockMarket? market,
    DateTime? addedAt,
    StockAlertConfig? alertConfig,
    bool? isEnabled,
  }) {
    return UserStockConfig(
      code: code ?? this.code,
      name: name ?? this.name,
      market: market ?? this.market,
      addedAt: addedAt ?? this.addedAt,
      alertConfig: alertConfig ?? this.alertConfig,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// 股票预警配置
class StockAlertConfig {
  final bool enableLimitUp; // 涨停预警
  final bool enableLimitDown; // 跌停预警
  final bool enableRapidRise; // 快速拉升预警
  final bool enableRapidFall; // 快速下跌预警
  final bool enableVolume; // 成交量异常
  final bool enableProfit; // 止盈止损
  final double rapidRiseThreshold; // 拉升阈值（%），默认 2.0
  final double rapidFallThreshold; // 下跌阈值（%），默认 -2.0
  final double volumeRatioThreshold; // 量比阈值，默认 2.0
  final double profitTarget; // 止盈目标（%）
  final double lossStop; // 止损线（%）

  StockAlertConfig({
    this.enableLimitUp = true,
    this.enableLimitDown = true,
    this.enableRapidRise = true,
    this.enableRapidFall = true,
    this.enableVolume = false,
    this.enableProfit = false,
    this.rapidRiseThreshold = 2.0,
    this.rapidFallThreshold = -2.0,
    this.volumeRatioThreshold = 2.0,
    this.profitTarget = 10.0,
    this.lossStop = -5.0,
  });

  factory StockAlertConfig.fromJson(Map<String, dynamic> json) {
    return StockAlertConfig(
      enableLimitUp: json['enableLimitUp'] as bool? ?? true,
      enableLimitDown: json['enableLimitDown'] as bool? ?? true,
      enableRapidRise: json['enableRapidRise'] as bool? ?? true,
      enableRapidFall: json['enableRapidFall'] as bool? ?? true,
      enableVolume: json['enableVolume'] as bool? ?? false,
      enableProfit: json['enableProfit'] as bool? ?? false,
      rapidRiseThreshold:
          (json['rapidRiseThreshold'] as num?)?.toDouble() ?? 2.0,
      rapidFallThreshold:
          (json['rapidFallThreshold'] as num?)?.toDouble() ?? -2.0,
      volumeRatioThreshold:
          (json['volumeRatioThreshold'] as num?)?.toDouble() ?? 2.0,
      profitTarget: (json['profitTarget'] as num?)?.toDouble() ?? 10.0,
      lossStop: (json['lossStop'] as num?)?.toDouble() ?? -5.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableLimitUp': enableLimitUp,
      'enableLimitDown': enableLimitDown,
      'enableRapidRise': enableRapidRise,
      'enableRapidFall': enableRapidFall,
      'enableVolume': enableVolume,
      'enableProfit': enableProfit,
      'rapidRiseThreshold': rapidRiseThreshold,
      'rapidFallThreshold': rapidFallThreshold,
      'volumeRatioThreshold': volumeRatioThreshold,
      'profitTarget': profitTarget,
      'lossStop': lossStop,
    };
  }

  StockAlertConfig copyWith({
    bool? enableLimitUp,
    bool? enableLimitDown,
    bool? enableRapidRise,
    bool? enableRapidFall,
    bool? enableVolume,
    bool? enableProfit,
    double? rapidRiseThreshold,
    double? rapidFallThreshold,
    double? volumeRatioThreshold,
    double? profitTarget,
    double? lossStop,
  }) {
    return StockAlertConfig(
      enableLimitUp: enableLimitUp ?? this.enableLimitUp,
      enableLimitDown: enableLimitDown ?? this.enableLimitDown,
      enableRapidRise: enableRapidRise ?? this.enableRapidRise,
      enableRapidFall: enableRapidFall ?? this.enableRapidFall,
      enableVolume: enableVolume ?? this.enableVolume,
      enableProfit: enableProfit ?? this.enableProfit,
      rapidRiseThreshold: rapidRiseThreshold ?? this.rapidRiseThreshold,
      rapidFallThreshold: rapidFallThreshold ?? this.rapidFallThreshold,
      volumeRatioThreshold: volumeRatioThreshold ?? this.volumeRatioThreshold,
      profitTarget: profitTarget ?? this.profitTarget,
      lossStop: lossStop ?? this.lossStop,
    );
  }
}

/// 市场枚举（复用自 stock_quote）
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
}
