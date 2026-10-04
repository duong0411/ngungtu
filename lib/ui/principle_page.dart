import 'package:flutter/material.dart';

import 'theme.dart';

class PrinciplePage extends StatelessWidget {
  const PrinciplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF062029), NgungTuTheme.deep],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: NgungTuTheme.soft),
                    ),
                    Text('Nguyên lý thu nước', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  children: [
                    Text(
                      'Từ hơi ẩm thành giọt nước',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28, height: 1.15),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Không khí quanh ta luôn chứa hơi nước. Khi làm lạnh một bề mặt xuống đủ thấp, '
                      'hơi nước sẽ ngưng tụ thành giọt — giống kính xe bị mờ vào buổi sáng.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: NgungTuTheme.soft.withValues(alpha: 0.82),
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 24),
                    _step(
                      context,
                      '01',
                      'Không khí ẩm đi vào',
                      'Quạt đưa không khí có độ ẩm cao đi qua vùng làm lạnh.',
                      NgungTuTheme.aqua,
                    ),
                    _step(
                      context,
                      '02',
                      'Bề mặt lạnh dưới điểm sương',
                      'Điểm sương là nhiệt độ mà hơi nước bắt đầu hóa lỏng. '
                      'Máy giữ bề mặt lạnh thấp hơn mức đó một chút để tạo giọt nước.',
                      NgungTuTheme.ice,
                    ),
                    _step(
                      context,
                      '03',
                      'Tản nhiệt mặt nóng',
                      'Khi một mặt lạnh đi thì mặt kia nóng lên. Quạt tản nhiệt giúp máy '
                      'duy trì khả năng làm lạnh ổn định và tiết kiệm điện.',
                      NgungTuTheme.copper,
                    ),
                    _step(
                      context,
                      '04',
                      'Thu nước vào bình',
                      'Giọt nước chảy xuống máng rồi vào bình chứa — sẵn sàng dùng cho nhu cầu phù hợp.',
                      const Color(0xFF7BDFF2),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: NgungTuTheme.aqua.withValues(alpha: 0.12),
                        border: Border.all(color: NgungTuTheme.aqua.withValues(alpha: 0.28)),
                      ),
                      child: Text(
                        'Tóm lại: làm lạnh thông minh theo điểm sương → hơi nước thành nước lỏng → thu vào bình.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: NgungTuTheme.ice,
                              fontWeight: FontWeight.w700,
                              height: 1.45,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(BuildContext context, String n, String title, String body, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(n, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: NgungTuTheme.soft.withValues(alpha: 0.75),
                          height: 1.45,
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
