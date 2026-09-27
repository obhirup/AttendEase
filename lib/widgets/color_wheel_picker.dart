import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Interactive Color Picker Wheel with HSV Hue/Saturation disc and Brightness slider.
class ColorWheelPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const ColorWheelPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  /// Static helper to open the color picker as an alert dialog
  static Future<Color?> show(BuildContext context, {required Color initialColor}) {
    Color selectedColor = initialColor;
    return showDialog<Color>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primary = Theme.of(context).colorScheme.primary;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              title: Row(
                children: [
                  Icon(Icons.palette_outlined, size: 20, color: primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Color Accent Wheel',
                    style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 300,
                  child: ColorWheelPicker(
                    initialColor: selectedColor,
                    onColorChanged: (newColor) {
                      setDialogState(() {
                        selectedColor = newColor;
                      });
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedColor,
                    foregroundColor: ThemeData.estimateBrightnessForColor(selectedColor) == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(selectedColor),
                  child: const Text('Select Color', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  State<ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<ColorWheelPicker> {
  late double _hue; // 0.0 - 360.0
  late double _saturation; // 0.0 - 1.0
  late double _value; // 0.0 - 1.0

  static const List<Color> _quickSwatches = [
    Color(0xFF818CF8), // Iris Pastel Purple
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFFA5B4FC), // Periwinkle / Iris
    Color(0xFFF9A8D4), // Baby Pink
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF43F5E), // Rose
  ];

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation.clamp(0.01, 1.0);
    _value = hsv.value.clamp(0.1, 1.0);
  }

  Color get _currentColor {
    return HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
  }

  String get _hexString {
    final c = _currentColor;
    return '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  void _handleWheelTouch(Offset localPosition, double size) {
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    final distance = math.sqrt(dx * dx + dy * dy);
    final sat = (distance / radius).clamp(0.0, 1.0);

    double angle = math.atan2(dy, dx) * 180 / math.pi;
    if (angle < 0) angle += 360;

    setState(() {
      _hue = angle.clamp(0.0, 360.0);
      _saturation = sat;
    });
    widget.onColorChanged(_currentColor);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const double wheelSize = 220.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Interactive HSV Color Wheel
        Center(
          child: GestureDetector(
            onPanDown: (details) => _handleWheelTouch(details.localPosition, wheelSize),
            onPanUpdate: (details) => _handleWheelTouch(details.localPosition, wheelSize),
            child: SizedBox(
              width: wheelSize,
              height: wheelSize,
              child: CustomPaint(
                painter: _ColorWheelPainter(
                  hue: _hue,
                  saturation: _saturation,
                  value: _value,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Brightness / Value Slider
        Row(
          children: [
            const Icon(Icons.brightness_6_outlined, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: _value,
                  min: 0.2,
                  max: 1.0,
                  divisions: 40,
                  onChanged: (v) {
                    setState(() => _value = v);
                    widget.onColorChanged(_currentColor);
                  },
                ),
              ),
            ),
            Text(
              '${(_value * 100).round()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Current Color Preview & Hex Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _currentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _currentColor.withOpacity(0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _hexString,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                'Selected Tone',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Quick Swatches Row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickSwatches.map((color) {
            final isSel = (_currentColor.value & 0x00FFFFFF) == (color.value & 0x00FFFFFF);
            return GestureDetector(
              onTap: () {
                final hsv = HSVColor.fromColor(color);
                setState(() {
                  _hue = hsv.hue;
                  _saturation = hsv.saturation;
                  _value = hsv.value;
                });
                widget.onColorChanged(color);
              },
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSel ? (isDark ? Colors.white : Colors.black87) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: isSel ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final double hue;
  final double saturation;
  final double value;

  _ColorWheelPainter({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Hue sweep gradient around circle
    const sweepGradient = SweepGradient(
      colors: [
        Color(0xFFFF0000), // 0 Red
        Color(0xFFFFFF00), // 60 Yellow
        Color(0xFF00FF00), // 120 Green
        Color(0xFF00FFFF), // 180 Cyan
        Color(0xFF0000FF), // 240 Blue
        Color(0xFFFF00FF), // 300 Magenta
        Color(0xFFFF0000), // 360 Red
      ],
    );

    final wheelPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, wheelPaint);

    // 2. Saturation radial gradient (white in center fading to transparent edge)
    final satGradient = RadialGradient(
      colors: [
        Colors.white.withOpacity(value.clamp(0.0, 1.0)),
        Colors.transparent,
      ],
    );
    final satPaint = Paint()
      ..shader = satGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, satPaint);

    // 3. Dark overlay if brightness < 1.0
    if (value < 1.0) {
      final valPaint = Paint()
        ..color = Colors.black.withOpacity(1.0 - value)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, valPaint);
    }

    // Outer subtle border
    final borderPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    // 4. Draw selector indicator thumb
    final angleRad = hue * math.pi / 180;
    final thumbDistance = saturation * radius;
    final thumbX = center.dx + thumbDistance * math.cos(angleRad);
    final thumbY = center.dy + thumbDistance * math.sin(angleRad);
    final thumbCenter = Offset(thumbX, thumbY);

    // Shadow
    canvas.drawCircle(
      thumbCenter,
      9,
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // White ring
    canvas.drawCircle(
      thumbCenter,
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Selected color dot
    final selectedColor = HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
    canvas.drawCircle(
      thumbCenter,
      5,
      Paint()
        ..color = selectedColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) {
    return oldDelegate.hue != hue ||
        oldDelegate.saturation != saturation ||
        oldDelegate.value != value;
  }
}
