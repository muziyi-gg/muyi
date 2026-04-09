import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/storage/hive_storage.dart';
import 'core/data/datasources/eastmoney_datasource.dart';
import 'core/data/repositories/stock_repository_impl.dart';
import 'core/services/scheduler/deduplication_service.dart';
import 'core/services/scheduler/interruption_manager.dart';
import 'core/services/scheduler/announcement_scheduler.dart';
import 'core/services/tts/tts_service.dart';
import 'core/services/monitor/market_monitor.dart';
import 'core/data/models/announcement.dart';
import 'core/ui/pages/home_page.dart';

// ==================== 全局服务容器 ====================
class AppServices {
  final HiveStorage hiveStorage;
  final EastMoneyDataSource dataSource;
  final StockRepositoryImpl repository;
  final DeduplicationService dedupService;
  final InterruptionManager interruptMgr;
  final AnnouncementScheduler scheduler;
  final SystemTtsImpl ttsService;
  final MarketMonitor marketMonitor;

  AppServices({
    required this.hiveStorage,
    required this.dataSource,
    required this.repository,
    required this.dedupService,
    required this.interruptMgr,
    required this.scheduler,
    required this.ttsService,
    required this.marketMonitor,
  });
}

final appServicesProvider = StateProvider<AppServices?>((ref) => null);

// ==================== 启动状态 ====================
enum StartupStatus { idle, loading, done, error }

class StartupState {
  final StartupStatus status;
  final String message;
  final String? error;

  const StartupState({required this.status, required this.message, this.error});

  factory StartupState.loading(String msg) =>
      StartupState(status: StartupStatus.loading, message: msg);

  factory StartupState.error(String msg) =>
      StartupState(status: StartupStatus.error, message: '启动失败', error: msg);

  factory StartupState.done() =>
      const StartupState(status: StartupStatus.done, message: '就绪');
}

final startupStateProvider = StateProvider<StartupState>(
  (_) => StartupState.loading('正在启动...'),
);

// ==================== main ====================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(
    ProviderScope(
      child: MaterialApp(
        title: '听股通',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE53935),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const _StartupScreen(),
      ),
    ),
  );
}

// ==================== 启动画面（带错误提示） ====================
class _StartupScreen extends ConsumerStatefulWidget {
  const _StartupScreen();

  @override
  ConsumerState<_StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends ConsumerState<_StartupScreen> {
  bool _navigated = false;
  StreamSubscription<Announcement>? _announcementSub;

  @override
  void initState() {
    super.initState();
    // microtask defer: 确保 UI 先构建完成，再修改 provider
    Future.microtask(() => _initApp());
  }

  Future<void> _initApp() async {
    try {
      debugPrint('[DEBUG] _initApp started');
      if (!mounted) { debugPrint('[DEBUG] Step 0: NOT mounted, returning early'); return; }

      // Step 1: Hive 初始化
      debugPrint('[DEBUG] Step 1: updating state -> 正在初始化本地存储...');
      ref.read(startupStateProvider.notifier).state =
          StartupState.loading('正在初始化本地存储...');
      debugPrint('[DEBUG] Step 1: Hive.initFlutter() starting...');
      try {
        await Hive.initFlutter();
        debugPrint('[DEBUG] Step 1: Hive.initFlutter() SUCCESS');
      } catch(e) {
        debugPrint('[DEBUG] Step 1: Hive.initFlutter() FAILED: $e — continuing anyway');
      }

      // Step 2: 打开存储 Box
      debugPrint('[DEBUG] Step 2: updating state -> 正在打开数据存储...');
      ref.read(startupStateProvider.notifier).state =
          StartupState.loading('正在打开数据存储...');
      debugPrint('[DEBUG] Step 2: HiveStorage() constructing...');
      final hiveStorage = HiveStorage();
      debugPrint('[DEBUG] Step 2: hiveStorage.init() starting...');
      await hiveStorage.init();
      debugPrint('[DEBUG] Step 2: hiveStorage.init() DONE');

      // Step 3: 数据源 & 仓库
      debugPrint('[DEBUG] Step 3: updating state -> 正在连接数据服务...');
      ref.read(startupStateProvider.notifier).state =
          StartupState.loading('正在连接数据服务...');
      debugPrint('[DEBUG] Step 3: EastMoneyDataSource() constructing...');
      final dataSource = EastMoneyDataSource();
      final repository = StockRepositoryImpl(dataSource);
      debugPrint('[DEBUG] Step 3: repository constructed');

      // Step 4: 服务初始化
      debugPrint('[DEBUG] Step 4: updating state -> 正在初始化播报服务...');
      ref.read(startupStateProvider.notifier).state =
          StartupState.loading('正在初始化播报服务...');
      debugPrint('[DEBUG] Step 4: creating DeduplicationService...');
      final dedupService = DeduplicationService(hiveStorage);
      debugPrint('[DEBUG] Step 4: creating InterruptionManager...');
      final interruptMgr = InterruptionManager();
      debugPrint('[DEBUG] Step 4: creating AnnouncementScheduler...');
      final scheduler = AnnouncementScheduler(dedupService, interruptMgr);
      debugPrint('[DEBUG] Step 4: scheduler constructed');

      // Step 5: TTS 初始化
      debugPrint('[DEBUG] Step 5: updating state -> 正在初始化语音引擎...');
      ref.read(startupStateProvider.notifier).state =
          StartupState.loading('正在初始化语音引擎...');
      debugPrint('[DEBUG] Step 5: SystemTtsImpl() constructing...');
      final ttsService = SystemTtsImpl();
      debugPrint('[DEBUG] Step 5: ttsService.init() starting...');
      await ttsService.init();
      debugPrint('[DEBUG] Step 5: ttsService.init() DONE');

      // Step 6: 市场监控
      debugPrint('[DEBUG] Step 6: updating state -> 正在启动行情监控...');
      ref.read(startupStateProvider.notifier).state =
          StartupState.loading('正在启动行情监控...');
      debugPrint('[DEBUG] Step 6: MarketMonitor() constructing...');
      final marketMonitor = MarketMonitor(dataSource, scheduler, hiveStorage);

      // 注册播报监听（独立 try-catch）
      debugPrint('[DEBUG] Step 7: registering announcement stream listener...');
      try {
        _announcementSub = scheduler.announcementStream.listen((announcement) {
          ttsService.speak(announcement.content);
        });
        debugPrint('[DEBUG] Step 7: stream listener registered OK');
      } catch (e) {
        debugPrint('[DEBUG] Step 7: stream listen FAILED: $e');
      }

      // 组装服务对象
      debugPrint('[DEBUG] Step 8: assembling AppServices...');
      final services = AppServices(
        hiveStorage: hiveStorage,
        dataSource: dataSource,
        repository: repository,
        dedupService: dedupService,
        interruptMgr: interruptMgr,
        scheduler: scheduler,
        ttsService: ttsService,
        marketMonitor: marketMonitor,
      );
      debugPrint('[DEBUG] Step 8: AppServices assembled');

      // 市场监控启动
      debugPrint('[DEBUG] Step 9: marketMonitor.start() starting...');
      try {
        await marketMonitor.start().timeout(
          const Duration(seconds: 10),
          onTimeout: () => debugPrint('[DEBUG] Step 9: marketMonitor.start() TIMEOUT (10s)'),
        );
        debugPrint('[DEBUG] Step 9: marketMonitor.start() DONE');
      } catch (e) {
        debugPrint('[DEBUG] Step 9: marketMonitor.start() FAILED: $e — continuing anyway');
      }

      // 注册 Provider
      debugPrint('[DEBUG] Step 10: setting appServicesProvider NOW');
      if (!mounted) { debugPrint('[DEBUG] Step 10: NOT mounted, skipping provider set'); return; }
      ref.read(appServicesProvider.notifier).state = services;
      debugPrint('[DEBUG] Step 10: appServicesProvider SET');
      ref.read(startupStateProvider.notifier).state = StartupState.done();
      debugPrint('[DEBUG] Step 10: startupStateProvider = done');

      // 切换到主页
      debugPrint('[DEBUG] Step 11: pushing HomePage...');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        debugPrint('[DEBUG] Step 11: Navigator.pushReplacement CALLED');
      } else {
        debugPrint('[DEBUG] Step 11: NOT mounted, skipping navigation');
      }
    } catch (e, st) {
      // 捕获所有初始化错误，显示错误界面
      debugPrint('[DEBUG] CRASH: $e\n$st');
      if (!mounted) return;
      ref.read(startupStateProvider.notifier).state =
          StartupState.error('${e.runtimeType}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(startupStateProvider);

    if (state.status == StartupStatus.error) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 72, color: Color(0xFFE53935)),
                const SizedBox(height: 24),
                const Text(
                  '启动失败',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121)),
                ),
                const SizedBox(height: 12),
                Text(
                  state.error ?? '未知错误',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF757575)),
                ),
                const SizedBox(height: 32),
                const Text(
                  '请截屏此页面，反馈给开发者',
                  style: TextStyle(fontSize: 12, color: Color(0xFFBDBDBD)),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(startupStateProvider.notifier).state =
                        StartupState.loading('正在重试...');
                    _initApp();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.status == StartupStatus.done) {
      if (!_navigated) {
        _navigated = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
      return const SizedBox.shrink();
    }

    // 启动画面
    return Scaffold(
      backgroundColor: const Color(0xFFE53935),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hearing,
                  size: 80, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                '听股通',
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4),
              ),
              const SizedBox(height: 8),
              const Text(
                '专业语音助手',
                style: TextStyle(
                    fontSize: 14, color: Colors.white70, letterSpacing: 2),
              ),
              const SizedBox(height: 48),
              if (state.status == StartupStatus.loading) ...[
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _announcementSub?.cancel();
    super.dispose();
  }
}
