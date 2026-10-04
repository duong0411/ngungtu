/// Cấu hình MQTT + API (cùng backend AloT / MongoDB)
class AppConfig {
  static const String apiBaseUrl = 'https://duynguyen.io.vn/api';
  static const String brokerUrl = 'wss://mqtt.duynguyen.io.vn/mqtt';
  static const String chipId = '789';
  static const String deviceName = 'Máy Ngưng Tụ STEM';

  static const String topicOnline = 'tele/$chipId/status';
  static const String topicTemp = 'tele/${chipId}_temp_livingroom/status';
  static const String topicHumi = 'tele/${chipId}_humi_living_room/status';
  static const String topicFan = 'tele/${chipId}_fan_livingroom/status';
  static const String topicDew = 'tele/${chipId}_dew_point/status';
  static const String topicCold = 'tele/${chipId}_cold_plate/status';
  static const String topicSetpoint = 'tele/${chipId}_setpoint/status';
  static const String topicTec = 'tele/${chipId}_tec/status';
  static const String topicStatus = 'tele/${chipId}_status/status';
  static const String topicPower = 'tele/${chipId}_power/status';

  static const String cmndPower = 'cmnd/${chipId}_power/POWER';
  static const String cmndFan = 'cmnd/${chipId}_fan_livingroom/POWER';

  static const List<String> subscribeTopics = [
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
