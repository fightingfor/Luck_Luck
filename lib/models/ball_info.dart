import 'ball.dart';

/// 双色球开奖信息数据模型
class BallInfo {
  final int qh;
  final String kjTime;
  final String zhou;
  final List<int> redBalls;
  final int blueBall;

  BallInfo({
    required this.qh,
    required this.kjTime,
    required this.zhou,
    required this.redBalls,
    required this.blueBall,
  });

  /// 从JSON数据创建BallInfo实例
  factory BallInfo.fromJson(Map<String, dynamic> json) {
    // 处理红球数据
    List<int> redBalls;
    if (json['red_balls'] != null) {
      // 新格式：从逗号分隔的字符串解析
      redBalls = json['red_balls']
          .toString()
          .split(',')
          .map((s) => int.parse(s.trim()))
          .toList();
    } else {
      // 旧格式：从单独的字段解析
      redBalls = [
        int.parse(json['hong_one'].toString()),
        int.parse(json['hong_two'].toString()),
        int.parse(json['hong_three'].toString()),
        int.parse(json['hong_four'].toString()),
        int.parse(json['hong_five'].toString()),
        int.parse(json['hong_six'].toString()),
      ];
    }

    return BallInfo(
      qh: json['qh'] is int ? json['qh'] : int.parse(json['qh'].toString()),
      kjTime: json['kj_time'].toString(),
      zhou: json['zhou'].toString(),
      redBalls: redBalls,
      blueBall: json['blue_ball'] != null
          ? int.parse(json['blue_ball'].toString())
          : int.parse(json['lan_ball'].toString()),
    );
  }

  /// 转换为Map，用于数据库操作
  Map<String, dynamic> toJson() => {
        'qh': qh,
        'kj_time': kjTime,
        'zhou': zhou,
        'red_balls': redBalls.join(','),
        'blue_ball': blueBall,
      };

  /// 转换为Ball对象列表
  List<Ball> toBalls() {
    return [
      ...redBalls.map((num) => Ball(num: num, isRed: true)),
      Ball(num: blueBall, isRed: false),
    ];
  }

  @override
  String toString() {
    return 'BallInfo{qh: $qh, kjTime: $kjTime, zhou: $zhou, redBalls: $redBalls, blueBall: $blueBall}';
  }
}

class WinnerDetail {
  final String awardEtc;
  final BaseBetWinner baseBetWinner;
  final String addToBetWinner;
  final String addToBetWinner2;
  final String addToBetWinner3;

  WinnerDetail({
    required this.awardEtc,
    required this.baseBetWinner,
    required this.addToBetWinner,
    required this.addToBetWinner2,
    required this.addToBetWinner3,
  });

  factory WinnerDetail.fromJson(Map<String, dynamic> json) {
    return WinnerDetail(
      awardEtc: json['awardEtc'],
      baseBetWinner: BaseBetWinner.fromJson(json['baseBetWinner']),
      addToBetWinner: json['addToBetWinner'],
      addToBetWinner2: json['addToBetWinner2'],
      addToBetWinner3: json['addToBetWinner3'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'awardEtc': awardEtc,
      'baseBetWinner': baseBetWinner.toJson(),
      'addToBetWinner': addToBetWinner,
      'addToBetWinner2': addToBetWinner2,
      'addToBetWinner3': addToBetWinner3,
    };
  }
}

class BaseBetWinner {
  final String remark;
  final String awardNum;
  final String awardMoney;
  final String totalMoney;

  BaseBetWinner({
    required this.remark,
    required this.awardNum,
    required this.awardMoney,
    required this.totalMoney,
  });

  factory BaseBetWinner.fromJson(Map<String, dynamic> json) {
    return BaseBetWinner(
      remark: json['remark'],
      awardNum: json['awardNum'],
      awardMoney: json['awardMoney'],
      totalMoney: json['totalMoney'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'remark': remark,
      'awardNum': awardNum,
      'awardMoney': awardMoney,
      'totalMoney': totalMoney,
    };
  }
}
