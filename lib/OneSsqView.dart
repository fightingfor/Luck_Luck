import 'package:flutter/material.dart';
import 'package:lucky_lucky/widgets/ball_view.dart';
import 'package:lucky_lucky/models/ball.dart';

class OneSsqView extends StatelessWidget {
  const OneSsqView({super.key, required this.balls});

  final List<Ball> balls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: balls.length,
          itemBuilder: (BuildContext context, int index) {
            final ball = balls[index];
            return Padding(
              padding: EdgeInsets.zero,
              child: BallView(
                ball: ball,
              ),
            );
          }),
    );
  }
}
