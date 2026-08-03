# GFCampusCard

> 一款专为河源广赋创新学校学生及家长设计的智慧校园信息查询工具

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.8+-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-brightgreen.svg)](https://developer.android.com/)

---

## 📖 项目简介

**广赋校园卡** 是一款基于 Flutter 开发的 Android 应用，为河源广赋创新学校的学生和家长提供便捷的校园卡信息查询服务。通过对接学校智慧校园系统 API，用户可以随时随地查看校园卡余额、消费流水、考勤记录和充值记录等关键信息。

本项目旨在为学校社区提供更高效、更透明的生活管理工具，帮助家长及时了解子女在校消费与考勤情况，也方便学生自主管理个人校园卡账户。

### ✨ 核心价值

- 🔐 **安全便捷登录**：支持手机号+密码登录，自动保存凭证并支持一键快速登录
- 💳 **实时余额查询**：首页卡片清晰展示当前余额、累计充值及累计消费总额
- 📊 **多维数据透视**：消费流水、考勤记录、充值记录三类数据独立分页，支持月度筛选
- 🖼️ **考勤照片查看**：点击考勤记录可查看对应的考勤抓拍照片
- 🎨 **优雅交互体验**：支持浅色/深色主题自适应，页面切换带淡入淡出动画

---

## 🚀 功能特性

| 功能模块        | 说明                                                            |
| --------------- | --------------------------------------------------------------- |
| 🔐 **账号登录** | 支持手机号登录，默认密码为手机号后6位，可记住账号               |
| 💰 **余额查询** | 实时查询校园卡余额、累计充值金额及已用总额                      |
| 📝 **消费流水** | 按时间倒序展示消费记录，支持按月筛选和分页加载                  |
| 🏫 **考勤记录** | 查看最近7天的考勤记录，点击可查看考勤照片                       |
| 💳 **充值记录** | 展示充值历史，支持按月筛选查看                                  |
| 🛠️ **调试工具** | 隐藏入口（点击关于页图标5次进入），可清理缓存、切换服务限制检测 |
| 🌗 **深色模式** | 跟随系统自动切换亮色/暗色主题                                   |

---

## 🛠️ 技术栈

| 技术                   | 用途                                   |
| ---------------------- | -------------------------------------- |
| **Flutter 3.22+**      | UI框架 & 跨平台开发                    |
| **Dart 3.8+**          | 编程语言                               |
| **Dio 5.9**            | 网络请求库，支持拦截器                 |
| **Shared Preferences** | 本地数据持久化（登录凭证、设置项）     |
| **Path Provider**      | 文件路径管理（日志、缓存）             |
| **Logging**            | 日志记录框架                           |
| **Intl**               | 日期格式化与国际化                     |
| **Synchronized**       | 异步锁，保证文件写入安全               |
| **URL Launcher**       | 打开系统浏览器（充值、请假、找回密码） |
| **Fade Indexed Stack** | 页面切换淡入淡出动画                   |

---

## 📦 快速开始

### 前置条件

- Flutter SDK 3.22.0 或更高版本
- Android Studio / VS Code（推荐）
- Android 设备或模拟器（Android 5.0+）

### 安装步骤

```bash
# 1. 克隆项目
git clone https://github.com/yangsongh/GFCampusCard.git
cd GFCampusCard

# 2. 获取依赖
flutter pub get

# 3. 生成本地配置文件（可选）
# 无需额外配置，开箱即用

# 4. 运行应用（调试模式）
flutter run

# 5. 构建 Release APK
flutter build apk --release
```

### 构建脚本

项目提供了两个 Windows 批处理脚本用于快速构建：

- **`PACKAGE.BAT`**：构建 Release APK
- **`PACKAGE_DEBUG.BAT`**：构建 Debug APK

---

## 📁 项目结构

```
GFCampusCard/
├── android/                     # Android 原生配置
│   ├── app/
│   │   └── src/main/
│   │       ├── kotlin/          # Kotlin 主入口
│   │       └── res/             # 应用图标资源
│   ├── build.gradle.kts         # Gradle 根配置
│   └── settings.gradle.kts      # Gradle 设置
├── assets/
│   └── icons/
│       └── icon.png             # 应用图标
├── lib/
│   ├── main.dart                # 应用入口 & 免责声明
│   ├── app_configs.dart         # 全局配置（主题、常量）
│   ├── pages/
│   │   ├── login.dart           # 登录页面
│   │   ├── about/               # 关于模块
│   │   │   ├── about_page.dart
│   │   │   └── children/
│   │   │       └── debug_page.dart  # 调试界面（隐藏入口）
│   │   └── home/                # 主页模块
│   │       ├── home_page.dart   # 主页（数据概览）
│   │       └── children/
│   │           ├── attendance_page.dart   # 考勤记录
│   │           ├── consumption_page.dart  # 消费流水
│   │           └── recharge_page.dart     # 充值记录
│   ├── service/
│   │   ├── gf_campus_card.dart  # 核心 API 服务类
│   │   └── service_configs.dart # API 端点配置
│   └── utils/
│       ├── utils.dart           # 工具函数（日期、金额、SnackBar）
│       └── logger_manager.dart  # 日志管理（控制台 + 文件）
├── pubspec.yaml                 # 依赖配置
├── analysis_options.yaml        # 代码检查规则
└── LICENSE                      # MIT 许可证
```

---

## 📡 API 说明

### 核心服务类：`GFCampusCard`

```dart
// 创建实例（异步工厂方法）
final card = await GFCampusCard.create(phone);

// 登录并更新 Cookie
final result = await card.loginAndUpdateCookie(
  userName: '13800138000',
  pwd: '138000', // 默认为手机号后6位
);

// 获取校园卡信息（余额、姓名、班级等）
final info = await card.getAndUpadateCardInfo();

// 获取消费流水（分页）
final flows = await card.getPersonalFlowRecords(1, 15, '2026-08');

// 获取考勤记录
final attendance = await card.getAttendanceRecords('2026-08-03');

// 获取充值记录
final recharge = await card.getRechargeRecords(1, '2026-08');

// 下载考勤照片
final photo = await card.downloadAttendancePictures(
  'attendance_images',
  '2026-08-03 12:00:00',
);
```

### 配置项（`app_configs.dart`）

| 常量                     | 默认值          | 说明                      |
| ------------------------ | --------------- | ------------------------- |
| `versionName`            | `v1.x.x 正式版` | 应用版本                  |
| `showPhotoHintThreshold` | `3`             | 前N次登录显示考勤图片提示 |
| `debugModePassword`      | `hygf999`       | 调试模式密码              |

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 提交 Issue 前请确认

- 使用最新版本重现问题
- 提供详细的错误日志和复现步骤
- 标明设备型号和 Android 版本

### Pull Request 规范

1. Fork 本仓库并从 `main` 分支创建特性分支
2. 代码风格遵循 `flutter_lints` 规范
3. 提交信息使用简洁的描述性语句（建议中文）
4. 确保所有功能正常，无新增 lint 警告

---

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源协议。

---

## 👨‍💻 致谢

- 开发者：[阳松鸿](https://github.com/yangsongh)
- 感谢河源广赋创新学校师生及家长的支持与反馈

---

## ⚠️ 免责声明

> 1. **软件性质**：本软件为校内学生基于便利学生、家长的目的开发的非官方工具，与学校及校园卡系统外包公司无任何关联，未经官方授权或认可。
> 2. **使用风险**：使用者需自行承担因软件使用引发的任何后果。
> 3. **免责条款**：开发者不对以下情况负责：
>    - 学校或外包公司因服务器调整造成的功能失效；
>    - 使用者滥用本软件引发的任何第三方追责；
>    - 本 App 内部分数据可能存在不准确的情况。
> 4. **用户义务**：本软件仅供学生或家长免费使用，严禁用于商业用途或恶意操作。使用即代表您已充分理解并自愿承担全部风险。
> 5. **声明变更**：开发者保留随时修改或终止软件服务的权利，恕不另行通知。

---

## 📮 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 [GitHub Issue](https://github.com/yangsongh/GFCampusCard/issues)
- 邮件联系：18675864731@163.com

---
