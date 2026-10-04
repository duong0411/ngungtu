import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../core/auth_provider.dart';
import '../core/condenser_provider.dart';
import '../core/config.dart';
import 'charts.dart';
import 'principle_page.dart';
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
            SafeArea(
              child: RefreshIndicator(
                color: NgungTuTheme.aqua,
                onRefresh: c.reconnect,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 32),
                  children: [
                    _Header(c: c),
                    SizedBox(height: size.height * 0.028),
                    Text(
                      'NGƯNG TỤ',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: size.width > 400 ? 52 : 42,
                            height: 0.95,
                          ),
                    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.1),
                    const SizedBox(height: 8),
                    Text(
                      'STEM · chip ${AppConfig.chipId}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: NgungTuTheme.ice.withValues(alpha: 0.85),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.status,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NgungTuTheme.soft.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 14),
                    _PrincipleTeaser(),
                    const SizedBox(height: 22),
                    Text('Thông số realtime', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _MetricGrid(c: c),
                    const SizedBox(height: 24),
                    TelemetryCharts(c: c),
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
    final auth = context.watch<AuthProvider>();
    final live = c.mqttConnected && c.hasTelemetry;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                auth.user?.name.isNotEmpty == true ? auth.user!.name : 'Người dùng',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: live ? NgungTuTheme.aqua : NgungTuTheme.copper,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    live ? 'Đang nhận dữ liệu' : (c.mqttConnected ? 'Chờ ESP32' : 'Mất kết nối'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Nguyên lý sò',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrinciplePage()),
            );
          },
          icon: const Icon(Icons.menu_book_rounded, color: NgungTuTheme.ice),
        ),
        IconButton(
          tooltip: 'Đăng xuất',
          onPressed: () => context.read<AuthProvider>().logout(),
          icon: const Icon(Icons.logout_rounded, color: NgungTuTheme.soft),
        ),
      ],
    );
  }
}

class _PrincipleTeaser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PrinciplePage()),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: NgungTuTheme.aqua.withValues(alpha: 0.3)),
            color: NgungTuTheme.mist.withValues(alpha: 0.25),
          ),
          child: Row(
            children: [
              const Icon(Icons.ac_unit_rounded, color: NgungTuTheme.ice),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sò làm lạnh thế nào?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      'Điện → mặt lạnh dưới điểm sương → hơi nước thành giọt.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NgungTuTheme.soft.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: NgungTuTheme.soft),
            ],
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
      _M('Không khí', _fmt(c.airTemp, '°C'), Icons.thermostat_rounded, NgungTuTheme.copper),
      _M('Độ ẩm', _fmt(c.humidity, '%', digits: 0), Icons.water_drop_rounded, NgungTuTheme.aqua),
      _M('Điểm sương', _fmt(c.dewPoint, '°C'), Icons.water_rounded, NgungTuTheme.ice),
      _M('Mặt lạnh', _fmt(c.coldPlate, '°C'), Icons.ac_unit_rounded, const Color(0xFF7BDFF2)),
      _M('Mục tiêu', _fmt(c.setpoint, '°C'), Icons.flag_rounded, const Color(0xFFF4A261)),
      _M('Công suất sò', _fmt(c.tecPercent, '%', digits: 0), Icons.bolt_rounded, const Color(0xFFE9C46A)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, i) {
        final m = items[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: NgungTuTheme.panel.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(m.icon, color: m.color, size: 20),
              const Spacer(),
              Text(m.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: NgungTuTheme.soft.withValues(alpha: 0.6),
                        fontSize: 12,
                      )),
              Text(m.value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      )),
            ],
          ),
        );
      },
    );
  }

  String _fmt(double? v, String unit, {int digits = 1}) {
    if (v == null) return '--';
    return '${v.toStringAsFixed(digits)} $unit';
  }
}

class _M {
  const _M(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
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
