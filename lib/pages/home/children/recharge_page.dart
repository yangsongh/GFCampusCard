import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gf_campus_card/app_configs.dart' show AppCfgs;
import 'package:gf_campus_card/service/gf_campus_card.dart' show GFCampusCard;
import 'package:gf_campus_card/utils/utils.dart' show DatePickerUtils, Utils;

class RechargePage extends StatefulWidget {
  final GFCampusCard campusCard;
  const RechargePage({super.key, required this.campusCard});

  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  Map<String, List<dynamic>> _rechargeRecords = {};
  bool _isLoading = true;
  DateTime _selectedYearMonth = DateTime.now();
  bool _isManualQuery = false;

  @override
  void initState() {
    super.initState();
    _fetchRecentRechargeRecords();
  }

  /// 获取最近几个月的充值记录
  Future<void> _fetchRecentRechargeRecords() async {
    try {
      setState(() => _isLoading = true);

      // 使用函数式风格生成月份范围（最近5个月）
      final months = List.generate(
        5,
        (i) => DateTime(DateTime.now().year, DateTime.now().month - i),
      );

      // 并行请求+自动构建Map
      final results = await Future.wait(
        months.map(
          (date) => widget.campusCard.getRechargeRecords(
            1,
            Utils.formatYearMonth(date),
          ),
        ),
      );

      if (!_isManualQuery) {
        setState(() {
          _rechargeRecords = Map.fromIterables(
            months.map((d) => '${d.year}年${d.month}月'),
            results.map((r) {
              if (r['success'] != true) {
                throw Exception(r['message']);
              }
              return r['data']['充值记录'] ?? [];
            }),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      unawaited(Utils.showSnackBar(context, '充值记录获取失败: $e'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 获取单月充值记录
  Future<void> _fetchSingleMonthRechargeRecords() async {
    try {
      setState(() {
        _isLoading = true;
        _isManualQuery = true;
      });

      final yearMonthStr = Utils.formatYearMonth(_selectedYearMonth);
      final result = await widget.campusCard.getRechargeRecords(
        1,
        yearMonthStr,
      );

      if (result['success'] != true) {
        throw Exception(result['message']);
      } else {
        final monthKey =
            '${_selectedYearMonth.year}年${_selectedYearMonth.month}月';
        setState(
          () => _rechargeRecords = {monthKey: result['data']['充值记录'] ?? []},
        );
      }
    } catch (e) {
      if (mounted) {
        unawaited(Utils.showSnackBar(context, '单月充值记录获取失败: $e'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 下拉刷新
  Future<void> _handleRefresh() async {
    if (_isManualQuery) {
      // 单月模式, 刷新当前选择的月份
      await _fetchSingleMonthRechargeRecords();
    } else {
      // 多月模式, 刷新最近几个月
      await _fetchRecentRechargeRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('充值记录'),
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
                  _fetchSingleMonthRechargeRecords();
                },
              ),
            ),
            tooltip: '选择月份',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rechargeRecords.isEmpty
          ? const Center(child: Text('暂无充值记录'))
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppCfgs.primaryColor,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: _rechargeRecords.entries.map((entry) {
                  return _buildMonthSection(entry.key, entry.value);
                }).toList(),
              ),
            ),
    );
  }

  /// 构建月份记录
  Widget _buildMonthSection(String month, List<dynamic> records) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 月份标题
          Padding(
            padding: EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppCfgs.primaryColor,
                  ),
                ),
                Text(
                  '共${records.length}条记录',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // 充值记录列表或空状态提示
          if (records.isNotEmpty)
            ...records.asMap().entries.map((entry) {
              final record = entry.value;
              final isLastItem = entry.key == records.length - 1;

              return _buildRecordItem(
                record,
                showBottomBorder: !isLastItem, // 最后一条不显示底部边框
              );
            })
          else
            Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 3),
                  Text(
                    '暂无充值记录',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 构建记录项目
  Widget _buildRecordItem(dynamic record, {bool showBottomBorder = true}) {
    final orderId = record['订单编号'];
    final rechargeDatetime = record['充值时间'];
    final receivedDatetime = record['到账时间'];
    final rechargeChannel = record['支付渠道'];
    final status = record['操作状态'];
    final accumulatedTotalAmount = record['商户累计入账'];
    final amount = record['充值金额'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 14, right: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：充值时间（黑色加粗）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '充值时间: ${Utils.extractNonYearDateTime(rechargeDatetime)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '¥$amount',
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppCfgs.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 第二行：到账时间（黑色加粗）
                  Text(
                    '到账时间: ${Utils.extractNonYearDateTime(receivedDatetime)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 16,
                      color: status.contains('成功')
                          ? AppCfgs.green
                          : status.contains('失败')
                          ? AppCfgs.primaryColor
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),

              // 第三行：支付渠道（灰色不加粗）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '支付渠道: $rechargeChannel',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 3),

              // 第四行：商户累计入账（灰色不加粗）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '商户累计入账: ¥$accumulatedTotalAmount',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 3),

              // 最后一行：订单号（灰色不加粗, 自动换行）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '订单号: $orderId',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),

              showBottomBorder
                  ? const Divider(height: 20) // 分隔线
                  : SizedBox(height: 15), // 空行
            ],
          ),
        ),
      ],
    );
  }
}
