import 'package:flutter/foundation.dart';
import 'package:lucky_lucky/models/ball_info.dart';
import 'package:lucky_lucky/services/network_service.dart';

class BallProvider extends ChangeNotifier {
  final NetworkService _networkService = NetworkService();
  final List<BallInfo> _balls = [];
  bool _hasMore = true;
  bool _isLoading = false;
  int _currentOffset = 0;
  static const int _pageSize = 20;

  BallProvider() {
    _initData();
  }

  List<BallInfo> get balls => List.unmodifiable(_balls);
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  Future<void> _initData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 先刷新数据
      await _networkService.checkForUpdates();

      // 等待一小段时间确保数据已经写入数据库
      await Future.delayed(Duration(milliseconds: 500));

      // 从数据库加载数据
      final newBalls = await _networkService.getNextPage(0, _pageSize);
      if (newBalls.isNotEmpty) {
        _balls.addAll(newBalls);
        _hasMore = true;
      } else {
        _hasMore = false;
      }

      print('Loaded ${_balls.length} balls from database');
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;

    final newBalls =
        await _networkService.getNextPage(_currentOffset, _pageSize);
    if (newBalls.isEmpty) {
      _hasMore = false;
      notifyListeners();
      return;
    }

    _balls.addAll(newBalls);
    _currentOffset += newBalls.length;
    notifyListeners();
  }

  Future<void> refresh() async {
    _balls.clear();
    _currentOffset = 0;
    _hasMore = true;
    await loadMore();
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
}
