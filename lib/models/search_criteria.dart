import 'package:flutter/material.dart';

class SearchCriteria {
  // 期数范围
  int? recentPeriods; // 最近几期
  int? startPeriod; // 起始期号
  int? endPeriod; // 结束期号

  // 日期范围
  DateTime? startDate; // 开始日期
  DateTime? endDate; // 结束日期

  // 号码搜索
  List<int> redBalls = []; // 红球号码
  List<int> blueBalls = []; // 蓝球号码

  SearchCriteria({
    this.recentPeriods,
    this.startPeriod,
    this.endPeriod,
    this.startDate,
    this.endDate,
    List<int>? redBalls,
    List<int>? blueBalls,
  }) {
    this.redBalls = redBalls?.toList() ?? [];
    this.blueBalls = blueBalls?.toList() ?? [];
  }

  // 检查是否有搜索条件
  bool get hasConditions {
    return recentPeriods != null ||
        startPeriod != null ||
        endPeriod != null ||
        startDate != null ||
        endDate != null ||
        redBalls.isNotEmpty ||
        blueBalls.isNotEmpty;
  }

  // 清除所有条件
  void clear() {
    recentPeriods = null;
    startPeriod = null;
    endPeriod = null;
    startDate = null;
    endDate = null;
    redBalls.clear();
    blueBalls.clear();
  }

  // 设置最近期数
  void setRecentPeriods(int periods) {
    recentPeriods = periods;
    startPeriod = null;
    endPeriod = null;
    startDate = null;
    endDate = null;
  }

  // 设置期号范围
  void setPeriodRange(int? start, int? end) {
    startPeriod = start;
    endPeriod = end;
    recentPeriods = null;
    startDate = null;
    endDate = null;
  }

  // 设置日期范围
  void setDateRange(DateTime? start, DateTime? end) {
    startDate = start;
    endDate = end;
    recentPeriods = null;
    startPeriod = null;
    endPeriod = null;
  }
}
