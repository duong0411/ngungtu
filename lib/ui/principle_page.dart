import 'package:flutter/material.dart';

import 'theme.dart';

/// Giải thích nguyên lý sò Peltier cho STEM (dễ hiểu)
class PrinciplePage extends StatelessWidget {
  const PrinciplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NgungTuTheme.deep,
      appBar: AppBar(
        backgroundColor: NgungTuTheme.panel,
        title: const Text('Nguyên lý sò làm lạnh'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Sò Peltier là gì?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 8),
          Text(
            'Là “bơm nhiệt” bằng điện bán dẫn: khi có dòng điện chạy qua, '
            'một mặt hút nhiệt (lạnh), mặt kia nhả nhiệt (nóng).',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: NgungTuTheme.soft.withValues(alpha: 0.85),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 20),
          _step(
            context,
            '1',
            'Không khí ẩm vào',
            'Quạt hút không khí có hơi nước (độ ẩm cao) đi qua buồng ngưng tụ.',
            NgungTuTheme.aqua,
          ),
          _step(
            context,
            '2',
            'Mặt lạnh dưới điểm sương',
            'ESP32 đo nhiệt độ + độ ẩm → tính điểm sương. Sò được điều khiển để mặt lạnh '
            'thấp hơn điểm sương vài độ → hơi nước ngưng thành giọt.',
            NgungTuTheme.ice,
          ),
          _step(
            context,
            '3',
            'Mặt nóng phải tản nhiệt',
            'Nhiệt hút từ mặt lạnh + nhiệt do sò sinh ra đều dồn sang mặt nóng. '
            'Quạt + tản nhiệt phải chạy — nếu nóng quá, sò không làm lạnh được.',
            NgungTuTheme.copper,
          ),
          _step(
            context,
            '4',
            'Thu nước',
            'Giọt nước chảy xuống máng → bình chứa. Có thể kết hợp cảm biến mực nước.',
            const Color(0xFF7BDFF2),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NgungTuTheme.panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: NgungTuTheme.aqua.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ví dụ số trên máy của bạn',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                const SizedBox(height: 8),
                Text(
                  'Không khí 32°C, RH 70% → điểm sương ≈ 26°C.\n'
                  'ESP đặt mục tiêu mặt lạnh ≈ 24°C (dưới điểm sương) → hơi nước ngưng.\n'
                  'Nếu không khí quá khô (RH thấp), máy tự tắt để tiết kiệm điện.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tóm tắt một câu: điện → sò tạo mặt lạnh dưới điểm sương → hơi nước thành nước lỏng.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: NgungTuTheme.ice,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }

  Widget _step(BuildContext context, String n, String title, String body, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NgungTuTheme.panel.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Text(n, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: NgungTuTheme.soft.withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
