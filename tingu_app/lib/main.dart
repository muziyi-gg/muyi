import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/storage/hive_storage.dart';
import 'core/data/datasources/eastmoney_datasource.dart';
import 'core/data/repositories/stock_repository_impl.dart';
import 'core/services/scheduler/deduplication_service.dart';
import 'core/services/scheduler/interruption_manager.dart';
import 'core/services/scheduler/announcement_scheduler.dart';
import 'core/services/tts/tts_service.dart';
import 'core/services/monitor/market_monitor.dart';
import 'core/ui/pages/home_page.dart';

/// 全局服务容器
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

/// 全局服务 Provider
final appServicesProvider = Provider<AppServices>((ref) {
  throw UnimplementedError('AppServices not initialized');
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // 初始化 Hive
<<<<<<< HEAD:tingu_app/lib/main.dart
  await Hive.initFlutter();
=======
  Hive.initFlutter();
>>>>>>> ac86b8a (fix: 修复 Hive 初始化、NDK 版本、import 路径及剩余编译错误):lib/main.dart

  // 初始化存储
  final hiveStorage = HiveStorage();
  await hiveStorage.init();

  // 初始化数据源
  final dataSource = EastMoneyDataSource();
  final repository = StockRepositoryImpl(dataSource);

  // 初始化服务
  final dedupService = DeduplicationService(hiveStorage);
  final interruptMgr = InterruptionManager();
  final scheduler = AnnouncementScheduler(dedupService, interruptMgr);
  final ttsService = SystemTtsImpl();
  await ttsService.init();

  // 初始化市场监控
  final marketMonitor = MarketMonitor(dataSource, scheduler, hiveStorage);

  // 监听调度器事件，播放 TTS
  scheduler.announcementStream.listen((announcement) {
    ttsService.speak(announcement.content);
  });

  // 创建 AppServices
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

  // 启动市场监控
  await marketMonitor.start();

  runApp(
    ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(services),
      ],
      child: const TingUApp(),
    ),
  );
}

class TingUApp extends StatelessWidget {
  const TingUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
