import 'package:flutter/foundation.dart';
import '../models/ball_info.dart';
import '../models/search_criteria.dart';
import '../services/network_service.dart';
import '../services/database_service.dart';

class BallProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  final NetworkService _networkService;

  List<BallInfo> _balls = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  static const int _pageSize = 20;

  BallProvider(this._databaseService, this._networkService) {
    _networkService.onLoadingProgress = (message, progress) {
      // 网络服务的加载进度回调
    };
  }

  List<BallInfo> get balls => _balls;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  // 设置初始数据
  void setInitialData(List<BallInfo> initialData) {
    _balls = initialData;
    _currentOffset = initialData.length;
    notifyListeners();
  }

  Future<void> loadInitialData({
    required void Function(String message, double progress) onProgress,
    bool forceReload = false,
  }) async {
    if (_balls.isNotEmpty && !forceReload) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 设置网络服务的进度回调
      _networkService.onLoadingProgress = onProgress;

      // 加载第一页数据
      final newBalls = await _databaseService.getBalls(0, _pageSize);

      if (newBalls.isEmpty) {
        _hasMore = false;
      } else {
        _balls = newBalls;
        _currentOffset = newBalls.length;
      }
    } catch (e) {
      debugPrint('加载初始数据时出错: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreData() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newBalls =
          await _databaseService.getBalls(_currentOffset, _pageSize);

      if (newBalls.isEmpty) {
        _hasMore = false;
      } else {
        _balls.addAll(newBalls);
        _currentOffset += newBalls.length;
      }
    } catch (e) {
      debugPrint('加载数据时出错: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    _balls.clear();
    _currentOffset = 0;
    _hasMore = true;
    notifyListeners();

    try {
      await _networkService.checkForUpdates();
    } finally {
      await loadMoreData();
    }
  }

  void addBalls(List<BallInfo> newBalls) {
    _balls.addAll(newBalls);
    notifyListeners();
  }

  void clearBalls() {
    _balls.clear();
    notifyListeners();
  }

  void updateBall(int index, BallInfo ball) {
    if (index >= 0 && index < _balls.length) {
      _balls[index] = ball;
      notifyListeners();
    }
  }

  // 获取总记录数
  Future<int> getTotalCount() async {
    return await _databaseService.getTotalCount();
  }

  // 搜索数据
  Future<List<BallInfo>> searchBalls(SearchCriteria criteria) async {
    return await _databaseService.searchBalls(criteria);
  }
}
