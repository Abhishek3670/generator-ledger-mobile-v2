import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SparklineChart extends StatelessWidget {
  final List<double> data;
  final Color lineColor;
  final Color? fillColor;
  final double height;
  final double strokeWidth;

  const SparklineChart({
    super.key,
    required this.data,
    this.lineColor = AppColors.primary,
    this.fillColor,
    this.height = 50.0,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height);

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          data: data,
          lineColor: lineColor,
          fillColor: fillColor ?? lineColor.withValues(alpha: 0.1),
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;
  final double strokeWidth;

  _SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double minVal = data.reduce((a, b) => a < b ? a : b);
    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double valRange = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    final double widthStep = size.width / (data.length - 1);
    
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final double x = i * widthStep;
      // invert Y coordinate for UI drawing
      final double normalizedY = (data[i] - minVal) / valRange;
      final double y = size.height - (normalizedY * (size.height - 4)) - 2; // leave padding for lines

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == data.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    // Paint the fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Paint the line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
