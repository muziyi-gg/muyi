// 市场常量：涨跌幅、交易时间、数据源地址
class MarketConstants {
  // 涨停比例
  static const double mainBoardLimit = 0.10; // 主板 ±10%
  static const double starBoardLimit = 0.20; // 科创/创业 ±20%

  // 集合竞价时间
  static const String auctionStart = '09:15';
  static const String auctionEnd = '09:25';

  // 东方财富 WebSocket 地址
  static const String wsUrl = 'wss://push2.eastmoney.com';

  // 交易时间段
  static const String morningSessionStart = '09:30';
  static const String morningSessionEnd = '11:30';
  static const String afternoonSessionStart = '13:00';
  static const String afternoonSessionEnd = '15:00';

  // 涨停容错比例（防止精度问题导致漏报）
  static const double limitTolerance = 0.005; // ±0.5%

  // 拉升/下跌阈值（5分钟涨跌幅）
  static const double quickRiseThreshold = 3.0; // 3%
  static const double quickFallThreshold = -3.0; // -3%

  // 板块异动阈值
  static const double sectorAlertThreshold = 3.0; // 板块涨幅 3%

  // 大盘异动阈值（沪深300）
  static const double marketAlertThreshold = 1.0; // 1%

  // 成交量异常倍数
  static const double volumeAlertMultiplier = 3.0; // 3倍于昨日均量
}
