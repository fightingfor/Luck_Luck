import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ball_provider.dart';
import '../widgets/ball_item.dart';
import '../widgets/search_panel.dart';
import '../models/search_criteria.dart';
import '../models/ball_info.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ScrollController _scrollController = ScrollController();
  SearchCriteria? _currentCriteria;
  List<BallInfo>? _searchResults;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTotalCount();
    // 加载初始数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BallProvider>(context, listen: false);
      provider.loadInitialData(
        onProgress: (message, progress) {
          // 可以在这里处理加载进度
        },
      );
    });

    // 添加滚动监听
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        // 滚动到底部时加载更多数据
        if (_searchResults == null) {
          final provider = Provider.of<BallProvider>(context, listen: false);
          provider.loadMoreData();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTotalCount() async {
    final provider = Provider.of<BallProvider>(context, listen: false);
    final count = await provider.getTotalCount();
    setState(() {
      _totalCount = count;
    });
  }

  Future<void> _handleSearch(SearchCriteria criteria) async {
    final provider = Provider.of<BallProvider>(context, listen: false);
    final results = await provider.searchBalls(criteria);
    setState(() {
      _currentCriteria = criteria;
      _searchResults = results;
    });
  }

  void _clearSearch() {
    setState(() {
      _currentCriteria = null;
      _searchResults = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('历史开奖'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 搜索面板
            Expanded(
              flex: 0,
              child: SingleChildScrollView(
                child: SearchPanel(
                  onSearch: _handleSearch,
                  onClear: _clearSearch,
                ),
              ),
            ),

            // 数据统计
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('总记录数：$_totalCount'),
                  if (_searchResults != null)
                    Text('搜索结果：${_searchResults!.length}条'),
                ],
              ),
            ),

            // 数据列表
            Expanded(
              flex: 1,
              child: Consumer<BallProvider>(
                builder: (context, provider, child) {
                  if (_searchResults != null) {
                    // 显示搜索结果
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: _searchResults!.length,
                      itemBuilder: (context, index) {
                        return BallItem(ball: _searchResults![index]);
                      },
                    );
                  } else {
                    // 显示所有数据
                    return provider.isLoading && provider.balls.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: provider.balls.length +
                                (provider.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == provider.balls.length) {
                                return provider.isLoading
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : const SizedBox();
                              }
                              return BallItem(ball: provider.balls[index]);
                            },
                          );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
