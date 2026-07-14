import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gf_campus_card/service/gf_campus_card.dart' show GFCampusCard;
import 'package:gf_campus_card/app_configs.dart' show AppCfgs;
import 'package:gf_campus_card/utils/utils.dart' show Utils;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

class Login extends StatefulWidget {
  final ValueChanged<GFCampusCard> onLoginSuccess;
  const Login({super.key, required this.onLoginSuccess});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoggingIn = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _rememberMe = true;

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

  /// 增加登录次数
  Future<void> _incrementLoginCount() async {
    final prefs = await SharedPreferences.getInstance();
    final newCount = (prefs.getInt('loginCount') ?? 0) + 1;
    await prefs.setInt('loginCount', newCount);
  }

  /// 执行登录
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: AppCfgs.padding,
          child: Column(
            children: [
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

              // 密码输入框
              Container(
                decoration: AppCfgs.inputBoxDecoration, // 阴影
                margin: EdgeInsets.only(top: 15),
                child: TextField(
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
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
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

                    // 右侧：忘记密码
                    GestureDetector(
                      onTap: _isLoggingIn
                          ? null
                          : () => Utils.launchURL(AppCfgs.forgotPasswordUrl, (
                              error,
                            ) {
                              Utils.showSnackBar(context, error);
                            }),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
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
                  onPressed: _isLoggingIn ? null : _performLogin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
