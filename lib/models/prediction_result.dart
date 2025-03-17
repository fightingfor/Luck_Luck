import 'package:flutter/foundation.dart';
import 'betting_strategy.dart';
import 'draw_result.dart';

class PredictionResult {
  final String periodNumber;
  final List<int> redBalls;
  final int blueBall;
  final DateTime predictDate;
  final double confidence;
  final BettingStrategy? bettingStrategy;
  DrawResult? drawResult;
  Map<String, double> accuracyDetails = {};
  final bool isFavorite;

  PredictionResult({
    required this.periodNumber,
    required this.redBalls,
    required this.blueBall,
    required this.predictDate,
    required this.confidence,
    this.bettingStrategy,
    this.drawResult,
    this.isFavorite = false,
  });

  PredictionResult copyWith({
    String? periodNumber,
    List<int>? redBalls,
    int? blueBall,
    DateTime? predictDate,
    double? confidence,
    BettingStrategy? bettingStrategy,
    DrawResult? drawResult,
    bool? isFavorite,
  }) {
    return PredictionResult(
      periodNumber: periodNumber ?? this.periodNumber,
      redBalls: redBalls ?? this.redBalls,
      blueBall: blueBall ?? this.blueBall,
      predictDate: predictDate ?? this.predictDate,
      confidence: confidence ?? this.confidence,
      bettingStrategy: bettingStrategy ?? this.bettingStrategy,
      drawResult: drawResult ?? this.drawResult,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  bool isDrawn() => drawResult != null;

  void calculatePrize(List<int> actualRed, int actualBlue) {
    List<int> matchedRed =
        redBalls.where((ball) => actualRed.contains(ball)).toList();
    bool matchedBlue = blueBall == actualBlue;

    int prize = DrawResult.calculatePrize(matchedRed.length, matchedBlue);

    drawResult = DrawResult(
      periodNumber: periodNumber,
      matchedRed: matchedRed,
      matchedBlue: matchedBlue,
      prize: prize,
      drawDate: DateTime.now(),
    );

    accuracyDetails = {
      'red_accuracy': matchedRed.length / 6.0,
      'blue_accuracy': matchedBlue ? 1.0 : 0.0,
      'total_accuracy':
          (matchedRed.length / 6.0 + (matchedBlue ? 1.0 : 0.0)) / 2.0,
    };
  }

  bool canDraw() {
    return accuracyDetails.isEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'periodNumber': periodNumber,
      'redBalls': redBalls,
      'blueBall': blueBall,
      'predictDate': predictDate.toIso8601String(),
      'confidence': confidence,
      'bettingStrategy': bettingStrategy?.toJson(),
      'drawResult': drawResult?.toJson(),
      'accuracyDetails': accuracyDetails,
      'isFavorite': isFavorite,
    };
  }

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      periodNumber: json['periodNumber'] as String,
      redBalls: List<int>.from(json['redBalls'] as List),
      blueBall: json['blueBall'] as int,
      predictDate: DateTime.parse(json['predictDate'] as String),
      confidence: json['confidence'] as double,
      bettingStrategy: json['bettingStrategy'] != null
          ? BettingStrategy.fromJson(
              json['bettingStrategy'] as Map<String, dynamic>)
          : null,
      drawResult: json['drawResult'] != null
          ? DrawResult.fromJson(json['drawResult'] as Map<String, dynamic>)
          : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
    )..accuracyDetails =
        Map<String, double>.from(json['accuracyDetails'] ?? {});
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PredictionResult &&
        other.periodNumber == periodNumber &&
        listEquals(other.redBalls, redBalls) &&
        other.blueBall == blueBall &&
        other.predictDate == predictDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      periodNumber,
      Object.hashAll(redBalls),
      blueBall,
      predictDate,
    );
  }
}
