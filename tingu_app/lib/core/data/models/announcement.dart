import '../../../constants/announcement_types.dart';
import 'stock_quote.dart';

class Announcement {
  final AnnouncementType type;
  final StockQuote? stock;
  final String? sectorName;
  final double? value; // 用于传递涨幅百分比、成交量倍数等
  final int timestamp;

  Announcement({
    required this.type,
    this.stock,
    this.sectorName,
    this.value,
    required this.timestamp,
  });

  Priority get priority => type.priority;

  String get content {
    switch (type) {
      case AnnouncementType.limitUp:
        return '涨停！${stock?.name ?? ''}，报${stock?.price.toStringAsFixed(2) ?? ''}元，涨停！';
      case AnnouncementType.limitDown:
        return '跌停！${stock?.name ?? ''}，报${stock?.price.toStringAsFixed(2) ?? ''}元，已跌停！';
      case AnnouncementType.burstBoard:
        return '炸板！${stock?.name ?? ''}，打开涨停，当前报${stock?.price.toStringAsFixed(2) ?? ''}元';
      case AnnouncementType.quickRise:
        return '拉升！${stock?.name ?? ''}，5分钟涨了${value?.toStringAsFixed(1) ?? ''}%';
      case AnnouncementType.quickFall:
        return '下跌！${stock?.name ?? ''}，5分钟跌了${value?.toStringAsFixed(1) ?? ''}%';
      case AnnouncementType.sectorAlert:
        return '板块异动：${sectorName ?? ''}涨幅${value?.toStringAsFixed(1) ?? ''}%';
      case AnnouncementType.marketAlert:
        final direction = (value ?? 0) > 0 ? '上涨' : '下跌';
        return '大盘${direction}，目前${value?.abs().toStringAsFixed(1) ?? ''}%';
      case AnnouncementType.stockQuote:
        final direction = (stock?.changePercent ?? 0) >= 0 ? '涨' : '跌';
        final pct = stock?.changePercent.abs().toStringAsFixed(2) ?? '0.00';
        return '${stock?.name ?? ''}，报${stock?.price.toStringAsFixed(2) ?? ''}元，$direction$pct%';
      case AnnouncementType.volumeAlert:
        return '${stock?.name ?? ''}成交量异常放大，是昨日均量的${value?.toStringAsFixed(0) ?? ''}倍';
      case AnnouncementType.auctionAlert:
        final direction = (value ?? 0) > 0 ? '高开' : '低开';
        return '竞价预警：${stock?.name ?? ''}$direction${value?.abs().toStringAsFixed(1) ?? ''}%';
      case AnnouncementType.profitLoss:
        return '${stock?.name ?? ''}触及您设定的${value == 1 ? '止盈' : '止损'}价';
    }
  }

  String get typeKey => '${type.name}_${stock?.code ?? sectorName ?? ''}';

  Announcement copyWith({
    AnnouncementType? type,
    StockQuote? stock,
    String? sectorName,
    double? value,
    int? timestamp,
  }) {
    return Announcement(
      type: type ?? this.type,
      stock: stock ?? this.stock,
      sectorName: sectorName ?? this.sectorName,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() => 'Announcement(type: ${type.label}, content: $content)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Announcement && other.typeKey == typeKey && other.timestamp == timestamp;
  }

  @override
  int get hashCode => typeKey.hashCode ^ timestamp.hashCode;
}
