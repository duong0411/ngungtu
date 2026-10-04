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

  /// Đã nhận tín hiệu đúng chipId người dùng nhập.
  bool chipVerified = false;
  String linkedChipId = '';
  bool chipBound = false;

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

  /// Vào dashboard khi MQTT OK + đúng chip đã xác thực + có online/tele.
  bool get canEnterSystem =>
      chipBound &&
      mqttConnected &&
      chipVerified &&
      linkedChipId == AppConfig.chipId &&
      (online || hasTelemetry);

  Future<void> start({bool force = false}) async {
    connecting = true;
    if (force) {
      chipVerified = false;
      linkedChipId = '';
      online = false;
    }
    status = chipBound
        ? 'Đang kết nối chip ${AppConfig.chipId}...'
        : 'Đang kết nối máy thu nước...';
    notifyListeners();

    _sub ??= _mqtt.messages.listen(_onMessage);

    final ok = await _mqtt.connect(force: force);
    connecting = false;
    if (!ok) {
      status = 'Chưa kết nối được — kéo xuống để thử lại';
      notifyListeners();
      return;
    }

    status = chipBound
        ? 'MQTT OK — chờ chip ${AppConfig.chipId} phản hồi...'
        : 'Đã sẵn sàng — đang chờ dữ liệu cảm biến';
    notifyListeners();
  }

  /// Gắn chipId người dùng nhập rồi kết nối / xác thực.
  Future<bool> connectWithChip(String rawChipId) async {
    final id = rawChipId.trim();
    if (id.isEmpty) {
      status = 'Vui lòng nhập Chip ID';
      notifyListeners();
      return false;
    }

    AppConfig.setChipId(id);
    chipBound = true;
    chipVerified = false;
    linkedChipId = '';
    online = false;
    airTemp = null;
    humidity = null;
    dewPoint = null;
    coldPlate = null;
    setpoint = null;
    tecPercent = null;
    fanPercent = null;
    fanOn = false;
    history.clear();
    lastUpdate = null;
    status = 'Đang kết nối chip ${AppConfig.chipId}...';
    notifyListeners();

    await start(force: true);
    return mqttConnected;
  }

  void disconnectChip() {
    chipBound = false;
    chipVerified = false;
    linkedChipId = '';
    online = false;
    airTemp = null;
    humidity = null;
    dewPoint = null;
    coldPlate = null;
    setpoint = null;
    tecPercent = null;
    fanPercent = null;
    fanOn = false;
    history.clear();
    lastUpdate = null;
    status = 'Đã ngắt thiết bị — nhập Chip ID để kết nối lại';
    notifyListeners();
  }

  bool _isOurChipTopic(String topic) {
    final id = AppConfig.chipId;
    return topic == 'tele/$id/status' ||
        topic.startsWith('tele/${id}_') ||
        topic.startsWith('cmnd/${id}_');
  }

  void _markChipVerified() {
    chipVerified = true;
    linkedChipId = AppConfig.chipId;
  }

  void _onMessage(Map<String, dynamic> data) {
    final topic = data['topic'] as String? ?? '';
    final value = data['value'];

    if (!chipBound) return;

    if (!_isOurChipTopic(topic)) {
      if (kDebugMode) print('Bỏ qua topic chip khác: $topic');
      return;
    }

    final isLwtOffline = topic == AppConfig.topicOnline &&
        value.toString().toLowerCase() == 'offline';

    var changedSensors = false;

    if (_is(topic, AppConfig.topicOnline)) {
      online = value.toString().toLowerCase() == 'online';
      if (online) {
        _markChipVerified();
        status = hasTelemetry ? 'Máy đang vận hành ổn định' : 'Chip ${AppConfig.chipId} online';
      } else if (isLwtOffline) {
        online = false;
        status = 'Chip ${AppConfig.chipId} offline — chờ kết nối lại';
      }
    } else if (_is(topic, AppConfig.topicTemp)) {
      airTemp = _asDouble(value);
      changedSensors = true;
      _markChipVerified();
    } else if (_is(topic, AppConfig.topicHumi)) {
      humidity = _asDouble(value);
      changedSensors = true;
      _markChipVerified();
    } else if (_is(topic, AppConfig.topicDew)) {
      dewPoint = _asDouble(value);
      changedSensors = true;
      _markChipVerified();
    } else if (_is(topic, AppConfig.topicCold)) {
      coldPlate = _asDouble(value);
      changedSensors = true;
      _markChipVerified();
    } else if (_is(topic, AppConfig.topicSetpoint)) {
      setpoint = _asDouble(value);
      changedSensors = true;
      _markChipVerified();
    } else if (_is(topic, AppConfig.topicTec)) {
      tecPercent = _asDouble(value);
      _markChipVerified();
    } else if (_is(topic, AppConfig.topicFan)) {
      final pct = _asDouble(value);
      if (pct != null) {
        fanPercent = pct.clamp(0, 100);
        fanOn = fanPercent! > 0;
      } else {
        fanOn = _asOn(value);
        fanPercent = fanOn ? 100 : 0;
      }
      _markChipVerified();
    } else if (_is(topic, AppConfig.topicPower)) {
      powerOn = _asOn(value);
      _markChipVerified();
    } else if (_is(topic, AppConfig.topicStatus)) {
      status = value?.toString() ?? status;
      _markChipVerified();
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

    if (history.isEmpty) {
      history.add(_snapshot(now.subtract(const Duration(seconds: 1))));
      history.add(_snapshot(now));
      return;
    }

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
