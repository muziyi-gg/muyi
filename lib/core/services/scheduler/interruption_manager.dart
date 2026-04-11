import '../../data/models/announcement.dart';
import '../../data/models/stock_quote.dart';
import '../../constants/announcement_types.dart';


/// 打断管理器：记录被打断的播报和队列状态
/// 当高优先级播报（P0/P1）打断正在播放的低优先级播报时，
/// 记录断点信息，以便后续恢复
class InterruptionManager {
  Announcement? _interruptedAnnouncement;
  int? _interruptedIndex;
  List<Announcement>? _interruptedQueue;
  bool _isInterrupted = false;

  /// 是否正在被打断
  bool get isInterrupted => _isInterrupted;

  /// 获取被打断的播报
  Announcement? get interruptedAnnouncement => _interruptedAnnouncement;

  /// 获取被打断时的队列索引
  int? get interruptedIndex => _interruptedIndex;

  /// 获取被打断时的完整队列
  List<Announcement>? get interruptedQueue => _interruptedQueue;

  /// 记录打断
  /// [current] 当前正在播放的播报
  /// [queue] 当前的播报队列
  /// [index] 当前播放的队列索引
  void interrupt(Announcement current, List<Announcement> queue, int index) {
    _interruptedAnnouncement = current;
    _interruptedQueue = List.from(queue);
    _interruptedIndex = index;
    _isInterrupted = true;
  }

  /// 打断并记录新的高优先级播报（用于不恢复场景）
  void interruptWith(Announcement highPriority) {
    _interruptedAnnouncement = highPriority;
    _isInterrupted = true;
  }

  /// 清除打断状态（延迟后调用）
  void clear() {
    _interruptedAnnouncement = null;
    _interruptedQueue = null;
    _interruptedIndex = null;
    _isInterrupted = false;
  }

  /// 获取恢复队列（被打断的队列中，从断点开始的部分）
  List<Announcement>? getResumeQueue() {
    if (_interruptedQueue == null || _interruptedIndex == null) return null;
    if (_interruptedIndex! >= _interruptedQueue!.length) return null;
    return _interruptedQueue!.sublist(_interruptedIndex!);
  }

  /// 重置所有状态
  void reset() {
    _interruptedAnnouncement = null;
    _interruptedQueue = null;
    _interruptedIndex = null;
    _isInterrupted = false;
  }
}
