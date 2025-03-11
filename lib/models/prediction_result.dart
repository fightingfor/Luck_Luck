import 'package:flutter/foundation.dart';

@immutable
class PredictionResult {
  final String periodNumber;
  final List<int> redBalls;
  final int blueBall;
  final DateTime predictDate;
  final Map<String, double> accuracyDetails;

  const PredictionResult({
    required this.periodNumber,
    required this.redBalls,
    required this.blueBall,
    required this.predictDate,
    this.accuracyDetails = const {},
  });

  PredictionResult copyWith({
    String? periodNumber,
    List<int>? redBalls,
    int? blueBall,
    DateTime? predictDate,
    Map<String, double>? accuracyDetails,
  }) {
    return PredictionResult(
      periodNumber: periodNumber ?? this.periodNumber,
      redBalls: redBalls ?? this.redBalls,
      blueBall: blueBall ?? this.blueBall,
      predictDate: predictDate ?? this.predictDate,
      accuracyDetails: accuracyDetails ?? this.accuracyDetails,
    );
  }

  PredictionResult calculatePrize(List<int> actualRed, int actualBlue) {
    int redMatches = redBalls.where((ball) => actualRed.contains(ball)).length;
    bool blueMatch = blueBall == actualBlue;

    double redAccuracy = redMatches / 6.0;
    double blueAccuracy = blueMatch ? 1.0 : 0.0;

    return copyWith(
      accuracyDetails: {
        'red_accuracy': redAccuracy,
        'blue_accuracy': blueAccuracy,
        'total_accuracy': (redAccuracy + blueAccuracy) / 2,
      },
    );
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
      'accuracyDetails': accuracyDetails,
    };
  }

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      periodNumber: json['periodNumber'] as String,
      redBalls: List<int>.from(json['redBalls'] as List),
      blueBall: json['blueBall'] as int,
      predictDate: DateTime.parse(json['predictDate'] as String),
      accuracyDetails: json.containsKey('accuracyDetails')
          ? Map<String, double>.from(json['accuracyDetails'] as Map)
          : const {},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PredictionResult &&
        other.periodNumber == periodNumber &&
        listEquals(other.redBalls, redBalls) &&
        other.blueBall == blueBall &&
        other.predictDate == predictDate &&
        mapEquals(other.accuracyDetails, accuracyDetails);
  }

  @override
  int get hashCode {
    return Object.hash(
      periodNumber,
      Object.hashAll(redBalls),
      blueBall,
      predictDate,
      Object.hashAll(accuracyDetails.entries),
    );
  }
}
