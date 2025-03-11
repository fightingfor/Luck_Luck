import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/ball_info.dart';

class HistoryDataView extends StatelessWidget {
  final List<BallInfo> historyData;
  final ScrollController? scrollController;

  const HistoryDataView({
    Key? key,
    required this.historyData,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: historyData.length,
      itemBuilder: (context, index) {
        final ball = historyData[index];
        return _buildHistoryItem(context, ball);
      },
    );
  }

  Widget _buildHistoryItem(BuildContext context, BallInfo ball) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          // 点击展示详细信息
          _showDetailDialog(context, ball);
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 期号和日期行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '第${ball.qh}期',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    '${ball.kjTime} (${ball.zhou})',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // 红球和蓝球展示
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: ball.redBalls.map((number) {
                        return _buildBallWidget(
                          number.toString().padLeft(2, '0'),
                          Colors.red,
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  _buildBallWidget(
                    ball.blueBall.toString().padLeft(2, '0'),
                    Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBallWidget(String number, Color color) {
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          number,
          style: TextStyle(
            color: color,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, BallInfo ball) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('第${ball.qh}期详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('开奖日期: ${ball.kjTime}'),
            Text('星期: ${ball.zhou}'),
            SizedBox(height: 12.h),
            Text(
                '红球: ${ball.redBalls.map((n) => n.toString().padLeft(2, '0')).join(', ')}'),
            Text('蓝球: ${ball.blueBall.toString().padLeft(2, '0')}'),
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
}
