import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prediction_provider.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时检查开奖结果
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PredictionProvider>().checkDrawResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        centerTitle: true,
      ),
      body: Consumer<PredictionProvider>(
        builder: (context, provider, child) {
          final groupedFavorites = provider.getGroupedFavorites();

          if (groupedFavorites.isEmpty) {
            return const Center(
              child: Text(
                '暂无收藏的预测号码',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: groupedFavorites.entries.map((entry) {
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
                    final confidence =
                        (result.confidence * 100).toStringAsFixed(1);
                    final strategy = result.bettingStrategy;
                    final drawResult = result.drawResult;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                  color: double.parse(confidence) >= 70
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
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                              Text(
                                '蓝球：${result.blueBall}',
                                style: const TextStyle(color: Colors.blue),
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
                          if (drawResult != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '开奖结果：${drawResult.prizeDescription}',
                                    style: TextStyle(
                                      color: drawResult.prize > 0
                                          ? Colors.red
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (drawResult.matchedRed.isNotEmpty)
                                    Text(
                                      '中奖红球：${drawResult.matchedRed.join(", ")}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  if (drawResult.matchedBlue)
                                    const Text(
                                      '中奖蓝球：√',
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                ],
                              ),
                            ),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.favorite,
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
            }).toList(),
          );
        },
      ),
    );
  }
}
