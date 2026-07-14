import 'package:flutter/material.dart';

class AppCfgs {
  // App版本号
  static const versionName = 'v1.0.2 正式版';
  // 显示考勤图片提示 的 登录计数阈值
  static const int showPhotoHintThreshold = 3;
  // 调试模式密码
  static const String debugModePassword = 'hygf999';

  // 忘记密码链接
  static const String forgotPasswordUrl =
      'https://appsvr01.szxinyu.com/SchoolUserOnline/wechatServer/index';
  // 请假链接
  static const String leaveRequestUrl =
      'https://appsvr01.szxinyu.com/SchoolUserOnline/wechatServer/toLeaveManagement';
  // 充值链接
  static const String rechargeUrl =
      'https://appsvr01.szxinyu.com/SchoolUserOnline/wechatRecharge/index?rechargePayType=wechat_sp_mch';

  // 圆角
  static const radius = 12.0;
  // 浅色模式背景色
  static const lightModeBackgroundColor = Color(0xFFF5F5F5);
  // 主题色
  static const primaryColor = Color(0xFFDC143C);
  // 绿色
  static const green = Color(0xFF4CAF50);
  // 卡片形状 (带圆角)
  static const cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(radius)),
  );
  // 卡片间距
  static const cardMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  // 输入框带圆角
  static final inputDecorationBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide.none,
  );
  // 距离界面边缘的间距
  static const padding = EdgeInsets.all(32);
  // 圆形进度条
  static const progressIndicatorTheme = ProgressIndicatorThemeData(
    color: primaryColor,
  );

  // 浅色主题
  static final lightTheme = ThemeData(
    appBarTheme: AppBarTheme(
      backgroundColor: AppCfgs.primaryColor, // 背景色
      foregroundColor: Colors.white, // 文字色
    ),
    scaffoldBackgroundColor: AppCfgs.lightModeBackgroundColor, // 背景色
    progressIndicatorTheme: AppCfgs.progressIndicatorTheme, // 圆形进度条

    cardTheme: CardThemeData(
      elevation: 2, // 阴影
      shape: AppCfgs.cardShape, // 圆角
      margin: AppCfgs.cardMargin,
      color: Colors.white,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: AppCfgs.inputDecorationBorder,
    ),

    textButtonTheme: TextButtonThemeData(
      // 文字按钮颜色
      style: TextButton.styleFrom(foregroundColor: AppCfgs.primaryColor),
    ),

    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppCfgs.primaryColor, // 全局光标颜色
      selectionHandleColor: AppCfgs.primaryColor, // 选择手柄颜色
      selectionColor: Colors.blueGrey, // 选中文本背景色
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected) &&
            !states.contains(WidgetState.disabled)) {
          return AppCfgs.primaryColor; // 复选框颜色
        }
        return null;
      }),
    ),
  );

  // 深色主题
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    appBarTheme: AppBarTheme(backgroundColor: AppCfgs.primaryColor),
    progressIndicatorTheme: AppCfgs.progressIndicatorTheme,

    cardTheme: CardThemeData(
      elevation: 2,
      shape: AppCfgs.cardShape,
      margin: AppCfgs.cardMargin,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: AppCfgs.inputDecorationBorder,
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppCfgs.primaryColor),
    ),

    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppCfgs.primaryColor,
      selectionHandleColor: AppCfgs.primaryColor,
      selectionColor: Colors.blueGrey,
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected) &&
            !states.contains(WidgetState.disabled)) {
          return AppCfgs.primaryColor; // 复选框颜色
        }
        return null;
      }),
      checkColor: WidgetStateProperty.resolveWith<Color?>((states) {
        return AppCfgs.lightModeBackgroundColor;
      }),
    ),
  );

  // 阴影装饰
  static final inputBoxDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(AppCfgs.radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: AppCfgs.radius,
        offset: Offset(0, 2), // 向下偏移
      ),
    ],
  );

  // 底部导航栏
  static Widget bottomNavigationBar(
    BuildContext context,
    int currentIndex,
    void Function(int) onIndexChanged,
  ) {
    return NavigationBar(
      // 动画时长
      animationDuration: const Duration(milliseconds: 300),
      // 背景色
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? AppCfgs.lightModeBackgroundColor
          : Theme.of(context).scaffoldBackgroundColor,
      indicatorColor: AppCfgs.primaryColor.withValues(alpha: 0.2), // 指示器颜色
      selectedIndex: currentIndex,
      onDestinationSelected: onIndexChanged,
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.credit_card, color: Colors.grey), // 未选中颜色
          selectedIcon: Icon(
            Icons.credit_card,
            color: AppCfgs.primaryColor,
          ), // 选中颜色
          label: '校园卡',
        ),
        NavigationDestination(
          icon: Icon(Icons.info_outline, color: Colors.grey), // 未选中颜色
          selectedIcon: Icon(
            Icons.info_outline,
            color: AppCfgs.primaryColor,
          ), // 选中颜色
          label: '关于',
        ),
      ],
    );
  }

  // 免责声明
  static const String disclaimer = '''1. 软件性质
    * 本软件为校内学生基于便利学生、家长的目的开发的非官方工具, 与学校及校园卡系统外包公司无任何关联。未经官方授权或认可。
2. 使用风险
    * 使用者需自行承担因软件使用引发的任何后果。
3. 免责条款
    * 开发者不对以下情况负责:
        - 学校或外包公司因服务器调整造成的功能失效；
        - 使用者滥用本软件引发的任何第三方追责；
        - 本App内的部分数据不准确。
4. 用户义务
    * 使用者需知悉:
        - 本软件仅供学生或家长免费使用, 严禁用于商业用途或恶意操作；
        - 使用即代表您已充分理解并自愿承担全部风险。
5. 声明变更
    * 开发者保留随时修改或终止软件服务的权利, 恕不另行通知。''';
}
