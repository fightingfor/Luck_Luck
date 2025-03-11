import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../providers/ball_provider.dart';
import '../widgets/ball_item.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<BallProvider>().loadInitialData(
          onProgress: (message, progress) {
            if (mounted) {
              setState(() {});
            }
          },
        );
      }
    });
  }

  void _onRefresh() async {
    await context.read<BallProvider>().refreshData();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await context.read<BallProvider>().loadMoreData();
    _refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('开奖历史'),
        centerTitle: true,
      ),
      body: Consumer<BallProvider>(
        builder: (context, provider, child) {
          if (provider.balls.isEmpty && provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SmartRefresher(
            enablePullDown: true,
            enablePullUp: provider.hasMore,
            controller: _refreshController,
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            child: ListView.builder(
              itemCount: provider.balls.length,
              itemBuilder: (context, index) {
                final ball = provider.balls[index];
                return BallItem(ball: ball);
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }
}
