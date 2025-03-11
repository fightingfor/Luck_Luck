enum BallType { red, blue }

class BallAnalysis {
  final int number;
  final BallType type;

  // 基础统计
  int frequency = 0; // 出现频率
  int currentMissing = 0; // 当前遗漏值
  int maxMissing = 0; // 最大遗漏值
  double avgMissing = 0.0; // 平均遗漏值

  // 间隔统计
  int currentGap = 0; // 当前间隔
  int maxGap = 0; // 最大间隔
  double avgGap = 0.0; // 平均间隔

  // 位置统计（仅红球）
  List<int> positionFrequency = List.filled(6, 0); // 各位置出现次数

  // 综合权重
  double weight = 100.0;

  // 温度状态
  String? temperature;

  BallAnalysis(this.number, this.type);

  // 更新统计数据
  void updateStats(int index, int position, int totalPeriods) {
    frequency++;

    // 更新间隔统计
    if (currentGap > maxGap) maxGap = currentGap;
    double totalGap = (avgGap * (frequency - 1) + currentGap) / frequency;
    avgGap = totalGap;
    currentGap = 0;

    // 更新遗漏值统计
    if (currentMissing > maxMissing) maxMissing = currentMissing;
    double totalMissing =
        (avgMissing * (frequency - 1) + currentMissing) / frequency;
    avgMissing = totalMissing;
    currentMissing = 0;

    // 更新位置频率（仅红球）
    if (type == BallType.red && position < 6) {
      positionFrequency[position]++;
    }

    // 更新温度状态
    double rate = frequency / totalPeriods;
    if (rate >= 0.3) {
      temperature = 'hot';
    } else if (rate >= 0.15) {
      temperature = 'warm';
    } else {
      temperature = 'cold';
    }

    // 更新权重
    _updateWeight();
  }

  // 更新权重
  void _updateWeight() {
    weight = 100.0;

    // 根据温度调整权重
    switch (temperature) {
      case 'hot':
        weight += 20;
        break;
      case 'warm':
        weight += 10;
        break;
      case 'cold':
        weight += 5;
        break;
    }

    // 根据遗漏值调整权重
    if (currentMissing > avgMissing) {
      weight += (currentMissing - avgMissing) * 2;
    }

    // 根据位置频率调整权重（仅红球）
    if (type == BallType.red) {
      int maxPosFreq = positionFrequency.reduce((a, b) => a > b ? a : b);
      if (maxPosFreq > 0) {
        weight += maxPosFreq * 2;
      }
    }
  }
}

class TrendData {
  final int qh;
  final DateTime drawDate;
  final List<int> redBalls;
  final int blueBall;

  // 特征统计
  late final int redSum; // 红球和值
  late final double oddEvenRatio; // 奇偶比
  late final double bigSmallRatio; // 大小比
  late final bool hasConsecutive; // 是否有连号
  late final int maxGap; // 最大间隔

  TrendData({
    required this.qh,
    required this.drawDate,
    required this.redBalls,
    required this.blueBall,
  }) {
    _calculateFeatures();
  }

  // 计算特征
  void _calculateFeatures() {
    redSum = redBalls.reduce((a, b) => a + b);

    int oddCount = redBalls.where((n) => n % 2 == 1).length;
    oddEvenRatio = oddCount / 6.0;

    int bigCount = redBalls.where((n) => n > 16).length;
    bigSmallRatio = bigCount / 6.0;

    // Calculate hasConsecutive
    bool foundConsecutive = false;
    for (int i = 0; i < redBalls.length - 1; i++) {
      if (redBalls[i + 1] - redBalls[i] == 1) {
        foundConsecutive = true;
        break;
      }
    }
    hasConsecutive = foundConsecutive;

    maxGap = redBalls.reduce((a, b) => b - a);
  }
}

class NumberFeatures {
  final int sum; // 号码和值
  final double oddRatio; // 奇数比例
  final double bigRatio; // 大号比例
  final bool hasConsecutive; // 是否有连号
  final int maxGap; // 最大间隔
  final int ac; // AC值（邻号差值和）
  final List<int> gaps; // 号码间隔序列

  NumberFeatures({
    required this.sum,
    required this.oddRatio,
    required this.bigRatio,
    required this.hasConsecutive,
    required this.maxGap,
    required this.ac,
    required this.gaps,
  });

  factory NumberFeatures.analyze(List<int> numbers) {
    numbers.sort();
    int sum = numbers.reduce((a, b) => a + b);
    int oddCount = numbers.where((n) => n % 2 == 1).length;
    int bigCount = numbers.where((n) => n > 16).length;

    bool consecutive = false;
    int ac = 0;
    List<int> gaps = [];

    for (int i = 0; i < numbers.length - 1; i++) {
      int gap = numbers[i + 1] - numbers[i];
      gaps.add(gap);
      ac += gap;
      if (gap == 1) consecutive = true;
    }

    return NumberFeatures(
      sum: sum,
      oddRatio: oddCount / numbers.length,
      bigRatio: bigCount / numbers.length,
      hasConsecutive: consecutive,
      maxGap: gaps.reduce((a, b) => a > b ? a : b),
      ac: ac,
      gaps: gaps,
    );
  }
}
