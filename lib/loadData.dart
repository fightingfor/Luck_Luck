import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:lucky_lucky/models/ball_info.dart';
import 'package:lucky_lucky/services/database_service.dart';
import 'package:lucky_lucky/services/network_service.dart';
import 'package:lucky_lucky/services/prediction_service.dart';
import 'package:flutter/foundation.dart';

const int MINIMUM_DATA_COUNT = 3223; // JSON文件中的数据量

typedef LoadingProgressCallback = void Function(
    String message, double progress);

/// 加载本地 json 数据
Future<List<BallInfo>> loadJsonData() async {
  try {
    // 读取本地JSON文件
    final String jsonString =
        await rootBundle.loadString('assets/AllBallsInfo.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    print('从JSON文件加载了 ${jsonList.length} 条数据');

    // 按期号排序
    jsonList.sort((a, b) =>
        int.parse(a['qh'].toString()).compareTo(int.parse(b['qh'].toString())));

    // 检查期号连续性，但不打印间隔
    for (int i = 0; i < jsonList.length - 1; i++) {
      int currentQh = int.parse(jsonList[i]['qh'].toString());
      int nextQh = int.parse(jsonList[i + 1]['qh'].toString());
      if (nextQh - currentQh > 1) {
        // 检查到间隔但不打印
        continue;
      }
    }

    print('数据条数: ${jsonList.length}');
    return jsonList.map((item) => BallInfo.fromJson(item)).toList();
  } catch (e) {
    print('加载JSON数据时出错: $e');
    return [];
  }
}

/// 初始化数据
/// 这个方法应该在App启动时调用
Future<void> initializeData(
  DatabaseService dbService,
  LoadingProgressCallback? onProgress,
) async {
  try {
    // 检查数据库
    onProgress?.call('正在检查数据库...', 0.0);
    final count = await dbService.getCount();

    // 如果数据库为空或数据不足，从JSON文件加载
    if (count < MINIMUM_DATA_COUNT) {
      onProgress?.call('正在从JSON文件加载数据...', 0.2);
      final jsonData = await loadJsonData();

      onProgress?.call('正在保存数据到数据库...', 0.4);
      for (var ball in jsonData) {
        await dbService.insertBall(ball);
      }
    }

    // 获取最新一期数据
    final latestBall = await dbService.getLatestBall();
    final latestQh = latestBall?.qh ?? 0;

    // 检查网络更新
    onProgress?.call('正在检查网络更新...', 0.6);
    final networkService = NetworkService(dbService);
    await networkService.fetchAndSaveNewData();

    onProgress?.call('数据初始化完成', 1.0);
  } catch (e) {
    debugPrint('初始化数据时出错: $e');
    rethrow;
  }
}

/// 检查数据库
Future<void> checkDatabase() async {
  final dbService = DatabaseService();
  await dbService.initialize();

  final count = await dbService.getCount();
  print('数据库中共有 $count 条数据');

  final balls = await dbService.getBalls(0, 20);
  if (balls.isNotEmpty) {
    print('最新一期: ${balls.first}');
  }
}

String removeLeadingZero(String number) {
  if (number.startsWith('0')) {
    return number.substring(1);
  }
  return number;
}

String extractJsonData(String response) {
  int startIndex = response.indexOf('(') + 1;
  int endIndex = response.lastIndexOf(')');
  if (startIndex > 0 && endIndex > startIndex) {
    return response.substring(startIndex, endIndex);
  }
  return response;
}

class DataLoader {
  final DatabaseService databaseService;
  final NetworkService networkService;
  final PredictionService predictionService;
  final LoadingProgressCallback? onLoadingProgress;

  DataLoader({
    required this.databaseService,
    required this.networkService,
    required this.predictionService,
    this.onLoadingProgress,
  });

  Future<void> loadData() async {
    try {
      // 获取最新一期数据
      final latestBall = await databaseService.getLatestBall();
      final latestQh = latestBall?.qh ?? 0;
      debugPrint('当前最新期号: $latestQh');

      // 检查网络更新
      onLoadingProgress?.call('正在检查网络更新...', 0.6);
      try {
        await networkService.fetchAndSaveNewData();
      } catch (e) {
        debugPrint('网络更新失败，但继续执行: $e');
      }

      // 获取最新数据
      onLoadingProgress?.call('正在获取最新数据...', 0.8);
      try {
        await predictionService.analyzeHistoricalData();
      } catch (e) {
        debugPrint('分析历史数据失败，但继续执行: $e');
      }

      onLoadingProgress?.call('数据初始化完成', 1.0);
    } catch (e) {
      debugPrint('加载数据时出错，但继续执行: $e');
    }
  }
}
