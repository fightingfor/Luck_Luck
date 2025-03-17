import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prediction_stats.dart';
import '../services/prediction_service.dart';
import '../services/database_service.dart';
import '../models/ball_info.dart';
import '../models/prediction_result.dart';
import 'dart:convert';

class PredictionProvider extends ChangeNotifier {
  final PredictionService _predictionService;
  final SharedPreferences _prefs;
  PredictionResult? _currentPrediction;
  bool _isLoading = false;
  Map<String, double> _accuracy = {
    'red_accuracy': 0.0,
    'blue_accuracy': 0.0,
    'total_accuracy': 0.0,
  };
  List<PredictionResult> _favorites = [];
  static const String _favoritesKey = 'favorites';

  PredictionProvider(DatabaseService databaseService, this._prefs)
      : _predictionService = PredictionService(databaseService) {
    _initialize();
  }

  bool get isLoading => _isLoading;
  PredictionResult? get currentPrediction => _currentPrediction;
  Map<String, double> get accuracy => _accuracy;

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await generatePrediction();
      await _loadFavorites();
    } catch (e) {
      debugPrint('初始化失败: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    final favorites = _prefs.getStringList(_favoritesKey);
    if (favorites != null) {
      _favorites = favorites.map((e) {
        final map = json.decode(e) as Map<String, dynamic>;
        return PredictionResult(
          redBalls: List<int>.from(map['redBalls']),
          blueBall: map['blueBall'],
          predictDate: DateTime.parse(map['predictDate']),
          periodNumber: map['periodNumber'],
          confidence: map['confidence'] ?? 0.0,
        );
      }).toList();
    }
  }

  void _saveFavorites() {
    _prefs.setStringList(
        _favoritesKey,
        _favorites
            .map((e) => json.encode({
                  'redBalls': e.redBalls,
                  'blueBall': e.blueBall,
                  'predictDate': e.predictDate.toIso8601String(),
                  'periodNumber': e.periodNumber,
                  'confidence': e.confidence,
                }))
            .toList());
  }

  Future<void> generatePrediction() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentPrediction = await _predictionService.generatePrediction();
      _accuracy = _predictionService.getPredictionAccuracy();
    } catch (e) {
      debugPrint('生成预测失败: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  List<PredictionResult> getPredictionHistory() {
    return _predictionService.getPredictionHistory();
  }

  // 更新预测结果的准确性
  Future<void> updatePredictionAccuracy(
      String periodNumber, List<int> actualRed, int actualBlue) async {
    final predictions = getPredictionHistory();
    final prediction = predictions.firstWhere(
      (p) => p.periodNumber == periodNumber,
      orElse: () => throw Exception('未找到对应期号的预测结果'),
    );

    prediction.calculatePrize(actualRed, actualBlue);
    _accuracy = _predictionService.getPredictionAccuracy();
    notifyListeners();
  }

  // 获取收藏的预测结果
  List<PredictionResult> getFavorites() => _favorites;

  // 检查是否已收藏
  bool isFavorite(PredictionResult prediction) {
    return _favorites.any((p) =>
        p.redBalls.toString() == prediction.redBalls.toString() &&
        p.blueBall == prediction.blueBall);
  }

  // 切换收藏状态
  void toggleFavorite(PredictionResult prediction) {
    final isExist = _favorites.any((p) =>
        p.redBalls.toString() == prediction.redBalls.toString() &&
        p.blueBall == prediction.blueBall);

    if (isExist) {
      _favorites.removeWhere((p) =>
          p.redBalls.toString() == prediction.redBalls.toString() &&
          p.blueBall == prediction.blueBall);
    } else {
      _favorites.add(prediction);
    }
    _saveFavorites();
    notifyListeners();
  }

  // 获取已分析的数据数量
  int getAnalyzedCount() {
    return _predictionService.getAnalyzedCount();
  }

  // 获取最新开奖结果
  Future<BallInfo?> getLatestDrawResult() async {
    try {
      return await _predictionService.databaseService.getLatestBall();
    } catch (e) {
      debugPrint('获取最新开奖结果失败: $e');
      return null;
    }
  }

  // 开奖
  Future<void> drawPrediction(PredictionResult prediction) async {
    if (!prediction.canDraw()) return;

    final latestBall = await getLatestDrawResult();
    if (latestBall == null) return;

    // 解析开奖号码
    List<int> actualRed = latestBall.redBalls;
    int actualBlue = latestBall.blueBall;

    // 计算中奖情况
    prediction.calculatePrize(actualRed, actualBlue);
    notifyListeners();
  }

  /// 清除所有历史预测记录
  Future<void> clearPredictionHistory() async {
    await _predictionService.clearPredictionHistory();
    notifyListeners();
  }

  // 获取按期号分组的预测历史
  Map<String, List<PredictionResult>> getGroupedPredictionHistory() {
    final Map<String, List<PredictionResult>> grouped = {};

    // 按完整期号分组
    for (var result in getPredictionHistory()) {
      grouped.putIfAbsent(result.periodNumber, () => []).add(result);
    }

    // 对分组键进行排序（降序）
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, grouped[key]!)),
    );
  }

  // 检查收藏列表中的开奖结果
  Future<void> checkDrawResults() async {
    bool hasChanges = false;

    for (var prediction in _favorites) {
      // 如果已经有开奖结果，跳过
      if (prediction.isDrawn()) continue;

      // 查询数据库中的开奖结果
      final ball = await _predictionService.databaseService
          .getBallByPeriod(prediction.periodNumber);
      if (ball != null) {
        prediction.calculatePrize(ball.redBalls, ball.blueBall);
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _saveFavorites();
      notifyListeners();
    }
  }

  // 获取按期号分组的收藏列表
  Map<String, List<PredictionResult>> getGroupedFavorites() {
    final Map<String, List<PredictionResult>> grouped = {};

    // 按完整期号分组
    for (var result in _favorites) {
      grouped.putIfAbsent(result.periodNumber, () => []).add(result);
    }

    // 对分组键进行排序（降序）
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, grouped[key]!)),
    );
  }
}
