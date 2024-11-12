import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lucky_lucky/BallInfo.dart';
import 'package:lucky_lucky/DatabaseHelper.dart';
import 'package:dio/dio.dart';

/// 加载 json 数据
Future<List<BallInfo>> loadJsonData() async {
  final String jsonString =
      await rootBundle.loadString('dbfile/AllBallsInfo.json');
  final List<dynamic> jsonData = json.decode(jsonString);
  final List<BallInfo> dataList =
      jsonData.map((item) => BallInfo.fromJson(item)).toList();
  print("数据为空，加载 json 数据");
  return dataList;
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
// 抓取并解析双色球数据的函数
Future<void> fetchAndInsertData() async {
  final dio = Dio();
  dio.options.headers = {
    'Accept': '*/*',
    'Accept-Language': 'zh-CN,zh;q=0.9,vi;q=0.8,en;q=0.7',
    'Connection': 'keep-alive',
    'Cookie':
        'PHPSESSID=kr1udvee4mqlbvamou7dmitvc7; Hm_lvt_692bd5f9c07d3ebd0063062fb0d7622f=1726211380; HMACCOUNT=4705011E81E143B0; Hm_lvt_12e4883fd1649d006e3ae22a39f97330=1726211380; _gid=GA1.2.1757776359.1727590077; _ga_9FDP3NWFMS=GS1.1.1727664103.9.1.1727664520.0.0.0; Hm_lpvt_692bd5f9c07d3ebd0063062fb0d7622f=1727664521; Hm_lpvt_12e4883fd1649d006e3ae22a39f97330=1727664521; _ga=GA1.2.1394554434.1726211380',
    'Referer': 'https://www.zhcw.com/',
    'Sec-Fetch-Dest': 'script',
    'Sec-Fetch-Mode': 'no-cors',
    'Sec-Fetch-Site': 'same-site',
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36',
    'sec-ch-ua':
        '"Google Chrome";v="129", "Not=A?Brand";v="8", "Chromium";v="129"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"macOS"'
  };

  const url = 'https://jc.zhcw.com/port/client_json.php';

  // 原脚本中的 params
  final params = {
    'callback': 'jQuery112209932733441559836_1727664520392',
    'transactionType': '10001001',
    'lotteryId': '1',
    'issueCount': '0',
    'startIssue': '',
    'endIssue': '',
    'startDate': '',
    'endDate': '',
    'type': '1',
    'pageNum': '1',
    'pageSize': '30',
    'tt': '0.9605816730096195',
    '_': '1727664520397'
  };

  try {
    final response = await dio.get(url, queryParameters: params);
    final db = DatabaseHelper();
    if (response.statusCode == 200) {
      final data = extractJsonData(response.data);
      final parseJson = jsonDecode(data);
      final dataList = parseJson['data'];
      final size = int.parse(parseJson["pageSize"].toString());
      print("请求成功 数据长度 $size");
      for (int i = 0; i < size; i++) {
        final firstData = dataList[i];
        final redBalls = firstData["frontWinningNum"].toString().split(" ");
        final blueBall = firstData["backWinningNum"];
        final ball = BallInfo(
            id: 1,
            qh: firstData["issue"],
            kjTime: firstData["openTime"],
            zhou: firstData["week"].toString().replaceAll("星期", ""),
            hongOne: removeLeadingZero(redBalls[0].toString()),
            hongTwo: removeLeadingZero(redBalls[1].toString()),
            hongThree: removeLeadingZero(redBalls[2].toString()),
            hongFour: removeLeadingZero(redBalls[3].toString()),
            hongFive: removeLeadingZero(redBalls[4].toString()),
            hongSix: removeLeadingZero(redBalls[5].toString()),
            lanBall: removeLeadingZero(blueBall.toString()));

        final resultBall = await db.getBallByQh(ball.qh);
        if (resultBall == null) {
          final resultId = await db.insertBall(ball);
          print("请求成功 数据插入 $resultId");
        } else {
          print("请求成功 数据已经存在不用插入");
        }
      }
    } else {
      print("请求失败");
    }
  } catch (e) {
    print("报错》》》  $e");
  }
}

int removeLeadingZero(String number) {
  // 将字符串转换为整数，再转回字符串，这样可以去掉前导零
  return int.parse(number);
}

String extractJsonData(String rawData) {
  // 查找第一个 '{' 和最后一个 '}'
  final startIndex = rawData.indexOf('{');
  final endIndex = rawData.lastIndexOf('}') + 1;

  // 如果找到了匹配的 JSON 部分，返回该部分；否则返回空字符串
  if (startIndex != -1 && endIndex != -1) {
    return rawData.substring(startIndex, endIndex);
  } else {
    throw Exception("未找到有效的 JSON 数据");
  }
}
