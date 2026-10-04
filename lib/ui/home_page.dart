import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../core/auth_provider.dart';
import '../core/condenser_provider.dart';
import 'charts.dart';
import 'principle_page.dart';
import 'theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _friendlyStatus(CondenserProvider c) {
    if (!c.mqttConnected) return 'Đang kết nối máy thu nước...';
    if (!c.hasTelemetry) return 'Đã sẵn sàng — chờ dữ liệu cảm biến';
    final s = c.status.toLowerCase();
    if (s.contains('ngung tu') || s.contains('đang ngưng')) return 'Đang thu nước từ không khí';
    if (s.contains('kho') || s.contains('khô')) return 'Không khí đang khô — tạm nghỉ để tiết kiệm điện';
    if (s.contains('dong bang') || s.contains('đóng băng')) return 'Đang bảo vệ bề mặt lạnh';
    if (s.contains('loi') || s.contains('lỗi') || s.contains('khoa')) return 'Cần kiểm tra thiết bị';
    if (c.powerOn) return 'Máy đang vận hành ổn định';
    return 'Máy đang tạm nghỉ';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CondenserProvider>();
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.sizeOf(context);
    final live = c.mqttConnected && c.hasTelemetry;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF04181F), NgungTuTheme.deep, Color(0xFF0C2A33)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -size.width * 0.2,
              right: -size.width * 0.15,
              child: _orb(size.width * 0.65, NgungTuTheme.aqua.withValues(alpha: 0.13))
                  .animate(onPlay: (a) => a.repeat(reverse: true))
                  .scale(begin: const Offset(0.94, 0.94), end: const Offset(1.05, 1.05), duration: 6.seconds),
            ),
            SafeArea(
              child: RefreshIndicator(
                color: NgungTuTheme.aqua,
                onRefresh: c.reconnect,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 36),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xin chào${auth.user?.name.isNotEmpty == true ? ', ${auth.user!.name.split(' ').last}' : ''}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
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
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      live ? 'Đang hoạt động' : 'Đang kết nối',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontSize: 12,
                                            color: NgungTuTheme.soft.withValues(alpha: 0.75),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tìm hiểu nguyên lý',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PrinciplePage()),
                            );
                          },
                          icon: const Icon(Icons.auto_stories_rounded, color: NgungTuTheme.ice),
                        ),
                        IconButton(
                          tooltip: 'Đăng xuất',
                          onPressed: () => context.read<AuthProvider>().logout(),
                          icon: Icon(Icons.logout_rounded, color: NgungTuTheme.soft.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.03),
                    Text(
                      'NGƯNG TỤ',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: size.width > 400 ? 50 : 42,
                            height: 0.95,
                            letterSpacing: -1.2,
                          ),
                    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08),
                    const SizedBox(height: 10),
                    Text(
                      'Thu nước sạch từ hơi ẩm trong không khí',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: NgungTuTheme.ice.withValues(alpha: 0.88),
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _friendlyStatus(c),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NgungTuTheme.soft.withValues(alpha: 0.72),
                          ),
                    ),
                    const SizedBox(height: 20),
                    _HeroInsight(c: c),
                    const SizedBox(height: 22),
                    Text('Không khí hôm nay', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _MetricRow(
                      left: _Metric('Nhiệt độ', _fmt(c.airTemp, '°C'), Icons.thermostat_rounded, NgungTuTheme.copper),
                      right: _Metric('Độ ẩm', _fmt(c.humidity, '%', d: 0), Icons.water_drop_rounded, NgungTuTheme.aqua),
                    ),
                    const SizedBox(height: 12),
                    _MetricRow(
                      left: _Metric('Điểm sương', _fmt(c.dewPoint, '°C'), Icons.water_rounded, NgungTuTheme.ice),
                      right: _Metric('Bề mặt lạnh', _fmt(c.coldPlate, '°C'), Icons.ac_unit_rounded, const Color(0xFF7BDFF2)),
                    ),
                    const SizedBox(height: 22),
                    _LearnCard(),
                    const SizedBox(height: 26),
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

  String _fmt(double? v, String unit, {int d = 1}) {
    if (v == null) return '--';
    return '${v.toStringAsFixed(d)} $unit';
  }

  Widget _orb(double size, Color color) {
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

class _HeroInsight extends StatelessWidget {
  const _HeroInsight({required this.c});
  final CondenserProvider c;

  @override
  Widget build(BuildContext context) {
    final cooling = (c.coldPlate != null && c.dewPoint != null && c.coldPlate! < c.dewPoint!);
    final title = cooling ? 'Điều kiện thuận lợi' : 'Đang điều chỉnh';
    final body = cooling
        ? 'Bề mặt lạnh đã thấp hơn điểm sương — hơi nước có thể ngưng thành giọt.'
        : 'Máy đang đưa bề mặt lạnh xuống gần điểm sương để bắt đầu thu nước.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            NgungTuTheme.aqua.withValues(alpha: 0.18),
            NgungTuTheme.mist.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: NgungTuTheme.aqua.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: NgungTuTheme.deep.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              cooling ? Icons.water_drop_rounded : Icons.timelapse_rounded,
              color: NgungTuTheme.ice,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: NgungTuTheme.soft.withValues(alpha: 0.78),
                        height: 1.35,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 120.ms);
  }
}

class _LearnCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PrinciplePage()),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFE9C46A)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vì sao tạo ra được nước?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(
                      'Xem nguyên lý làm lạnh và điểm sương — giải thích dễ hiểu.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NgungTuTheme.soft.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: NgungTuTheme.soft.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.left, required this.right});
  final _Metric left;
  final _Metric right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NgungTuTheme.panel.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: NgungTuTheme.soft.withValues(alpha: 0.58),
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
