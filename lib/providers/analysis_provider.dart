import 'package:flutter/foundation.dart';
import '../services/analysis_service.dart';
import '../models/analysis_stats.dart';

class AnalysisProvider extends ChangeNotifier {
  final AnalysisService _analysisService;
  bool _isLoading = false;

  AnalysisProvider(this._analysisService) {
    _initialize();
  }

  bool get isLoading => _isLoading;

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _analysisService.analyzeHistoricalData();
    } catch (e) {
      debugPrint('初始化分析数据时出错: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // 获取所有红球分析
  List<BallAnalysis> getAllRedBallAnalysis() {
    return _analysisService.getAllRedBallAnalysis();
  }

  // 获取所有蓝球分析
  List<BallAnalysis> getAllBlueBallAnalysis() {
    return _analysisService.getAllBlueBallAnalysis();
  }

  // 获取走势数据
  List<TrendData> getTrendData([int limit = 30]) {
    return _analysisService.getTrendData(limit);
  }

  // 获取热门号码
  List<BallAnalysis> getHotNumbers(BallType type, [int limit = 5]) {
    return _analysisService.getHotNumbers(type, limit);
  }

  // 获取冷门号码
  List<BallAnalysis> getColdNumbers(BallType type, [int limit = 5]) {
    return _analysisService.getColdNumbers(type, limit);
  }

  // 获取位置偏好分析
  List<Map<int, int>> getPositionPreference() {
    return _analysisService.getPositionPreference();
  }

  // 刷新分析数据
  Future<void> refreshAnalysis() async {
    if (!_analysisService.needsUpdate()) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _analysisService.analyzeHistoricalData();
    } catch (e) {
      debugPrint('刷新分析数据时出错: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
