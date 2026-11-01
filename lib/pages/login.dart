import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gf_campus_card/service/gf_campus_card.dart' show GFCampusCard;
import 'package:gf_campus_card/app_configs.dart' show AppCfgs;
import 'package:gf_campus_card/pages/reset_password.dart' show ResetPasswordPage;
import 'package:gf_campus_card/utils/utils.dart' show Utils;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

/// 登录方式
enum _LoginMode { password, validCode }

class Login extends StatefulWidget {
  final ValueChanged<GFCampusCard> onLoginSuccess;
  const Login({super.key, required this.onLoginSuccess});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _validCodeController = TextEditingController();
  _LoginMode _mode = _LoginMode.password;
  bool _isLoggingIn = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isSendingValidCode = false;
  int _validCodeCountdown = 0;
  Timer? _validCodeTimer;

  @override
  void initState() {
    super.initState();

    // 自动填充保存的凭证
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString('savedPhone');
      final savedPassword = prefs.getString('savedPassword');

      if (savedPhone != null) {
        setState(() {
          _phoneController.text = savedPhone;
        });
      }
      if (savedPassword != null) {
        setState(() {
          _passwordController.text = savedPassword;
        });
      }
      if (savedPhone != null && savedPassword != null) {
        // 自动登录
        unawaited(_performLogin());
      }
    });
  }

  @override
  void dispose() {
    _validCodeTimer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _validCodeController.dispose();
    super.dispose();
  }

  /// 增加登录次数
  Future<void> _incrementLoginCount() async {
    final prefs = await SharedPreferences.getInstance();
    final newCount = (prefs.getInt('loginCount') ?? 0) + 1;
    await prefs.setInt('loginCount', newCount);
  }

  /// 执行密码登录
  Future<void> _performLogin() async {
    try {
      setState(() {
        _isLoggingIn = true;
        _errorMessage = null;
      });

      // 获取手机号并验证
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        setState(() => _errorMessage = '手机号不能为空');
        return;
      }

      // 获取密码, 如果为空则使用手机号后六位
      String password = _passwordController.text.trim();
      if (password.isEmpty) {
        // 使用手机号后六位作为默认密码
        password = phone.length >= 6
            ? phone.substring(phone.length - 6)
            : phone; // 如果手机号不足6位, 使用整个手机号
      }

      // 创建校园卡实例并执行登录
      final card = await GFCampusCard.create(phone);
      final result = await card.loginAndUpdateCookie(
        userName: phone,
        pwd: password,
      );

      if (result['success'] != true) {
        setState(() => _errorMessage = result['message']);
      } else {
        // 登录成功后保存凭证
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('savedPhone', phone);
          if (password.isNotEmpty) {
            await prefs.setString('savedPassword', password);
          }
        }
        // 增加登录计数, 传递卡片实例到父组件
        await _incrementLoginCount();
        widget.onLoginSuccess(card);
      }
    } catch (e) {
      if (!mounted) return;
      unawaited(Utils.showSnackBar(context, '登录失败: $e'));
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  /// 获取登录短信验证码
  Future<void> _sendValidCode() async {
    if (_isSendingValidCode || _validCodeCountdown > 0) return;

    final phone = _phoneController.text.trim();
    if (phone.length != 11) {
      setState(() => _errorMessage = '请输入正确的手机号');
      return;
    }

    setState(() {
      _isSendingValidCode = true;
      _errorMessage = null;
    });
    try {
      final card = await GFCampusCard.create(phone);
      final result = await card.requestLoginValidCode();
      if (result['success'] == true) {
        if (!mounted) return;
        _startValidCodeCountdown();
        unawaited(Utils.showSnackBar(context, '验证码已发送'));
      } else {
        if (!mounted) return;
        setState(() => _errorMessage = result['message']);
      }
    } catch (e) {
      if (!mounted) return;
      unawaited(Utils.showSnackBar(context, '获取验证码失败: $e'));
    } finally {
      if (mounted) {
        setState(() => _isSendingValidCode = false);
      }
    }
  }

  /// 开始30秒倒计时, 倒计时期间禁止重复获取
  void _startValidCodeCountdown() {
    _validCodeTimer?.cancel();
    setState(() => _validCodeCountdown = 30);
    _validCodeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _validCodeCountdown--;
        if (_validCodeCountdown <= 0) {
          _validCodeCountdown = 0;
          timer.cancel();
        }
      });
    });
  }

  /// 执行短信验证码登录
  Future<void> _performValidCodeLogin() async {
    try {
      setState(() {
        _isLoggingIn = true;
        _errorMessage = null;
      });

      final phone = _phoneController.text.trim();
      final validCode = _validCodeController.text.trim();
      if (phone.isEmpty) {
        setState(() => _errorMessage = '手机号不能为空');
        return;
      }
      if (validCode.isEmpty) {
        setState(() => _errorMessage = '验证码不能为空');
        return;
      }

      final card = await GFCampusCard.create(phone);
      final result = await card.loginWithValidCode(validCode);

      if (result['success'] != true) {
        setState(() => _errorMessage = result['message']);
      } else {
        // 记住手机号, 短信登录不保存密码
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('savedPhone', phone);
          await prefs.remove('savedPassword');
        }
        await _incrementLoginCount();
        widget.onLoginSuccess(card);
      }
    } catch (e) {
      if (!mounted) return;
      unawaited(Utils.showSnackBar(context, '登录失败: $e'));
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  /// 登录方式切换标签
  Widget _buildModeTab(String label, _LoginMode mode) {
    final selected = _mode == mode;
    return InkWell(
      onTap: _isLoggingIn
          ? null
          : () => setState(() {
              _mode = mode;
              _errorMessage = null;
            }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppCfgs.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppCfgs.primaryColor : Colors.grey,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPasswordMode = _mode == _LoginMode.password;
    final canSendValidCode =
        !_isSendingValidCode &&
        !_isLoggingIn &&
        _validCodeCountdown == 0;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: AppCfgs.padding,
          child: Column(
            children: [
              // 登录方式切换
              Row(
                children: [
                  Expanded(child: _buildModeTab('密码登录', _LoginMode.password)),
                  Expanded(
                    child: _buildModeTab('短信验证码登录', _LoginMode.validCode),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // 手机号输入框
              Container(
                decoration: AppCfgs.inputBoxDecoration, // 阴影
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: InputDecoration(
                    hintText: '请输入手机号',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                  enabled: !_isLoggingIn,
                ),
              ),

              // 密码输入框 / 验证码输入框
              Container(
                decoration: AppCfgs.inputBoxDecoration, // 阴影
                margin: EdgeInsets.only(top: 15),
                child: isPasswordMode
                    ? TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '默认密码手机号后6位',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        enabled: !_isLoggingIn,
                      )
                    : TextField(
                        controller: _validCodeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: InputDecoration(
                          hintText: '请输入短信验证码',
                          prefixIcon: Icon(Icons.sms),
                          suffixIcon: TextButton(
                            onPressed: canSendValidCode ? _sendValidCode : null,
                            child: Text(
                              _validCodeCountdown > 0
                                  ? '${_validCodeCountdown}s'
                                  : _isSendingValidCode
                                  ? '发送中'
                                  : '获取验证码',
                            ),
                          ),
                        ),
                        enabled: !_isLoggingIn,
                      ),
              ),

              // 记住账号复选框和忘记密码链接
              Padding(
                padding: EdgeInsets.only(top: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 左侧：记住账号
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: _isLoggingIn
                              ? null
                              : (value) => setState(() => _rememberMe = value!),
                        ),
                        Text(
                          '记住账号',
                          style: TextStyle(
                            color: _isLoggingIn
                                ? Colors.grey
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),

                    // 右侧：忘记密码 (App内重置密码)
                    GestureDetector(
                      onTap: _isLoggingIn
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ResetPasswordPage(),
                              ),
                            ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_reset,
                            color: _isLoggingIn
                                ? Colors.grey
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '忘记密码',
                            style: TextStyle(
                              color: _isLoggingIn
                                  ? Colors.grey
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 错误提示
              if (_errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppCfgs.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              // 登录按钮
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: ElevatedButton.icon(
                  icon: _isLoggingIn
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.grey,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(
                    _isLoggingIn ? '登录中' : '登录',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppCfgs.radius),
                    ),
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: AppCfgs.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoggingIn
                      ? null
                      : isPasswordMode
                      ? _performLogin
                      : _performValidCodeLogin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
