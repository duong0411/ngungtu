import 'dart:async';

import 'package:flutter/foundation.dart';

import 'config.dart';
import 'mqtt_service.dart';

typedef TelemetrySync = Future<void> Function(Map<String, dynamic> state);

class TelemetryPoint {
  TelemetryPoint({
    required this.at,
    this.airTemp,
    this.humidity,
    this.dewPoint,
    this.coldPlate,
    this.setpoint,
  });

  final DateTime at;
  final double? airTemp;
  final double? humidity;
  final double? dewPoint;
  final double? coldPlate;
  final double? setpoint;
}

class CondenserProvider extends ChangeNotifier {
  CondenserProvider({MqttService? mqtt}) : _mqtt = mqtt ?? MqttService();

  final MqttService _mqtt;
  StreamSubscription? _sub;
  TelemetrySync? onTelemetry;

  static const int maxHistory = 90;
  static const Duration _historyInterval = Duration(milliseconds: 800);

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
  double? fanPercent;
  bool fanOn = false;
  String status = 'Chưa kết nối';

  final List<TelemetryPoint> history = [];

  bool get mqttConnected => _mqtt.isConnected;
  bool get hasTelemetry =>
      airTemp != null || humidity != null || dewPoint != null || coldPlate != null;

  Future<void> start({bool force = false}) async {
    connecting = true;
    status = 'Đang kết nối máy thu nước...';
    notifyListeners();

    _sub ??= _mqtt.messages.listen(_onMessage);

    final ok = await _mqtt.connect(force: force);
    connecting = false;
    if (!ok) {
      status = 'Chưa kết nối được — kéo xuống để thử lại';
      notifyListeners();
      return;
    }

    status = 'Đã sẵn sàng — đang chờ dữ liệu cảm biến';
    notifyListeners();
  }

  void _onMessage(Map<String, dynamic> data) {
    final topic = data['topic'] as String? ?? '';
    final value = data['value'];

    final isLwtOffline = (topic == AppConfig.topicOnline || topic == 'tele/789/status') &&
        value.toString().toLowerCase() == 'offline';

    var changedSensors = false;

    if (_is(topic, AppConfig.topicOnline) || topic == 'tele/789/status') {
      online = value.toString().toLowerCase() == 'online';
      if (online) {
        status = hasTelemetry ? 'Máy đang vận hành ổn định' : 'Đã sẵn sàng — chờ dữ liệu cảm biến';
      } else if (isLwtOffline) {
        status = 'Đang chờ tín hiệu từ máy...';
      }
    } else if (_is(topic, AppConfig.topicTemp) || topic.endsWith('_temp_livingroom/status')) {
      airTemp = _asDouble(value);
      changedSensors = true;
    } else if (_is(topic, AppConfig.topicHumi) || topic.endsWith('_humi_living_room/status')) {
      humidity = _asDouble(value);
      changedSensors = true;
    } else if (_is(topic, AppConfig.topicDew) || topic.endsWith('_dew_point/status')) {
      dewPoint = _asDouble(value);
      changedSensors = true;
    } else if (_is(topic, AppConfig.topicCold) || topic.endsWith('_cold_plate/status')) {
      coldPlate = _asDouble(value);
      changedSensors = true;
    } else if (_is(topic, AppConfig.topicSetpoint) || topic.endsWith('_setpoint/status')) {
      setpoint = _asDouble(value);
      changedSensors = true;
    } else if (_is(topic, AppConfig.topicTec) || topic.endsWith('_tec/status')) {
      tecPercent = _asDouble(value);
    } else if (_is(topic, AppConfig.topicFan) || topic.endsWith('_fan_livingroom/status')) {
      final pct = _asDouble(value);
      if (pct != null) {
        fanPercent = pct.clamp(0, 100);
        fanOn = fanPercent! > 0;
      } else {
        fanOn = _asOn(value);
        fanPercent = fanOn ? 100 : 0;
      }
    } else if (_is(topic, AppConfig.topicPower) || topic.endsWith('_power/status')) {
      powerOn = _asOn(value);
    } else if (_is(topic, AppConfig.topicStatus) ||
        (topic.endsWith('_status/status') && topic.contains('789_status'))) {
      status = value?.toString() ?? status;
    } else {
      return;
    }

    lastUpdate = DateTime.now();

    if (changedSensors && hasTelemetry) {
      _pushHistory();
    }

    notifyListeners();

    if (hasTelemetry && onTelemetry != null) {
      onTelemetry!({
        'temperature': airTemp,
        'humidity': humidity,
        'dewPoint': dewPoint,
        'coldPlate': coldPlate,
        'setpoint': setpoint,
        'tecPercent': tecPercent,
        'fanPercent': fanPercent,
        'fan': fanOn,
        'power': powerOn,
        'status': status,
        'chipId': AppConfig.chipId,
      });
    }
  }

  TelemetryPoint _snapshot([DateTime? at]) => TelemetryPoint(
        at: at ?? DateTime.now(),
        airTemp: airTemp,
        humidity: humidity,
        dewPoint: dewPoint,
        coldPlate: coldPlate,
        setpoint: setpoint,
      );

  void _pushHistory() {
    final now = DateTime.now();

    // Điểm đầu: seed 2 điểm gần nhau để biểu đồ vẽ ngay (không chờ chu kỳ MQTT tiếp)
    if (history.isEmpty) {
      history.add(_snapshot(now.subtract(const Duration(seconds: 1))));
      history.add(_snapshot(now));
      return;
    }

    // Topic MQTT tới dồn cục — cập nhật điểm cuối trong ~0.8s, sau đó mới thêm điểm mới
    if (now.difference(history.last.at) < _historyInterval) {
      history[history.length - 1] = _snapshot(now);
      return;
    }

    history.add(_snapshot(now));
    while (history.length > maxHistory) {
      history.removeAt(0);
    }
  }

  bool _is(String topic, String expected) => topic == expected;

  void togglePower() {
    if (!_mqtt.isConnected) {
      status = 'Chưa kết nối — kéo xuống để thử lại';
      notifyListeners();
      return;
    }
    final next = !powerOn;
    powerOn = next;
    status = next ? 'Đã bật hệ thống' : 'Đã tạm dừng hệ thống';
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
