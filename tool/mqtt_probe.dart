import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

Future<void> tryConnect(String label, Future<bool> Function() fn) async {
  stdout.writeln('\n=== $label ===');
  try {
    final ok = await fn();
    stdout.writeln(ok ? 'OK' : 'FAIL');
  } catch (e) {
    stdout.writeln('FAIL: $e');
  }
}

Future<void> main() async {
  // Thử cấu hình giống SmartHome app (đã chạy thực tế)
  stdout.writeln('Probe MQTT broker for chip 789');

  final clientId = 'probe_${DateTime.now().millisecondsSinceEpoch}';
  final client = MqttServerClient.withPort(
    'wss://mqtt.duynguyen.io.vn/mqtt',
    clientId,
    443,
  );
  client.useWebSocket = true;
  client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
  client.logging(on: true);
  client.keepAlivePeriod = 20;
  client.connectTimeoutPeriod = 20000;
  client.autoReconnect = false;
  client.setProtocolV311();
  client.connectionMessage = MqttConnectMessage()
      .withClientIdentifier(clientId)
      .startClean()
      .withWillQos(MqttQos.atLeastOnce);

  stdout.writeln('Connecting wss://mqtt.duynguyen.io.vn/mqtt ...');
  try {
    await client.connect();
  } catch (e) {
    stderr.writeln('CONNECT FAIL: $e');
    stderr.writeln('PC/mạng hiện tại có thể chặn broker. Thử trên điện thoại app DEBUG panel.');
    exit(2);
  }

  if (client.connectionStatus?.state != MqttConnectionState.connected) {
    stderr.writeln('CONNECT FAIL: ${client.connectionStatus}');
    exit(2);
  }

  stdout.writeln('CONNECTED OK');
  for (final t in [
    'tele/+/status',
    'tele/789/status',
    'tele/789_temp_livingroom/status',
    'tele/789_humi_living_room/status',
    'tele/789_dew_point/status',
    'tele/789_cold_plate/status',
  ]) {
    client.subscribe(t, MqttQos.atLeastOnce);
  }

  final seen789 = <String>{};
  var anyMsg = 0;
  final sub = client.updates!.listen((events) {
    for (final e in events) {
      final rec = e.payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(rec.payload.message);
      final topic = e.topic;
      anyMsg++;
      stdout.writeln('RX [$topic] $payload');
      if (topic.contains('789')) {
        seen789.add(topic);
        try {
          final v = jsonDecode(payload);
          stdout.writeln('   => value=${v is Map ? v['value'] : v}');
        } catch (_) {}
      }
    }
  });

  stdout.writeln('Listening 25s...');
  await Future<void>.delayed(const Duration(seconds: 25));
  await sub.cancel();
  client.disconnect();

  stdout.writeln('--- total=$anyMsg chip789=${seen789.length}');
  exit(seen789.isEmpty ? 1 : 0);
}
