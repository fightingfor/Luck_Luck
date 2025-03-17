import 'dart:math' as math;
import '../models/ball_info.dart';
import '../models/prediction_stats.dart' hide NumberFeatures, BallStats;
import '../models/analysis_stats.dart';
import '../models/prediction_result.dart';
import '../models/ball_stats.dart';
import '../models/betting_strategy.dart';
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

  // 配置参数 - 增加分析维度
  static const int _analyzePeriods = 100; // 分析最近100期
  static const int _historicalYears = 10; // 分析近10年同期数据
  static const int _shortTermPeriods = 30; // 短期分析30期
  static const int _mediumTermPeriods = 50; // 中期分析50期
  static const double _confidenceThreshold = 0.7; // 置信度阈值

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

  // 增强的历史数据分析
  Future<void> analyzeHistoricalData() async {
    _resetStats();

    // 1. 获取最近的开奖数据
    final recentBalls = await _databaseService.getBalls(0, _analyzePeriods);
    if (recentBalls.isEmpty) return;

    // 2. 获取最新一期的信息
    final latestBall = recentBalls.first;
    final latestDate = DateTime.parse(latestBall.kjTime);

    // 3. 分析最近期数据
    for (int i = 0; i < recentBalls.length; i++) {
      final ball = recentBalls[i];
      _analyzePeriod(ball, i);
    }

    // 4. 分析历史同期数据
    final historicalPeriods = await _getHistoricalPeriods(latestDate);
    _analyzeHistoricalPeriods(historicalPeriods);

    // 5. 分析短期趋势
    await _analyzeShortTermTrends(recentBalls.take(_shortTermPeriods).toList());

    // 6. 分析中期趋势
    await _analyzeMediumTermTrends(
        recentBalls.take(_mediumTermPeriods).toList());

    // 7. 分析长期趋势
    await _analyzeLongTermTrends(historicalPeriods);

    // 8. 计算统计指标
    _calculateStats(recentBalls.length);
  }

  // 分析单期数据 - 增强版
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

      // 记录位置偏好
      stats.positionPreference = i;

      // 记录相邻号码
      if (i > 0) stats.adjacentNumbers.add(ball.redBalls[i - 1]);
      if (i < ball.redBalls.length - 1)
        stats.adjacentNumbers.add(ball.redBalls[i + 1]);

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

    // 分析号码组合特征
    _analyzeCombinationFeatures(ball);
  }

  // 分析号码组合特征
  void _analyzeCombinationFeatures(BallInfo ball) {
    // 计算和值
    int sum = ball.redBalls.reduce((a, b) => a + b);

    // 计算跨度
    int span = ball.redBalls.reduce(math.max) - ball.redBalls.reduce(math.min);

    // 计算奇偶比
    int oddCount = ball.redBalls.where((n) => n % 2 == 1).length;
    double oddEvenRatio = oddCount / ball.redBalls.length;

    // 计算大小比（以17为界）
    int bigCount = ball.redBalls.where((n) => n > 17).length;
    double bigSmallRatio = bigCount / ball.redBalls.length;

    // 计算连号个数
    int consecutiveCount = 0;
    for (int i = 0; i < ball.redBalls.length - 1; i++) {
      if (ball.redBalls[i + 1] - ball.redBalls[i] == 1) {
        consecutiveCount++;
      }
    }

    // 更新组合特征统计
    _updateCombinationStats(
      sum: sum,
      span: span,
      oddEvenRatio: oddEvenRatio,
      bigSmallRatio: bigSmallRatio,
      consecutiveCount: consecutiveCount,
    );
  }

  // 分析短期趋势
  Future<void> _analyzeShortTermTrends(List<BallInfo> balls) async {
    for (var ball in balls) {
      // 分析近期热号
      _analyzeHotNumbers(ball);

      // 分析近期冷号
      _analyzeColdNumbers(ball);

      // 分析近期遗漏
      _analyzeRecentGaps(ball);
    }
  }

  // 分析中期趋势
  Future<void> _analyzeMediumTermTrends(List<BallInfo> balls) async {
    // 分析号码周期性
    _analyzePeriodicity(balls);

    // 分析位置偏好
    _analyzePositionPreference(balls);

    // 分析组合特征趋势
    _analyzeCombinationTrends(balls);
  }

  // 分析长期趋势
  Future<void> _analyzeLongTermTrends(List<BallInfo> balls) async {
    // 分析号码长期表现
    _analyzeLongTermPerformance(balls);

    // 分析季节性特征
    _analyzeSeasonality(balls);

    // 分析历史同期特征
    _analyzeHistoricalPatterns(balls);
  }

  // 计算号码权重 - 增强版
  void _calculateWeight(BallStats stats, int totalPeriods) {
    // 基础权重
    stats.weight = 100;

    // 1. 频率权重 (20%)
    final temperature = stats.getTemperature(totalPeriods);
    switch (temperature) {
      case 'hot':
        stats.weight += 40;
        break;
      case 'warm':
        stats.weight += 20;
        break;
      case 'cold':
        stats.weight += 10;
        break;
    }

    // 2. 间隔权重 (15%)
    if (stats.currentGap > 0) {
      if (stats.currentGap >= stats.avgGap) {
        stats.weight += (stats.currentGap - stats.avgGap) * 5;
      }
      if (stats.currentGap >= stats.maxGap * 0.8) {
        stats.weight += 30;
      }
    }

    // 3. 历史同期权重 (15%)
    if (stats.historicalPeriodFreq > 0) {
      stats.weight += stats.historicalPeriodFreq * 10;
      if (stats.historicalPeriodFreq >= 3) {
        stats.weight += 20;
      }
    }

    // 4. 位置权重 (15%)
    if (stats.positionFreq.isNotEmpty) {
      double mean = stats.positionFreq.reduce((a, b) => a + b) /
          stats.positionFreq.length;
      double variance = stats.positionFreq
              .map((x) => math.pow(x - mean, 2))
              .reduce((a, b) => a + b) /
          stats.positionFreq.length;
      double stdDev = math.sqrt(variance);

      if (stdDev < 2) {
        stats.weight += 30;
      }

      final maxPosFreq = stats.positionFreq.reduce(math.max);
      if (maxPosFreq > 0) {
        stats.weight += maxPosFreq * 5;
      }
    }

    // 5. 组合特征权重 (15%)
    if (_recentPeriods.isNotEmpty) {
      final lastPeriod = _recentPeriods.first;
      final features = NumberFeatures.analyze(lastPeriod.redBalls);

      if (features.sum >= 90 && features.sum <= 120) {
        stats.weight += 10;
      }
      if (features.oddRatio >= 0.4 && features.oddRatio <= 0.6) {
        stats.weight += 10;
      }
      if (features.bigRatio >= 0.4 && features.bigRatio <= 0.6) {
        stats.weight += 10;
      }
    }

    // 6. 趋势权重 (10%)
    if (_isInPositiveTrend(stats.number)) {
      stats.weight += 20;
    }

    // 7. 相邻号码权重 (10%)
    if (stats.adjacentNumbers.isNotEmpty) {
      double adjacentWeight = stats.adjacentNumbers
              .map((n) => _redBallStats[n]?.weight ?? 0)
              .reduce((a, b) => a + b) /
          stats.adjacentNumbers.length;
      stats.weight += adjacentWeight * 0.1;
    }

    // 8. 应用衰减因子
    double decayFactor = 1.0;
    for (int i = 0; i < _recentPeriods.length; i++) {
      if (_recentPeriods[i].redBalls.contains(stats.number)) {
        decayFactor = 1.0 - (i * 0.02);
        break;
      }
    }
    stats.weight *= decayFactor;
  }

  // 检查号码是否处于上升趋势
  bool _isInPositiveTrend(int number) {
    if (_recentPeriods.length < _shortTermPeriods) return false;

    int recentCount = 0;
    int previousCount = 0;

    // 计算近期出现次数
    for (int i = 0; i < _shortTermPeriods ~/ 2; i++) {
      if (_recentPeriods[i].redBalls.contains(number)) recentCount++;
    }

    // 计算前期出现次数
    for (int i = _shortTermPeriods ~/ 2; i < _shortTermPeriods; i++) {
      if (_recentPeriods[i].redBalls.contains(number)) previousCount++;
    }

    return recentCount > previousCount;
  }

  // 生成预测结果 - 增强版
  Future<PredictionResult> generatePrediction() async {
    await analyzeHistoricalData();

    // 1. 生成多组候选号码
    List<List<int>> redCandidates = [];
    List<int> blueCandidates = [];

    for (int i = 0; i < 5; i++) {
      final reds = _generateRedBalls();
      redCandidates.add(reds);
      blueCandidates.add(_generateBlueBall());
    }

    // 2. 评估每组号码的合理性
    List<double> scores =
        await _evaluateCombinations(redCandidates, blueCandidates);

    // 3. 选择最优组合
    int bestIndex = scores.indexOf(scores.reduce(math.max));
    final selectedRed = redCandidates[bestIndex];
    final selectedBlue = blueCandidates[bestIndex];

    // 4. 获取下一期期号
    final nextPeriod = await _getNextPeriodNumber();

    // 5. 计算预测置信度
    final confidence =
        await _calculatePredictionConfidence(selectedRed, selectedBlue);

    // 6. 生成投注建议
    final bettingStrategy = _generateBettingStrategy(confidence);

    // 7. 创建预测结果
    final prediction = PredictionResult(
      periodNumber: nextPeriod,
      redBalls: selectedRed,
      blueBall: selectedBlue,
      predictDate: DateTime.now(),
      confidence: confidence,
      bettingStrategy: bettingStrategy,
    );

    _predictionHistory.add(prediction);
    await _savePredictionHistory();
    return prediction;
  }

  // 生成红球号码
  List<int> _generateRedBalls() {
    List<int> selected = [];
    List<int> available = List.generate(33, (i) => i + 1);

    while (selected.length < 6) {
      final weights = available.map((n) => _redBallStats[n]!.weight).toList();
      final number = _selectBallByWeight(available, weights);
      selected.add(number);
      available.remove(number);
    }

    return selected;
  }

  // 生成蓝球号码
  int _generateBlueBall() {
    return _selectBallByWeight(
      List.generate(16, (i) => i + 1),
      List.generate(16, (i) => _blueBallStats[i + 1]!.weight),
    );
  }

  // 评估号码组合的合理性
  Future<List<double>> _evaluateCombinations(
    List<List<int>> redCandidates,
    List<int> blueCandidates,
  ) async {
    List<double> scores = [];

    for (int i = 0; i < redCandidates.length; i++) {
      double score = 100.0;
      final reds = redCandidates[i];
      final blue = blueCandidates[i];

      // 1. 计算和值得分
      final sum = reds.reduce((a, b) => a + b);
      if (sum >= 90 && sum <= 120) score += 20;

      // 2. 计算奇偶比得分
      final oddCount = reds.where((n) => n % 2 == 1).length;
      if (oddCount >= 2 && oddCount <= 4) score += 20;

      // 3. 计算大小比得分
      final bigCount = reds.where((n) => n > 17).length;
      if (bigCount >= 2 && bigCount <= 4) score += 20;

      // 4. 计算连号得分
      int consecutiveCount = 0;
      for (int j = 0; j < reds.length - 1; j++) {
        if (reds[j + 1] - reds[j] == 1) consecutiveCount++;
      }
      if (consecutiveCount <= 2) score += 20;

      // 5. 历史重复性检查
      final isHistoryDuplicate = await _checkHistoryDuplicate(reds, blue);
      if (!isHistoryDuplicate) score += 20;

      scores.add(score);
    }

    return scores;
  }

  // 检查历史重复
  Future<bool> _checkHistoryDuplicate(List<int> reds, int blue) async {
    final recentBalls = await _databaseService.getBalls(0, 100);

    for (var ball in recentBalls) {
      if (ball.redBalls.every((r) => reds.contains(r)) &&
          ball.blueBall == blue) {
        return true;
      }
    }

    return false;
  }

  // 计算预测置信度
  Future<double> _calculatePredictionConfidence(
      List<int> redBalls, int blueBall) async {
    double confidence = 0.0;

    // 1. 号码权重得分 (40%)
    double weightScore =
        redBalls.map((n) => _redBallStats[n]!.weight).reduce((a, b) => a + b) /
            600.0;
    // 确保权重得分在0-1之间
    weightScore = weightScore.clamp(0.0, 1.0);
    confidence += weightScore * 0.4;

    // 2. 组合特征得分 (30%)
    final features = NumberFeatures.analyze(redBalls);
    double featureScore = 0.0;

    if (features.sum >= 90 && features.sum <= 120) featureScore += 0.2;
    if (features.oddRatio >= 0.4 && features.oddRatio <= 0.6)
      featureScore += 0.2;
    if (features.bigRatio >= 0.4 && features.bigRatio <= 0.6)
      featureScore += 0.2;
    // 确保特征得分在0-1之间
    featureScore = featureScore.clamp(0.0, 1.0);
    confidence += featureScore * 0.3;

    // 3. 历史模式得分 (30%)
    final historyScore =
        await _calculateHistoryPatternScore(redBalls, blueBall);
    // 确保历史得分在0-1之间
    confidence += historyScore.clamp(0.0, 1.0) * 0.3;

    // 最终确保总可信度在0-1之间
    return confidence.clamp(0.0, 1.0);
  }

  // 计算历史模式得分
  Future<double> _calculateHistoryPatternScore(
      List<int> redBalls, int blueBall) async {
    double score = 0.0;
    final recentBalls = await _databaseService.getBalls(0, 100);

    // 1. 检查和值范围
    int currentSum = redBalls.reduce((a, b) => a + b);
    int matchingCount = 0;

    for (var ball in recentBalls) {
      int sum = ball.redBalls.reduce((a, b) => a + b);
      if ((sum - currentSum).abs() <= 10) matchingCount++;
    }

    score += (matchingCount / 100.0) * 0.5;

    // 2. 检查号码间隔
    List<int> gaps = [];
    for (int i = 0; i < redBalls.length - 1; i++) {
      gaps.add(redBalls[i + 1] - redBalls[i]);
    }

    matchingCount = 0;
    for (var ball in recentBalls) {
      List<int> ballGaps = [];
      for (int i = 0; i < ball.redBalls.length - 1; i++) {
        ballGaps.add(ball.redBalls[i + 1] - ball.redBalls[i]);
      }

      if (gaps.every((g) => ballGaps.contains(g))) matchingCount++;
    }

    score += (matchingCount / 100.0) * 0.5;

    // 确保得分在0-1之间
    return score.clamp(0.0, 1.0);
  }

  // 生成投注策略
  BettingStrategy _generateBettingStrategy(double confidence) {
    int multiple = 1;
    String explanation = '建议谨慎投注';

    if (confidence >= 0.8) {
      multiple = 5;
      explanation = '预测置信度较高，建议加倍投注';
    } else if (confidence >= 0.6) {
      multiple = 3;
      explanation = '预测置信度中等，可以适当加倍';
    } else if (confidence >= 0.4) {
      multiple = 2;
      explanation = '预测置信度一般，建议小额投注';
    }

    final totalAmount = multiple * 2.0; // 假设每注2元

    return BettingStrategy(
      multiple: multiple,
      amount: totalAmount,
      explanation: explanation,
    );
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
    return _analyzedCount;
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

    if (count == 0) {
      return {
        'red_accuracy': 0.0,
        'blue_accuracy': 0.0,
        'total_accuracy': 0.0,
      };
    }

    return {
      'red_accuracy': redTotal / count,
      'blue_accuracy': blueTotal / count,
      'total_accuracy': (redTotal + blueTotal) / (count * 2),
    };
  }

  // 从持久化存储加载预测历史
  Future<void> _loadPredictionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('prediction_history');
    if (historyJson != null) {
      final List<dynamic> historyList = jsonDecode(historyJson);
      _predictionHistory =
          historyList.map((json) => PredictionResult.fromJson(json)).toList();
    }
  }

  // 保存预测历史到持久化存储
  Future<void> _savePredictionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _predictionHistory.map((p) => p.toJson()).toList();
    await prefs.setString('prediction_history', jsonEncode(historyJson));
  }

  // 清除所有历史预测记录
  Future<void> clearPredictionHistory() async {
    _predictionHistory.clear();
    await _savePredictionHistory();
  }

  // 获取历史同期数据
  Future<List<BallInfo>> _getHistoricalPeriods(DateTime currentDate) async {
    List<BallInfo> historicalPeriods = [];
    for (int year = 1; year <= _historicalYears; year++) {
      final targetDate = currentDate.subtract(Duration(days: 365 * year));
      final periodData = await _databaseService.getBallsByDate(
        targetDate.subtract(const Duration(days: 15)),
        targetDate.add(const Duration(days: 15)),
      );
      historicalPeriods.addAll(periodData);
    }
    return historicalPeriods;
  }

  // 分析历史同期数据
  void _analyzeHistoricalPeriods(List<BallInfo> historicalPeriods) {
    for (var ball in historicalPeriods) {
      for (var number in ball.redBalls) {
        _redBallStats[number]?.historicalPeriodFreq++;
      }
      _blueBallStats[ball.blueBall]?.historicalPeriodFreq++;
    }
  }

  // 计算统计指标
  void _calculateStats(int totalPeriods) {
    _redBallStats.forEach((number, stats) {
      _calculateWeight(stats, totalPeriods);
    });
    _blueBallStats.forEach((number, stats) {
      _calculateWeight(stats, totalPeriods);
    });
  }

  // 更新组合特征统计
  void _updateCombinationStats({
    required int sum,
    required int span,
    required double oddEvenRatio,
    required double bigSmallRatio,
    required int consecutiveCount,
  }) {
    // 这里可以添加组合特征的统计逻辑
  }

  // 分析热号
  void _analyzeHotNumbers(BallInfo ball) {
    for (var number in ball.redBalls) {
      final stats = _redBallStats[number];
      if (stats != null && stats.frequency / _analyzePeriods >= 0.2) {
        stats.isHot = true;
      }
    }
  }

  // 分析冷号
  void _analyzeColdNumbers(BallInfo ball) {
    _redBallStats.forEach((number, stats) {
      if (stats.currentGap > stats.avgGap * 1.5) {
        stats.isHot = false;
      }
    });
  }

  // 分析近期遗漏
  void _analyzeRecentGaps(BallInfo ball) {
    _redBallStats.forEach((number, stats) {
      if (!ball.redBalls.contains(number)) {
        stats.currentGap++;
        stats.recentGaps.add(stats.currentGap);
        if (stats.currentGap > stats.maxGap) {
          stats.maxGap = stats.currentGap;
        }
      }
    });
  }

  // 分析号码周期性
  void _analyzePeriodicity(List<BallInfo> balls) {
    // 对每个红球号码分析周期
    for (int number = 1; number <= 33; number++) {
      List<int> intervals = [];
      int lastIndex = -1;

      // 计算出现间隔
      for (int i = 0; i < balls.length; i++) {
        if (balls[i].redBalls.contains(number)) {
          if (lastIndex != -1) {
            intervals.add(i - lastIndex);
          }
          lastIndex = i;
        }
      }

      if (intervals.isNotEmpty) {
        // 计算平均周期
        double avgInterval =
            intervals.reduce((a, b) => a + b) / intervals.length;
        _redBallStats[number]?.avgPeriod = avgInterval;

        // 检测是否接近下一个周期
        if (lastIndex != -1) {
          int currentGap = balls.length - lastIndex;
          if (currentGap >= avgInterval * 0.8) {
            _redBallStats[number]?.weight += 20;
          }
        }
      }
    }
  }

  // 分析位置偏好
  void _analyzePositionPreference(List<BallInfo> balls) {
    // 初始化位置统计
    Map<int, List<int>> positionCounts = {};
    for (int number = 1; number <= 33; number++) {
      positionCounts[number] = List.filled(6, 0);
    }

    // 统计每个号码在各个位置的出现次数
    for (var ball in balls) {
      for (int i = 0; i < ball.redBalls.length; i++) {
        int number = ball.redBalls[i];
        positionCounts[number]![i]++;
      }
    }

    // 分析位置偏好
    for (int number = 1; number <= 33; number++) {
      var counts = positionCounts[number]!;
      int maxCount = counts.reduce((a, b) => a > b ? a : b);
      int preferredPosition = counts.indexOf(maxCount);

      // 更新位置偏好
      _redBallStats[number]?.positionPreference = preferredPosition;

      // 如果位置偏好明显，增加权重
      if (maxCount > balls.length * 0.3) {
        _redBallStats[number]?.weight += 15;
      }
    }
  }

  // 分析组合特征趋势
  void _analyzeCombinationTrends(List<BallInfo> balls) {
    List<Map<String, double>> trends = [];

    // 计算每期的组合特征
    for (var ball in balls) {
      int sum = ball.redBalls.reduce((a, b) => a + b);
      int oddCount = ball.redBalls.where((n) => n % 2 == 1).length;
      int bigCount = ball.redBalls.where((n) => n > 17).length;

      trends.add({
        'sum': sum.toDouble(),
        'odd_ratio': oddCount / 6,
        'big_ratio': bigCount / 6,
      });
    }

    // 分析趋势
    if (trends.length >= 2) {
      var latest = trends.first;
      var previous = trends[1];

      // 根据趋势调整权重
      _redBallStats.forEach((number, stats) {
        bool isOdd = number % 2 == 1;
        bool isBig = number > 17;

        // 和值趋势
        if (latest['sum']! > previous['sum']! && number > 20) {
          stats.weight += 10;
        }

        // 奇偶趋势
        if (latest['odd_ratio']! > previous['odd_ratio']! && isOdd) {
          stats.weight += 10;
        }

        // 大小趋势
        if (latest['big_ratio']! > previous['big_ratio']! && isBig) {
          stats.weight += 10;
        }
      });
    }
  }

  // 分析号码长期表现
  void _analyzeLongTermPerformance(List<BallInfo> balls) {
    Map<int, Map<String, dynamic>> performance = {};

    // 初始化性能统计
    for (int i = 1; i <= 33; i++) {
      performance[i] = {
        'total_frequency': 0,
        'win_rate': 0.0,
        'stability': 0.0,
      };
    }

    // 统计长期表现
    for (var ball in balls) {
      for (var number in ball.redBalls) {
        performance[number]!['total_frequency']++;
      }
    }

    // 计算稳定性和胜率
    for (int number = 1; number <= 33; number++) {
      var stats = performance[number]!;
      double frequency = stats['total_frequency'] / balls.length;

      // 计算稳定性（方差）
      List<int> gaps = [];
      int lastIndex = -1;
      for (int i = 0; i < balls.length; i++) {
        if (balls[i].redBalls.contains(number)) {
          if (lastIndex != -1) {
            gaps.add(i - lastIndex);
          }
          lastIndex = i;
        }
      }

      if (gaps.isNotEmpty) {
        double mean = gaps.reduce((a, b) => a + b) / gaps.length;
        double variance =
            gaps.map((g) => math.pow(g - mean, 2)).reduce((a, b) => a + b) /
                gaps.length;
        stats['stability'] = 1 / (1 + variance);
      }

      // 更新权重
      if (frequency >= 0.15) {
        _redBallStats[number]?.weight += 20;
      }
      if (stats['stability'] >= 0.5) {
        _redBallStats[number]?.weight += 15;
      }
    }
  }

  // 分析季节性特征
  void _analyzeSeasonality(List<BallInfo> balls) {
    Map<int, Map<int, int>> seasonalCounts = {};

    // 初始化季节统计
    for (int number = 1; number <= 33; number++) {
      seasonalCounts[number] = {};
      for (int month = 1; month <= 12; month++) {
        seasonalCounts[number]![month] = 0;
      }
    }

    // 统计每个月份的出现次数
    for (var ball in balls) {
      final month = DateTime.parse(ball.kjTime).month;
      for (var number in ball.redBalls) {
        seasonalCounts[number]![month] =
            (seasonalCounts[number]![month] ?? 0) + 1;
      }
    }

    // 分析季节性偏好
    final currentMonth = DateTime.now().month;
    for (int number = 1; number <= 33; number++) {
      var monthlyCounts = seasonalCounts[number]!;

      // 检查当前月份的历史表现
      int currentMonthCount = monthlyCounts[currentMonth] ?? 0;
      int totalCount = monthlyCounts.values.reduce((a, b) => a + b);

      if (currentMonthCount > totalCount / 12) {
        _redBallStats[number]?.seasonalWeight = 1.2;
        _redBallStats[number]?.weight *= 1.2;
      }
    }
  }

  // 分析历史同期特征
  void _analyzeHistoricalPatterns(List<BallInfo> balls) {
    // 获取当前日期
    final now = DateTime.now();
    final currentDayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

    Map<int, int> historicalFrequency = {};
    for (int i = 1; i <= 33; i++) {
      historicalFrequency[i] = 0;
    }

    // 分析历史同期数据
    for (var ball in balls) {
      final ballDate = DateTime.parse(ball.kjTime);
      final ballDayOfYear =
          ballDate.difference(DateTime(ballDate.year, 1, 1)).inDays;

      // 检查是否在同期范围内（前后15天）
      if ((ballDayOfYear - currentDayOfYear).abs() <= 15) {
        for (var number in ball.redBalls) {
          historicalFrequency[number] = (historicalFrequency[number] ?? 0) + 1;
        }
      }
    }

    // 更新权重
    historicalFrequency.forEach((number, frequency) {
      if (frequency > balls.length / 20) {
        // 如果在历史同期出现频率较高
        _redBallStats[number]?.weight += 25;
        _redBallStats[number]?.historicalPeriodFreq = frequency;
      }
    });
  }

  // 获取下一期期号
  Future<String> _getNextPeriodNumber() async {
    final latestBall = await _databaseService.getLatestBall();
    if (latestBall != null) {
      final nextNumber = latestBall.qh + 1;
      return nextNumber.toString().padLeft(7, '0');
    }
    return '0000001';
  }
}
