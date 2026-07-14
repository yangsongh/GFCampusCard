import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path show join;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart' show Lock;

class LoggerManager {
  late Logger _logger;
  late File _logFile;
  final String? _name;
  static final Lock _lock = Lock();

  // 构造函数为异步工厂
  static Future<LoggerManager> create(String? name) async {
    final instance = LoggerManager._(name);
    await instance._initLogger();
    return instance;
  }

  LoggerManager._(this._name);

  /// 初始化日志器
  Future<void> _initLogger() async {
    _logger = Logger(_name ?? 'LoggerManager');

    // 获取应用的外部缓存存储
    final cacheDir = await getExternalCacheDirectories();
    if (cacheDir == null || cacheDir.isEmpty) return;

    // 清除所有现有处理器
    _logger.clearListeners();

    // 启用层级日志级别控制, 允许非根 Logger 设置级别
    hierarchicalLoggingEnabled = true;

    // 设置日志级别 (关键, Release版本为INFO | Debug版本为FINE)
    _logger.level = bool.fromEnvironment('dart.vm.product')
        ? Level.INFO
        : Level.FINE;

    // 控制台处理器 (可单独控制输出级别)
    _logger.onRecord.listen((record) {
      if (record.level >= Level.FINE) {
        debugPrint(_formatConsoleRecord(record));
      }
    });

    // 文件处理器 (可单独控制输出级别)
    _logger.onRecord.listen((record) async {
      if (record.level >= Level.FINE) {
        await _lock.synchronized(() async {
          // 确保日志目录存在
          final logsDir = Directory(path.join(cacheDir.first.path, 'logs'));
          await logsDir.create(recursive: true);
          _logFile = File(path.join(logsDir.path, getLogFileName()));

          await _logFile.writeAsString(
            '${_formatFileRecord(record)}\n',
            mode: FileMode.append,
            flush: true,
          );
        });
      }
    });
  }

  /// 获取日志文件名
  String getLogFileName() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final fileName = _name != null ? '${dateStr}_$_name.log' : '$dateStr.log';
    return fileName;
  }

  String _formatConsoleRecord(LogRecord record) {
    final (file, line) = _getCallerInfo();
    return '${record.level.name[0]} $file:$line ${record.message}';
  }

  String _formatFileRecord(LogRecord record) {
    return '${_formatTime(record.time)} ${record.level.name[0]} ${record.message}';
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm:ss.SSS').format(time);
  }

  /// 获取调用者信息
  static (String file, int line) _getCallerInfo({int skipFrames = 14}) {
    try {
      final stack = StackTrace.current;
      final frames = stack.toString().split('\n');

      // 确保跳过足够的帧数
      if (frames.length > skipFrames) {
        final frame = frames[skipFrames];
        final match = RegExp(r'\((.*):(\d+):\d+\)').firstMatch(frame);
        if (match != null) {
          final file = match.group(1)!;
          final line = int.parse(match.group(2)!);

          // 只保留文件名部分
          final fileName = file.split('/').last;
          return (fileName, line);
        }
      }
    } catch (e) {
      // 如果解析失败, 返回默认值
    }
    return ('unknown', 0);
  }

  void info(String message) {
    _logger.info(message);
  }

  void warning(String message) {
    _logger.warning(message);
  }

  void error(String message) {
    _logger.severe(message);
  }

  void debug(String message) {
    _logger.fine(message);
  }
}
