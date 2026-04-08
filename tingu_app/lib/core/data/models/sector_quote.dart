/// 板块行情数据模型
import '../../core/constants/announcement_types.dart';
class SectorQuote {
  final String code;
  final String name;
  final double changePercent;
  final double amount;
  final int timestamp;

  SectorQuote({
    required this.code,
    required this.name,
    required this.changePercent,
    required this.amount,
    required this.timestamp,
  });

  factory SectorQuote.fromJson(Map<String, dynamic> json) => SectorQuote(
    code: json['code'] ?? '',
    name: json['name'] ?? '',
    changePercent: (json['changePercent'] as num?)?.toDouble() ?? 0.0,
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'changePercent': changePercent,
    'amount': amount,
    'timestamp': timestamp,
  };
}
