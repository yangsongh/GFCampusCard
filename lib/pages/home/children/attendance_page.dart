import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:gf_campus_card/service/gf_campus_card.dart' show GFCampusCard;
import 'package:gf_campus_card/app_configs.dart' show AppCfgs;
import 'package:gf_campus_card/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

class AttendancePage extends StatefulWidget {
  final GFCampusCard campusCard;
  const AttendancePage({super.key, required this.campusCard});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  Map<String, List<dynamic>> _attendanceRecords = {};
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  bool _isManualQuery = false;
  bool _shouldShowPhotoHint = false;

  @override
  void initState() {
    super.initState();
    _checkShouldShowHint();
    _fetchRecentAttendanceRecords();
  }

  /// 获取最近几天的考勤记录
  Future<void> _fetchRecentAttendanceRecords() async {
    try {
      setState(() => _isLoading = true);

      // 使用函数式风格生成日期范围（最近7天）
      final dates = List.generate(
        7,
        (i) => DateTime.now().subtract(Duration(days: i)),
      );

      // 并行请求+自动构建Map
      final results = await Future.wait(
        dates.map(
          (date) => widget.campusCard.getAttendanceRecords(
            Utils.formatYearDate(date),
          ),
        ),
      );

      if (!_isManualQuery) {
        setState(() {
          _attendanceRecords = Map.fromIterables(
            dates.map(Utils.formatYearDate),
            results.map((r) {
              if (r['success'] != true) {
                throw Exception(r['message']);
              }
              return r['data'] ?? [];
            }),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      unawaited(Utils.showSnackBar(context, '考勤记录获取失败: $e'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 获取单日考勤记录
  Future<void> _fetchSingleDayRecords() async {
    try {
      setState(() {
        _isLoading = true;
        _isManualQuery = true;
      });

      final dateStr = Utils.formatYearDate(_selectedDate);
      final result = await widget.campusCard.getAttendanceRecords(dateStr);

      if (result['success'] != true) {
        throw Exception(result['message']);
      } else {
        setState(() => _attendanceRecords = {dateStr: result['data']});
      }
    } catch (e) {
      if (!mounted) return;
      unawaited(Utils.showSnackBar(context, '单日考勤记录获取失败: $e'));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 检查是否需要显示卡片提示
  Future<void> _checkShouldShowHint() async {
    final prefs = await SharedPreferences.getInstance();
    final loginCount = prefs.getInt('loginCount') ?? 0;
    _shouldShowPhotoHint = loginCount <= AppCfgs.showPhotoHintThreshold;
  }

  /// 下载并展示考勤图片
  Future<void> _downloadAndShowPhoto(
    BuildContext context,
    String attendanceDatetime,
  ) async {
    try {
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text('正在加载考勤照片...'),
              ],
            ),
          ),
        ),
      );

      final result = await widget.campusCard.downloadAttendancePictures(
        'attendance_images',
        attendanceDatetime,
      );

      if (result['success'] != true) {
        throw Exception(result['message']);
      } else {
        if (!context.mounted) return;
        Navigator.of(context).pop(); // 关闭“加载中”对话框

        final file = File(result['savePath']);
        unawaited(
          showDialog(
            context: context,
            builder: (_) => Dialog(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.error,
                      color: AppCfgs.primaryColor,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭“加载中”对话框
        unawaited(Utils.showSnackBar(context, '考勤照片下载失败: $e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('考勤记录'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '选择日期',
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showDatePicker(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _attendanceRecords.length,
              itemBuilder: (context, index) {
                final date = _attendanceRecords.keys.elementAt(index);
                final records = _attendanceRecords[date]!;
                return _buildDateGroup(date, records);
              },
            ),
    );
  }

  /// 显示自定义日期选择器
  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppCfgs.primaryColor,
              onPrimary: isDark
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _fetchSingleDayRecords();
    }
  }

  /// 构建单日考勤记录组
  Widget _buildDateGroup(String date, List<dynamic> records) {
    if (_shouldShowPhotoHint && records.isNotEmpty) {
      Utils.showSnackBar(
        context,
        '点击考勤记录卡片可查看考勤图片',
        duration: Duration(seconds: 3),
      );
      _shouldShowPhotoHint = false;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标题
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 16),
          child: Text(
            date,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppCfgs.primaryColor,
            ),
          ),
        ),

        // 空状态判断
        if (records.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 10, bottom: 5),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 3),
                  Text(
                    '暂无考勤记录',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

        // 渲染记录列表
        ...records.map((record) {
          final datetime = record['考勤时间'];
          final location = record['考勤地点'];
          final status = record['考勤状态'];
          final type = record['进出类型'];
          final statusColor = status == '正常'
              ? AppCfgs.green
              : status == '迟到'
              ? Colors.orange
              : AppCfgs.primaryColor;

          return Card(
            child: InkWell(
              borderRadius: const BorderRadius.all(
                Radius.circular(AppCfgs.radius),
              ),
              onTap: () => _downloadAndShowPhoto(context, datetime),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 第一行（时间+右侧两个状态）
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Utils.extractTime(datetime),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        // 两个状态标签（类型+状态）
                        Row(
                          children: [
                            _buildStatusTag(type, Colors.blue, Colors.white),
                            const SizedBox(width: 8),
                            _buildStatusTag(
                              status,
                              statusColor,
                              statusColor.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 第二行（地点）
                    Text(
                      location,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // 构建状态标签
  Widget _buildStatusTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
