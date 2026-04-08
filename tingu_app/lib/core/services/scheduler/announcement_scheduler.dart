import 'dart:async';
import '../../data/models/announcement.dart';
import '../../data/models/stock_quote.dart';
import '../../constants/announcement_types.dart';
import 'deduplication_service.dart';
import 'interruption_manager.dart';
import '../../core/constants/announcement_types.dart';

/// 调度器状态
enum SchedulerState { idle, playing, queued }

/// 核心播报调度器
/// 负责：
/// 1. 接收各种类型的播报事件
/// 2. 根据优先级决定立即播放或加入队列
/// 3. P0/P1 打断逻辑（立即打断当前播放）
/// 4. P2/P3/P4 队列排队逻辑
/// 5. 播报时长估算
class AnnouncementScheduler {
  final DeduplicationService _dedup;
  final InterruptionManager _interruptMgr;
  final List<Announcement> _queue = [];
  bool _isPlaying = false;
  Announcement? _currentPlaying;
  final _controller = StreamController<Announcement>.broadcast();
  final _stateController = StreamController<SchedulerState>.broadcast();

  SchedulerState get state {
    if (_isPlaying) {
      return _queue.isEmpty ? SchedulerState.playing : SchedulerState.queued;
    }
    return SchedulerState.idle;
  }

  Announcement? get currentPlaying => _currentPlaying;
  int get queueLength => _queue.length;

  AnnouncementScheduler(this._dedup, this._interruptMgr);

  /// 播报事件流
  Stream<Announcement> get announcementStream => _controller.stream;

  /// 调度器状态流
  Stream<SchedulerState> get stateStream => _stateController.stream;

  /// 核心方法：加入播报队列
  /// [announcement] 播报事件
  Future<void> enqueue(Announcement announcement) async {
    // 1. 检查去重
    if (await _dedup.shouldDeduplicate(announcement)) {
      return;
    }

    // 2. 记录触发（用于去重）
    await _dedup.recordAlert(announcement);

    // 3. 根据优先级决定处理方式
    final priority = announcement.priority;

    if (priority == Priority.p0 || priority == Priority.p1) {
      // P0/P1：打断逻辑
      await _handleHighPriority(announcement);
    } else {
      // P2/P3/P4：入队
      _insertByPriority(announcement);
      _notifyStateChange();
      if (!_isPlaying) {
        _playNext();
      }
    }
  }

  /// 处理高优先级播报（P0/P1）
  Future<void> _handleHighPriority(Announcement announcement) async {
    if (_isPlaying && _currentPlaying != null) {
      // 打断当前播放
      final currentIdx = _queue.isEmpty ? 0 : _queue.length;
      _interruptMgr.interrupt(_currentPlaying!, _queue, currentIdx);
    }

    // 立即播放打断内容
    await _playAnnouncement(announcement);

    // 延迟1秒后恢复队列（如果有）
    await Future.delayed(const Duration(seconds: 1));

    // 检查是否有被打断的队列需要恢复
    final resumeQueue = _interruptMgr.getResumeQueue();
    if (resumeQueue != null && resumeQueue.isNotEmpty) {
      // 将恢复的队列加回调度器
      for (final a in resumeQueue) {
        _insertByPriority(a);
      }
      _interruptMgr.clear();
      _notifyStateChange();
      if (!_isPlaying) {
        _playNext();
      }
    }
  }

  /// 按优先级插入队列
  /// P0 > P1 > P2 > P3，同优先级按时间顺序
  void _insertByPriority(Announcement a) {
    int insertIdx = _queue.length;
    for (int i = 0; i < _queue.length; i++) {
      // 按优先级从高到低排列
      if (a.priority.index < _queue[i].priority.index) {
        insertIdx = i;
        break;
      }
    }
    _queue.insert(insertIdx, a);
  }

  /// 播放单个播报
  Future<void> _playAnnouncement(Announcement a) async {
    _isPlaying = true;
    _currentPlaying = a;
    _notifyStateChange();

    // 通过 Stream 发出播报事件，交给 TTS 服务处理播放
    _controller.add(a);

    // 等待播报完成（由 TTS 回调或估算时长）
    final duration = _estimateDuration(a);
    await Future.delayed(Duration(milliseconds: duration));

    _isPlaying = false;
    _currentPlaying = null;
    _notifyStateChange();
  }

  /// 估算播报时长（毫秒）
  /// 按每字符 120ms 估算，最短 1.5s，最长 8s
  int _estimateDuration(Announcement a) {
    final len = a.content.length;
    return (len * 120).toInt().clamp(1500, 8000);
  }

  /// 从队列中取出下一个播报并播放
  Future<void> _playNext() async {
    if (_queue.isEmpty) return;
    if (_isPlaying) return;

    _isPlaying = true;
    final a = _queue.removeAt(0);
    _currentPlaying = a;
    _notifyStateChange();

    _controller.add(a);

    final duration = _estimateDuration(a);
    await Future.delayed(Duration(milliseconds: duration));

    _isPlaying = false;
    _currentPlaying = null;
    _notifyStateChange();

    // 递归播放下一个
    if (_queue.isNotEmpty) {
      _playNext();
    }
  }

  void _notifyStateChange() {
    _stateController.add(state);
  }

  /// 清空队列
  void clearQueue() {
    _queue.clear();
    _notifyStateChange();
  }

  /// 跳过当前播放
  void skipCurrent() {
    _isPlaying = false;
    _currentPlaying = null;
    _notifyStateChange();
    if (_queue.isNotEmpty) {
      _playNext();
    }
  }

  /// 获取当前队列副本（用于调试）
  List<Announcement> getQueueSnapshot() => List.from(_queue);

  /// 释放资源
  void dispose() {
    _controller.close();
    _stateController.close();
    _queue.clear();
  }
}
