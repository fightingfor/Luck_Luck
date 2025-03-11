import 'dart:math' as math;
import '../models/ball_info.dart';
import '../models/prediction_stats.dart' hide NumberFeatures;
import '../models/analysis_stats.dart';
import '../models/prediction_result.dart';
import 'database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PredictionService {
  final DatabaseService _databaseService;
  final math.Random _random = math.Random();

  // 统计数据
  final Map<int, BallStats> _redBallStats = {};
  final Map<int, BallStats> _blueBallStats = {};
  List<PeriodStats> _recentPeriods = [];
  List<PredictionResult> _predictionHistory = [];
  int _analyzedCount = 0;

  // 配置参数
  static const int _analyzePeriods = 50; // 分析最近50期
  static const int _historicalYears = 5; // 分析近5年同期数据

  PredictionService(this._databaseService) {
    // 初始化统计对象
    for (int i = 1; i <= 33; i++) {
      _redBallStats[i] = BallStats(i);
    }
    for (int i = 1; i <= 16; i++) {
      _blueBallStats[i] = BallStats(i);
    }
    _loadPredictionHistory();
  }

  DatabaseService get databaseService => _databaseService;

  // 重置统计数据
  void _resetStats() {
    _redBallStats.values.forEach((stats) => stats.reset());
    _blueBallStats.values.forEach((stats) => stats.reset());
    _recentPeriods.clear();
  }

  // 分析历史数据
  Future<void> analyzeHistoricalData() async {
    _resetStats();

    // 获取最近的开奖数据
    final recentBalls = await _databaseService.getBalls(0, _analyzePeriods);
    if (recentBalls.isEmpty) return;

    // 获取最新一期的信息
    final latestBall = recentBalls.first;
    final latestDate = DateTime.parse(latestBall.kjTime);

    // 分析最近N期数据
    for (int i = 0; i < recentBalls.length; i++) {
      final ball = recentBalls[i];
      _analyzePeriod(ball, i);
    }

    // 分析历史同期数据
    final historicalPeriods = await _getHistoricalPeriods(latestDate);
    _analyzeHistoricalPeriods(historicalPeriods);

    // 计算统计指标
    _calculateStats(recentBalls.length);
  }

  // 分析单期数据
  void _analyzePeriod(BallInfo ball, int index) {
    final periodStats = PeriodStats(
      periodNumber: ball.qh.toString(),
      redBalls: ball.redBalls,
      blueBall: ball.blueBall,
      drawDate: DateTime.parse(ball.kjTime),
    );
    periodStats.analyzePatterns();
    _recentPeriods.add(periodStats);

    // 更新红球统计
    for (int i = 0; i < ball.redBalls.length; i++) {
      final number = ball.redBalls[i];
      final stats = _redBallStats[number]!;
      stats.frequency++;
      stats.positionFreq[i]++;

      if (index == 0) {
        stats.currentGap = 0;
      }
    }

    // 更新蓝球统计
    final blueStats = _blueBallStats[ball.blueBall]!;
    blueStats.frequency++;
    if (index == 0) {
      blueStats.currentGap = 0;
    }
  }

  // 获取历史同期数据
  Future<List<BallInfo>> _getHistoricalPeriods(DateTime latestDate) async {
    List<BallInfo> historicalBalls = [];

    // 获取近5年同期数据
    for (int year = 1; year <= _historicalYears; year++) {
      final historicalDate = DateTime(
        latestDate.year - year,
        latestDate.month,
        latestDate.day,
      );

      // 获取该日期前后7天的开奖数据
      final weekBalls = await _databaseService.getBallsByDateRange(
        historicalDate.subtract(const Duration(days: 7)),
        historicalDate.add(const Duration(days: 7)),
      );

      historicalBalls.addAll(weekBalls);
    }

    return historicalBalls;
  }

  // 分析历史同期数据
  void _analyzeHistoricalPeriods(List<BallInfo> historicalBalls) {
    for (final ball in historicalBalls) {
      // 更新红球历史同期频率
      for (final number in ball.redBalls) {
        _redBallStats[number]!.historicalPeriodFreq++;
      }

      // 更新蓝球历史同期频率
      _blueBallStats[ball.blueBall]!.historicalPeriodFreq++;
    }
  }

  // 计算统计指标
  void _calculateStats(int totalPeriods) {
    // 计算红球统计指标
    for (final stats in _redBallStats.values) {
      _calculateBallStats(stats, totalPeriods);
    }

    // 计算蓝球统计指标
    for (final stats in _blueBallStats.values) {
      _calculateBallStats(stats, totalPeriods);
    }
  }

  // 计算单个号码的统计指标
  void _calculateBallStats(BallStats stats, int totalPeriods) {
    // 计算间隔指标
    int totalGap = 0;
    int maxGap = 0;
    int currentGap = 0;

    for (int i = 0; i < _recentPeriods.length; i++) {
      if (_recentPeriods[i].redBalls.contains(stats.number) ||
          _recentPeriods[i].blueBall == stats.number) {
        if (currentGap > maxGap) maxGap = currentGap;
        totalGap += currentGap;
        currentGap = 0;
      } else {
        currentGap++;
      }
    }

    stats.avgGap = totalGap / (stats.frequency > 0 ? stats.frequency : 1);
    stats.maxGap = maxGap;
    stats.currentGap = currentGap;

    // 计算权重
    _calculateWeight(stats, totalPeriods);
  }

  // 计算号码权重
  void _calculateWeight(BallStats stats, int totalPeriods) {
    // 基础权重
    stats.weight = 100;

    // 1. 频率权重（保持原有逻辑）
    final temperature = stats.getTemperature(totalPeriods);
    switch (temperature) {
      case 'hot':
        stats.weight += 20;
        break;
      case 'warm':
        stats.weight += 10;
        break;
      case 'cold':
        stats.weight += 5;
        break;
    }

    // 2. 间隔权重（优化）
    if (stats.currentGap > 0) {
      // 如果当前间隔超过平均间隔，增加权重
      if (stats.currentGap >= stats.avgGap) {
        stats.weight += (stats.currentGap - stats.avgGap) * 3;
      }
      // 如果接近最大间隔，显著增加权重
      if (stats.currentGap >= stats.maxGap * 0.8) {
        stats.weight += 15;
      }
    }

    // 3. 历史同期权重（优化）
    if (stats.historicalPeriodFreq > 0) {
      // 根据历史同期出现频率增加权重
      stats.weight += stats.historicalPeriodFreq * 8;

      // 如果历史同期出现频率较高，额外增加权重
      if (stats.historicalPeriodFreq >= 3) {
        stats.weight += 10;
      }
    }

    // 4. 位置权重（优化）
    if (stats.positionFreq.isNotEmpty) {
      // 计算位置频率的标准差
      double mean = stats.positionFreq.reduce((a, b) => a + b) /
          stats.positionFreq.length;
      double variance = stats.positionFreq
              .map((x) => math.pow(x - mean, 2))
              .reduce((a, b) => a + b) /
          stats.positionFreq.length;
      double stdDev = math.sqrt(variance);

      // 位置稳定性权重
      if (stdDev < 2) {
        // 位置比较稳定
        stats.weight += 15;
      }

      // 最高频率位置权重
      final maxPosFreq = stats.positionFreq.reduce(math.max);
      if (maxPosFreq > 0) {
        stats.weight += maxPosFreq * 3;
      }
    }

    // 5. 组合特征权重
    if (_recentPeriods.isNotEmpty) {
      final lastPeriod = _recentPeriods.first;

      // 计算上期号码特征
      final features = NumberFeatures.analyze(lastPeriod.redBalls);

      // 根据和值范围调整权重
      if (features.sum >= 90 && features.sum <= 120) {
        stats.weight += 5;
      }

      // 根据奇偶比例调整权重
      if (features.oddRatio >= 0.4 && features.oddRatio <= 0.6) {
        stats.weight += 5;
      }

      // 根据大小比例调整权重
      if (features.bigRatio >= 0.4 && features.bigRatio <= 0.6) {
        stats.weight += 5;
      }
    }

    // 6. 衰减因子
    // 根据数据的时间远近调整权重
    double decayFactor = 1.0;
    for (int i = 0; i < _recentPeriods.length; i++) {
      if (_recentPeriods[i].redBalls.contains(stats.number)) {
        decayFactor = 1.0 - (i * 0.02); // 每期衰减2%
        break;
      }
    }
    stats.weight *= decayFactor;
  }

  // 获取下一期期号
  Future<int> _getNextPeriodNumber() async {
    final latestBall = await _databaseService.getLatestBall();
    if (latestBall == null) return 2024001;

    return latestBall.qh + 1;
  }

  // 生成预测结果
  Future<PredictionResult> generatePrediction() async {
    await analyzeHistoricalData();

    // 使用轮盘赌算法选择红球
    List<int> selectedRed = [];
    List<int> availableRed = List.generate(33, (i) => i + 1);

    while (selectedRed.length < 6) {
      final selected = _selectBallByWeight(
        availableRed,
        availableRed.map((n) => _redBallStats[n]!.weight).toList(),
      );
      selectedRed.add(selected);
      availableRed.remove(selected);
    }

    // 选择蓝球
    final blueBall = _selectBallByWeight(
      List.generate(16, (i) => i + 1),
      List.generate(16, (i) => _blueBallStats[i + 1]!.weight),
    );

    // 获取下一期期号
    final nextPeriod = await _getNextPeriodNumber();

    // 创建预测结果
    final prediction = PredictionResult(
      redBalls: selectedRed..sort(),
      blueBall: blueBall,
      predictDate: DateTime.now(),
      periodNumber: nextPeriod.toString().padLeft(7, '0'),
    );

    _predictionHistory.add(prediction);
    await _savePredictionHistory();
    return prediction;
  }

  // 使用轮盘赌算法选择号码
  int _selectBallByWeight(List<int> numbers, List<double> weights) {
    final totalWeight = weights.reduce((a, b) => a + b);
    double random = _random.nextDouble() * totalWeight;

    for (int i = 0; i < numbers.length; i++) {
      random -= weights[i];
      if (random <= 0) {
        return numbers[i];
      }
    }

    return numbers.last;
  }

  // 获取预测历史
  List<PredictionResult> getPredictionHistory() {
    return List.from(_predictionHistory);
  }

  // 获取已分析的数据数量
  int getAnalyzedCount() {
    return _recentPeriods.length;
  }

  // 获取预测准确率
  Map<String, double> getPredictionAccuracy() {
    if (_predictionHistory.isEmpty) {
      return {
        'red_accuracy': 0.0,
        'blue_accuracy': 0.0,
        'total_accuracy': 0.0,
      };
    }

    double redTotal = 0.0;
    double blueTotal = 0.0;
    int count = 0;

    for (final prediction in _predictionHistory) {
      if (prediction.accuracyDetails.isNotEmpty) {
        redTotal += prediction.accuracyDetails['red_accuracy'] ?? 0.0;
        blueTotal += prediction.accuracyDetails['blue_accuracy'] ?? 0.0;
        count++;
      }
    }

    if (count == 0)
      return {'red_accuracy': 0.0, 'blue_accuracy': 0.0, 'total_accuracy': 0.0};

    return {
      'red_accuracy': redTotal / count,
      'blue_accuracy': blueTotal / count,
      'total_accuracy': (redTotal + blueTotal) / (count * 2),
    };
  }

  /// 从持久化存储加载预测历史
  Future<void> _loadPredictionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('prediction_history');
    if (historyJson != null) {
      final List<dynamic> historyList = jsonDecode(historyJson);
      _predictionHistory =
          historyList.map((json) => PredictionResult.fromJson(json)).toList();
    }
  }

  /// 保存预测历史到持久化存储
  Future<void> _savePredictionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _predictionHistory.map((p) => p.toJson()).toList();
    await prefs.setString('prediction_history', jsonEncode(historyJson));
  }

  /// 清除所有历史预测记录
  Future<void> clearPredictionHistory() async {
    _predictionHistory.clear();
    await _savePredictionHistory();
  }
}
