enum FlowType {
  consume('0'),
  deposit('1'),
  modifyInfo('6'),
  manualDeposit('10');

  const FlowType(this.value);
  final String value;
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
