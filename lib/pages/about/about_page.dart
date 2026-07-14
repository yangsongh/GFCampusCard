import 'package:flutter/material.dart';
import 'package:gf_campus_card/app_configs.dart' show AppCfgs;
import 'package:gf_campus_card/pages/about/children/debug_page.dart'
    show DebugPage;

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  int _iconTapCount = 0;
  DateTime? _lastTapTime;

  void _handleIconTap() {
    final now = DateTime.now();
    // 重置计数器（如果超过1秒未点击）
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) > Duration(seconds: 1)) {
      _iconTapCount = 0;
    }

    _iconTapCount++;
    _lastTapTime = now;

    // 检测到5次点击
    if (_iconTapCount >= 5) {
      _iconTapCount = 0; // 重置计数器
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DebugPage()),
      );
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
              GestureDetector(
                onTap: _handleIconTap,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 17.54,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset('assets/icons/icon.png'),
                ),
              ),
              const SizedBox(height: 30),

              Text(
                '广赋校园卡',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              Text('版本号: ${AppCfgs.versionName}'),
              SizedBox(height: 5),

              Text('开发者: 无痕芳华'),
              SizedBox(height: 15),
              Text(
                '仅供河源广赋创新学校学生或家长使用, 方便查询校园卡信息。如有侵权, 请及时联系开发者, 开发者将在15个工作日内处理。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
