import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prediction_provider.dart';
import '../models/prediction_stats.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        centerTitle: true,
      ),
      body: Consumer<PredictionProvider>(
        builder: (context, provider, child) {
          final favorites = provider.getFavorites();
          if (favorites.isEmpty) {
            return const Center(
              child: Text('暂无收藏的预测号码'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final prediction = favorites[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '期号：${prediction.periodNumber}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.red),
                            onPressed: () =>
                                provider.toggleFavorite(prediction),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('红球：'),
                          Expanded(
                            child: Text(
                              prediction.redBalls.join(', '),
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('蓝球：'),
                          Text(
                            prediction.blueBall.toString(),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        prediction.getDrawTimeDescription(),
                        style: TextStyle(
                          color: prediction.canDraw()
                              ? Colors.red
                              : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: prediction.canDraw()
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (prediction.actualRedBalls != null) ...[
                        const Divider(),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: prediction.prizeLevel == 0
                                ? Colors.grey[100]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    prediction.prizeLevel == 0
                                        ? Icons.info_outline
                                        : Icons.emoji_events,
                                    color: prediction.prizeLevel == 0
                                        ? Colors.grey
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '开奖结果',
                                    style: TextStyle(
                                      color: prediction.prizeLevel == 0
                                          ? Colors.grey[600]
                                          : Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '开奖号码：',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text('红球：'),
                                  Expanded(
                                    child: Text(
                                      prediction.actualRedBalls!.join(', '),
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text('蓝球：'),
                                  Text(
                                    prediction.actualBlueBall.toString(),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                prediction.getPrizeDescription(),
                                style: TextStyle(
                                  color: prediction.prizeLevel == 0
                                      ? Colors.grey[600]
                                      : Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (prediction.canDraw()) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.notifications_active,
                                color: Colors.red,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '已到开奖时间',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      provider.drawPrediction(prediction),
                                  icon: const Icon(Icons.casino),
                                  label: const Text('立即开奖'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
