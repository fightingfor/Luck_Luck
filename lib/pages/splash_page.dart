import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../services/database_service.dart';
import '../services/network_service.dart';
import '../services/prediction_service.dart';
import '../loadData.dart';
import 'main_page.dart';

class SplashPage extends StatefulWidget {
  final DatabaseService databaseService;
  final NetworkService networkService;
  final PredictionService predictionService;

  const SplashPage({
    super.key,
    required this.databaseService,
    required this.networkService,
    required this.predictionService,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _loadingMessage = '正在初始化...';
  double _progress = 0.0;
  bool _isError = false;
  String _errorMessage = '';
  Timer? _timeoutTimer;

  static const int TIMEOUT_SECONDS = 30; // 超时时间设置为30秒

  @override
  void initState() {
    super.initState();

    // 初始化动画
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // 设置超时定时器
    _timeoutTimer = Timer(Duration(seconds: TIMEOUT_SECONDS), () {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = '数据加载超时，请检查网络连接后重试';
        });
      }
    });

    // 开始数据加载
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // 1. 检查并加载基础数据
      setState(() {
        _loadingMessage = '正在加载基础数据...';
        _progress = 0.2;
      });

      await initializeData(
        widget.databaseService,
        (message, progress) {
          if (mounted) {
            setState(() {
              _loadingMessage = message;
              _progress = 0.2 + progress * 0.3; // 基础数据加载占30%进度
            });
          }
        },
      );

      // 2. 确保数据完整性
      setState(() {
        _loadingMessage = '正在验证数据完整性...';
        _progress = 0.5;
      });

      final count = await widget.databaseService.getCount();
      if (count < MINIMUM_DATA_COUNT) {
        throw Exception('数据加载不完整');
      }

      // 3. 分析历史数据
      setState(() {
        _loadingMessage = '正在分析历史数据...';
        _progress = 0.7;
      });

      await widget.predictionService.analyzeHistoricalData();

      // 4. 获取最新数据
      setState(() {
        _loadingMessage = '正在同步最新数据...';
        _progress = 0.9;
      });

      await widget.networkService.fetchAndSaveNewData();

      // 5. 完成加载
      setState(() {
        _loadingMessage = '加载完成';
        _progress = 1.0;
      });

      // 取消超时定时器
      _timeoutTimer?.cancel();

      // 延迟一小段时间以显示完成状态
      await Future.delayed(const Duration(milliseconds: 500));

      // 确保所有数据都已加载完成后跳转
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = '数据加载失败: \${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.lightBlue],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo或应用名称
                Text(
                  '双色球智能预测',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 50.h),

                // 加载动画
                if (!_isError) ...[
                  RotationTransition(
                    turns: _animation,
                    child: Icon(
                      Icons.refresh,
                      size: 50.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // 进度条
                  Container(
                    width: 200.w,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 10,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // 加载信息
                  Text(
                    _loadingMessage,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white70,
                    ),
                  ),
                ] else ...[
                  // 错误显示
                  Icon(
                    Icons.error_outline,
                    size: 50.sp,
                    color: Colors.red,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30.h),

                  // 重试按钮
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isError = false;
                        _progress = 0.0;
                        _loadingMessage = '正在初始化...';
                      });
                      _initializeData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: 30.w, vertical: 15.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      '重新加载',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
