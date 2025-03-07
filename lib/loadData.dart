import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lucky_lucky/models/ball_info.dart';
import 'package:lucky_lucky/DatabaseHelper.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'services/database_service.dart';

/// 加载 json 数据
Future<List<BallInfo>> loadJsonData() async {
  try {
    final response = await http.get(
      Uri.parse(
          'https://www.cwl.gov.cn/cwl_admin/front/cwlkj/search/kjxx/findDrawNotice?name=ssq&issueCount=5000'),
      headers: {
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        'Connection': 'keep-alive',
        'Referer': 'https://www.cwl.gov.cn/ygkj/wqkjgg/ssq/',
        'Sec-Fetch-Dest': 'empty',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Site': 'same-origin',
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'X-Requested-With': 'XMLHttpRequest'
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print(
          'Response body: ${response.body.substring(0, 500)}...'); // Print first 500 chars for debugging

      if (jsonData['result'] != null) {
        final List<dynamic> items = jsonData['result'];
        print('Found ${items.length} items in response');

        final dbService = DatabaseService();
        await dbService.initialize();

        final List<BallInfo> balls = [];
        for (var item in items) {
          try {
            final ball = BallInfo.fromJson(item);
            balls.add(ball);
            print('Successfully processed ball with issue: ${ball.qh}');
          } catch (e) {
            print('Error processing item: $e');
            print('Item data: $item');
          }
        }

        if (balls.isNotEmpty) {
          await dbService.insertBalls(balls);
          print('Successfully inserted ${balls.length} balls into database');
        }

        return balls;
      } else {
        print('No result field in response');
        return [];
      }
    } else {
      print('Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      return [];
    }
  } catch (e) {
    print('Error fetching data: $e');
    return [];
  }
}

///检查并插入数据
Future checkDbAndInsert() async {
  final dbhelper = DatabaseHelper();
  final isTableEmpty = await dbhelper.isTableEmpty();
  if (!isTableEmpty) {
    print("数据不为空，不用插入");
    return;
  }
  List<BallInfo> ballInfos = await loadJsonData();

  for (int i = 0; i < ballInfos.length; i++) {
    await dbhelper.insertBall(ballInfos[i]);
  }
}

// 抓取并解析双色球数据的函数
Future<void> fetchAndInsertData() async {
  try {
    await loadJsonData();
    await checkDatabase();
  } catch (e) {
    print('Error in fetchAndInsertData: $e');
  }
}

Future<void> checkDatabase() async {
  final dbService = DatabaseService();
  await dbService.initialize();

  final balls = await dbService.getBalls(0, 20);
  print('Loaded ${balls.length} balls from database');

  if (balls.isNotEmpty) {
    print('First ball: ${balls.first}');
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
