import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/search_criteria.dart';

class SearchPanel extends StatefulWidget {
  final Function(SearchCriteria) onSearch;
  final Function() onClear;

  const SearchPanel({
    Key? key,
    required this.onSearch,
    required this.onClear,
  }) : super(key: key);

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  late SearchCriteria _criteria;
  bool _isExpanded = false;
  final TextEditingController _redBallController = TextEditingController();
  final TextEditingController _blueBallController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _criteria = SearchCriteria();
  }

  @override
  void dispose() {
    _redBallController.dispose();
    _blueBallController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.w),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 快捷搜索栏
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickButton('最近10期', 10),
                        SizedBox(width: 8.w),
                        _buildQuickButton('最近30期', 30),
                        SizedBox(width: 8.w),
                        _buildQuickButton('最近50期', 50),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon:
                      Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),

          // 展开的高级搜索
          if (_isExpanded) ...[
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 号码搜索行
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _redBallController,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 12.h),
                            hintText: '红球号码',
                            prefixIcon: Icon(Icons.circle,
                                color: Colors.red, size: 16.w),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _criteria = SearchCriteria();
                              _criteria.redBalls = _parseNumbers(value);
                              if (_blueBallController.text.isNotEmpty) {
                                _criteria.blueBalls =
                                    _parseNumbers(_blueBallController.text);
                              }
                            });
                            if (_criteria.hasConditions) {
                              widget.onSearch(_criteria);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: TextField(
                          controller: _blueBallController,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 12.h),
                            hintText: '蓝球号码',
                            prefixIcon: Icon(Icons.circle,
                                color: Colors.blue, size: 16.w),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _criteria = SearchCriteria();
                              _criteria.blueBalls = _parseNumbers(value);
                              if (_redBallController.text.isNotEmpty) {
                                _criteria.redBalls =
                                    _parseNumbers(_redBallController.text);
                              }
                            });
                            if (_criteria.hasConditions) {
                              widget.onSearch(_criteria);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // 日期选择按钮
                  OutlinedButton.icon(
                    onPressed: () => _selectDateRange(context),
                    icon: Icon(Icons.date_range),
                    label: Text(
                      _criteria.startDate == null
                          ? '选择日期范围'
                          : '${_formatDate(_criteria.startDate!)} 至 ${_formatDate(_criteria.endDate!)}',
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // 按钮组
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _clearSearch,
                        child: Text('清除'),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton(
                        onPressed: () {
                          if (_criteria.hasConditions) {
                            setState(() {
                              _isExpanded = false;
                            });
                            widget.onSearch(_criteria);
                          }
                        },
                        child: Text('搜索'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickButton(String text, int periods) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _criteria = SearchCriteria();
          _criteria.setRecentPeriods(periods);
          _redBallController.clear();
          _blueBallController.clear();
          _isExpanded = false;
        });
        widget.onSearch(_criteria);
      },
      child: Text(text),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        side: BorderSide(color: Theme.of(context).primaryColor),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _criteria.startDate != null && _criteria.endDate != null
          ? DateTimeRange(
              start: _criteria.startDate!,
              end: _criteria.endDate!,
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _criteria = SearchCriteria();
        _criteria.setDateRange(picked.start, picked.end);
        _redBallController.clear();
        _blueBallController.clear();
        _isExpanded = false;
      });
      widget.onSearch(_criteria);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<int> _parseNumbers(String input) {
    if (input.isEmpty) return [];
    return input
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .where((n) => n != null)
        .map((n) => n!)
        .toList();
  }

  void _clearSearchWithoutCallback() {
    setState(() {
      _criteria = SearchCriteria();
      _redBallController.clear();
      _blueBallController.clear();
    });
  }

  void _clearSearch() {
    setState(() {
      _criteria = SearchCriteria();
      _redBallController.clear();
      _blueBallController.clear();
      _isExpanded = false;
    });
    widget.onSearch(_criteria);
  }
}
