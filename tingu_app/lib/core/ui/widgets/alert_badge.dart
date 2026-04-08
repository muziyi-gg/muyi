import 'package:flutter/material.dart';
import '../../constants/announcement_types.dart';



/// 预警类型气泡标签
class AlertBadge extends StatelessWidget {
  final AnnouncementType type;
  final bool small;

  const AlertBadge({
    super.key,
    required this.type,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (type) {
      case AnnouncementType.limitUp:
        color = Colors.red; label = '涨停';
        break;
      case AnnouncementType.limitDown:
        color = Colors.green; label = '跌停';
        break;
      case AnnouncementType.burstBoard:
        color = Colors.orange; label = '炸板';
        break;
      case AnnouncementType.quickRise:
        color = Colors.red; label = '拉升';
        break;
      case AnnouncementType.quickFall:
        color = Colors.blue; label = '下跌';
        break;
      case AnnouncementType.marketAlert:
        color = Colors.purple; label = '大盘';
        break;
      case AnnouncementType.sectorAlert:
        color = Colors.teal; label = '板块';
        break;
      case AnnouncementType.auctionAlert:
        color = Colors.amber; label = '竞价';
        break;
      case AnnouncementType.stockQuote:
        color = Colors.indigo; label = '行情';
        break;
      case AnnouncementType.volumeAlert:
        color = Colors.cyan; label = '放量';
        break;
      case AnnouncementType.profitLoss:
        color = Colors.lime; label = '止盈止损';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(small ? 4 : 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
