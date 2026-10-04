import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../core/auth_provider.dart';
import '../core/condenser_provider.dart';
import '../core/config.dart';
import 'theme.dart';
import 'widgets/feedback.dart';

/// Nhập Chip ID → kết nối MQTT → xác thực thiết bị trước khi xem cảm biến/biểu đồ.
class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  late final TextEditingController _chip;
  bool _bannerShown = false;
  String? _successStatus;

  @override
  void initState() {
    super.initState();
    _chip = TextEditingController(text: AppConfig.chipId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPendingBanner());
  }

  void _showPendingBanner() {
    if (!mounted || _bannerShown) return;
    final msg = context.read<AuthProvider>().consumeSuccessBanner();
    if (msg != null) {
      _bannerShown = true;
      setState(() => _successStatus = msg);
      showAppSnack(context, message: msg, success: true);
    }
  }

  @override
  void dispose() {
    _chip.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final id = _chip.text.trim();
    if (id.isEmpty) {
      showAppSnack(context, message: 'Vui lòng nhập Chip ID của máy ESP32');
      return;
    }

    final auth = context.read<AuthProvider>();
    final condenser = context.read<CondenserProvider>();

    await auth.bindChip(id);
    final ok = await condenser.connectWithChip(id);
    if (!mounted) return;

    if (!ok) {
      showAppSnack(context, message: 'Chưa kết nối MQTT — kiểm tra mạng rồi thử lại');
      return;
    }

    showAppSnack(
      context,
      message: 'Đã gửi yêu cầu — đang chờ chip $id phản hồi...',
      success: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CondenserProvider>();
    final auth = context.watch<AuthProvider>();
    final chip = _chip.text.trim().isEmpty ? AppConfig.chipId : _chip.text.trim();

    String step;
    if (c.connecting) {
      step = 'Đang kết nối MQTT...';
    } else if (!c.chipBound) {
      step = 'Nhập Chip ID rồi bấm Kết nối để xem cảm biến & biểu đồ';
    } else if (!c.mqttConnected) {
      step = 'Chưa kết nối MQTT — kéo xuống hoặc bấm Kết nối lại';
    } else if (!c.chipVerified || c.linkedChipId != AppConfig.chipId) {
      step = 'Đã MQTT — đang chờ chip $chip phản hồi...';
    } else if (!c.online && !c.hasTelemetry) {
      step = 'Chip $chip chưa online';
    } else {
      step = 'Đã xác thực chip $chip — vào bảng điều khiển...';
    }

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
              top: -70,
              right: -40,
              child: _orb(200, NgungTuTheme.aqua.withValues(alpha: 0.12))
                  .animate(onPlay: (a) => a.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1.06, 1.06),
                    duration: 5.seconds,
                  ),
            ),
            SafeArea(
              child: RefreshIndicator(
                color: NgungTuTheme.aqua,
                onRefresh: () async {
                  if (c.chipBound) await c.reconnect();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: NgungTuTheme.aqua.withValues(alpha: 0.12),
                            border: Border.all(color: NgungTuTheme.aqua.withValues(alpha: 0.28)),
                          ),
                          child: Text(
                            'KẾT NỐI THIẾT BỊ',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: NgungTuTheme.ice,
                                  fontSize: 11,
                                  letterSpacing: 1.1,
                                ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Đăng xuất',
                          onPressed: () async {
                            context.read<CondenserProvider>().disconnectChip();
                            await auth.clearBoundChip();
                            await auth.logout();
                          },
                          icon: Icon(
                            Icons.logout_rounded,
                            color: NgungTuTheme.soft.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'NGƯNG TỤ',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 44,
                            height: 0.95,
                            letterSpacing: -1.2,
                          ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),
                    const SizedBox(height: 10),
                    Text(
                      'Nhập Chip ID trên ESP32 để hiển thị thông số cảm biến và biểu đồ realtime.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: NgungTuTheme.ice.withValues(alpha: 0.9),
                            height: 1.45,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: 28),
                    if (_successStatus != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: NgungTuTheme.aqua.withValues(alpha: 0.14),
                          border: Border.all(color: NgungTuTheme.aqua.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: NgungTuTheme.aqua),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _successStatus!,
                                style: const TextStyle(
                                  color: NgungTuTheme.soft,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.08),
                    ],
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: NgungTuTheme.panel.withValues(alpha: 0.72),
                        border: Border.all(color: NgungTuTheme.aqua.withValues(alpha: 0.22)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chip ID',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: NgungTuTheme.soft.withValues(alpha: 0.65),
                                  fontSize: 13,
                                ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _chip,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z_\-]')),
                            ],
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontSize: 28,
                                  color: NgungTuTheme.aqua,
                                  letterSpacing: 1.5,
                                ),
                            decoration: InputDecoration(
                              hintText: AppConfig.defaultChipId,
                              hintStyle: TextStyle(
                                color: NgungTuTheme.aqua.withValues(alpha: 0.35),
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                              prefixIcon: const Icon(Icons.memory_rounded, color: NgungTuTheme.ice),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: NgungTuTheme.aqua, width: 1.5),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Firmware Ngưng Tụ mặc định dùng Chip ID ${AppConfig.defaultChipId}.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                          ),
                          const SizedBox(height: 18),
                          _statusRow('MQTT', c.mqttConnected ? 'Đã kết nối' : 'Chưa kết nối', c.mqttConnected),
                          const SizedBox(height: 10),
                          _statusRow(
                            'Chip ID',
                            c.chipVerified && c.linkedChipId == AppConfig.chipId
                                ? 'Khớp ${c.linkedChipId}'
                                : c.chipBound
                                    ? 'Đang chờ $chip'
                                    : 'Chưa gắn',
                            c.chipVerified && c.linkedChipId == AppConfig.chipId,
                          ),
                          const SizedBox(height: 10),
                          _statusRow(
                            'Cảm biến',
                            c.hasTelemetry
                                ? 'Có dữ liệu'
                                : c.online
                                    ? 'Online'
                                    : 'Chưa có',
                            c.hasTelemetry || c.online,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.05),
                    const SizedBox(height: 20),
                    Text(
                      step,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: NgungTuTheme.soft.withValues(alpha: 0.82),
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: c.connecting ? null : _connect,
                        style: FilledButton.styleFrom(
                          backgroundColor: NgungTuTheme.aqua,
                          foregroundColor: NgungTuTheme.deep,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: c.connecting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: NgungTuTheme.deep,
                                ),
                              )
                            : Text(
                                c.chipBound ? 'Kết nối lại' : 'Kết nối & xem dữ liệu',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                      ),
                    ),
                    if (auth.user?.email != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Tài khoản: ${auth.user!.email}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, String value, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 18,
          color: ok ? NgungTuTheme.aqua : NgungTuTheme.soft.withValues(alpha: 0.35),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: NgungTuTheme.soft.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: ok ? NgungTuTheme.soft : NgungTuTheme.copper,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
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
