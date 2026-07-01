import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class MetricSparkline extends StatelessWidget {
  final List<double> points;
  final Color lineColor;
  final String timeStart;
  final String timeEnd;

  const MetricSparkline({
    super.key,
    required this.points,
    required this.lineColor,
    required this.timeStart,
    required this.timeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
