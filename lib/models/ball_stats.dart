class BallStats {
  final int number;
  int frequency = 0;
  int currentGap = 0;
  int maxGap = 0;
  double avgGap = 0.0;
  double weight = 100.0;
  int historicalPeriodFreq = 0;
  List<int> positionFreq = List.filled(6, 0);
  int positionPreference = -1;
  Set<int> adjacentNumbers = {};

  // 新增特征
  List<int> recentGaps = [];
  bool isHot = false;
  bool isCold = false;
  double seasonalWeight = 1.0;
  double avgPeriod = 0.0;

  BallStats(this.number);

  void reset() {
    frequency = 0;
    currentGap = 0;
    maxGap = 0;
    avgGap = 0.0;
    weight = 100.0;
    historicalPeriodFreq = 0;
    positionFreq = List.filled(6, 0);
    positionPreference = -1;
    adjacentNumbers.clear();
    recentGaps.clear();
    isHot = false;
    isCold = false;
    seasonalWeight = 1.0;
    avgPeriod = 0.0;
  }

  String getTemperature(int totalPeriods) {
    double ratio = frequency / totalPeriods;
    if (ratio >= 0.2) return 'hot';
    if (ratio >= 0.15) return 'warm';
    return 'cold';
  }
}
