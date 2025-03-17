class BettingStrategy {
  final int multiple;
  final double amount;
  final String explanation;
  final String riskLevel;
  final double expectedReturn;

  const BettingStrategy({
    required this.multiple,
    required this.amount,
    required this.explanation,
    this.riskLevel = '中等',
    this.expectedReturn = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'multiple': multiple,
      'amount': amount,
      'explanation': explanation,
      'riskLevel': riskLevel,
      'expectedReturn': expectedReturn,
    };
  }

  factory BettingStrategy.fromJson(Map<String, dynamic> json) {
    return BettingStrategy(
      multiple: json['multiple'] as int,
      amount: json['amount'] as double,
      explanation: json['explanation'] as String,
      riskLevel: json['riskLevel'] as String? ?? '中等',
      expectedReturn: json['expectedReturn'] as double? ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BettingStrategy &&
        other.multiple == multiple &&
        other.amount == amount &&
        other.explanation == explanation &&
        other.riskLevel == riskLevel &&
        other.expectedReturn == expectedReturn;
  }

  @override
  int get hashCode {
    return Object.hash(
      multiple,
      amount,
      explanation,
      riskLevel,
      expectedReturn,
    );
  }
}
