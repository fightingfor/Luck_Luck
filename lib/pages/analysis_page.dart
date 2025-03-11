import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../models/analysis_stats.dart';
import '../widgets/ball_grid.dart';
import '../widgets/trend_chart.dart';
import '../widgets/analysis_card.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据分析'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '号码分析'),
            Tab(text: '走势图'),
            Tab(text: '冷热分析'),
            Tab(text: '位置分析'),
          ],
        ),
      ),
      body: Consumer<AnalysisProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNumberAnalysisTab(provider),
              _buildTrendChartTab(provider),
              _buildHotColdAnalysisTab(provider),
              _buildPositionAnalysisTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNumberAnalysisTab(AnalysisProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 红球分析
        AnalysisCard(
          title: '红球分析',
          child: BallGrid(
            context: context,
            ballType: BallType.red,
            ballAnalysis: provider.getAllRedBallAnalysis(),
          ),
        ),
        const SizedBox(height: 16),
        // 蓝球分析
        AnalysisCard(
          title: '蓝球分析',
          child: BallGrid(
            context: context,
            ballType: BallType.blue,
            ballAnalysis: provider.getAllBlueBallAnalysis(),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChartTab(AnalysisProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AnalysisCard(
          title: '近30期走势',
          child: TrendChart(
            trendData: provider.getTrendData(),
          ),
        ),
        const SizedBox(height: 16),
        AnalysisCard(
          title: '特征统计',
          child: _buildFeatureStats(provider),
        ),
      ],
    );
  }

  Widget _buildHotColdAnalysisTab(AnalysisProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 红球冷热分析
        AnalysisCard(
          title: '红球冷热分析',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHotColdSection(
                  '热门红球', provider.getHotNumbers(BallType.red)),
              const SizedBox(height: 16),
              _buildHotColdSection(
                  '冷门红球', provider.getColdNumbers(BallType.red)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 蓝球冷热分析
        AnalysisCard(
          title: '蓝球冷热分析',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHotColdSection(
                  '热门蓝球', provider.getHotNumbers(BallType.blue)),
              const SizedBox(height: 16),
              _buildHotColdSection(
                  '冷门蓝球', provider.getColdNumbers(BallType.blue)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPositionAnalysisTab(AnalysisProvider provider) {
    final positionPreference = provider.getPositionPreference();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AnalysisCard(
          title: '红球位置偏好分析',
          child: Column(
            children: List.generate(6, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPositionRow(index + 1, positionPreference[index]),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureStats(AnalysisProvider provider) {
    final trends = provider.getTrendData();
    if (trends.isEmpty) return const SizedBox();

    final latest = trends.first;
    return Column(
      children: [
        _buildFeatureRow('和值', latest.redSum.toString()),
        _buildFeatureRow(
            '奇偶比', '${(latest.oddEvenRatio * 100).toStringAsFixed(1)}%'),
        _buildFeatureRow(
            '大小比', '${(latest.bigSmallRatio * 100).toStringAsFixed(1)}%'),
        _buildFeatureRow('是否有连号', latest.hasConsecutive ? '是' : '否'),
        _buildFeatureRow('最大间隔', latest.maxGap.toString()),
      ],
    );
  }

  Widget _buildFeatureRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotColdSection(String title, List<BallAnalysis> balls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: balls.map((ball) {
            return _buildBallChip(ball);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBallChip(BallAnalysis ball) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ball.type == BallType.red ? Colors.red[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ball.number.toString().padLeft(2, '0'),
            style: TextStyle(
              color: ball.type == BallType.red ? Colors.red : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${ball.frequency}次',
            style: TextStyle(
              color: ball.type == BallType.red
                  ? Colors.red[700]
                  : Colors.blue[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionRow(int position, Map<int, int> frequencies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '第$position位',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: frequencies.entries
              .where((e) => e.value > 0)
              .map((e) => _buildPositionChip(e.key, e.value))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPositionChip(int number, int frequency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            number.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${frequency}次',
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
