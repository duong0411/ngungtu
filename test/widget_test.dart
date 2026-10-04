import 'package:flutter_test/flutter_test.dart';
import 'package:ngungtu_app/core/condenser_provider.dart';
import 'package:ngungtu_app/core/config.dart';

void main() {
  test('MQTT topics match ESP32 chip 789 by default', () {
    AppConfig.setChipId('789');
    expect(AppConfig.chipId, '789');
    expect(AppConfig.apiBaseUrl, 'https://duynguyen.io.vn/api');
    expect(AppConfig.topicDew, 'tele/789_dew_point/status');
    expect(AppConfig.topicCold, 'tele/789_cold_plate/status');
    expect(AppConfig.cmndPower, 'cmnd/789_power/POWER');
  });

  test('AppConfig topics follow selected chipId', () {
    AppConfig.setChipId('789');
    expect(AppConfig.topicTemp, 'tele/789_temp_livingroom/status');
    AppConfig.setChipId('123');
    expect(AppConfig.topicTemp, 'tele/123_temp_livingroom/status');
    expect(AppConfig.topicOnline, 'tele/123/status');
    AppConfig.setChipId(AppConfig.defaultChipId);
  });

  test('CondenserProvider initial state blocks dashboard', () {
    final c = CondenserProvider();
    expect(c.powerOn, isTrue);
    expect(c.online, isFalse);
    expect(c.airTemp, isNull);
    expect(c.canEnterSystem, isFalse);
    expect(c.chipBound, isFalse);
    c.dispose();
  });
}
