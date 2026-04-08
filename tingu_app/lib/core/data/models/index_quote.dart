/// 指数行情数据模型
import '../../core/constants/announcement_types.dart';
class IndexQuote {
  final String code;
  final String name;
  final double price;
  final double changePercent;
  final double amount;
  final int timestamp;

  IndexQuote({
    required this.code,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.amount,
    required this.timestamp,
  });

  factory IndexQuote.fromJson(Map<String, dynamic> json) => IndexQuote(
    code: json['code'] ?? '',
    name: json['name'] ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    changePercent: (json['changePercent'] as num?)?.toDouble() ?? 0.0,
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'price': price,
    'changePercent': changePercent,
    'amount': amount,
    'timestamp': timestamp,
  };
}
