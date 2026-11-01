enum FlowType {
  consume('0', '消费'),
  deposit('1', '存款'),
  modifyInfo('6', '账户信息变更'),
  manualDeposit('10', '人工充值'),
  arrears('14', '欠款'),
  cancelArrears('15', '取消欠款'),
  reserveMeal('17', '预订餐');

  const FlowType(this.value, this.label);

  final String value;
  final String label;

  /// 需要在流水中显示映射文案的记录类型
  static const Set<String> _displayLabelTypes = {'10', '14', '15', '17'};

  /// 根据 recordType 获取显示文案, 非映射类型返回 null
  static String? displayLabelOf(String value) {
    if (!_displayLabelTypes.contains(value)) return null;
    for (final type in FlowType.values) {
      if (type.value == value) return type.label;
    }
    return null;
  }
}

enum AttendanceStatus {
  normal('0'),
  late('1');

  const AttendanceStatus(this.value);
  final String value;
}

enum EntryType {
  parentConfirmation('ParentConfirmation'),
  enterSchool('0'),
  leaveSchool('1'),
  dormitory('2');

  const EntryType(this.value);
  final String value;
}

enum ServiceLimit {
  normal('0'),
  restricted('1');

  const ServiceLimit(this.value);
  final String value;
}

class ServiceCfgs {
  static const int timeout = 30;
  static const String schoolCode = 'gfcxxx';
  static const String getAuthUrl =
      'https://appsvr01.szxinyu.com/SchoolUserCenter/loginUserSso/login';
  static const String getLoginValidCodeUrl =
      'https://appsvr01.szxinyu.com/SchoolUserCenter/loginUserSso/getLoginValidCode';
  static const String getValidCodeUrl =
      'https://appsvr01.szxinyu.com/SchoolUserCenter/loginUserSso/getValidCode';
  static const String findPasswordUrl =
      'https://appsvr01.szxinyu.com/SchoolUserCenter/loginUserSso/findPassword';
  static const String loginInfoUrl =
      'https://appsvr01.szxinyu.com/SchoolUserCenter/loginUserSso/loginInto';
  static const String loginBackUrl =
      'https://appsvr01.szxinyu.com/SchoolUserOnline/wechatServer/index';
  static const String queryBalanceUrl =
      'https://appsvr01.szxinyu.com/SchoolUserOnline/wechatRecharge/queryAllBalance';
  static const String serviceLimitUrl =
      'https://appsvr01.szxinyu.com/SchoolUserOnline/studentServiceLimitController/getStudentServiceLimitByStuId';
  static const String personalFlowUrl =
      'https://appsvr01.szxinyu.com/SchoolUserOnline/personalFlowRecordController/getAllPersonalFlowRecord';
  static const String rechargeRecordUrl =
      'https://appsvr01.szxinyu.com/SchoolUserOnline/wechatRecharge/getRechargeOrderByPage';
  static const String detailsInfoUrl =
      'https://appsvr01.szxinyu.com/SchoolUserOnline/userInfoController/findStudentDetailsInfo';
  static const String attendanceRecordUrl =
      'https://appsvr01.szxinyu.com/SchoolUserOnline/parentConfirmationController/getAttendanceRecord';
  static final String faceRecordBaseUrl =
      'https://appsvr01.szxinyu.com/SchoolUserOnline/faceCompare/$schoolCode';
  static const String noPictureUrl =
      'https://appsvr01.szxinyu.com/SchoolUserOnline/wechat/message/img/no-pictures.png';
}
