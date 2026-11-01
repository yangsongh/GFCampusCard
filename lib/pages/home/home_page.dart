import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:gf_campus_card/main.dart' show MainScreen;
import 'package:gf_campus_card/service/gf_campus_card.dart' show GFCampusCard;
import 'package:gf_campus_card/pages/home/children/attendance_page.dart'
    show AttendancePage;
import 'package:gf_campus_card/app_configs.dart' show AppCfgs;
import 'package:gf_campus_card/pages/home/children/consumption_page.dart'
    show ConsumptionPage;
import 'package:gf_campus_card/pages/home/children/recharge_page.dart'
    show RechargePage;
import 'package:gf_campus_card/utils/utils.dart' show Utils;
import 'package:gf_campus_card/service/service_configs.dart' show ServiceLimit;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

class HomePage extends StatefulWidget {
  final GFCampusCard campusCard;
  const HomePage({super.key, required this.campusCard});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  Map<String, dynamic>? _cardInfo;
  List<dynamic>? _flowRecords;
  List<dynamic>? _attendanceRecords;
  List<dynamic>? _rechargeRecords;
  String? _hostelName;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  /// 退出登录
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    // await prefs.remove('savedPhone');
    await prefs.remove('savedPassword');

    if (!mounted) return;
    await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()),
      (route) => false,
    );
  }

  /// 获取主页数据
  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 1. 先获取校园卡信息
      final cardInfoResult = await widget.campusCard.getAndUpadateCardInfo();
      if (cardInfoResult['success'] != true) {
        throw Exception(cardInfoResult['message']);
      } else {
        setState(() {
          _cardInfo = cardInfoResult['data'];
        });
      }

      // 获取宿舍号信息 (失败不影响主界面)
      try {
        final detailsResult = await widget.campusCard.getDetailsInfo();
        if (detailsResult['success'] == true) {
          final hostelName = _parseHostelName(detailsResult['data']);
          if (mounted) {
            setState(() => _hostelName = hostelName);
          }
        }
      } catch (e) {
        widget.campusCard.logger.warning('获取宿舍号失败: $e');
      }

      final prefs = await SharedPreferences.getInstance();
      final checkLimit = prefs.getBool('checkServiceLimit') ?? true;

      // 如果需要检查服务限制
      if (checkLimit) {
        final limitResult = await widget.campusCard.getStudentServiceLimit();
        if (limitResult['success'] != true ||
            limitResult['data'] != ServiceLimit.normal.value) {
          if (!mounted) return;
          await Utils.showSnackBar(context, '您的账号服务受限, 部分功能无法使用');
        }
      } else {
        widget.campusCard.noServiceLimit = true;
      }

      // 没有服务限制
      if (widget.campusCard.noServiceLimit) {
        // 2. 并行获取其他数据
        final results = await Future.wait([
          widget.campusCard.getPersonalFlowRecords(1, 1000, ''),
          widget.campusCard.getAttendanceRecords(Utils.todayDateString),
          widget.campusCard.getRechargeRecords(1, Utils.currentMonthString),
        ]);

        // 检查其他API调用是否成功
        for (final result in results) {
          if (result['success'] != true) {
            throw Exception(result['message']);
          }
        }

        setState(() {
          _flowRecords = results[0]['data']['消费记录'];
          _attendanceRecords = results[1]['data'];
          _rechargeRecords = results[2]['data']['充值记录'];
        });
      } else {
        setState(() {
          _flowRecords = null;
          _attendanceRecords = null;
          _rechargeRecords = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      unawaited(Utils.showSnackBar(context, '主页数据获取失败: $e'));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 导航到某页
  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  /// 解析宿舍号, 拼接格式: {hostelName}{hostel_room_name}宿舍
  String? _parseHostelName(dynamic details) {
    try {
      final data = details is Map ? details['data'] : null;
      if (data is! Map) return null;

      final hostelList = data['hostelList'];
      if (hostelList is! List || hostelList.isEmpty) return null;
      final first = hostelList.first;
      if (first is! Map) return null;

      final hostel = first['hostel'];
      final hostelName = hostel is Map
          ? hostel['hostelName']?.toString()
          : null;

      // 房间号优先取根级 hostelRoom, 否则取 hostelList[0].hostelRoom
      final rootRoom = data['hostelRoom'];
      final itemRoom = first['hostelRoom'];
      final roomSource = rootRoom is Map && rootRoom.isNotEmpty
          ? rootRoom
          : itemRoom;
      final roomName = roomSource is Map
          ? roomSource['hostel_room_name']?.toString()
          : null;

      // 任一字段缺失时不显示
      if (hostelName == null ||
          hostelName.isEmpty ||
          roomName == null ||
          roomName.isEmpty) {
        return null;
      }
      return '$hostelName$roomName宿舍';
    } catch (e) {
      return null;
    }
  }

  /// 充值弹窗: 提示在微信中打开并复制充值链接
  Future<void> _showRechargeDialog() async {
    final copied = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('充值提示'),
        content: const Text('请在微信中打开链接充值'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                const ClipboardData(text: AppCfgs.rechargeUrl),
              );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );

    if (copied == true && mounted) {
      await Utils.showSnackBar(context, '充值链接已复制, 请到微信中打开');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchData,
            color: AppCfgs.primaryColor,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // 用户信息卡片
                _buildUserCard(context),
                // 消费流水卡片
                _buildCardWithList(
                  title: '消费流水',
                  items:
                      _flowRecords?.map((record) {
                        return [
                          '${Utils.extractNonYearDate(record['交易时间'])} ${record['餐次/类型']}',
                          '¥${record['交易金额']}',
                          record['交易名称'],
                        ];
                      }).toList() ??
                      [],
                  buttonLabel: '查看全部流水',
                  onTap: () => _navigateToPage(
                    context,
                    ConsumptionPage(campusCard: widget.campusCard),
                  ),
                ),
                // 考勤记录卡片
                _buildCardWithList(
                  title: '考勤记录',
                  items:
                      _attendanceRecords?.map((record) {
                        return [
                          Utils.extractTime(record['考勤时间']),
                          '${record['进出类型']} ${record['考勤状态']}',
                          record['考勤地点'],
                        ];
                      }).toList() ??
                      [],
                  buttonLabel: '查看考勤详情',
                  onTap: () => _navigateToPage(
                    context,
                    AttendancePage(campusCard: widget.campusCard),
                  ),
                ),
                // 充值记录卡片
                _buildCardWithList(
                  title: '充值记录',
                  items:
                      _rechargeRecords?.map((record) {
                        return [
                          Utils.extractNonYearDate(record['充值时间']),
                          '¥${record['充值金额']} ${record['操作状态']}',
                          record['支付渠道'],
                        ];
                      }).toList() ??
                      [],
                  buttonLabel: '查看充值记录',
                  onTap: () => _navigateToPage(
                    context,
                    RechargePage(campusCard: widget.campusCard),
                  ),
                ),
              ],
            ),
          );
  }

  /// 构建“用户”卡片
  Widget _buildUserCard(BuildContext context) {
    final userName = _cardInfo?['用户名'] ?? '未知';
    final gender = _cardInfo?['性别'] ?? '未知';
    final gradeName = _cardInfo?['年级'] ?? '未知年级';
    final className = _cardInfo?['班级'] ?? '未知班级';
    final studentId = _cardInfo?['学号'] ?? '未知';
    final balance = _cardInfo?['饭卡余额'] ?? '未知';
    final accumulatedRechargeAmount = _cardInfo?['累充金额'] ?? '未知';
    final accumulatedTotalAmount = _cardInfo?['已用总额'] ?? '未知';
    final registrationDate = _cardInfo != null
        ? Utils.extractYearDate(_cardInfo?['注册时间'])
        : '未知';
    final expiryDate = _cardInfo != null
        ? Utils.extractYearDate(_cardInfo?['饭卡到期日'])
        : '未知';

    /// 确认退出登录提示框
    Future<void> showLogoutConfirmDialog() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认退出登录'),
          content: const Text('您确定要退出当前账号吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认退出'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _logout(); // 调用原有的退出方法
      }
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 左侧部分（名字+性别标签）用 Expanded 包裹
                Expanded(
                  child: Row(
                    children: [
                      // XXX 同学
                      Text(
                        '$userName 同学',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 性别标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: gender == '男'
                              ? Colors.blue[50]
                              : gender == '女'
                              ? Colors.pink[50]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          gender,
                          style: TextStyle(
                            color: gender == '男'
                                ? Colors.blue
                                : gender == '女'
                                ? Colors.pink
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 右侧三个图标按钮
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: showLogoutConfirmDialog,
                      tooltip: '退出登录',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_calendar),
                      onPressed: () => {
                        if (widget.campusCard.noServiceLimit) // 无服务限制
                          {
                            Utils.launchURL(AppCfgs.leaveRequestUrl, (error) {
                              Utils.showSnackBar(context, error);
                            }),
                          }
                        else
                          {Utils.showSnackBar(context, '您的账号服务受限, 请假功能无法使用')},
                      },
                      tooltip: '请假',
                    ),
                    IconButton(
                      icon: const Icon(Icons.monetization_on),
                      onPressed: _showRechargeDialog,
                      tooltip: '充值',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // XX年级XX班
                Text(
                  '$gradeName$className',
                  style: const TextStyle(color: Colors.grey),
                ),
                // 余额: XX.XX
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '余额:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextSpan(
                        text: ' ¥$balance',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppCfgs.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),

            // 累计充值和累计使用总额
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 累计充值: XX.XX
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '累计充值:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextSpan(
                        text: ' ¥$accumulatedRechargeAmount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                // 累计使用: XX.XX
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '累计使用:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextSpan(
                        text: ' ¥$accumulatedTotalAmount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppCfgs.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // 学号: 7520XXXXXXX (右侧显示宿舍号)
            Row(
              children: [
                Text(
                  '学号: $studentId',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (_hostelName != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _hostelName!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 3),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 注册时间: 20XX-XX-XX
                Text(
                  '注册时间: $registrationDate',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                // 有效期至: 20XX-XX-XX
                Text(
                  '有效期至: $expiryDate',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建列表卡片
  Widget _buildCardWithList({
    required String title,
    required List<List<dynamic>> items,
    required String buttonLabel,
    required VoidCallback onTap,
    int maxItems = 5,
  }) {
    // 实际显示的条目（不超过maxItems）
    final displayItems = items.length > maxItems
        ? items.sublist(0, maxItems)
        : items;

    // 是否截断的标记
    final hasTruncated = items.length > maxItems;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题部分
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 5),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // 列表项
          ...displayItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧区域：item[0] 和 item[1]（不省略）
                  Row(
                    mainAxisSize: MainAxisSize.min, // 让左侧内容紧凑
                    children: [
                      Text(
                        item[0],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item[1],
                        style: TextStyle(
                          color:
                              (item[1].contains('¥') &&
                                      item[1].contains('-')) ||
                                  item[1].contains('异常') ||
                                  item[1].contains('失败')
                              ? AppCfgs
                                    .primaryColor // 消费 考勤异常 充值失败
                              : item[1].contains('正常') || item[1].contains('¥')
                              ? AppCfgs
                                    .green // 考勤正常 充值
                              : item[1].contains('迟到')
                              ? Colors
                                    .orange // 考勤迟到
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  // 右侧区域：item[2]（强制居右+省略）
                  Expanded(
                    child: Text(
                      item[2],
                      style: TextStyle(
                        color: item[2].contains('正常') || item[2].contains('成功')
                            ? AppCfgs.green
                            : item[2].contains('异常') || item[2].contains('失败')
                            ? AppCfgs.primaryColor
                            : Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end, // 文本右对齐
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 截断提示（当被截断时显示）
          if (hasTruncated)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Center(
                child: Text(
                  '还有${items.length - maxItems}项未显示',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ),

          // 空状态提示
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Center(
                child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
              ),
            ),

          SizedBox(height: 8),
          Divider(height: 0), // 分隔线
          // 底部按钮
          InkWell(
            // 左右底部两个圆角
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppCfgs.radius),
              bottomRight: Radius.circular(AppCfgs.radius),
            ),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 按钮文本
                  Text(
                    buttonLabel,
                    style: const TextStyle(color: AppCfgs.primaryColor),
                  ),
                  // > 图标
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
