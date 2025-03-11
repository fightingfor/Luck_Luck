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

class PredictionResult {
  final List<int> redBalls;
  final int blueBall;
  final DateTime predictDate;
  final String periodNumber;
  bool? isCorrect;
  Map<String, double> accuracyDetails = {};

  // 开奖相关属性
  DateTime? drawDate; // 开奖日期
  List<int>? actualRedBalls; // 实际开奖红球
  int? actualBlueBall; // 实际开奖蓝球
  int? matchedRedCount; // 匹配的红球数量
  bool? matchedBlue; // 蓝球是否匹配
  int? prizeLevel; // 中奖等级，0表示未中奖，1-6表示对应等级

  PredictionResult({
    required this.redBalls,
    required this.blueBall,
    required this.predictDate,
    required this.periodNumber,
    this.isCorrect,
    Map<String, double>? accuracyDetails,
    this.drawDate,
    this.actualRedBalls,
    this.actualBlueBall,
    this.matchedRedCount,
    this.matchedBlue,
    this.prizeLevel,
  }) {
    this.accuracyDetails = accuracyDetails ?? {};
    // 计算开奖日期
    if (drawDate == null) {
      drawDate = _calculateDrawDate(predictDate);
    }
  }

  // 计算开奖日期（每周二、四、日开奖）
  static DateTime _calculateDrawDate(DateTime date) {
    // 如果当前时间是开奖日且在21:15之前，就用当天作为开奖日期
    int weekday = date.weekday;
    if ((weekday == DateTime.tuesday ||
            weekday == DateTime.thursday ||
            weekday == DateTime.sunday) &&
        (date.hour < 21 || (date.hour == 21 && date.minute < 15))) {
      return DateTime(date.year, date.month, date.day, 21, 15);
    }

    // 否则找下一个开奖日
    DateTime nextDate = date.add(const Duration(days: 1));
    while (true) {
      weekday = nextDate.weekday;
      if (weekday == DateTime.tuesday ||
          weekday == DateTime.thursday ||
          weekday == DateTime.sunday) {
        return DateTime(nextDate.year, nextDate.month, nextDate.day, 21, 15);
      }
      nextDate = nextDate.add(const Duration(days: 1));
    }
  }

  // 检查是否可以开奖
  bool canDraw() {
    if (drawDate == null) return false;
    if (actualRedBalls != null) return false; // 如果已经开奖，就不能再开奖

    final now = DateTime.now();
    // 如果还没到开奖时间
    if (now.isBefore(drawDate!)) return false;

    // 计算开奖时间后24小时的时间点
    final endTime = drawDate!.add(const Duration(hours: 24));
    // 如果当前时间在开奖时间和开奖后24小时之间，则可以开奖
    return now.isBefore(endTime);
  }

  // 计算中奖等级
  void calculatePrize(List<int> actualRed, int actualBlue) {
    actualRedBalls = actualRed;
    actualBlueBall = actualBlue;

    // 计算匹配的红球数量
    matchedRedCount = redBalls.where((ball) => actualRed.contains(ball)).length;
    matchedBlue = blueBall == actualBlue;

    // 计算中奖等级
    if (matchedRedCount == 6 && matchedBlue!) {
      prizeLevel = 1; // 一等奖
    } else if (matchedRedCount == 6) {
      prizeLevel = 2; // 二等奖
    } else if (matchedRedCount == 5 && matchedBlue!) {
      prizeLevel = 3; // 三等奖
    } else if ((matchedRedCount == 5) ||
        (matchedRedCount == 4 && matchedBlue!)) {
      prizeLevel = 4; // 四等奖
    } else if ((matchedRedCount == 4) ||
        (matchedRedCount == 3 && matchedBlue!)) {
      prizeLevel = 5; // 五等奖
    } else if (matchedBlue!) {
      prizeLevel = 6; // 六等奖
    } else {
      prizeLevel = 0; // 未中奖
    }
  }

  // 获取开奖结果描述
  String getPrizeDescription() {
    if (actualRedBalls == null || actualBlueBall == null) {
      return '未开奖';
    }

    String result = '';
    if (prizeLevel == 0) {
      result = '未中奖\n';
      result += '红球猜中：$matchedRedCount 个\n';
      result += '蓝球猜中：${matchedBlue! ? "是" : "否"}';
    } else {
      result = '恭喜中得 $prizeLevel 等奖！\n';
      result += '红球猜中：$matchedRedCount 个\n';
      result += '蓝球猜中：${matchedBlue! ? "是" : "否"}';
    }
    return result;
  }

  // 获取开奖时间描述
  String getDrawTimeDescription() {
    if (drawDate == null) return '未知开奖时间';

    // 格式化日期
    String dateStr =
        '${drawDate!.year}-${drawDate!.month.toString().padLeft(2, '0')}-${drawDate!.day.toString().padLeft(2, '0')} 21:15';

    // 如果已经开奖
    if (actualRedBalls != null) {
      return '开奖日期：$dateStr (已开奖)';
    }

    // 如果已过开奖时间但还未开奖
    if (DateTime.now().isAfter(drawDate!)) {
      return '开奖日期：$dateStr (等待开奖)';
    }

    // 未到开奖时间
    return '开奖日期：$dateStr';
  }
}

class PeriodStats {
  final int periodNumber;
  final List<int> redBalls;
  final int blueBall;
  final DateTime drawDate;
  final Map<String, dynamic> patterns; // 保存该期的特征模式

  PeriodStats({
    required this.periodNumber,
    required this.redBalls,
    required this.blueBall,
    required this.drawDate,
    Map<String, dynamic>? patterns,
  }) : patterns = patterns ?? {};

  // 分析该期的特征模式
  void analyzePatterns() {
    int oddCount = redBalls.where((ball) => ball % 2 == 1).length;
    int smallCount = redBalls.where((ball) => ball <= 16).length;
    bool hasConsecutive = false;
    for (int i = 0; i < redBalls.length - 1; i++) {
      if (redBalls[i + 1] - redBalls[i] == 1) {
        hasConsecutive = true;
        break;
      }
    }

    patterns.addAll({
      'odd_even_ratio': oddCount / 6.0,
      'small_large_ratio': smallCount / 6.0,
      'has_consecutive': hasConsecutive,
      'sum': redBalls.reduce((a, b) => a + b),
      'max_gap': redBalls.reduce((a, b) => b - a),
      'weekday': drawDate.weekday,
    });
  }
}
