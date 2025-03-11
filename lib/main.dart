import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucky_lucky/pages/main_page.dart';
import 'package:lucky_lucky/providers/ball_provider.dart';
import 'package:lucky_lucky/providers/prediction_provider.dart';
import 'package:lucky_lucky/providers/analysis_provider.dart';
import 'package:lucky_lucky/services/database_service.dart';
import 'package:lucky_lucky/services/network_service.dart';
import 'package:lucky_lucky/services/analysis_service.dart';
import 'package:lucky_lucky/services/prediction_service.dart';
import 'package:lucky_lucky/pages/home_page.dart';
import 'package:lucky_lucky/loadData.dart';
import 'package:lucky_lucky/models/ball_info.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 强制竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  final databaseService = DatabaseService();
  await databaseService.initialize();

  final networkService = NetworkService(databaseService);

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize prediction service
  final predictionService = PredictionService(databaseService);

  runApp(LoadingApp(
    databaseService: databaseService,
    networkService: networkService,
    predictionService: predictionService,
    prefs: prefs,
  ));
}

class LoadingApp extends StatefulWidget {
  final DatabaseService databaseService;
  final NetworkService networkService;
  final PredictionService predictionService;
  final SharedPreferences prefs;

  const LoadingApp({
    super.key,
    required this.databaseService,
    required this.networkService,
    required this.predictionService,
    required this.prefs,
  });

  @override
  State<LoadingApp> createState() => _LoadingAppState();
}

class _LoadingAppState extends State<LoadingApp> {
  List<BallInfo>? _initialData;
  String _loadingMessage = '';
  double _loadingProgress = 0.0;
  bool _isLoading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      debugPrint('开始初始化数据...');

      // 获取数据库中的数据量
      final count = await widget.databaseService.getCount();
      debugPrint('数据库中现有数据量: $count');

      // 如果数据量不足，从JSON文件加载历史数据
      if (count < 3223) {
        // 历史数据总量
        debugPrint('数据量不足，开始从JSON文件加载历史数据...');
        await initializeData(widget.databaseService, (message, progress) {
          setState(() {
            _loadingMessage = message;
            _loadingProgress = progress;
          });
        });
        debugPrint('JSON数据加载完成，重新获取数据库数量...');
        final newCount = await widget.databaseService.getCount();
        debugPrint('加载后数据库数量: $newCount');
      }

      // 获取最新一期的期号
      final lastQh = await widget.databaseService.getLastQh() ?? 0;
      debugPrint('当前最新期号: $lastQh');

      // 检查数据连续性
      final List<int> gaps = await widget.databaseService.findQhGaps();
      if (gaps.isNotEmpty) {
        debugPrint('数据连续性检查完成');
      } else {
        debugPrint('数据连续性检查通过');
      }

      // 获取最新数据
      await widget.networkService.fetchAndSaveNewData();
      debugPrint('网络更新完成');

      // 加载历史数据进行分析
      _initialData = await widget.databaseService.getLastNBalls(20);
      debugPrint('历史数据加载完成，数据条数: ${_initialData?.length ?? 0}');

      if (_initialData?.isEmpty ?? true) {
        throw Exception('无法加载历史数据');
      }

      // 分析历史数据
      try {
        await widget.predictionService.analyzeHistoricalData();
        debugPrint('历史数据分析完成');
      } catch (e) {
        debugPrint('分析历史数据失败，但继续执行: $e');
      }

      setState(() {
        _isLoading = false;
        _loadingMessage = '';
        _loadingProgress = 1.0;
      });
    } catch (e) {
      debugPrint('初始化数据时出错: $e');
      setState(() {
        _isLoading = false;
        _loadingMessage = '数据加载失败';
        _loadingProgress = 0.0;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = BallProvider(
              widget.databaseService,
              widget.networkService,
            );
            if (_initialData != null) {
              provider.setInitialData(_initialData!);
            }
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => PredictionProvider(
            widget.databaseService,
            widget.prefs,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalysisProvider(
            AnalysisService(widget.databaseService),
          ),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp(
          title: '双色球智能预测',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.grey[100],
            useMaterial3: true,
            cardTheme: CardTheme(
              elevation: 2,
              margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            cardTheme: CardTheme(
              elevation: 2,
              margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          home: const MainPage(),
        ),
      ),
    );
  }
}
