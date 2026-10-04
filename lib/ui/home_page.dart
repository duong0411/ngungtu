import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../core/condenser_provider.dart';
import 'theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CondenserProvider>();
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF041018),
              NgungTuTheme.deep,
              Color(0xFF0B3040),
              Color(0xFF12343C),
            ],
            stops: [0, 0.35, 0.72, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -size.width * 0.25,
              right: -size.width * 0.2,
              child: _MistOrb(size: size.width * 0.7, color: NgungTuTheme.aqua.withValues(alpha: 0.14))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(0.92, 0.92), end: const Offset(1.06, 1.06), duration: 5.seconds),
            ),
            Positioned(
              bottom: size.height * 0.12,
              left: -40,
              child: _MistOrb(size: size.width * 0.55, color: NgungTuTheme.ice.withValues(alpha: 0.08))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: -18, duration: 4.seconds),
            ),
            SafeArea(
              child: RefreshIndicator(
                color: NgungTuTheme.aqua,
                onRefresh: c.reconnect,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 32),
                  children: [
                    _Header(c: c),
                    SizedBox(height: size.height * 0.04),
                    Text(
                      'NGƯNG TỤ',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: size.width > 400 ? 54 : 44,
                            height: 0.95,
                            color: NgungTuTheme.soft,
                          ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.12, duration: 500.ms),
                    const SizedBox(height: 10),
                    Text(
                      'STEM · máy ngưng tụ hơi nước ESP32',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: NgungTuTheme.ice.withValues(alpha: 0.85),
                            letterSpacing: 0.3,
                          ),
                    ).animate().fadeIn(delay: 120.ms, duration: 450.ms),
                    const SizedBox(height: 8),
                    Text(
                      c.status,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NgungTuTheme.soft.withValues(alpha: 0.7),
                          ),
                    ),
                    SizedBox(height: size.height * 0.04),
                    _PowerButton(c: c)
                        .animate()
                        .fadeIn(delay: 180.ms)
                        .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1)),
                    const SizedBox(height: 28),
                    Text(
                      'Thông số realtime',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    _MetricGrid(c: c),
                    const SizedBox(height: 20),
                    _StatusStrip(c: c),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.c});
  final CondenserProvider c;

  @override
  Widget build(BuildContext context) {
    final mqttOk = c.mqttConnected;
    final deviceOk = c.online;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: NgungTuTheme.aqua.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(999),
            color: NgungTuTheme.panel.withValues(alpha: 0.55),
          ),
          child: Row(
            children: [
              _Dot(color: mqttOk ? NgungTuTheme.aqua : NgungTuTheme.copper),
              const SizedBox(width: 8),
              Text(
                mqttOk ? 'MQTT OK' : 'MQTT OFF',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(999),
            color: NgungTuTheme.panel.withValues(alpha: 0.35),
          ),
          child: Row(
            children: [
              _Dot(color: deviceOk ? NgungTuTheme.ice : Colors.white38),
              const SizedBox(width: 8),
              Text(
                deviceOk ? 'ESP32 ONLINE' : 'ESP32...',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: c.connecting ? null : c.reconnect,
          icon: c.connecting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: NgungTuTheme.aqua),
                )
              : const Icon(Icons.refresh_rounded, color: NgungTuTheme.soft),
        ),
      ],
    );
  }
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({required this.c});
  final CondenserProvider c;

  @override
  Widget build(BuildContext context) {
    final on = c.powerOn;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: c.mqttConnected ? c.togglePower : null,
        child: Ink(
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: on
                  ? const [Color(0xFF1FA89A), NgungTuTheme.aqua]
                  : const [Color(0xFF2A3438), Color(0xFF1A2428)],
            ),
            boxShadow: [
              BoxShadow(
                color: (on ? NgungTuTheme.aqua : Colors.black).withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.power_settings_new_rounded,
                    color: on ? NgungTuTheme.deep : NgungTuTheme.soft,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        on ? 'Hệ thống đang BẬT' : 'Hệ thống đang TẮT',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: on ? NgungTuTheme.deep : NgungTuTheme.soft,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chạm để ${on ? 'tắt' : 'bật'} sò nóng lạnh',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: on
                                  ? NgungTuTheme.deep.withValues(alpha: 0.75)
                                  : NgungTuTheme.soft.withValues(alpha: 0.65),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.c});
  final CondenserProvider c;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Metric('Không khí', _fmt(c.airTemp, '°C'), Icons.thermostat_rounded, NgungTuTheme.copper),
      _Metric('Độ ẩm', _fmt(c.humidity, '%', digits: 0), Icons.water_drop_rounded, NgungTuTheme.aqua),
      _Metric('Điểm sương', _fmt(c.dewPoint, '°C'), Icons.water_rounded, NgungTuTheme.ice),
      _Metric('Mặt lạnh', _fmt(c.coldPlate, '°C'), Icons.ac_unit_rounded, const Color(0xFF7BDFF2)),
      _Metric('Mục tiêu', _fmt(c.setpoint, '°C'), Icons.flag_rounded, const Color(0xFFF4A261)),
      _Metric('Công suất sò', _fmt(c.tecPercent, '%', digits: 0), Icons.bolt_rounded, const Color(0xFFE9C46A)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, i) {
        final m = items[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NgungTuTheme.panel.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(m.icon, color: m.color, size: 22),
              const Spacer(),
              Text(
                m.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: NgungTuTheme.soft.withValues(alpha: 0.62),
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                m.value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: NgungTuTheme.soft,
                    ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: (80 * i).ms, duration: 400.ms)
            .slideY(begin: 0.08, delay: (80 * i).ms, duration: 400.ms);
      },
    );
  }

  String _fmt(double? v, String unit, {int digits = 1}) {
    if (v == null) return '--';
    return '${v.toStringAsFixed(digits)} $unit';
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.c});
  final CondenserProvider c;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NgungTuTheme.aqua.withValues(alpha: 0.28)),
        color: NgungTuTheme.mist.withValues(alpha: 0.28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trạng thái vận hành', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
          const SizedBox(height: 10),
          _kv(context, 'Quạt tản nhiệt', c.fanOn ? 'ĐANG CHẠY' : 'TẮT'),
          _kv(context, 'Chip ID', '789'),
          _kv(context, 'MQTT', c.mqttConnected ? 'Đã kết nối' : 'Mất kết nối'),
          _kv(context, 'Gói nhận', '${c.rxCount}'),
          _kv(
            context,
            'Cập nhật',
            c.lastUpdate == null
                ? '—'
                : '${c.lastUpdate!.hour.toString().padLeft(2, '0')}:${c.lastUpdate!.minute.toString().padLeft(2, '0')}:${c.lastUpdate!.second.toString().padLeft(2, '0')}',
          ),
          if (c.lastTopic != null) _kv(context, 'Topic cuối', c.lastTopic!),
          if (c.mqttConnected && !c.hasTelemetry) ...[
            const SizedBox(height: 8),
            Text(
              'App đã subscribe đúng ID 789. Nếu vẫn --: mở Serial ESP32, cần thấy MQTT=1 và dòng Air/Dew/Cold.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NgungTuTheme.copper,
                    fontSize: 12,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NgungTuTheme.soft.withValues(alpha: 0.65),
                  ),
            ),
          ),
          Text(v, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MistOrb extends StatelessWidget {
  const _MistOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
