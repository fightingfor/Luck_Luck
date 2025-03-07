import 'ball.dart';

/// 双色球开奖信息数据模型
class BallInfo {
  final String qh;
  final String kjTime;
  final List<int> redBalls;
  final int blueBall;
  final String saleMoney;
  final String prizePoolMoney;
  final String zhou;
  final List<WinnerDetail> winnerDetails;

  BallInfo({
    required this.qh,
    required this.kjTime,
    required this.redBalls,
    required this.blueBall,
    required this.saleMoney,
    required this.prizePoolMoney,
    required this.zhou,
    required this.winnerDetails,
  });

  /// 从JSON数据创建BallInfo实例
  factory BallInfo.fromJson(Map<String, dynamic> json) {
    return BallInfo(
      qh: json['qh'],
      kjTime: json['kjTime'],
      redBalls: [
        int.parse(json['hong_one'].toString()),
        int.parse(json['hong_two'].toString()),
        int.parse(json['hong_three'].toString()),
        int.parse(json['hong_four'].toString()),
        int.parse(json['hong_five'].toString()),
        int.parse(json['hong_six'].toString()),
      ],
      blueBall: int.parse(json['lan_ball'].toString()),
      saleMoney: json['saleMoney'] ?? '0',
      prizePoolMoney: json['prizePoolMoney'] ?? '0',
      zhou: json['zhou'],
      winnerDetails: (json['winnerDetails'] as List?)
              ?.map((detail) => WinnerDetail.fromJson(detail))
              .toList() ??
          [],
    );
  }

  /// 转换为Map，用于数据库操作
  Map<String, dynamic> toJson() {
    return {
      'qh': qh,
      'kjTime': kjTime,
      'hong_one': redBalls[0],
      'hong_two': redBalls[1],
      'hong_three': redBalls[2],
      'hong_four': redBalls[3],
      'hong_five': redBalls[4],
      'hong_six': redBalls[5],
      'lan_ball': blueBall,
      'saleMoney': saleMoney,
      'prizePoolMoney': prizePoolMoney,
      'zhou': zhou,
      'winnerDetails': winnerDetails.map((detail) => detail.toJson()).toList(),
    };
  }

  /// 转换为Ball对象列表
  List<Ball> toBalls() {
    return [
      Ball(num: redBalls[0], isRed: true),
      Ball(num: redBalls[1], isRed: true),
      Ball(num: redBalls[2], isRed: true),
      Ball(num: redBalls[3], isRed: true),
      Ball(num: redBalls[4], isRed: true),
      Ball(num: redBalls[5], isRed: true),
      Ball(num: blueBall, isRed: false),
    ];
  }

  @override
  String toString() {
    return 'BallInfo{qh: $qh, kjTime: $kjTime, redBalls: $redBalls, blueBall: $blueBall, saleMoney: $saleMoney, prizePoolMoney: $prizePoolMoney, zhou: $zhou, winnerDetails: $winnerDetails}';
  }

  // 从Map创建BallInfo对象
  factory BallInfo.fromMap(Map<String, dynamic> map) {
    return BallInfo(
      qh: map['qh']?.toString() ?? '',
      kjTime: map['kj_time']?.toString() ?? '',
      redBalls: [
        int.tryParse(map['hong_one']?.toString() ?? '0') ?? 0,
        int.tryParse(map['hong_two']?.toString() ?? '0') ?? 0,
        int.tryParse(map['hong_three']?.toString() ?? '0') ?? 0,
        int.tryParse(map['hong_four']?.toString() ?? '0') ?? 0,
        int.tryParse(map['hong_five']?.toString() ?? '0') ?? 0,
        int.tryParse(map['hong_six']?.toString() ?? '0') ?? 0,
      ],
      blueBall: int.tryParse(map['lan_ball']?.toString() ?? '0') ?? 0,
      saleMoney: map['saleMoney']?.toString() ?? '0',
      prizePoolMoney: map['prizePoolMoney']?.toString() ?? '0',
      zhou: map['zhou']?.toString() ?? '',
      winnerDetails: (map['winnerDetails'] as List?)
              ?.map((detail) => WinnerDetail.fromJson(detail))
              .toList() ??
          [],
    );
  }

  // 将BallInfo对象转换为Map
  Map<String, dynamic> toMap() {
    return {
      'qh': qh,
      'kjTime': kjTime,
      'hong_one': redBalls[0],
      'hong_two': redBalls[1],
      'hong_three': redBalls[2],
      'hong_four': redBalls[3],
      'hong_five': redBalls[4],
      'hong_six': redBalls[5],
      'lan_ball': blueBall,
      'saleMoney': saleMoney,
      'prizePoolMoney': prizePoolMoney,
      'zhou': zhou,
      'winnerDetails': winnerDetails.map((detail) => detail.toJson()).toList(),
    };
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
