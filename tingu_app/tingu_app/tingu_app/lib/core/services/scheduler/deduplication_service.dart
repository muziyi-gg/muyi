import '../../data/models/announcement.dart';
import '../storage/hive_storage.dart';
import '../../constants/announcement_types.dart';



/// 去重服务：管理各种播报类型的去重逻辑
/// 规则说明：
/// - 涨停/跌停/炸板：同一股票每天最多1次
/// - 拉升/下跌：5分钟冷却窗口
/// - 板块异动：每天1次
/// - 大盘异动：每小时最多1次
/// - 成交量异常：30分钟冷却
/// - 集合竞价：时间窗口内自然去重
/// - 止盈止损：不自动去重
/// - 自选股行情：按间隔播报，不去重
class DeduplicationService {
  final HiveStorage _storage;

  DeduplicationService(this._storage);

  /// 判断某播报是否应该去重（已在冷却中则返回 true）
  Future<bool> shouldDeduplicate(Announcement announcement) async {
    switch (announcement.type) {
      case AnnouncementType.limitUp:
      case AnnouncementType.limitDown:
        // 涨停/跌停：同一股票每天最多1次
        return await _storage.hasAlertToday(
            '${announcement.type.name}_${announcement.stock?.code}');

      case AnnouncementType.burstBoard:
        // 炸板：同一股票每天最多1次
        return await _storage.hasAlertToday(
            'burst_${announcement.stock?.code}');

      case AnnouncementType.quickRise:
      case AnnouncementType.quickFall:
        // 拉升/下跌：5分钟冷却窗口
        return await _storage.isInCooldown(
            'rise_${announcement.stock?.code}', 5);

      case AnnouncementType.sectorAlert:
        // 板块异动：每天1次
        return await _storage.hasAlertToday('sector_${announcement.sectorName}');

      case AnnouncementType.marketAlert:
        // 大盘异动：每小时最多1次
        return await _storage.isInCooldown('market_${announcement.value}', 60);

      case AnnouncementType.volumeAlert:
        // 成交量异常：30分钟冷却
        return await _storage.isInCooldown(
            'vol_${announcement.stock?.code}', 30);

      case AnnouncementType.auctionAlert:
        // 集合竞价：9:25后失效，时间窗口内自然去重
        return false;

      case AnnouncementType.profitLoss:
        // 止盈止损：每次触发后需手动重置，不自动去重
        return false;

      case AnnouncementType.stockQuote:
        // 自选股行情：不做去重，按间隔正常播
        return false;
    }
  }

  /// 记录播报触发（标记已触发，用于去重判断）
  Future<void> recordAlert(Announcement announcement) async {
    switch (announcement.type) {
      case AnnouncementType.limitUp:
      case AnnouncementType.limitDown:
        await _storage.cacheAlert(
            '${announcement.type.name}_${announcement.stock?.code}');
        break;
      case AnnouncementType.burstBoard:
        await _storage
            .cacheAlert('burst_${announcement.stock?.code}');
        break;
      case AnnouncementType.quickRise:
      case AnnouncementType.quickFall:
        await _storage
            .cacheAlert('rise_${announcement.stock?.code}');
        break;
      case AnnouncementType.sectorAlert:
        await _storage
            .cacheAlert('sector_${announcement.sectorName}');
        break;
      case AnnouncementType.volumeAlert:
        await _storage
            .cacheAlert('vol_${announcement.stock?.code}');
        break;
      default:
        // 其他类型不需要记录
        break;
    }
  }

  /// 重置指定播报的去重状态（用于止盈止损等需要手动重置的场景）
  Future<void> resetDeduplication(Announcement announcement) async {
    switch (announcement.type) {
      case AnnouncementType.limitUp:
      case AnnouncementType.limitDown:
        await _storage.cacheAlert(
            '${announcement.type.name}_${announcement.stock?.code}');
        break;
      case AnnouncementType.burstBoard:
        await _storage
            .cacheAlert('burst_${announcement.stock?.code}');
        break;
      case AnnouncementType.quickRise:
      case AnnouncementType.quickFall:
        await _storage
            .cacheAlert('rise_${announcement.stock?.code}');
        break;
      case AnnouncementType.volumeAlert:
        await _storage
            .cacheAlert('vol_${announcement.stock?.code}');
        break;
      default:
        break;
    }
  }
}
