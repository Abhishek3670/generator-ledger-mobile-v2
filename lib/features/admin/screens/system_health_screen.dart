import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/side_navigation_drawer.dart';

class SystemHealthScreen extends StatelessWidget {
  const SystemHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'SYSTEM HEALTH',
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Metrics refreshed')),
              );
            },
          ),
        ],
      ),
      drawer: SideNavigationDrawer(
        currentRoute: '/admin/health',
        onNavigate: (routePath) {
          context.go(routePath);
        },
        userName: 'Abhishek Sharma',
        userRole: 'Fleet Manager',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'MONITOR',
                style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Live Server Metrics',
                style: AppTypography.displayLarge.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                'Live CPU, memory, and temperature with real-time charts.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Status Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'APPLICATION STATUS',
                              style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 10),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Healthy',
                                    style: AppTypography.labelCaps.copyWith(color: AppColors.success, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'LAST CHECKED',
                              style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 10),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '4/20/2026, 12:32:08 PM',
                              style: AppTypography.bodySmall.copyWith(fontFamily: 'Courier', fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: AppColors.surfaceContainer, height: 1),
                    ),
                    Text(
                      'DATABASE CONNECTION',
                      style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 10),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'postgresql://genset_user:***@postgres-db:5432/ledger_db',
                        style: AppTypography.bodySmall.copyWith(fontFamily: 'Courier', color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // CPU Usage Card
              _buildMetricCard(
                title: 'CPU USAGE',
                value: '0.2%',
                description: 'System-wide CPU utilization.',
                statusText: 'NORMAL',
                lineColor: AppColors.primary,
                points: [38, 38, 38, 38, 35, 38, 38],
                timeStart: '12:32:09',
                timeEnd: '12:32:27',
              ),
              const SizedBox(height: 16),

              // Memory Usage Card
              _buildMetricCard(
                title: 'MEMORY USAGE',
                value: '12.7%',
                description: 'Used 923.9 MB / Total 7,281.5 MB',
                statusText: 'NORMAL',
                lineColor: Colors.blue,
                points: [35, 35, 35, 35, 35, 35, 35],
                timeStart: '12:32:09',
                timeEnd: '12:32:27',
              ),
              const SizedBox(height: 16),

              // Temperature Card
              _buildMetricCard(
                title: 'TEMPERATURE',
                value: '39.9°C',
                description: 'Sensor: k10temp',
                statusText: 'NORMAL',
                lineColor: AppColors.danger,
                points: [30, 30, 29, 29, 30, 20, 22, 25],
                timeStart: '12:32:09',
                timeEnd: '12:32:27',
              ),
              const SizedBox(height: 16),

              // Build Info Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BUILD INFO',
                      style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 10),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Title:',
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Generator Booking Ledger',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Version:',
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '4.0.2',
                          style: AppTypography.bodySmall,
                        ),
                      ],
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String description,
    required String statusText,
    required Color lineColor,
    required List<double> points,
    required String timeStart,
    required String timeEnd,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(9999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.displayLarge.copyWith(fontSize: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: AppTypography.bodySmall.copyWith(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          // Sparkline view
          SizedBox(
            height: 40,
            child: CustomPaint(
              painter: _SparklinePainter(points: points, lineColor: lineColor),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(timeStart, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary)),
              Text(timeEnd, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;

  _SparklinePainter({required this.points, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintGrid = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw reference grids
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paintGrid);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paintGrid);

    final path = Path();
    final xStep = size.width / (points.length - 1);
    
    // Scale points to fit the height (assuming points range 0..40 where 40 is bottom/0 offset)
    const maxVal = 40.0;
    
    for (int i = 0; i < points.length; i++) {
      final x = i * xStep;
      // Invert Y coordinate because Flutter canvas 0,0 is top-left
      final y = (points[i] / maxVal) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
