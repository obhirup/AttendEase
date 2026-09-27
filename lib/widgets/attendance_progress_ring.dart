import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AttendanceProgressRing extends StatelessWidget {
  final double percentage; // 0 to 100
  final double minimumRequired; // e.g. 75.0
  final double size;
  final double strokeWidth;
  final String? subtitle;

  const AttendanceProgressRing({
    super.key,
    required this.percentage,
    required this.minimumRequired,
    this.size = 130,
    this.strokeWidth = 10,
    this.subtitle,
  });

  bool get isBelowPar => percentage < minimumRequired;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryThemeColor = Theme.of(context).colorScheme.primary;

    // Highlight in bold red if below par
    final activeColor = isBelowPar ? AppColors.alertRed : primaryThemeColor;
    final trackColor = isDark
        ? (isBelowPar ? AppColors.alertRedBgDark : AppColors.darkBorder)
        : (isBelowPar ? AppColors.alertRedBg : AppColors.lightSurfaceSubtle);

    final clampedPct = percentage.clamp(0.0, 100.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular Progress Track & Fill
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: clampedPct / 100.0,
              trackColor: trackColor,
              progressColor: activeColor,
              strokeWidth: strokeWidth,
            ),
          ),
          // Center Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${clampedPct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w800,
                  color: isBelowPar ? AppColors.alertRed : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: size * 0.09,
                    fontWeight: FontWeight.w600,
                    color: isBelowPar ? AppColors.alertRed : (isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Background circle
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc starting from top (-pi / 2)
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
