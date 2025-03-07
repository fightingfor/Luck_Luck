import 'dart:convert';
import 'dart:isolate';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/ball_info.dart';
import 'database_service.dart';

class NetworkService {
  final DatabaseService _databaseService = DatabaseService();
  final String _baseUrl =
      'https://webapi.sporttery.cn/gateway/lottery/getHistoryPageListV1.qry';
  final Map<String, String> _headers = {
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'zh-CN,zh;q=0.9',
    'Connection': 'keep-alive',
    'Host': 'webapi.sporttery.cn',
    'Origin': 'https://www.sporttery.cn',
    'Referer': 'https://www.sporttery.cn/',
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
  };

  Timer? _updateTimer;
  static const Duration _updateInterval = Duration(minutes: 30);

  // 后台数据更新任务
  bool _isUpdating = false;

  // 在应用启动时调用此方法开始后台更新
  Future<void> startBackgroundUpdate() async {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(_updateInterval, (_) => checkForUpdates());
    await checkForUpdates(); // 立即执行一次检查
  }

  // 停止后台更新
  void stopBackgroundUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _isUpdating = false;
  }

  Future<void> checkForUpdates() async {
    try {
      final latestQh = await _databaseService.getLatestQh();
      final oldestQh = await _databaseService.getOldestQh();

      if (latestQh.isEmpty) {
        await _fetchInitialData();
      } else {
        await _fetchNewData(latestQh);
      }

      if (oldestQh != '2003001') {
        await _fetchHistoricalData(oldestQh);
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
  }

  Future<void> _fetchInitialData() async {
    try {
      final data = await _fetchDataByPage(1);
      if (data.isNotEmpty) {
        await _databaseService.insertBalls(data);
      }
    } catch (e) {
      print('Error fetching initial data: $e');
    }
  }

  Future<void> _fetchNewData(String latestQh) async {
    try {
      final data = await _fetchDataByPage(1);
      if (data.isNotEmpty && data.first.qh != latestQh) {
        print('Found new data, latest qh: ${data.first.qh}');
        final newData = data.takeWhile((ball) => ball.qh != latestQh).toList();
        if (newData.isNotEmpty) {
          await _databaseService.insertBalls(newData);
        }
      }
    } catch (e) {
      print('Error fetching new data: $e');
    }
  }

  Future<void> _fetchHistoricalData(String oldestQh) async {
    try {
      var currentPage = 1;
      var reachedFirstIssue = false;
      final oldestIssueNumber =
          oldestQh.isEmpty ? 2003001 : int.parse(oldestQh);

      while (!reachedFirstIssue && currentPage <= 10) {
        // 限制最多获取10页数据
        final data = await _fetchDataByPage(currentPage);
        if (data.isEmpty) {
          print('No more data available at page $currentPage');
          break;
        }

        print('Fetched ${data.length} records from page $currentPage');
        final newData = data.where((ball) {
          try {
            final issueNumber = int.parse(ball.qh);
            final shouldInclude = issueNumber < oldestIssueNumber;
            if (shouldInclude) {
              print('Including qh ${ball.qh} (older than $oldestQh)');
            }
            return shouldInclude;
          } catch (e) {
            print('Error parsing issue number: ${ball.qh}');
            return false;
          }
        }).toList();

        if (newData.isNotEmpty) {
          print('Inserting ${newData.length} new records into database');
          await _databaseService.insertBalls(newData);
          if (newData.any((ball) => ball.qh == '2003001')) {
            print('Reached earliest issue (2003001)');
            break;
          }
        } else {
          print('No new data to insert from page $currentPage');
          // 如果没有新数据，尝试获取更早的数据
          final earliestBall = data.last;
          final earliestIssueNumber = int.parse(earliestBall.qh);
          if (earliestIssueNumber <= oldestIssueNumber) {
            print('Reached target issue number $oldestQh');
            break;
          }
        }

        currentPage++;
      }

      if (currentPage > 10) {
        print('Reached maximum page limit (10)');
      }
    } catch (e) {
      print('Error fetching historical data: $e');
    }
  }

  Future<List<BallInfo>> getNextPage(int offset, int limit) async {
    return await _databaseService.getBalls(offset, limit);
  }

  Future<List<BallInfo>> _fetchDataByPage(int page) async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl).replace(queryParameters: {
          'name': 'ssq',
          'issueCount': '5000',
        }),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(
            'API Response: ${response.body.substring(0, 500)}...'); // Print first 500 chars for debugging

        if (jsonData['result'] != null) {
          final List<dynamic> data = jsonData['result'];
          print('Fetched ${data.length} records from page $page');
          print('First record: ${data.first}');

          return data.map((item) {
            try {
              print('Processing item: $item');
              final redBalls = (item['red'] as String)
                  .split(',')
                  .map((e) => int.parse(e.trim()))
                  .toList();

              final date = (item['date'] as String).split('(')[0].trim();

              return BallInfo(
                qh: item['code'].toString(),
                kjTime: date,
                zhou: item['week'].toString().replaceAll("星期", ""),
                redBalls: redBalls,
                blueBall: int.parse(item['blue'].toString()),
                saleMoney: item['sales'].toString(),
                prizePoolMoney: item['poolmoney'].toString(),
                winnerDetails: [],
              );
            } catch (e) {
              print('Error processing item: $e');
              print('Item data: $item');
              rethrow;
            }
          }).toList();
        }
      }
      print('Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      return [];
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  }

  String removeLeadingZero(String number) {
    if (number.startsWith('0')) {
      return number.substring(1);
    }
    return number;
  }

  void dispose() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }
}
