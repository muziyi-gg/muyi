// 11种播报类型枚举 + 优先级定义
enum AnnouncementType {
  limitUp, // 涨停 A4
  limitDown, // 跌停 A5
  burstBoard, // 炸板 A6
  profitLoss, // 止盈止损 A11
  quickRise, // 快速拉升 A2
  quickFall, // 快速下跌 A3
  marketAlert, // 大盘异动 A8
  sectorAlert, // 板块异动 A7
  auctionAlert, // 集合竞价 A10
  stockQuote, // 自选股行情 A1
  volumeAlert, // 成交量异常 A9
}

enum Priority { p0, p1, p2, p3, p4 }

extension AnnouncementTypeExt on AnnouncementType {
  Priority get priority {
    switch (this) {
      case AnnouncementType.limitUp:
      case AnnouncementType.limitDown:
      case AnnouncementType.burstBoard:
      case AnnouncementType.profitLoss:
        return Priority.p0;
      case AnnouncementType.quickRise:
      case AnnouncementType.quickFall:
      case AnnouncementType.marketAlert:
        return Priority.p1;
      case AnnouncementType.sectorAlert:
      case AnnouncementType.auctionAlert:
        return Priority.p2;
      case AnnouncementType.stockQuote:
      case AnnouncementType.volumeAlert:
        return Priority.p3;
    }
  }

  String get label {
    switch (this) {
      case AnnouncementType.limitUp:
        return '涨停预警';
      case AnnouncementType.limitDown:
        return '跌停预警';
      case AnnouncementType.burstBoard:
        return '炸板预警';
      case AnnouncementType.profitLoss:
        return '触及止盈止损';
      case AnnouncementType.quickRise:
        return '快速拉升预警';
      case AnnouncementType.quickFall:
        return '快速下跌预警';
      case AnnouncementType.marketAlert:
        return '大盘异动';
      case AnnouncementType.sectorAlert:
        return '板块异动';
      case AnnouncementType.auctionAlert:
        return '集合竞价异动';
      case AnnouncementType.stockQuote:
        return '自选股行情';
      case AnnouncementType.volumeAlert:
        return '成交量异常';
    }
  }

  String get code {
    switch (this) {
      case AnnouncementType.limitUp:
        return 'A4';
      case AnnouncementType.limitDown:
        return 'A5';
      case AnnouncementType.burstBoard:
        return 'A6';
      case AnnouncementType.profitLoss:
        return 'A11';
      case AnnouncementType.quickRise:
        return 'A2';
      case AnnouncementType.quickFall:
        return 'A3';
      case AnnouncementType.marketAlert:
        return 'A8';
      case AnnouncementType.sectorAlert:
        return 'A7';
      case AnnouncementType.auctionAlert:
        return 'A10';
      case AnnouncementType.stockQuote:
        return 'A1';
      case AnnouncementType.volumeAlert:
        return 'A9';
    }
  }

  int get index => AnnouncementType.values.indexOf(this);
}
