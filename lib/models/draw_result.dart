class DrawResult {
  final String periodNumber;
  final List<int> matchedRed; // 匹配的红球
  final bool matchedBlue; // 是否匹配蓝球
  final int prize; // 中奖等级：1-6等奖，0表示未中奖
  final DateTime drawDate; // 开奖日期

  DrawResult({
    required this.periodNumber,
    required this.matchedRed,
    required this.matchedBlue,
    required this.prize,
    required this.drawDate,
  });

  // 获取中奖等级描述
  String get prizeDescription {
    switch (prize) {
      case 1:
        return '一等奖';
      case 2:
        return '二等奖';
      case 3:
        return '三等奖';
      case 4:
        return '四等奖';
      case 5:
        return '五等奖';
      case 6:
        return '六等奖';
      default:
        return '未中奖';
    }
  }

  // 计算中奖等级
  static int calculatePrize(int redCount, bool blueMatched) {
    if (redCount == 6 && blueMatched) return 1; // 一等奖：6红+1蓝
    if (redCount == 6) return 2; // 二等奖：6红
    if (redCount == 5 && blueMatched) return 3; // 三等奖：5红+1蓝
    if (redCount == 5 || (redCount == 4 && blueMatched))
      return 4; // 四等奖：5红或4红+1蓝
    if (redCount == 4 || (redCount == 3 && blueMatched))
      return 5; // 五等奖：4红或3红+1蓝
    if (blueMatched) return 6; // 六等奖：只中蓝球
    return 0; // 未中奖
  }

  Map<String, dynamic> toJson() => {
        'periodNumber': periodNumber,
        'matchedRed': matchedRed,
        'matchedBlue': matchedBlue,
        'prize': prize,
        'drawDate': drawDate.toIso8601String(),
      };

  factory DrawResult.fromJson(Map<String, dynamic> json) => DrawResult(
        periodNumber: json['periodNumber'],
        matchedRed: List<int>.from(json['matchedRed']),
        matchedBlue: json['matchedBlue'],
        prize: json['prize'],
        drawDate: DateTime.parse(json['drawDate']),
      );
}
