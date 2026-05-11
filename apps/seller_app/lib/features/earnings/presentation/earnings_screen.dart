import 'package:flutter/material.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0F172A);
    const accent = Color(0xFF10B981);
    const background = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Earnings',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: primary,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main Earnings Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primary, Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '₹12,450.00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _StatMini(label: 'Today', value: '₹1,250'),
                      const SizedBox(width: 24),
                      _StatMini(label: 'Orders', value: '18'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── Chart Placeholder Section ──
            const Text(
              'Weekly Overview',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CustomPaint(
                  painter: _ChartPainter(accent),
                  child: Container(),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── Recent Activity ──
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            _ActivityTile(
              title: 'Order #88A2',
              subtitle: 'Today, 2:30 PM',
              amount: '₹350.00',
              isPositive: true,
            ),
            _ActivityTile(
              title: 'Order #889F',
              subtitle: 'Today, 1:15 PM',
              amount: '₹420.00',
              isPositive: true,
            ),
            _ActivityTile(
              title: 'Payout to Bank',
              subtitle: 'Yesterday, 11:00 AM',
              amount: '- ₹5,000.00',
              isPositive: false,
            ),
            _ActivityTile(
              title: 'Order #8872',
              subtitle: 'Yesterday, 9:30 PM',
              amount: '₹280.00',
              isPositive: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  const _StatMini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final bool isPositive;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPositive ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.add_rounded : Icons.account_balance_rounded,
              color: isPositive ? const Color(0xFF10B981) : const Color(0xFF64748B),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: isPositive ? const Color(0xFF10B981) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final Color accent;
  _ChartPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.5, size.width * 0.4, size.height * 0.65);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.8, size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    final linePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    linePath.moveTo(0, size.height * 0.7);
    linePath.quadraticBezierTo(size.width * 0.2, size.height * 0.5, size.width * 0.4, size.height * 0.65);
    linePath.quadraticBezierTo(size.width * 0.6, size.height * 0.8, size.width * 0.8, size.height * 0.4);
    linePath.lineTo(size.width, size.height * 0.3);

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
