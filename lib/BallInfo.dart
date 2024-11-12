/// id : 3223
/// qh : "2024128"
/// kj_time : "2024-11-07"
/// zhou : "四"
/// hong_one : 1
/// hong_two : 8
/// hong_three : 13
/// hong_four : 18
/// hong_five : 20
/// hong_six : 26
/// lan_ball : 16

import 'dart:convert';

class BallInfo {
  final int id;
  final String qh;
  final String kjTime;
  final String zhou;
  final int hongOne;
  final int hongTwo;
  final int hongThree;
  final int hongFour;
  final int hongFive;
  final int hongSix;
  final int lanBall;

  BallInfo({
    required this.id,
    required this.qh,
    required this.kjTime,
    required this.zhou,
    required this.hongOne,
    required this.hongTwo,
    required this.hongThree,
    required this.hongFour,
    required this.hongFive,
    required this.hongSix,
    required this.lanBall,
  });


  @override
  String toString() {
    return 'BallInfo{id: $id, qh: $qh, kjTime: $kjTime, zhou: $zhou, hongOne: $hongOne, hongTwo: $hongTwo, hongThree: $hongThree, hongFour: $hongFour, hongFive: $hongFive, hongSix: $hongSix, lanBall: $lanBall}';
  } // 从 JSON 创建 BallInfo 实例的工厂构造函数
  factory BallInfo.fromJson(Map<String, dynamic> json) {
    return BallInfo(
      id: json['id'],
      qh: json['qh'],
      kjTime: json['kj_time'],
      zhou: json['zhou'],
      hongOne: json['hong_one'],
      hongTwo: json['hong_two'],
      hongThree: json['hong_three'],
      hongFour: json['hong_four'],
      hongFive: json['hong_five'],
      hongSix: json['hong_six'],
      lanBall: json['lan_ball'],
    );
  }


  // 转换为 Map，用于插入数据库
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'qh': qh,
      'kj_time': kjTime,
      'zhou': zhou,
      'hong_one': hongOne,
      'hong_two': hongTwo,
      'hong_three': hongThree,
      'hong_four': hongFour,
      'hong_five': hongFive,
      'hong_six': hongSix,
      'lan_ball': lanBall,
    };
  }

}
