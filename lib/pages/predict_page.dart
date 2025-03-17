import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prediction_provider.dart';
import '../models/prediction_stats.dart';
import '../pages/analysis_page.dart';

class PredictPage extends StatefulWidget {
  const PredictPage({super.key});

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startPrediction() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    _controller.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 1500));
    await context.read<PredictionProvider>().generatePrediction();

    setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能预测'),
        centerTitle: true,
      ),
      body: Consumer<PredictionProvider>(
        builder: (context, provider, child) {
          final prediction = provider.currentPrediction;
          final history = provider.getPredictionHistory();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // 当前预测结果卡片
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '本期预测',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (prediction != null)
                                  Text(
                                    '期号：${prediction.periodNumber}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  if (prediction == null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.psychology,
                                        size: 48,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      '人工智能预测',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '基于大数据分析和机器学习算法',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '已分析 ${provider.getAnalyzedCount()} 期历史数据',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ] else ...[
                                    Row(
                                      children: [
                                        const Text('红球：'),
                                        Expanded(
                                          child: _isGenerating
                                              ? const LinearProgressIndicator()
                                              : Text(
                                                  prediction.redBalls
                                                      .join(', '),
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        const Text('蓝球：'),
                                        Expanded(
                                          child: _isGenerating
                                              ? const LinearProgressIndicator()
                                              : Text(
                                                  prediction.blueBall
                                                      .toString(),
                                                  style: const TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed:
                                        _isGenerating ? null : _startPrediction,
                                    icon: Icon(prediction == null
                                        ? Icons.auto_awesome
                                        : Icons.refresh),
                                    label: Text(_isGenerating
                                        ? '正在生成...'
                                        : (prediction == null
                                            ? '开始预测'
                                            : '重新预测')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 历史预测列表
                    if (history.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '历史预测',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('清除历史预测'),
                                  content: const Text('确定要清除所有历史预测记录吗？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await provider.clearPredictionHistory();
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: const Text(
                                        '确定',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_outline, size: 20),
                            label: const Text('清除'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 按期号分组显示历史预测
                      ...provider.getGroupedPredictionHistory().entries.map(
                        (entry) {
                          final periodNumber = entry.key;
                          final predictions = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              title: Text(
                                '第 $periodNumber 期',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              children: predictions.map((result) {
                                final confidence = (result.confidence * 100)
                                    .toStringAsFixed(1);
                                final strategy = result.bettingStrategy;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '期号：${result.periodNumber}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '可信度：$confidence%',
                                            style: TextStyle(
                                              color:
                                                  double.parse(confidence) >= 70
                                                      ? Colors.green
                                                      : Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '红球：${result.redBalls.join(", ")}',
                                              style: const TextStyle(
                                                  color: Colors.red),
                                            ),
                                          ),
                                          Text(
                                            '蓝球：${result.blueBall}',
                                            style: const TextStyle(
                                                color: Colors.blue),
                                          ),
                                        ],
                                      ),
                                      if (strategy != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '建议：${strategy.multiple}倍 (${strategy.amount}元)',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          strategy.explanation,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (result.accuracyDetails.isNotEmpty)
                                            Icon(
                                              Icons.check_circle,
                                              color: result.accuracyDetails[
                                                          'total_accuracy']! >
                                                      0.5
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                          IconButton(
                                            icon: Icon(
                                              provider.isFavorite(result)
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                provider.toggleFavorite(result),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ).toList(),
                    ],

                    const SizedBox(height: 16),
                    // 数据分析入口
                    Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AnalysisPage(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.analytics,
                                      color: Colors.blue),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '数据分析',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '已分析 ${provider.getAnalyzedCount()} 期',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildAnalysisFeature(
                                    icon: Icons.show_chart,
                                    label: '走势分析',
                                    color: Colors.blue,
                                  ),
                                  _buildAnalysisFeature(
                                    icon: Icons.whatshot,
                                    label: '冷热分析',
                                    color: Colors.orange,
                                  ),
                                  _buildAnalysisFeature(
                                    icon: Icons.grid_on,
                                    label: '位置分析',
                                    color: Colors.green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnalysisFeature({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 48,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
