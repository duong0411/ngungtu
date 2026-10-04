/// Cấu hình MQTT + API (cùng backend AloT / MongoDB)
class AppConfig {
  static const String apiBaseUrl = 'https://duynguyen.io.vn/api';
  static const String brokerUrl = 'wss://mqtt.duynguyen.io.vn/mqtt';
  static const String defaultChipId = '789';
  static const String deviceName = 'Máy Ngưng Tụ STEM';

  /// Chip đang gắn — người dùng nhập ở màn Connect (mặc định 789).
  static String chipId = defaultChipId;

  static void setChipId(String id) {
    final cleaned = id.trim();
    chipId = cleaned.isEmpty ? defaultChipId : cleaned;
  }

  static String get topicOnline => 'tele/$chipId/status';
  static String get topicTemp => 'tele/${chipId}_temp_livingroom/status';
  static String get topicHumi => 'tele/${chipId}_humi_living_room/status';
  static String get topicFan => 'tele/${chipId}_fan_livingroom/status';
  static String get topicDew => 'tele/${chipId}_dew_point/status';
  static String get topicCold => 'tele/${chipId}_cold_plate/status';
  static String get topicSetpoint => 'tele/${chipId}_setpoint/status';
  static String get topicTec => 'tele/${chipId}_tec/status';
  static String get topicStatus => 'tele/${chipId}_status/status';
  static String get topicPower => 'tele/${chipId}_power/status';

  static String get cmndPower => 'cmnd/${chipId}_power/POWER';
  static String get cmndFan => 'cmnd/${chipId}_fan_livingroom/POWER';

  static List<String> get subscribeTopics => [
        topicOnline,
        topicTemp,
        topicHumi,
        topicFan,
        topicDew,
        topicCold,
        topicSetpoint,
        topicTec,
        topicStatus,
        topicPower,
      ];
}
