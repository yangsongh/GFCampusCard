import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fade_indexed_stack/fade_indexed_stack.dart';
import 'package:gf_campus_card/service/gf_campus_card.dart' show GFCampusCard;
import 'package:gf_campus_card/pages/login.dart' show Login;
import 'package:gf_campus_card/pages/about/about_page.dart' show AboutPage;
import 'package:gf_campus_card/app_configs.dart' show AppCfgs;
import 'package:gf_campus_card/pages/home/home_page.dart' show HomePage;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 检查免责声明是否已同意
  final prefs = await SharedPreferences.getInstance();
  final disclaimerAgreed = prefs.getBool('disclaimerAgreed') ?? false;

  if (!disclaimerAgreed) {
    // 显示免责声明页面
    runApp(DisclaimerApp());
  } else {
    runApp(MainApp());
  }
}

// 免责声明专用App
class DisclaimerApp extends StatelessWidget {
  const DisclaimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      /* 浅色模式组件样式 */
      theme: AppCfgs.lightTheme,
      /* 深色模式组件样式 */
      darkTheme: AppCfgs.darkTheme,
      title: '广赋校园卡',
      home: DisclaimerPage(),
    );
  }
}

// 免责声明页面
class DisclaimerPage extends StatelessWidget {
  const DisclaimerPage({super.key});

  Future<void> _agreeDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disclaimerAgreed', true);

    // 重启主应用
    runApp(MainApp());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('免责声明'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppCfgs.padding,
          child: Column(
            children: [
              Text(
                '非官方校园卡查询软件免责声明',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              SizedBox(height: 20),
              Text(AppCfgs.disclaimer),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () => SystemNavigator.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ), // 退出应用
                    child: Text(
                      '不同意并退出',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _agreeDisclaimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppCfgs.green,
                    ),
                    child: Text('同意并继续', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ], // 组件多语言支持
      supportedLocales: [Locale('zh', 'CN')],
      title: '广赋校园卡',

      /* 浅色模式组件样式 */
      theme: AppCfgs.lightTheme,
      /* 深色模式组件样式 */
      darkTheme: AppCfgs.darkTheme,

      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isLoggedIn = false;
  GFCampusCard? _campusCard;

  @override
  void initState() {
    super.initState();
  }

  void onLoginSuccess(GFCampusCard card) {
    setState(() {
      _campusCard = card;
      _isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 定义页面内容
    final List<Widget> pages = [
      _isLoggedIn
          ? HomePage(campusCard: _campusCard!)
          : Login(onLoginSuccess: onLoginSuccess),
      AboutPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? '广赋校园卡' : '关于应用'),
        centerTitle: true,
      ),
      // 淡入淡出动画
      body: FadeIndexedStack(
        index: _currentIndex,
        duration: const Duration(milliseconds: 300), // 动画时长
        children: pages,
      ),
      bottomNavigationBar: AppCfgs.bottomNavigationBar(
        context,
        _currentIndex,
        (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
