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

/// 系统 TTS 实现（使用 flutter_tts）
///
/// 防御策略（应对 flutter_tts 活跃 bug #554）：
/// 1. Handler 先注册，引擎配置后置 —— 避免 race condition
/// 2. speak() 前先 stop() —— 防止并发调用导致 NPE（issue #260）
/// 3. speak() 加 try-catch —— TTS 炸了也不能让 App 崩溃
/// 4. init 加 isAvailable 检测 —— 引擎真的就绪再使用，否则静默失败
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

      // 2. 设置引擎参数
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      // 3. 检测引擎是否真的可用
      final available = await _flutterTts.isLanguageAvailable('zh-CN');
      if (available == 1) {
        _isInitialized = true;
      } else {
        debugPrint('TTS zh-CN not available, trying en-US');
        await _flutterTts.setLanguage('en-US');
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('TTS init failed: $e');
      _isInitialized = false;
    }
  }

  @override
  Future<void> speak(String text) async {
    if (!_isInitialized) return;
    try {
      await _flutterTts.stop(); // 先停止上一次，避免并发 NPE
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
    try {
      await _flutterTts.setSpeechRate(speed.clamp(0.5, 2.0));
    } catch (_) {}
  }

  @override
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
    } catch (_) {}
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      _flutterTts.stop();
    } catch (_) {}
  }
}
