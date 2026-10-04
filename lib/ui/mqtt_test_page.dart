import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/condenser_provider.dart';
import 'theme.dart';

class MqttTestPage extends StatefulWidget {
  const MqttTestPage({super.key});

  @override
  State<MqttTestPage> createState() => _MqttTestPageState();
}

class _MqttTestPageState extends State<MqttTestPage> {
  bool _running = false;
  String _result = 'Chạm nút để test nhận MQTT từ ESP32 (chip 789).';
  Map<String, String> _samples = {};

  Future<void> _runTest() async {
    final c = context.read<CondenserProvider>();
    setState(() {
      _running = true;
      _result = 'Đang kết nối broker + chờ gói ESP32 (~12s)...';
      _samples = {};
    });

    final r = await c.testMqttReceive();
    if (!mounted) return;
    setState(() {
      _running = false;
      _result = (r['ok'] == true ? '✅ ' : '❌ ') + (r['reason']?.toString() ?? '');
      final samples = r['samples'];
      if (samples is Map) {
        _samples = samples.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CondenserProvider>();

    return Scaffold(
      backgroundColor: NgungTuTheme.deep,
      appBar: AppBar(
        backgroundColor: NgungTuTheme.panel,
        title: const Text('MQTT Test Mobile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trạng thái hiện tại', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                _row('Broker', c.mqttConnected ? 'CONNECTED' : 'DISCONNECTED'),
                _row('Client', c.mqttClientId.isEmpty ? '—' : c.mqttClientId),
                _row('Gói nhận (all)', '${c.rxCount}'),
                _row('Gói chip 789', '${c.rx789Count}'),
                _row('KK / RH',
                    '${c.airTemp?.toStringAsFixed(1) ?? "--"}°C / ${c.humidity?.toStringAsFixed(0) ?? "--"}%'),
                if (c.lastError.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Lỗi: ${c.lastError}',
                      style: const TextStyle(color: NgungTuTheme.copper, fontSize: 12)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _running ? null : _runTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: NgungTuTheme.aqua,
                foregroundColor: NgungTuTheme.deep,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: _running
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: NgungTuTheme.deep),
                    )
                  : const Icon(Icons.science_rounded),
              label: Text(_running ? 'Đang test...' : 'Test nhận MQTT từ ESP32'),
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kết quả test', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(_result, style: Theme.of(context).textTheme.bodyMedium),
                if (_samples.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._samples.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${e.key}\n→ ${e.value}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: NgungTuTheme.ice,
                            ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Log realtime', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (c.debugLog.isEmpty)
                  const Text('Chưa có log', style: TextStyle(color: Colors.white54))
                else
                  ...c.debugLog.take(20).map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            line,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NgungTuTheme.panel.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(k, style: const TextStyle(color: Colors.white60))),
          Flexible(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
