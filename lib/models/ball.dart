import 'package:flutter/material.dart';

class Ball {
  final int num;
  final bool isRed;

  const Ball({
    required this.num,
    required this.isRed,
  });

  Color get color => isRed ? Colors.red : Colors.blue;

  @override
  String toString() {
    return 'Ball{num: $num, isRed: $isRed}';
  }
}