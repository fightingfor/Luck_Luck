import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucky_lucky/pages/splash_page.dart';
import 'package:lucky_lucky/providers/ball_provider.dart';
import 'package:lucky_lucky/providers/prediction_provider.dart';
import 'package:lucky_lucky/providers/analysis_provider.dart';
import 'package:lucky_lucky/services/database_service.dart';
import 'package:lucky_lucky/services/network_service.dart';
import 'package:lucky_lucky/services/analysis_service.dart';
import 'package:lucky_lucky/services/prediction_service.dart';

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
  final predictionService = PredictionService(databaseService);
  final prefs = await SharedPreferences.getInstance();

  runApp(MyApp(
    databaseService: databaseService,
    networkService: networkService,
    predictionService: predictionService,
    prefs: prefs,
  ));
}

class MyApp extends StatelessWidget {
  final DatabaseService databaseService;
  final NetworkService networkService;
  final PredictionService predictionService;
  final SharedPreferences prefs;

  const MyApp({
    super.key,
    required this.databaseService,
    required this.networkService,
    required this.predictionService,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BallProvider(
            databaseService,
            networkService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PredictionProvider(
            databaseService,
            prefs,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalysisProvider(
            AnalysisService(databaseService),
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
          home: SplashPage(
            databaseService: databaseService,
            networkService: networkService,
            predictionService: predictionService,
          ),
        ),
      ),
    );
  }
}
