class BallStats {
  final int number;
  int frequency = 0; // 出现频率
  int currentGap = 0; // 当前间隔
  double avgGap = 0; // 平均间隔
  int maxGap = 0; // 最大间隔
  int currentMissing = 0; // 当前遗漏值
  int maxMissing = 0; // 历史最大遗漏值
  double avgMissing = 0; // 平均遗漏值
  List<int> positionFreq = List.filled(6, 0); // 位置频率（红球专用）
  double weight = 100; // 综合权重

  // 历史同期数据
  int historicalPeriodFreq = 0; // 历史同期出现频率

  BallStats(this.number);

  // 计算热温冷状态
  String getTemperature(int totalPeriods) {
    double rate = frequency / totalPeriods;
    if (rate >= 0.3) return 'hot';
    if (rate >= 0.15) return 'warm';
    return 'cold';
  }

  // 重置统计数据
  void reset() {
    frequency = 0;
    currentGap = 0;
    avgGap = 0;
    maxGap = 0;
    currentMissing = 0;
    maxMissing = 0;
    avgMissing = 0;
    positionFreq = List.filled(6, 0);
    weight = 100;
    historicalPeriodFreq = 0;
  }
}

class NumberFeatures {
  final int sum;
  final double oddRatio;
  final double bigRatio;

  NumberFeatures({
    required this.sum,
    required this.oddRatio,
    required this.bigRatio,
  });

  static NumberFeatures analyze(List<int> numbers) {
    int sum = numbers.reduce((a, b) => a + b);
    int oddCount = numbers.where((n) => n % 2 == 1).length;
    int bigCount = numbers.where((n) => n > 16).length;

    return NumberFeatures(
      sum: sum,
      oddRatio: oddCount / numbers.length,
      bigRatio: bigCount / numbers.length,
    );
  }
}

class PeriodStats {
  final String periodNumber;
  final List<int> redBalls;
  final int blueBall;
  final DateTime drawDate;
  List<String> patterns = [];

  PeriodStats({
    required this.periodNumber,
    required this.redBalls,
    required this.blueBall,
    required this.drawDate,
  });

  void analyzePatterns() {
    // 分析号码特征
    final features = NumberFeatures.analyze(redBalls);

    // 记录特征
    if (features.sum >= 90 && features.sum <= 120) {
      patterns.add('和值适中');
    }

    if (features.oddRatio >= 0.4 && features.oddRatio <= 0.6) {
      patterns.add('奇偶均衡');
    }

    if (features.bigRatio >= 0.4 && features.bigRatio <= 0.6) {
      patterns.add('大小均衡');
    }
  }
}
