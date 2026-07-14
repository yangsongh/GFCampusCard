import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gf_campus_card/service/gf_campus_card.dart' show GFCampusCard;
import 'package:gf_campus_card/app_configs.dart' show AppCfgs;
import 'package:gf_campus_card/utils/utils.dart';

class ConsumptionPage extends StatefulWidget {
  final GFCampusCard campusCard;
  const ConsumptionPage({super.key, required this.campusCard});

  @override
  State<ConsumptionPage> createState() => _ConsumptionPageState();
}

class _ConsumptionPageState extends State<ConsumptionPage> {
  List<dynamic> _flowRecords = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  DateTime _selectedYearMonth = DateTime.now();
  bool _isManualQuery = false;
  final _pageSize = 15;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchFlowRecords();
    _scrollController.addListener(_scrollListener);
  }

  /// 滚动监听方法
  Future<void> _scrollListener() async {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMore) {
        setState(() {
          _isLoadingMore = true;
        });

        await _fetchFlowRecords(
          currentPage: _currentPage + 1,
          monthStr: _isManualQuery
              ? Utils.formatYearMonth(_selectedYearMonth)
              : '',
        );
      }
    }
  }

  /// 获取流水记录
  Future<void> _fetchFlowRecords({
    int currentPage = 1,
    String monthStr = '',
  }) async {
    try {
      setState(() {
        _isLoading = !_isLoadingMore;
        _isManualQuery = monthStr != '';
        _currentPage = currentPage;
      });

      final result = await widget.campusCard.getPersonalFlowRecords(
        currentPage,
        _pageSize,
        monthStr,
      );

      if (result['success'] != true) {
        throw Exception(result['message']);
      } else {
        final List<Map> newRecords = result['data']['消费记录'] ?? [];
        setState(() {
          if (_isLoadingMore) {
            _flowRecords.addAll(newRecords);
          } else {
            _flowRecords = newRecords;
          }
          _hasMore = result['data']['分页信息']['总记录数'] > _flowRecords.length;
        });
      }
    } catch (e) {
      if (!mounted) return;
      unawaited(Utils.showSnackBar(context, '流水记录获取失败: $e'));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  /// 下拉刷新
  Future<void> _handleRefresh() async {
    if (_isManualQuery) {
      // 单月模式, 刷新当前选择的月份
      await _fetchFlowRecords(
        monthStr: Utils.formatYearMonth(_selectedYearMonth),
      );
    } else {
      // 默认模式, 刷新最近30天
      await _fetchFlowRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消费流水'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => DatePickerUtils.showYearPicker(
              context: context,
              selectedDate: _selectedYearMonth,
              onYearSelected: (year) => DatePickerUtils.showMonthPicker(
                context: context,
                year: year,
                onDateSelected: (date) {
                  setState(() => _selectedYearMonth = date);
                  _fetchFlowRecords(
                    monthStr: Utils.formatYearMonth(_selectedYearMonth),
                  );
                },
              ),
            ),
            tooltip: '选择月份',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _flowRecords.isEmpty
          ? const Center(child: Text('暂无消费记录'))
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppCfgs.primaryColor,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _flowRecords.length + 1,
                itemBuilder: (context, index) {
                  if (index < _flowRecords.length) {
                    return _buildRecordItem(_flowRecords[index]);
                  } else {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: _isLoadingMore
                            ? const CircularProgressIndicator()
                            : const Text('没有更多数据了'),
                      ),
                    );
                  }
                },
              ),
            ),
    );
  }

  /// 构建单条消费记录项目
  Widget _buildRecordItem(Map<String, dynamic> record) {
    final datetime = record['交易时间'];
    final double amountDouble = (double.tryParse(record['交易金额']) ?? 0.0);
    final String amount = record['交易金额'];
    final String balance = record['交易后余额'];
    final String type = record['餐次/类型'];
    final String name = record['交易名称'];
    final String orderId = record['订单号'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：交易时间 + XX日 + 餐次/类型
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 交易时间
                Text(
                  datetime,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),

                // 右侧：XX日 + 餐次/类型
                Row(
                  children: [
                    // XX日提示
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${Utils.extractPureDay(datetime)}日',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // 餐次/类型
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),

            // 第二行：交易名称 + 金额信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 交易名称
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // 金额信息
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '¥$amount',
                      style: TextStyle(
                        color: amountDouble > 0
                            ? AppCfgs.green
                            : AppCfgs.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '余额: ¥$balance',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),

            // 第三行：订单号
            Text(
              '订单号: $orderId',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
