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
class SystemTtsImpl implements TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;

  @override
  Future<void> init() async {
    await _flutterTts.setLanguage('zh-CN');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);

    _flutterTts.setStartHandler(() => _isPlaying = true);
    _flutterTts.setCompletionHandler(() => _isPlaying = false);
    _flutterTts.setErrorHandler((msg) => _isPlaying = false);
    _flutterTts.setCancelHandler(() => _isPlaying = false);
    _flutterTts.setPauseHandler(() {});
    _flutterTts.setContinueHandler(() => _isPlaying = true);
  }

  @override
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
  }

  @override
  Future<void> pause() async {
    await _flutterTts.pause();
    _isPlaying = false;
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> setSpeed(double speed) async {
    await _flutterTts.setSpeechRate(speed.clamp(0.5, 2.0));
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
  }

  @override
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
  }

  @override
  void dispose() {
    _flutterTts.stop();
  }
}
