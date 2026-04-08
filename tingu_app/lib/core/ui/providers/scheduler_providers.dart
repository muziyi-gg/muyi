import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/scheduler/announcement_scheduler.dart';
import '../../../main.dart';

/// 调度器状态 Provider
final schedulerStateProvider = StreamProvider<SchedulerState>((ref) {
  final services = ref.watch(appServicesProvider);
  return services.scheduler.stateStream;
});

/// 当前播放 Provider
final currentPlayingProvider = Provider<String?>((ref) {
  final services = ref.watch(appServicesProvider);
  return services.scheduler.currentPlaying?.content;
});

/// 队列长度 Provider
final queueLengthProvider = Provider<int>((ref) {
  final services = ref.watch(appServicesProvider);
  return services.scheduler.queueLength;
});
