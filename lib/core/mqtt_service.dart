import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'config.dart';

class MqttService {
  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _updatesSub;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String lastError = '';

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  Future<bool> connect({String brokerUrl = AppConfig.brokerUrl}) async {
    await disconnect();
    lastError = '';

    final uri = Uri.parse(brokerUrl);
    final scheme = uri.scheme.isNotEmpty ? uri.scheme : 'wss';
    final host = uri.host.isNotEmpty ? uri.host : 'mqtt.duynguyen.io.vn';
    final port = uri.port != 0 ? uri.port : 443;
    final path = uri.path.isNotEmpty ? uri.path : '/mqtt';
    final clientId = 'ngungtu_${DateTime.now().millisecondsSinceEpoch}';

    // QUAN TRỌNG: với WSS chỉ truyền URL wss://..., KHÔNG set secure=true
    // (secure chỉ dùng cho MQTT TCP/TLS — set nhầm sẽ fail DNS)
    final wsUrl = '$scheme://$host$path';
    if (kDebugMode) print('MQTT: connecting $wsUrl port=$port');

    _client = MqttServerClient.withPort(wsUrl, clientId, port);
    _client!.useWebSocket = true;
    _client!.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
    _client!.logging(on: kDebugMode);
    _client!.keepAlivePeriod = 30;
    _client!.connectTimeoutPeriod = 12000;
    _client!.autoReconnect = true;
    _client!.resubscribeOnAutoReconnect = true;

    _client!.onConnected = () {
      _isConnected = true;
      _subscribeAll();
      if (kDebugMode) print('MQTT: connected');
    };
    _client!.onDisconnected = () {
      _isConnected = false;
      if (kDebugMode) print('MQTT: disconnected');
    };
    _client!.onAutoReconnected = () {
      _isConnected = true;
      _subscribeAll();
      if (kDebugMode) print('MQTT: reconnected');
    };

    _client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillTopic('tele/ngungtu_app/status')
        .withWillMessage('offline')
        .withWillQos(MqttQos.atLeastOnce);

    try {
      await _client!.connect().timeout(const Duration(seconds: 15));
    } catch (e) {
      lastError = e.toString();
      if (kDebugMode) print('MQTT connect error: $e');
      _isConnected = false;
      try {
        _client?.disconnect();
      } catch (_) {}
      return false;
    }

    if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
      _isConnected = true;
      _listen();
      _subscribeAll();
      return true;
    }

    lastError = _client!.connectionStatus?.toString() ?? 'unknown';
    _isConnected = false;
    return false;
  }

  void _subscribeAll() {
    if (_client == null || !_isConnected) return;

    final topics = <String>{
      'tele/+/status',
      ...AppConfig.subscribeTopics,
    };

    for (final topic in topics) {
      try {
        _client!.subscribe(topic, MqttQos.atLeastOnce);
        if (kDebugMode) print('MQTT SUB: $topic');
      } catch (e) {
        if (kDebugMode) print('Subscribe error $topic: $e');
      }
    }
  }

  void _listen() {
    _updatesSub?.cancel();
    final updates = _client?.updates;
    if (updates == null) return;

    _updatesSub = updates.listen((events) {
      if (events.isEmpty) return;

      for (final event in events) {
        final rec = event.payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(rec.payload.message);
        final topic = event.topic;

        dynamic value;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map && decoded.containsKey('value')) {
            value = decoded['value'];
          } else {
            value = decoded;
          }
        } catch (_) {
          value = payload.trim();
        }

        if (kDebugMode) print('MQTT RX: [$topic] $payload');

        _messageController.add({
          'topic': topic,
          'value': value,
          'raw': payload,
        });
      }
    });
  }

  void publish(String topic, String message) {
    if (!_isConnected || _client == null) return;
    final builder = MqttClientPayloadBuilder()..addString(message);
    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    if (kDebugMode) print('MQTT TX [$topic] $message');
  }

  void setPower(bool on) {
    final cmd = on ? 'ON' : 'OFF';
    publish(AppConfig.cmndPower, cmd);
    publish(AppConfig.cmndFan, cmd);
  }

  Future<void> disconnect() async {
    _updatesSub?.cancel();
    _updatesSub = null;
    _isConnected = false;
    try {
      _client?.disconnect();
    } catch (_) {}
    _client = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
  }
}
