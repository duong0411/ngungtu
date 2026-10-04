import 'package:flutter_test/flutter_test.dart';
import 'package:ngungtu_app/core/condenser_provider.dart';
import 'package:ngungtu_app/core/config.dart';

void main() {
  test('MQTT topics match ESP32 chip 789', () {
    expect(AppConfig.chipId, '789');
    expect(AppConfig.apiBaseUrl, 'https://duynguyen.io.vn/api');
    expect(AppConfig.topicDew, 'tele/789_dew_point/status');
    expect(AppConfig.topicCold, 'tele/789_cold_plate/status');
    expect(AppConfig.cmndPower, 'cmnd/789_power/POWER');
  });

  test('CondenserProvider initial state', () {
    final c = CondenserProvider();
    expect(c.powerOn, isTrue);
    expect(c.online, isFalse);
    expect(c.airTemp, isNull);
    c.dispose();
  });
}
