import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'config.dart';

class MqttService {
  MqttServerClient? _client;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  Future<bool> connect({String brokerUrl = AppConfig.brokerUrl}) async {
    if (_isConnected && _client != null) return true;

    final uri = Uri.parse(brokerUrl);
    final scheme = uri.scheme.isNotEmpty ? uri.scheme : 'wss';
    final isSecure = scheme == 'wss' || scheme == 'https';
    final host = uri.host.isNotEmpty ? uri.host : 'mqtt.duynguyen.io.vn';
    final port = uri.port != 0 ? uri.port : (isSecure ? 443 : 8083);
    final path = uri.path.isNotEmpty ? uri.path : '/mqtt';
    final clientId = 'ngungtu_${DateTime.now().millisecondsSinceEpoch}';

    if (kDebugMode) {
      print('MQTT: connecting $scheme://$host:$port$path');
    }

    _client = MqttServerClient.withPort('$scheme://$host$path', clientId, port);
    _client!.useWebSocket = true;
    _client!.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 60;
    _client!.autoReconnect = true;
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
        .withWillRetain()
        .withWillQos(MqttQos.atLeastOnce);

    try {
      await _client!.connect().timeout(const Duration(seconds: 12));
    } catch (e) {
      if (kDebugMode) print('MQTT connect error: $e');
      _isConnected = false;
      return false;
    }

    if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
      _isConnected = true;
      _listen();
      _subscribeAll();
      return true;
    }

    _isConnected = false;
    return false;
  }

  void _subscribeAll() {
    if (_client == null || !_isConnected) return;
    for (final topic in AppConfig.subscribeTopics) {
      try {
        _client!.subscribe(topic, MqttQos.atLeastOnce);
      } catch (e) {
        if (kDebugMode) print('Subscribe error $topic: $e');
      }
    }
  }

  void _listen() {
    _client!.updates!.listen((events) {
      if (events.isEmpty) return;
      final rec = events.first.payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(rec.payload.message);
      final topic = events.first.topic;

      dynamic value;
      try {
        value = jsonDecode(payload)['value'];
      } catch (_) {
        value = payload.trim();
      }

      _messageController.add({
        'topic': topic,
        'value': value,
        'raw': payload,
      });
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

  void disconnect() {
    _client?.disconnect();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
