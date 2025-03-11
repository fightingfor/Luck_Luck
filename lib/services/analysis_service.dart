import 'package:flutter/foundation.dart';
import '../models/ball_info.dart';
import '../models/analysis_stats.dart';
import 'database_service.dart';

class AnalysisService {
  final DatabaseService _databaseService;

  // 缓存分析结果
  Map<int, BallAnalysis> _redBallAnalysis = {};
  Map<int, BallAnalysis> _blueBallAnalysis = {};
  List<TrendData> _trendData = [];
  DateTime? _lastAnalysisTime;

  AnalysisService(this._databaseService) {
    _initializeAnalysis();
  }

  // 初始化分析
  Future<void> _initializeAnalysis() async {
    await analyzeHistoricalData();
  }

  // 分析历史数据
  Future<void> analyzeHistoricalData() async {
    try {
      // 获取所有历史数据
      final allData = await _databaseService.getAllBalls();
      if (allData.isEmpty) return;

      // 初始化分析对象
      _redBallAnalysis.clear();
      _blueBallAnalysis.clear();
      for (int i = 1; i <= 33; i++) {
        _redBallAnalysis[i] = BallAnalysis(i, BallType.red);
      }
      for (int i = 1; i <= 16; i++) {
        _blueBallAnalysis[i] = BallAnalysis(i, BallType.blue);
      }

      // 分析每一期数据
      for (int i = 0; i < allData.length; i++) {
        final ball = allData[i];
        _analyzePeriod(ball, i, allData.length);
      }

      // 生成走势数据
      _generateTrendData(allData);

      _lastAnalysisTime = DateTime.now();
    } catch (e) {
      debugPrint('分析历史数据时出错: $e');
    }
  }

  // 分析单期数据
  void _analyzePeriod(BallInfo ball, int index, int totalPeriods) {
    // 分析红球
    for (int i = 0; i < ball.redBalls.length; i++) {
      final number = ball.redBalls[i];
      final analysis = _redBallAnalysis[number]!;
      analysis.updateStats(index, i, totalPeriods);
    }

    // 分析蓝球
    final blueAnalysis = _blueBallAnalysis[ball.blueBall]!;
    blueAnalysis.updateStats(index, 0, totalPeriods);
  }

  // 生成走势数据
  void _generateTrendData(List<BallInfo> data) {
    _trendData = data
        .map((ball) => TrendData(
              qh: ball.qh,
              drawDate: DateTime.parse(ball.kjTime),
              redBalls: ball.redBalls,
              blueBall: ball.blueBall,
            ))
        .toList();
  }

  // 获取号码分析结果
  BallAnalysis? getBallAnalysis(int number, BallType type) {
    return type == BallType.red
        ? _redBallAnalysis[number]
        : _blueBallAnalysis[number];
  }

  // 获取所有红球分析
  List<BallAnalysis> getAllRedBallAnalysis() {
    return _redBallAnalysis.values.toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
  }

  // 获取所有蓝球分析
  List<BallAnalysis> getAllBlueBallAnalysis() {
    return _blueBallAnalysis.values.toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
  }

  // 获取走势数据
  List<TrendData> getTrendData([int limit = 30]) {
    return _trendData.take(limit).toList();
  }

  // 获取热门号码
  List<BallAnalysis> getHotNumbers(BallType type, [int limit = 5]) {
    final analysis =
        type == BallType.red ? _redBallAnalysis : _blueBallAnalysis;
    return analysis.values.toList()
      ..sort((a, b) => b.frequency.compareTo(a.frequency))
      ..take(limit);
  }

  // 获取冷门号码
  List<BallAnalysis> getColdNumbers(BallType type, [int limit = 5]) {
    final analysis =
        type == BallType.red ? _redBallAnalysis : _blueBallAnalysis;
    return analysis.values.toList()
      ..sort((a, b) => b.currentMissing.compareTo(a.currentMissing))
      ..take(limit);
  }

  // 获取遗漏值分析
  Map<int, int> getMissingValueAnalysis(BallType type) {
    final analysis =
        type == BallType.red ? _redBallAnalysis : _blueBallAnalysis;
    return Map.fromEntries(
        analysis.entries.map((e) => MapEntry(e.key, e.value.currentMissing)));
  }

  // 获取位置偏好分析（仅红球）
  List<Map<int, int>> getPositionPreference() {
    List<Map<int, int>> result = List.generate(6, (index) => {});
    for (var analysis in _redBallAnalysis.values) {
      for (int i = 0; i < 6; i++) {
        result[i][analysis.number] = analysis.positionFrequency[i];
      }
    }
    return result;
  }

  // 检查是否需要更新分析
  bool needsUpdate() {
    if (_lastAnalysisTime == null) return true;
    return DateTime.now().difference(_lastAnalysisTime!) >
        const Duration(hours: 1);
  }
}
