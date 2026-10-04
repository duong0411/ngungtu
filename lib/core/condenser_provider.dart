import 'dart:async';

import 'package:flutter/foundation.dart';

import 'config.dart';
import 'mqtt_service.dart';

typedef TelemetrySync = Future<void> Function(Map<String, dynamic> state);

class CondenserProvider extends ChangeNotifier {
  CondenserProvider({MqttService? mqtt}) : _mqtt = mqtt ?? MqttService();

  final MqttService _mqtt;
  StreamSubscription? _sub;
  TelemetrySync? onTelemetry;

  bool connecting = false;
  bool online = false;
  bool powerOn = true;
  DateTime? lastUpdate;
  String? lastTopic;
  String? lastPayload;
  int rxCount = 0;
  int rx789Count = 0;
  final List<String> debugLog = [];

  double? airTemp;
  double? humidity;
  double? dewPoint;
  double? coldPlate;
  double? setpoint;
  double? tecPercent;
  bool fanOn = false;
  String status = 'Chưa kết nối';

  bool get mqttConnected => _mqtt.isConnected;
  String get lastError => _mqtt.lastError;
  String get mqttClientId => _mqtt.clientId;
  bool get hasTelemetry =>
      airTemp != null || humidity != null || dewPoint != null || coldPlate != null;

  void _log(String line) {
    final ts = DateTime.now();
    final stamp =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}';
    debugLog.insert(0, '[$stamp] $line');
    if (debugLog.length > 40) debugLog.removeLast();
  }

  Future<void> start({bool force = false}) async {
    connecting = true;
    status = 'Đang kết nối MQTT...';
    _log(force ? 'Force reconnect...' : 'Connecting broker...');
    notifyListeners();

    _sub ??= _mqtt.messages.listen(_onMessage);

    final ok = await _mqtt.connect(force: force);
    connecting = false;
    if (!ok) {
      status = 'Không kết nối được MQTT';
      _log('CONNECT FAIL: ${lastError.isEmpty ? "?" : lastError}');
      notifyListeners();
      return;
    }

    status = 'MQTT OK — chờ ESP32 (chip 789)...';
    _log('CONNECTED ${mqttClientId}');
    notifyListeners();
  }

  void _onMessage(Map<String, dynamic> data) {
    final topic = data['topic'] as String? ?? '';
    final value = data['value'];
    final raw = data['raw']?.toString() ?? '';
    lastTopic = topic;
    lastPayload = raw;
    rxCount++;

    final is789 = topic.contains('789');
    // Bỏ qua LWT offline — không tính là đã có telemetry
    final isLwtOffline = (topic == AppConfig.topicOnline || topic == 'tele/789/status') &&
        value.toString().toLowerCase() == 'offline';

    if (is789) {
      if (!isLwtOffline) rx789Count++;
      _log('RX789 $topic → $raw');
    }

    if (_is(topic, AppConfig.topicOnline) || topic == 'tele/789/status') {
      online = value.toString().toLowerCase() == 'online';
      if (online) {
        status = hasTelemetry ? 'ESP32 online' : 'ESP32 online — chờ số liệu...';
      } else {
        // Retained LWT "offline" — ESP có thể vẫn đang chạy, đừng coi như chết hẳn
        status = 'Nhận LWT offline — chờ telemetry ESP...';
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
      if (kDebugMode) print('MQTT ignore: $topic');
      notifyListeners();
      return;
    }

    lastUpdate = DateTime.now();
    notifyListeners();

    if (hasTelemetry && onTelemetry != null) {
      onTelemetry!({
        'temperature': airTemp,
        'humidity': humidity,
        'dewPoint': dewPoint,
        'coldPlate': coldPlate,
        'setpoint': setpoint,
        'tecPercent': tecPercent,
        'fan': fanOn,
        'power': powerOn,
        'status': status,
        'chipId': AppConfig.chipId,
      });
    }
  }

  bool _is(String topic, String expected) => topic == expected;

  Future<Map<String, dynamic>> testMqttReceive() async {
    _log('START MQTT TEST (wait ESP 789)...');
    notifyListeners();
    final result = await _mqtt.testReceiveEsp();
    _log(result['ok'] == true
        ? 'TEST OK count=${result['count']}'
        : 'TEST FAIL: ${result['reason']}');
    // Đồng bộ lại listener provider
    _sub ??= _mqtt.messages.listen(_onMessage);
    notifyListeners();
    return result;
  }

  void togglePower() {
    if (!_mqtt.isConnected) {
      status = 'MQTT chưa kết nối — nhấn refresh';
      _log('TX blocked: not connected');
      notifyListeners();
      return;
    }
    final next = !powerOn;
    powerOn = next;
    status = next ? 'Đã gửi lệnh BẬT...' : 'Đã gửi lệnh TẮT...';
    _log('TX power=${next ? "ON" : "OFF"}');
    notifyListeners();
    _mqtt.setPower(next);
  }

  Future<void> reconnect() => start(force: true);

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
