import 'package:flutter/material.dart';
import '../models/analysis_stats.dart';

class BallGrid extends StatelessWidget {
  final BallType ballType;
  final List<BallAnalysis> ballAnalysis;
  final BuildContext context;

  const BallGrid({
    super.key,
    required this.ballType,
    required this.ballAnalysis,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: ballType == BallType.red ? 33 : 16,
      itemBuilder: (context, index) {
        final number = index + 1;
        final analysis = ballAnalysis.firstWhere(
          (a) => a.number == number,
          orElse: () => BallAnalysis(number, ballType),
        );
        return _buildBallItem(analysis);
      },
    );
  }

  Widget _buildBallItem(BallAnalysis analysis) {
    return InkWell(
      onTap: () => _showBallDetails(analysis),
      child: Container(
        decoration: BoxDecoration(
          color: _getBallColor(analysis),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              analysis.number.toString().padLeft(2, '0'),
              style: TextStyle(
                color: Colors.white,
                fontSize: analysis.temperature == 'hot' ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${analysis.frequency}次',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBallColor(BallAnalysis analysis) {
    final baseColor = ballType == BallType.red ? Colors.red : Colors.blue;

    switch (analysis.temperature) {
      case 'hot':
        return baseColor;
      case 'warm':
        return baseColor.withOpacity(0.7);
      default:
        return baseColor.withOpacity(0.4);
    }
  }

  void _showBallDetails(BallAnalysis analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${ballType == BallType.red ? "红球" : "蓝球"} ${analysis.number.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: ballType == BallType.red ? Colors.red : Colors.blue,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('出现次数', '${analysis.frequency}次'),
            _buildDetailRow('当前遗漏', '${analysis.currentMissing}期'),
            _buildDetailRow('最大遗漏', '${analysis.maxMissing}期'),
            _buildDetailRow('平均遗漏', analysis.avgMissing.toStringAsFixed(1)),
            _buildDetailRow('当前间隔', '${analysis.currentGap}期'),
            _buildDetailRow('最大间隔', '${analysis.maxGap}期'),
            _buildDetailRow('平均间隔', analysis.avgGap.toStringAsFixed(1)),
            if (ballType == BallType.red) ...[
              const Divider(),
              const Text(
                '位置偏好',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildPositionStats(analysis),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionStats(BallAnalysis analysis) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return Column(
          children: [
            Text('${index + 1}位'),
            const SizedBox(height: 4),
            Text(
              '${analysis.positionFrequency[index]}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }),
    );
  }
}
