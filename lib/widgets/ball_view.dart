import 'package:flutter/material.dart';
import '../models/ball.dart';

class BallView extends StatelessWidget {
  final Ball ball;
  final double size;

  const BallView({
    super.key,
    required this.ball,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ball.isRed ? Colors.red : Colors.blue,
        boxShadow: [
          BoxShadow(
            color: ball.isRed
                ? Colors.red.withOpacity(0.3)
                : Colors.blue.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          ball.num.toString().padLeft(2, '0'),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
