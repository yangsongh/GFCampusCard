import 'dart:async';
import 'dart:convert' show json;
import 'dart:io' show HttpException, Directory, File;
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path show join;
import 'package:gf_campus_card/utils/logger_manager.dart' show LoggerManager;
import 'package:gf_campus_card/utils/utils.dart' show Utils;
import 'package:gf_campus_card/service/service_configs.dart';
import 'package:path_provider/path_provider.dart'
    show getExternalCacheDirectories;

/// 广赋校园卡
class GFCampusCard {
  InterceptorsWrapper? cookieInterceptor;
  final Dio dio = Dio();
  final LoggerManager logger;
  final String phone;
  String? password;
  String? username;
  String? cookie;
  String? stuId;
  String? stuNo;
  bool noServiceLimit = false;

  // 构造函数为异步工厂
  static Future<GFCampusCard> create(String phone) async {
    final logger = await LoggerManager.create(phone);
    final instance = GFCampusCard._(phone, logger);
    return instance;
  }

  GFCampusCard._(this.phone, this.logger) {
    dio.options.headers['content-type'] = Headers.formUrlEncodedContentType;
  }

  /// 根据请求状态抛出异常
  void _throwForStatus(Response resp, {bool checkInnerCode = false}) {
    if (resp.statusCode != 302 && resp.statusCode != 200) {
      throw HttpException('请求失败: ${resp.statusCode}');
    }
    if (checkInnerCode && resp.data['code'] != 0) {
      throw Exception(
        "响应内部状态码错误: ${resp.data['code']} - ${resp.data['msg'] ?? '(未知错误)'}",
      );
    }
  }

  /// 清理手动设置的Cookie拦截器
  void _clearCookieInterceptor() {
    dio.interceptors.remove(cookieInterceptor);
    logger.info('Cookie拦截器已清除');
  }

  /// 调用登录接口, 获取登录令牌
  Future<Map<String, dynamic>> _getLoginAuth() async {
    try {
      // 尝试登录
      final response = await dio
          .post(
            ServiceCfgs.getAuthUrl,
            data: {'username': username, 'password': password},
          )
          .timeout(const Duration(seconds: ServiceCfgs.timeout));
      _throwForStatus(response);
      final respJson = response.data;
      logger.debug('登录令牌响应: $respJson');

      if (respJson['Authorization'] != null) {
        // 登录成功
        final List authList = json.decode(
          respJson['Authorization'],
        ); // [{...}, {...}]
        logger.debug('令牌列表: $authList');
        return {'success': true, 'data': authList};
      } else {
        // 登录失败
        return {'success': false, 'message': respJson['message'] ?? '(未知错误)'};
      }
    } on FormatException catch (e) {
      String? err = '解析登录令牌JSON数据失败: $e';
      throw Exception(err);
    } catch (e) {
      final String error = '获取登录令牌失败: $e';
      logger.error(error);
      return {'success': false, 'message': error};
    }
  }

  /// 获取登录Cookie (调用“登录到”接口登录到主界面)
  Future<Map<String, dynamic>> _getLoginCookie(
    Map<String, dynamic> authDict,
  ) async {
    try {
      _clearCookieInterceptor(); // 先清理旧的拦截器

      late Response response;
      late String? redirectUrl;

      // 尝试获取
      response = await dio
          .post(
            ServiceCfgs.loginInfoUrl,
            data: {
              'Authorization': authDict['authorization'] ?? '',
              'category': authDict['type'] ?? '',
              'userId': authDict['userId'] ?? '',
              'schoolCode': authDict['schoolcode'] ?? '',
              'backUrl': ServiceCfgs.loginBackUrl,
            },
            options: Options(validateStatus: (status) => status! < 500),
          )
          .timeout(const Duration(seconds: ServiceCfgs.timeout));
      _throwForStatus(response);

      // 手动重定向并从URL中获取Cookie
      if (response.statusCode == 302) {
        // 第一次重定向
        redirectUrl =
            response.headers['location']?.first ?? response.realUri.toString();
        logger.debug('第一次重定向URL: $redirectUrl');
        response = await dio.get(redirectUrl);

        // 获取带 JSESSIONID 的 URL
        if (response.isRedirect) {
          redirectUrl =
              response.headers['location']?.first ??
              response.realUri.toString();
          logger.debug('带 JSESSIONID 的 URL: $redirectUrl');

          if (redirectUrl.contains('jsessionid=')) {
            // 从URL中提取 Cookie
            final String jsessionid = redirectUrl
                .split("jsessionid=")[1]
                .split("?")[0];
            // 更新 Cookie
            cookieInterceptor = InterceptorsWrapper(
              onRequest: (options, handler) {
                options.headers['Cookie'] = 'JSESSIONID=$jsessionid';
                handler.next(options);
              },
            );
            dio.interceptors.add(cookieInterceptor!);

            logger.debug('登录Cookie: $jsessionid');
            return {'success': true, 'cookie': jsessionid};
          }
        }
      }
      throw Exception('无法获取登录Cookie, 响应码: ${response.statusCode}');
    } catch (e) {
      final String error = '获取登录Cookie失败: $e';
      logger.error(error);
      return {'success': false, 'message': error};
    }
  }

  /// 通过API登录账号并更新Cookie
  Future<Map<String, dynamic>> loginAndUpdateCookie({
    String? userName,
    String? pwd,
  }) async {
    username = userName ?? username;
    password = pwd ?? password;

    logger.info('通过API登录账号并更新Cookie...用户名: $username');
    // logger.info('通过API登录账号并更新Cookie...用户名: $username, 密码: $password');
    final stopwatch = Stopwatch()..start();

    try {
      // 获取登录令牌
      final Map<String, dynamic> authResult = await _getLoginAuth();
      if (!authResult['success']) {
        return {'success': false, 'message': authResult['message']};
      }

      // 使用令牌登录（暂时只考虑单用户）
      final Map<String, dynamic> loginResult = await _getLoginCookie(
        authResult['data'][0],
      );
      if (!loginResult['success']) {
        return {'success': false, 'message': loginResult['message']};
      }

      cookie = loginResult['cookie'];
      String first10 = cookie!.substring(0, 10);
      logger.info('Cookie已更新, 前10位: $first10');
      // logger.info('Cookie已更新: $cookie');
      return {'success': true, 'cookie': cookie};
    } catch (e) {
      final String error = '登录账号失败: $e';
      logger.error(error);
      return {'success': false, 'message': error};
    } finally {
      stopwatch.stop();
      logger.info('API登录用时: ${stopwatch.elapsedMilliseconds / 1000}s');
    }
  }

  /// 检查当前会话是否有效
  Future<bool> _checkSessionValid() async {
    try {
      final response = await dio
          .post(ServiceCfgs.queryBalanceUrl)
          .timeout(const Duration(seconds: ServiceCfgs.timeout));

      // 检查响应是否为JSON格式
      if (response.data is! Map<String, dynamic>) {
        return false;
      } else {
        return true;
      }
    } catch (e) {
      logger.error('检查会话有效性失败: $e');
      return false;
    }
  }

  /// 确保会话有效, 无效则重新登录
  Future<void> _ensureSessionValid() async {
    if (!await _checkSessionValid()) {
      logger.info('会话已过期, 正在重新登录...');
      Map<String, dynamic> result = await loginAndUpdateCookie();
      if (result['success'] != true) {
        throw Exception(result['message']);
      }
    }
  }

  /// 获取并更新校园卡信息
  Future<Map<String, dynamic>> getAndUpadateCardInfo() async {
    logger.info('获取校园卡信息...');
    final stopwatch = Stopwatch()..start();

    try {
      await _ensureSessionValid();

      // 尝试获取
      final response = await dio
          .post(ServiceCfgs.queryBalanceUrl)
          .timeout(const Duration(seconds: ServiceCfgs.timeout));
      _throwForStatus(response, checkInnerCode: true);

      final respJson = response.data;
      logger.debug('校园卡信息响应: $respJson');

      // 尝试解析数据
      try {
        Map<String, dynamic> data = respJson['data']['whtiePersonnel'] ?? {};

        stuNo = data['stuNo'] ?? '(未知学号)';
        stuId = data['stuId'] ?? '(未知ID)';
        logger.debug('学号和ID已更新: 学号 $stuNo, ID $stuId');

        final Map<String, String> result = {
          '用户名': data['name'],
          '性别': data['sex'],
          '年级': data['yesr'],
          '班级': data['class_'],
          '学号': data['stuNo'],
          '用户ID': data['stuId'],
          '饭卡余额': Utils.convertMoney(data['leftMoney'] ?? 0),
          '累充金额': Utils.convertMoney(data['depositSum'] ?? 0),
          '已用总额': Utils.convertMoney(data['useMoneySum'] ?? 0),
          '上次消费时间': Utils.convertTime(data['lastConsumeTime'] ?? 0),
          '注册时间': Utils.convertTime(data['insertTime'] ?? 0),
          '更新时间': Utils.convertTime(data['updateTime'] ?? 0),
          '饭卡到期日': Utils.convertTime(data['expireDate'] ?? 0),
        };

        logger.debug('校园卡数据解析结果: $result');
        return {'success': true, 'data': result};
      } catch (e) {
        throw Exception('无法解析校园卡信息JSON数据: $e');
      }
    } catch (e) {
      final String error = '获取校园卡信息失败: $e';
      logger.error(error);
      return {'success': false, 'message': error};
    } finally {
      stopwatch.stop();
      logger.info('获取校园卡信息用时: ${stopwatch.elapsedMilliseconds / 1000}s');
    }
  }

  /// 通过用户编号获取用户服务限制
  Future<Map<String, dynamic>> getStudentServiceLimit() async {
    logger.info('获取用户$stuNo的服务限制状态...');
    final stopwatch = Stopwatch()..start();

    try {
      // 尝试获取
      final response = await dio
          .post(
            ServiceCfgs.serviceLimitUrl,
            data: {'schoolCode': ServiceCfgs.schoolCode, 'stuNo': stuNo},
          )
          .timeout(const Duration(seconds: ServiceCfgs.timeout));
      _throwForStatus(response, checkInnerCode: true);

      final respJson = response.data;
      logger.debug('用户服务限制响应: $respJson');

      // 解析并返回data字段
      final serviceLimit =
          respJson['data']?.toString() ?? ServiceLimit.normal.value;
      if (serviceLimit == ServiceLimit.normal.value) {
        noServiceLimit = true; // 无服务限制
      } else {
        noServiceLimit = false; // 有服务限制
      }
      return {'success': true, 'data': serviceLimit};
    } catch (e) {
      final String error = '获取用户服务限制失败: $e';
      logger.error(error);
      noServiceLimit = false; // 有服务限制
      return {'success': false, 'message': error};
    } finally {
      stopwatch.stop();
      logger.info('获取用户服务限制用时: ${stopwatch.elapsedMilliseconds / 1000}s');
    }
  }

  /// 确保遵循服务限制
  Future<void> _ensureAllowServiceLimit() async {
    if (!noServiceLimit) {
      throw Exception('您的账号服务受限, 该功能无法使用');
    }
  }

  /// 获取校园卡流水记录
  Future<Map<String, dynamic>> getPersonalFlowRecords(
    int currentPage,
    int pageSize,
    String monthStr,
  ) async {
    logger.info(
      '获取校园卡流水记录, 当前页码: $currentPage, 每页条数: $pageSize, 月份: $monthStr...',
    );
    final stopwatch = Stopwatch()..start();

    try {
      await _ensureAllowServiceLimit();
      await _ensureSessionValid();

      // 尝试获取
      final response = await dio
          .post(
            ServiceCfgs.personalFlowUrl,
            data: {
              'currentPage': currentPage,
              'pageSize': pageSize,
              'time': monthStr,
            },
          )
          .timeout(const Duration(seconds: ServiceCfgs.timeout));
      _throwForStatus(response, checkInnerCode: true);

      final respJson = response.data;
      logger.debug('校园卡流水记录响应: $respJson');
      final pageInfo = respJson['data']['page'] ?? {};

      List<Map<String, String>> records = [];
      // 依次向字典中添加记录
      for (final record in pageInfo['list'] ?? []) {
        final recordType = record['type'] ?? '(未知类型)'; // 记录类型
        final isDeposit =
            recordType == FlowType.deposit.value ||
            recordType == FlowType.manualDeposit.value; // 是否是存款
        final isModifyInfo = recordType == FlowType.modifyInfo.value; // 是否是修改信息

        final amount =
            isDeposit // 金额
            ? Utils.convertMoney(record['money']?.abs() ?? 0) // 存款：正数
            : '-${Utils.convertMoney(record['money']?.abs() ?? 0)}'; // 消费: 负数

        final transactionName =
            isDeposit // 交易名称 (现金充值/组名+窗口名)
            ? '账户充值'
            : "${record['grpName'] ?? '(未知组名)'}-${record['winName'] ?? '(未知窗口名)'}";

        final mealType = isModifyInfo
            ? '账户信息变更'
            : isDeposit
            ? '账户充值'
            : transactionName.contains('商店')
            ? '小卖铺'
            : record['schName'] ?? '未知餐次'; // 餐次

        records.add({
          '交易类型': isDeposit
              ? '存款'
              : isModifyInfo
              ? '账户信息变更'
              : '消费',
          '机器号': record['machineNumber'] ?? '(未知机器号)',
          '交易名称': transactionName,
          '餐次/类型': mealType,
          '交易时间': Utils.convertTime(record['insertTime'] ?? 0),
          '交易金额': amount,
          '交易前余额': Utils.convertMoney(record['beforeMoney'] ?? 0),
          '交易后余额': Utils.convertMoney(record['afterMoney'] ?? 0),
          '订单号': record['orderNo'] ?? '(未知订单号)',
        });
      }

      Map<String, dynamic> result = {
        '分页信息': {
          '当前页码': pageInfo['currentPage'].toString(),
          '每页条数': pageInfo['pageSize'].toString(),
          '总记录数': pageInfo['count'] ?? 0,
        },
        '消费记录': records,
      };

      logger.debug('校园卡流水记录解析结果: $result');
      return {'success': true, 'data': result};
    } catch (e) {
      final String error = '获取校园卡流水记录失败: $e';
      logger.error(error);
      return {'success': false, 'message': error};
    } finally {
      stopwatch.stop();
      logger.info('获取校园卡流水记录用时: ${stopwatch.elapsedMilliseconds / 1000}s');
    }
  }

  /// 解析微信商户数据
  Map<String, dynamic> _parseWechatMerchant(String wechatStr) {
    try {
      final Map<String, dynamic> result = json.decode(wechatStr);
      // 处理时间戳字段
      for (final field in ['insertTime', 'updateTime']) {
        if (result[field] != null) {
          final ts = result[field]['time'] ?? 0;
          result[field]['datetime'] = Utils.convertTime(ts);
        }
      }

      logger.debug('微信商户数据解析结果: $result');
      return result;
    } on FormatException catch (e) {
      String? err = '解析微信商户JSON数据失败: $e';
      throw Exception(err);
    } catch (e) {
      logger.error('微信商户数据解析失败: $e');
      return {};
    }
  }

  /// 解析内部充值记录数据
  Map<String, dynamic> _parseInnerRechargeRecords(
    Map<String, dynamic> outterJson,
  ) {
    try {
      // 处理嵌套JSON字符串
      final Map<String, dynamic> data = json.decode(outterJson['data'] ?? '{}');
      logger.debug('充值记录内部数据: $data');

      if (data['list'] != null) {
        // 处理订单列表
        for (Map<String, dynamic> order in data['list'] as List<dynamic>) {
          // 解析微信商户信息
          if (order.containsKey('wechat_merchant') &&
              order['wechat_merchant'] != null) {
            final wechatStr = order['wechat_merchant']?.toString() ?? '{}';
            order['wechat_merchant'] = _parseWechatMerchant(wechatStr);
          }
          logger.debug('内部充值记录微信商户解析后数据: $order');
        }
      }

      return data;
    } on FormatException catch (e) {
      logger.error('内部充值记录解析失败: $e');
      return {};
    } catch (e) {
      logger.error('内部充值记录解析失败: $e');
      return {};
    }
  }

  /// 解析充值记录数据为易读格式
  Map<String, dynamic> _parseLegibleRechargeRecords(
    Map<String, dynamic> parsedData,
    String monthStr,
  ) {
    final Map<String, dynamic> result = {};

    try {
      final String currentPage = parsedData['pageNumber']?.toString() ?? '(未知)';
      final String totalPage = parsedData['totalPage']?.toString() ?? '(未知)';
      // 基础信息解析
      result['基础信息'] = {
        '查询月份': monthStr,
        '分页信息': {
          '当前页码/总页数': '$currentPage/$totalPage',
          '每页条数': parsedData['pageSize']?.toString() ?? '(未知)',
          '总记录数': parsedData['totalRow']?.toString() ?? '(未知)',
        },
      };

      // 处理交易记录
      final records = <Map<String, String>>[];
      final list = parsedData['list'] ?? [] as List<dynamic>?;

      if (list != null) {
        for (final record in list) {
          final String rechargeAmount = Utils.convertMoney(
            record['recharge_money'] ?? 0,
          ); // 充值金额
          final String accumulatedMerchants = Utils.convertMoney(
            record['new_today_total_money'] ?? 0,
          ); // 商户累计入账

          records.add({
            '支付渠道': record['recharge_type'] ?? '(未知渠道)',
            '充值金额': rechargeAmount,
            '操作状态': record['recharge_status'] ?? '(未知状态)',
            '订单编号': record['custom_order_id'] ?? '(未知编号)',
            '商户累计入账': accumulatedMerchants,
            '充值时间': record['inserttime'] ?? '(未知时间)',
            '到账时间': record['recordedtime'] ?? '(未知时间)',
            '更新时间': record['updatetime'] ?? '(未知时间)',
          });
        }
      }

      result['充值记录'] = records;
      logger.debug('充值记录解析为易读格式: $result');
    } catch (e) {
      logger.error('充值记录解析失败: $e');
      throw Exception(e);
    }

    return result;
  }

  /// 获取充值记录
  Future<Map<String, dynamic>> getRechargeRecords(
    int pageNumber,
    String monthStr,
  ) async {
    logger.info('获取充值记录, 当前页码：$pageNumber, 月份: $monthStr...');
    final stopwatch = Stopwatch()..start();

    try {
      await _ensureAllowServiceLimit();
      await _ensureSessionValid();

      // 尝试获取
      final response = await dio
          .post(
            ServiceCfgs.rechargeRecordUrl,
            data: {'pageNumber': pageNumber, 'monthStr': monthStr},
          )
          .timeout(const Duration(seconds: ServiceCfgs.timeout));
      _throwForStatus(response, checkInnerCode: true);

      final respJson = response.data;
      logger.debug('$monthStr充值记录响应: $respJson');

      // 尝试解析
      Map<String, dynamic> result = {};
      if (respJson['data'] != null) {
        final fullData = _parseInnerRechargeRecords(respJson);
        result = _parseLegibleRechargeRecords(fullData, monthStr);
      } else {
        logger.info('$monthStr充值记录返回数据为空');
      }

      return {'success': true, 'data': result};
    } catch (e) {
      final String error = '获取$monthStr充值记录失败: $e';
      logger.error(error);
      return {'success': false, 'message': error};
    } finally {
      stopwatch.stop();
      logger.info(
        '获取$monthStr充值记录用时: ${stopwatch.elapsedMilliseconds / 1000}s',
      );
    }
  }

  /// 获取账号注册时填写的详细信息
  Future<Map<String, dynamic>> getDetailsInfo() async {
    logger.info('获取ID为$stuId的详细信息...');
    final stopwatch = Stopwatch()..start();

    try {
      await _ensureSessionValid();

      // 尝试获取
      final response = await dio
          .post(
            ServiceCfgs.detailsInfoUrl,
            data: {'schoolcode': ServiceCfgs.schoolCode, 'id': stuId!},
          )
          .timeout(const Duration(seconds: ServiceCfgs.timeout));
      _throwForStatus(response, checkInnerCode: true);

      final respJson = response.data;
      logger.debug('账号详细信息响应: $respJson');

      return {'success': true, 'data': respJson};
    } catch (e) {
      final String error = '获取详细信息失败: $e';
      logger.error(error);
      return {'success': false, 'message': error};
    } finally {
      stopwatch.stop();
      logger.info('获取详细信息用时: ${stopwatch.elapsedMilliseconds / 1000}s');
    }
  }

  /// 获取考勤记录
  Future<Map<String, dynamic>> getAttendanceRecords(String date) async {
    logger.info('获取用户$stuNo在$date的考勤记录...');
    final stopwatch = Stopwatch()..start();

    try {
      await _ensureAllowServiceLimit();
      await _ensureSessionValid();

      // 尝试获取
      final response = await dio
          .post(
            ServiceCfgs.attendanceRecordUrl,
            data: {
              'kqDate': date,
              'date': date,
              'stuNo': stuNo,
              'stuId': stuId,
              'schoolCode': ServiceCfgs.schoolCode,
              'kqId': '',
              'id': '',
            },
          )
          .timeout(const Duration(seconds: ServiceCfgs.timeout));
      _throwForStatus(response, checkInnerCode: true);

      final respJson = response.data;
      logger.debug('$date考勤记录响应: $respJson');

      final records = <Map<String, dynamic>>[];
      // 处理一天中的多条记录
      for (final record in respJson['data'] ?? {}) {
        final status = record['status'] == AttendanceStatus.normal.value
            ? '正常'
            : record['status'] == AttendanceStatus.late.value
            ? '迟到'
            : '异常'; // 考勤状态
        final String recordType = record['type'] ?? '-1'; // 记录类型
        final String entryType =
            (record['dataType'] ?? '-1') == EntryType.parentConfirmation.value
            ? '家长确认'
            : recordType == EntryType.enterSchool.value
            ? '进校'
            : recordType == EntryType.leaveSchool.value
            ? '离校'
            : recordType == EntryType.dormitory.value
            ? '宿舍'
            : '(未知)'; // 进出类型

        records.add({
          '考勤地点':
              '${record['machineName'] ?? '(未知)'} (机器号${record['machineNum'] ?? '(未知)'})',
          '考勤时间': record['rdTime'] ?? '',
          '考勤状态': status,
          '进出类型': entryType,
        });
      }

      logger.debug('解析$date考勤记录: $records');
      return {'success': true, 'data': records};
    } catch (e) {
      final String error = '获取$date考勤记录失败: $e';
      logger.error(error);
      return {'success': false, 'message': error};
    } finally {
      stopwatch.stop();
      logger.info('获取$date考勤记录用时: ${stopwatch.elapsedMilliseconds / 1000}s');
    }
  }

  /// 下载考勤图片
  Future<Map<String, dynamic>> downloadAttendancePictures(
    String baseDir,
    String datetime,
  ) async {
    logger.info('下载考勤图片, 基础目录: $baseDir, 日期时间: $datetime...');
    final stopwatch = Stopwatch()..start();

    try {
      // 获取应用的外部缓存存储
      final cacheDir = await getExternalCacheDirectories();
      if (cacheDir == null || cacheDir.isEmpty) {
        throw Exception('无法获取外部缓存目录');
      }

      // 纯考勤时间 (2025-03-01 12:00:00 -> 20250301120000)
      final cleanDatetime = datetime.replaceAll(RegExp(r'[^\d]'), '');
      // 纯考勤带年日期: (20250301)
      final cleanYearDate = cleanDatetime.substring(0, 8);
      // 图片URL (.../20250301/75202400000/20250301120000)
      final imageUrl =
          '${ServiceCfgs.faceRecordBaseUrl}/$cleanYearDate/${stuNo}_$cleanDatetime.jpg';

      // 图片保存目录 (.../pic_dir/75202400000/20250301)
      final saveDir = Directory(
        path.join(
          cacheDir.first.path,
          baseDir,
          stuNo.toString(),
          cleanYearDate,
        ),
      );
      // 图片保存路径
      final savePath = path.join(
        saveDir.path,
        '${cleanDatetime.substring(8)}.jpg',
      );
      if (!saveDir.existsSync()) {
        saveDir.createSync(recursive: true);
      }

      // 图片已存在且未损坏, 直接返回
      if (await Utils.isImageCached(savePath)) {
        return {'success': true, 'savePath': savePath};
      }

      try {
        // 防止会话过期
        await _ensureSessionValid();

        // 尝试下载图片
        final response = await dio
            .get(imageUrl, options: Options(responseType: ResponseType.bytes))
            .timeout(const Duration(seconds: 10));
        _throwForStatus(response);

        if (response.data.isEmpty) {
          final err = '获取到的图片数据为空';
          throw Exception(err);
        }

        // 将图片写入到文件
        final file = File(savePath);
        await file.writeAsBytes(response.data);

        logger.info('下载$datetime考勤图片成功: $imageUrl, 保存路径: $savePath');
        return {'success': true, 'savePath': savePath};
      } catch (e) {
        if (e is HttpException) {
          logger.warning('下载$datetime考勤图片失败: $e');
        }

        try {
          // 尝试下载默认图片
          final defaultResponse = await dio
              .get(
                ServiceCfgs.noPictureUrl,
                options: Options(responseType: ResponseType.bytes),
              )
              .timeout(const Duration(seconds: ServiceCfgs.timeout));
          _throwForStatus(defaultResponse);

          // 将图片写入到文件
          final file = File(savePath);
          await file.writeAsBytes(defaultResponse.data);

          logger.info('下载默认图片成功: $savePath');
          return {'success': true, 'savePath': savePath};
        } catch (deftErr) {
          final err = '下载默认图片失败: $deftErr';
          logger.error(err);
          return {'success': false, 'message': err};
        }
      }
    } catch (e) {
      final String err = '下载$datetime考勤图片失败: $e';
      logger.error(err);
      return {'success': false, 'message': err};
    } finally {
      stopwatch.stop();
      logger.info(
        '考勤图片$datetime下载用时: ${stopwatch.elapsedMilliseconds / 1000}s',
      );
    }
  }
}
