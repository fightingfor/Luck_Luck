import 'dart:convert';
import 'dart:isolate';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/ball_info.dart';
import 'database_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NetworkService {
  final DatabaseService _databaseService;
  Timer? _timer;
  Function(String, double)? onLoadingProgress;
  late Dio _dio;

  NetworkService(this._databaseService) {
    _dio = Dio();
  }

  void startBackgroundUpdate() {
    // 每5分钟检查一次更新
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      // 获取当前时间
      final now = DateTime.now();

      // 判断是否是开奖时间（每周二、四、日的21:15-22:00）
      bool isDrawTime = false;
      if ((now.weekday == 2 || now.weekday == 4 || now.weekday == 7) &&
          ((now.hour == 21 && now.minute >= 15) ||
              (now.hour == 21 && now.minute < 60))) {
        isDrawTime = true;
      }

      // 如果是开奖时间，每分钟检查一次
      if (isDrawTime) {
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
          checkForUpdates();
        });
      } else {
        checkForUpdates();
      }
    });
  }

  void stopBackgroundUpdate() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> checkForUpdates() async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 10);

    while (retryCount < maxRetries) {
      try {
        final response = await http.get(
          Uri.parse(
              'https://www.cwl.gov.cn/cwl_admin/front/cwlkj/search/kjxx/findDrawNotice?name=ssq&issueCount=1'),
          headers: {
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
            'Accept-Language': 'zh-CN,zh;q=0.9,vi;q=0.8,en;q=0.7',
            'Cache-Control': 'max-age=0',
            'Connection': 'keep-alive',
            'Cookie':
                'HMF_CI=a435e384b43cc5f713b156b20f1c576a8c009be6f6fc940a60367092cf00ed304266283e998afb65c447df15dfffa0283a7caac46cb98fea240cfda6004e3be52b',
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
            'sec-ch-ua':
                '"Not(A:Brand";v="99", "Google Chrome";v="133", "Chromium";v="133"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          debugPrint('Response data: $data');

          if (data['result'] != null && data['result'].isNotEmpty) {
            final latestDraw = data['result'][0];
            final latestQh = int.parse(latestDraw['code']);
            final lastQh = await _databaseService.getLastQh() ?? 0;

            if (latestQh > lastQh) {
              await fetchAndSaveNewData();
            }
          }
          break; // 成功后跳出循环
        } else {
          throw Exception('HTTP错误: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        debugPrint('检查更新时出错 (尝试 $retryCount/$maxRetries): $e');

        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }
  }

  Future<void> fetchAndSaveNewData() async {
    try {
      debugPrint('开始获取最新数据...');

      // 获取数据库中最新一期的数据
      final latestBall = await _databaseService.getLatestBall();
      if (latestBall != null) {
        debugPrint('数据库最新一期: ${latestBall.qh} (${latestBall.kjTime})');
      } else {
        debugPrint('数据库中暂无数据');
      }

      // 获取最新50期数据，确保不会遗漏
      final response = await _dio.get(
        'https://www.cwl.gov.cn/cwl_admin/front/cwlkj/search/kjxx/findDrawNotice',
        queryParameters: {
          'name': 'ssq',
          'issueCount': '50',
          'orderBy': 'code',
          'orderType': 'desc',
        },
        options: Options(
          headers: {
            'Accept': '*/*',
            'Accept-Language': 'zh-CN,zh;q=0.9',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
            'Cookie': 'HMF_CI=a2c6125b4e7b2d7c3a9e0e0d8d4f8e7c',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          },
        ),
      );

      debugPrint('API响应: ${response.data}');
      final data = response.data;
      if (data['state'] != 0) {
        throw Exception('API返回错误: ${data['message']}');
      }

      if (data['result'] == null) {
        throw Exception('API返回数据格式错误: 缺少result字段');
      }

      final results = data['result'] as List;
      debugPrint('获取到 ${results.length} 条数据');

      // 按期号排序，确保按顺序处理
      results
          .sort((a, b) => int.parse(a['code']).compareTo(int.parse(b['code'])));

      // 记录处理过的期号，避免重复
      Set<int> processedQh = {};

      for (final item in results) {
        try {
          String code = item['code'] ?? '';
          if (code.isEmpty) {
            debugPrint('警告: 期号为空，跳过该记录');
            continue;
          }

          int currentQh = int.parse(code);

          // 如果这个期号已经处理过，跳过
          if (processedQh.contains(currentQh)) {
            debugPrint('期号 $currentQh 已处理过，跳过');
            continue;
          }
          processedQh.add(currentQh);

          // 解析日期，格式为 "2025-03-09(日)"
          String dateStr = item['date'] ?? '';
          if (dateStr.isEmpty) {
            debugPrint('警告: 日期为空，跳过该记录');
            continue;
          }
          String formattedDate = dateStr.substring(0, 10);

          debugPrint('处理期号: $currentQh, 开奖日期: $formattedDate');

          // 解析红球和蓝球
          String redBallsStr = item['red'] ?? '';
          if (redBallsStr.isEmpty) {
            debugPrint('警告: 红球数据为空，跳过该记录');
            continue;
          }
          List<int> redBalls =
              redBallsStr.split(',').map((s) => int.parse(s.trim())).toList();

          String blueStr = item['blue'] ?? '';
          if (blueStr.isEmpty) {
            debugPrint('警告: 蓝球数据为空，跳过该记录');
            continue;
          }
          int blueBall = int.parse(blueStr);

          // 创建并保存开奖信息
          final ballInfo = BallInfo(
            qh: currentQh,
            kjTime: formattedDate,
            zhou: item['week'] ?? '',
            redBalls: redBalls,
            blueBall: blueBall,
          );

          await _databaseService.insertBall(ballInfo);
          debugPrint('成功保存开奖信息: $ballInfo');
        } catch (e) {
          debugPrint('处理单条数据时出错: $e');
          debugPrint('问题数据: $item');
          continue;
        }
      }
      debugPrint('数据保存完成');
    } catch (e) {
      debugPrint('获取或保存数据时出错: $e');
      rethrow;
    }
  }

  String removeLeadingZero(String number) {
    if (number.startsWith('0')) {
      return number.substring(1);
    }
    return number;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
