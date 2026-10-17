import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gf_campus_card/app_configs.dart';
import 'package:gf_campus_card/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  int _loginCount = 0;
  bool _isClearing = false;
  double _cacheSizeMB = 0;
  bool _checkServiceLimit = true;

  @override
  void initState() {
    super.initState();
    _loadLoginCount();
    _calculateCacheSize();
    _loadServiceLimitSetting();
  }

  /// 计算缓存大小
  Future<void> _calculateCacheSize() async {
    try {
      final cacheDir = await getExternalCacheDirectories();
      if (cacheDir == null || cacheDir.isEmpty) throw Exception('无法获取外部缓存目录');

      // 计算文件夹大小（字节）
      int totalSize = 0;
      cacheDir.first.listSync(recursive: true).forEach((file) {
        if (file is File) {
          totalSize += file.lengthSync();
        }
      });

      // 转换为MB并更新状态
      setState(() {
        _cacheSizeMB = totalSize / (1024 * 1024);
      });
    } catch (e) {
      if (!mounted) return;
      unawaited(Utils.showSnackBar(context, '计算缓存大小失败: $e'));
    }
  }

  /// 清理外部缓存
  Future<void> _clearExternalCache() async {
    try {
      setState(() => _isClearing = true);

      // 清理图片缓存
      final cacheDir = await getExternalCacheDirectories();
      if (cacheDir == null || cacheDir.isEmpty) throw Exception('无法获取外部缓存目录');

      cacheDir.first.deleteSync(recursive: true);
      await _calculateCacheSize(); // 清理后刷新大小

      if (!mounted) return;
      unawaited(
        Utils.showSnackBar(context, '外部缓存已清除', duration: Duration(seconds: 3)),
      );
    } catch (e) {
      if (!mounted) return;
      unawaited(Utils.showSnackBar(context, '清理失败: $e'));
    } finally {
      setState(() => _isClearing = false);
    }
  }

  /// 加载登录次数
  Future<void> _loadLoginCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loginCount = prefs.getInt('loginCount') ?? 0;
    });
  }

  /// 加载服务限制设置
  Future<void> _loadServiceLimitSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _checkServiceLimit = prefs.getBool('checkServiceLimit') ?? true;
    });
  }

  /// 切换服务限制检测
  Future<void> _toggleServiceLimitCheck(bool value) async {
    // 如果是开启操作, 直接执行
    if (value) {
      await _updateServiceLimitSetting(value);
      return;
    }

    // 如果是关闭操作, 需要验证密码
    final passwordController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('验证密码'),
        content: Container(
          decoration: AppCfgs.inputBoxDecoration, // 阴影
          child: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: '请输入调试密码',
              prefixIcon: Icon(Icons.lock),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (passwordController.text == AppCfgs.debugModePassword) {
                _updateServiceLimitSetting(value);
                Navigator.pop(context);
              } else {
                Utils.showSnackBar(
                  context,
                  '密码错误',
                  duration: Duration(seconds: 2),
                );
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  /// 更新服务限制设置的共享方法
  Future<void> _updateServiceLimitSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('checkServiceLimit', value);
    if (!mounted) return;
    setState(() {
      _checkServiceLimit = value;
    });
    unawaited(Utils.showSnackBar(context, '主页下拉刷新或重新登录后生效'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('调试界面'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppCfgs.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 登录次数显示
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: AppCfgs.primaryColor),
                      const SizedBox(width: 10),
                      Text('累计登录次数: $_loginCount'),
                    ],
                  ),
                ),
              ),

              // 缓存大小显示
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.storage, color: AppCfgs.primaryColor),
                      const SizedBox(width: 10),
                      Text('外部缓存大小: ${_cacheSizeMB.toStringAsFixed(2)} MB'),
                    ],
                  ),
                ),
              ),

              // 服务限制开关
              Card(
                child: SwitchListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppCfgs.radius),
                  ),
                  title: const Text('检测服务限制'),
                  value: _checkServiceLimit,
                  onChanged: _toggleServiceLimitCheck,
                  secondary: const Icon(
                    Icons.security,
                    color: AppCfgs.primaryColor,
                  ),
                  activeThumbColor: AppCfgs.primaryColor,
                ),
              ),

              const SizedBox(height: 20),

              // 缓存清理按钮
              ElevatedButton.icon(
                icon: _isClearing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.grey,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Icon(Icons.delete_forever),
                label: Text(_isClearing ? '清理中' : '清空外部缓存'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppCfgs.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isClearing ? null : _clearExternalCache,
              ),

              // 调试信息（可选）
              const SizedBox(height: 30),
              const Text(
                '调试信息:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Flutter SDK: ${Platform.version}'),
              Text('设备: ${Platform.operatingSystem}'),
            ],
          ),
        ),
      ),
    );
  }
}
