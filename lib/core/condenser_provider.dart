import 'dart:async';

import 'package:flutter/foundation.dart';

import 'config.dart';
import 'mqtt_service.dart';

class CondenserProvider extends ChangeNotifier {
  CondenserProvider({MqttService? mqtt}) : _mqtt = mqtt ?? MqttService();

  final MqttService _mqtt;
  StreamSubscription? _sub;

  bool connecting = false;
  bool online = false;
  bool powerOn = true;
  DateTime? lastUpdate;
  String? lastTopic;
  int rxCount = 0;

  double? airTemp;
  double? humidity;
  double? dewPoint;
  double? coldPlate;
  double? setpoint;
  double? tecPercent;
  bool fanOn = false;
  String status = 'Chưa kết nối';

  bool get mqttConnected => _mqtt.isConnected;
  bool get hasTelemetry =>
      airTemp != null || humidity != null || dewPoint != null || coldPlate != null;

  Future<void> start() async {
    connecting = true;
    status = 'Đang kết nối MQTT...';
    notifyListeners();

    _sub?.cancel();
    _sub = _mqtt.messages.listen(_onMessage);

    final ok = await _mqtt.connect();
    connecting = false;
    if (!ok) {
      status = 'Không kết nối được MQTT';
      notifyListeners();
      return;
    }

    status = 'MQTT OK — chờ ESP32 publish (chip 789)...';
    notifyListeners();
  }

  void _onMessage(Map<String, dynamic> data) {
    final topic = data['topic'] as String? ?? '';
    final value = data['value'];
    lastTopic = topic;
    rxCount++;

    // Match linh hoạt: full topic hoặc endsWith device suffix
    if (_is(topic, AppConfig.topicOnline) || topic == 'tele/789/status') {
      online = value.toString().toLowerCase() == 'online';
      if (online && !hasTelemetry) {
        status = 'ESP32 online — chờ telemetry...';
      } else if (online) {
        status = 'ESP32 online';
      }
    } else if (_is(topic, AppConfig.topicTemp) || topic.endsWith('_temp_livingroom/status')) {
      airTemp = _asDouble(value);
    } else if (_is(topic, AppConfig.topicHumi) || topic.endsWith('_humi_living_room/status')) {
      humidity = _asDouble(value);
    } else if (_is(topic, AppConfig.topicDew) || topic.endsWith('_dew_point/status')) {
      dewPoint = _asDouble(value);
    } else if (_is(topic, AppConfig.topicCold) || topic.endsWith('_cold_plate/status')) {
      coldPlate = _asDouble(value);
    } else if (_is(topic, AppConfig.topicSetpoint) || topic.endsWith('_setpoint/status')) {
      setpoint = _asDouble(value);
    } else if (_is(topic, AppConfig.topicTec) || topic.endsWith('_tec/status')) {
      tecPercent = _asDouble(value);
    } else if (_is(topic, AppConfig.topicFan) || topic.endsWith('_fan_livingroom/status')) {
      fanOn = _asOn(value);
    } else if (_is(topic, AppConfig.topicPower) || topic.endsWith('_power/status')) {
      powerOn = _asOn(value);
    } else if (_is(topic, AppConfig.topicStatus) ||
        (topic.endsWith('_status/status') && topic.contains('789_status'))) {
      status = value?.toString() ?? status;
    } else {
      // Topic khác (vd chip 123) — bỏ qua, không cập nhật lastUpdate UI chính
      if (kDebugMode) print('MQTT ignore topic: $topic');
      notifyListeners();
      return;
    }

    lastUpdate = DateTime.now();
    notifyListeners();
  }

  bool _is(String topic, String expected) => topic == expected;

  void togglePower() {
    if (!_mqtt.isConnected) {
      status = 'MQTT chưa kết nối — nhấn refresh';
      notifyListeners();
      return;
    }
    final next = !powerOn;
    powerOn = next;
    status = next ? 'Đã gửi lệnh BẬT...' : 'Đã gửi lệnh TẮT...';
    notifyListeners();
    _mqtt.setPower(next);
  }

  Future<void> reconnect() => start();

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }

  bool _asOn(dynamic v) {
    final s = v.toString().toUpperCase();
    return s == 'ON' || s == '1' || s == 'TRUE';
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mqtt.dispose();
    super.dispose();
  }
}
