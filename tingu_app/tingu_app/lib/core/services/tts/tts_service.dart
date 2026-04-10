import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS 抽象接口
abstract class TtsService {
  /// 初始化
  Future<void> init();

  /// 播放文本
  Future<void> speak(String text);

  /// 停止播放
  Future<void> stop();

  /// 暂停播放
  Future<void> pause();

  /// 是否正在播放
  bool get isPlaying;

  /// 设置语速 (0.5 - 2.0)
  Future<void> setSpeed(double speed);

  /// 设置音调 (0.5 - 2.0)
  Future<void> setPitch(double pitch);

  /// 设置音量 (0.0 - 1.0)
  Future<void> setVolume(double volume);

  /// 释放资源
  void dispose();
}

/// 超时封装——防止任何一个 TTS await 无限 hang
Future<void> _withTimeout(Future<void> future, String label) async {
  try {
    await future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => debugPrint('TTS $label timeout (5s) skipped'),
    );
  } catch (e) {
    debugPrint('TTS $label error: $e');
  }
}

/// 系统 TTS 实现（使用 flutter_tts）
///
/// 防御策略（应对 flutter_tts 活跃 bug #554）：
/// 1. Handler 先注册，引擎配置后置
/// 2. 所有 await 全部加 5 秒超时——永不卡死初始化
/// 3. speak() 前先 stop() + try-catch
/// 4. init 失败不影响主流程（_isInitialized = false）
class SystemTtsImpl implements TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  Future<void> init() async {
    try {
      // 1. 先注册所有 handler（防止 race condition）
      _flutterTts.setStartHandler(() => _isPlaying = true);
      _flutterTts.setCompletionHandler(() => _isPlaying = false);
      _flutterTts.setErrorHandler((msg) {
        _isPlaying = false;
        debugPrint('TTS error: $msg');
      });
      _flutterTts.setCancelHandler(() => _isPlaying = false);
      _flutterTts.setPauseHandler(() {});
      _flutterTts.setContinueHandler(() => _isPlaying = true);

      // 2. 每个 TTS 操作都独立超时，互不阻塞
      await _withTimeout(_flutterTts.setLanguage('zh-CN'), 'setLanguage-zh');
      await _withTimeout(_flutterTts.setSpeechRate(0.5), 'setSpeechRate');
      await _withTimeout(_flutterTts.setPitch(1.0), 'setPitch');
      await _withTimeout(_flutterTts.setVolume(1.0), 'setVolume');

      // 3. 检测引擎是否可用
      bool available = false;
      try {
        final result = await _flutterTts
            .isLanguageAvailable('zh-CN')
            .timeout(const Duration(seconds: 5));
        available = (result == 1);
      } catch (_) {}

      if (!available) {
        debugPrint('TTS zh-CN not available, trying en-US');
        await _withTimeout(_flutterTts.setLanguage('en-US'), 'setLanguage-en');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS init failed: $e');
      _isInitialized = false;
    }
  }

  @override
  Future<void> speak(String text) async {
    if (!_isInitialized) return;
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isPlaying = false;
    } catch (_) {}
  }

  @override
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _isPlaying = false;
    } catch (_) {}
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> setSpeed(double speed) async {
    await _withTimeout(
        _flutterTts.setSpeechRate(speed.clamp(0.5, 2.0)), 'setSpeed');
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _withTimeout(
        _flutterTts.setPitch(pitch.clamp(0.5, 2.0)), 'setPitch');
  }

  @override
  Future<void> setVolume(double volume) async {
    await _withTimeout(
        _flutterTts.setVolume(volume.clamp(0.0, 1.0)), 'setVolume');
  }

  @override
  void dispose() {
    try {
      _flutterTts.stop();
    } catch (_) {}
  }
}
