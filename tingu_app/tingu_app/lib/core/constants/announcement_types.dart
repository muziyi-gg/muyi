/// 公告类型枚举，对应东方财富的各类股票异动类型
enum AnnouncementType {
  limitUp('涨停', '801'),
  limitDown('跌停', '802'),
  burstBoard('炸板', '803'),
  quickRise('快速上涨', '804'),
  quickFall('快速下跌', '805'),
  marketAlert('大盘异动', '806'),
  sectorAlert('板块异动', '807'),
  auctionAlert('竞价异动', '808'),
  stockQuote('个股行情', '809'),
  volumeAlert('成交量异动', '810'),
  profitLoss('业绩预告/快报', '811');

  /// 中文标签
  final String label;

  /// 东方财富代码
  final String code;

  const AnnouncementType(this.label, this.code);

  /// 获取该类型对应的优先级
  Priority get priority {
    switch (this) {
      case AnnouncementType.limitUp:
      case AnnouncementType.limitDown:
        return Priority.p0;
      case AnnouncementType.burstBoard:
        return Priority.p1;
      case AnnouncementType.quickRise:
      case AnnouncementType.quickFall:
      case AnnouncementType.sectorAlert:
      case AnnouncementType.auctionAlert:
        return Priority.p2;
      case AnnouncementType.marketAlert:
      case AnnouncementType.volumeAlert:
      case AnnouncementType.stockQuote:
      case AnnouncementType.profitLoss:
        return Priority.p3;
    }
  }
}

enum Priority {
  p0,
  p1,
  p2,
  p3,
}
