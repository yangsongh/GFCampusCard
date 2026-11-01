import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gf_campus_card/app_configs.dart' show AppCfgs;
import 'package:gf_campus_card/service/gf_campus_card.dart' show GFCampusCard;
import 'package:gf_campus_card/utils/utils.dart' show Utils;

/// App内重置密码页面
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _validCodeController = TextEditingController();
  final TextEditingController _newPwdController = TextEditingController();
  final TextEditingController _confirmPwdController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSendingValidCode = false;
  int _validCodeCountdown = 0;
  Timer? _validCodeTimer;

  @override
  void dispose() {
    _validCodeTimer?.cancel();
    _phoneController.dispose();
    _validCodeController.dispose();
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  /// 获取重置密码短信验证码
  Future<void> _sendValidCode() async {
    if (_isSendingValidCode || _validCodeCountdown > 0) return;

    final phone = _phoneController.text.trim();
    if (phone.length != 11) {
      unawaited(Utils.showSnackBar(context, '请输入正确的手机号'));
      return;
    }

    setState(() => _isSendingValidCode = true);
    try {
      final card = await GFCampusCard.create(phone);
      final result = await card.requestResetPasswordValidCode();
      if (result['success'] == true) {
        if (!mounted) return;
        _startValidCodeCountdown();
        unawaited(Utils.showSnackBar(context, '验证码已发送'));
      } else {
        if (!mounted) return;
        unawaited(Utils.showSnackBar(context, result['message'] ?? '获取验证码失败'));
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

  /// 提交重置密码
  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final validCode = _validCodeController.text.trim();
    final newPwd = _newPwdController.text;
    final confirmPwd = _confirmPwdController.text;

    if (phone.length != 11) {
      unawaited(Utils.showSnackBar(context, '请输入正确的手机号'));
      return;
    }
    if (validCode.isEmpty) {
      unawaited(Utils.showSnackBar(context, '请输入验证码'));
      return;
    }
    if (newPwd.isEmpty) {
      unawaited(Utils.showSnackBar(context, '请输入新密码'));
      return;
    }
    if (newPwd != confirmPwd) {
      unawaited(Utils.showSnackBar(context, '两次输入的密码不一致'));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final card = await GFCampusCard.create(phone);
      final result = await card.resetPassword(
        validCode: validCode,
        newPwd: newPwd,
        confirmPwd: confirmPwd,
      );

      if (!mounted) return;
      if (result['success'] == true) {
        unawaited(Utils.showSnackBar(context, '密码重置成功, 请使用新密码登录'));
        Navigator.of(context).pop();
      } else {
        unawaited(Utils.showSnackBar(context, result['message'] ?? '重置密码失败'));
      }
    } catch (e) {
      if (!mounted) return;
      unawaited(Utils.showSnackBar(context, '重置密码失败: $e'));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// 构建带阴影的输入框
  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    EdgeInsetsGeometry margin = const EdgeInsets.only(top: 15),
  }) {
    return Container(
      decoration: AppCfgs.inputBoxDecoration, // 阴影
      margin: margin,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
        ),
        enabled: !_isSubmitting,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSendValidCode =
        !_isSendingValidCode &&
        !_isSubmitting &&
        _validCodeCountdown == 0;

    return Scaffold(
      appBar: AppBar(title: const Text('重置密码'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppCfgs.padding,
            child: Column(
              children: [
                // 手机号输入框
                _buildInput(
                  controller: _phoneController,
                  hintText: '请输入手机号',
                  icon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  margin: EdgeInsets.zero,
                ),

                // 验证码输入框
                _buildInput(
                  controller: _validCodeController,
                  hintText: '请输入短信验证码',
                  icon: Icons.sms,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
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

                // 新密码输入框
                _buildInput(
                  controller: _newPwdController,
                  hintText: '请输入新密码',
                  icon: Icons.lock,
                  obscureText: true,
                ),

                // 确认密码输入框
                _buildInput(
                  controller: _confirmPwdController,
                  hintText: '请再次输入新密码',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),

                // 提交按钮
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton.icon(
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.grey,
                              strokeWidth: 2.0,
                            ),
                          )
                        : const Icon(Icons.lock_reset),
                    label: Text(
                      _isSubmitting ? '提交中' : '重置密码',
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
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
