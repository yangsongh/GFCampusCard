import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:gf_campus_card/app_configs.dart' show AppCfgs;
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart' show launchUrl;

class Utils {
  /// 转换13位时间戳为可读格式
  static String convertTime(int timestamp) {
    try {
      if (timestamp == 0) return '(时间转换失败)';
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
    } catch (e) {
      return '(时间转换失败: $timestamp - $e)';
    }
  }

  /// 分转元处理, 保留两位小数
  static String convertMoney(int fen) {
    try {
      return (fen / 100).toStringAsFixed(2);
    } catch (e) {
      return '(转换金额失败: $fen - $e)';
    }
  }

  /// 当前日期字符串
  static String get todayDateString =>
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// 当前月份字符串
  static String get currentMonthString {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// 日期格式化 (yyyy-MM-DD)
  static String formatYearDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// 月份格式化 (yyyy-MM)
  static String formatYearMonth(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  /// 提取带年日期部分 (YYYY-MM-DD)
  static String extractYearDate(String datetime) {
    // 长度检查
    if (datetime.length >= 10) {
      return datetime.substring(0, 10); // 取 YYYY-MM-DD 部分
    }
    return datetime;
  }

  /// 提取不带年日期时间部分 (MM-DD HH:MM:SS)
  static String extractNonYearDateTime(String datetime) {
    // 长度检查
    if (datetime.length >= 19) {
      return datetime.substring(5, 19); // 取 MM-DD HH:MM:SS 部分
    }
    return datetime;
  }

  // 提取不带年日期部分 (MM-DD)
  static String extractNonYearDate(String datetime) {
    // 长度检查
    if (datetime.length >= 10) {
      return datetime.substring(5, 10); // 取 MM-DD 部分
    }
    return datetime;
  }

  // 提取纯天数部分 (DD)
  static String extractPureDay(String datetime) {
    // 长度检查
    if (datetime.length >= 10) {
      return datetime.substring(8, 10); // DD 部分
    }
    return datetime;
  }

  /// 提取时间部分 (HH:MM:SS)
  static String extractTime(String datetime) {
    // 长度检查
    if (datetime.length >= 19) {
      return datetime.substring(11, 19); // 取 HH:MM:SS 部分
    }
    return datetime;
  }

  /// 检测图片是否存在且有效
  static Future<bool> isImageCached(String imagePath) async {
    try {
      final file = File(imagePath);
      // 检查文件是否存在
      if (!await file.exists()) {
        return false;
      }

      // 检查文件大小是否为0（可能损坏）
      if (await file.length() == 0) {
        return false;
      }
      // 尝试解码图片以验证是否损坏
      final bytes = await file.readAsBytes();
      await decodeImageFromList(bytes);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 打开浏览器链接
  static Future<void> launchURL(String url, Function(String) onError) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri)) {
        throw Exception(url);
      }
    } catch (e) {
      onError('打开浏览器链接失败: $e');
    }
  }

  /// 显示底部提示
  static Future<void> showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    VoidCallback? onShown,
  }) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.center),
          duration: duration,
          behavior: behavior,
        ),
      );
      onShown?.call();
    });
  }
}

class DatePickerUtils {
  /// 显示年份选择器
  static Future<void> showYearPicker({
    required BuildContext context,
    required DateTime selectedDate,
    required Function(int) onYearSelected,
  }) async {
    final now = DateTime.now();
    final firstDate = DateTime(2020);
    final lastDate = DateTime(now.year, now.month + 1);

    await showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择年份'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppCfgs.primaryColor,
                onPrimary: Colors.white,
              ),
            ),
            child: YearPicker(
              firstDate: firstDate,
              lastDate: lastDate,
              selectedDate: selectedDate,
              onChanged: (date) {
                Navigator.pop(context);
                onYearSelected(date.year);
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 显示月份选择器
  static Future<void> showMonthPicker({
    required BuildContext context,
    required int year,
    required Function(DateTime) onDateSelected,
  }) async {
    final now = DateTime.now();
    final maxMonth = year == now.year ? now.month : 12;

    await showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择月份'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Center(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
              ),
              itemCount: maxMonth,
              itemBuilder: (context, index) {
                final month = index + 1;
                return TextButton(
                  onPressed: () =>
                      Navigator.pop(context, DateTime(year, month)),
                  child: Text(
                    '$month月',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ).then((date) {
      if (date != null) {
        onDateSelected(date);
      }
    });
  }
}
