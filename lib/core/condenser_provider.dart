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

  double? airTemp;
  double? humidity;
  double? dewPoint;
  double? coldPlate;
  double? setpoint;
  double? tecPercent;
  bool fanOn = false;
  String status = 'Chưa kết nối';

  bool get mqttConnected => _mqtt.isConnected;

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

    status = 'Đã kết nối — chờ ESP32...';
    notifyListeners();
  }

  void _onMessage(Map<String, dynamic> data) {
    final topic = data['topic'] as String? ?? '';
    final value = data['value'];

    if (topic == AppConfig.topicOnline) {
      online = value.toString().toLowerCase() == 'online';
      if (online) status = 'ESP32 online';
    } else if (topic == AppConfig.topicTemp) {
      airTemp = _asDouble(value);
    } else if (topic == AppConfig.topicHumi) {
      humidity = _asDouble(value);
    } else if (topic == AppConfig.topicDew) {
      dewPoint = _asDouble(value);
    } else if (topic == AppConfig.topicCold) {
      coldPlate = _asDouble(value);
    } else if (topic == AppConfig.topicSetpoint) {
      setpoint = _asDouble(value);
    } else if (topic == AppConfig.topicTec) {
      tecPercent = _asDouble(value);
    } else if (topic == AppConfig.topicFan) {
      fanOn = _asOn(value);
    } else if (topic == AppConfig.topicPower) {
      powerOn = _asOn(value);
    } else if (topic == AppConfig.topicStatus) {
      status = value?.toString() ?? status;
    } else {
      return;
    }

    lastUpdate = DateTime.now();
    notifyListeners();
  }

  void togglePower() {
    final next = !powerOn;
    powerOn = next;
    status = next ? 'Đang bật hệ thống...' : 'Đang tắt hệ thống...';
    notifyListeners();
    _mqtt.setPower(next);
  }

  Future<void> reconnect() => start();

  double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
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
