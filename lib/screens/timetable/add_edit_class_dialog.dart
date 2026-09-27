import 'package:flutter/material.dart';
import '../../models/class_session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/color_wheel_picker.dart';

class AddEditClassDialog extends StatefulWidget {
  final ClassSession? existingSession;
  final int initialDayOfWeek;
  final Function(ClassSession session) onSave;

  const AddEditClassDialog({
    super.key,
    this.existingSession,
    this.initialDayOfWeek = 1,
    required this.onSave,
  });

  @override
  State<AddEditClassDialog> createState() => _AddEditClassDialogState();
}

class _AddEditClassDialogState extends State<AddEditClassDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectController;
  late TextEditingController _roomController;
  late int _dayOfWeek;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late double _defaultPoints;
  late int _colorValue;

  final List<int> _colorOptions = const [
    0xFF818CF8, // Iris Pastel Purple
    0xFF38BDF8, // Sky Blue
    0xFFA5B4FC, // Periwinkle Iris
    0xFFF9A8D4, // Baby Pink
    0xFF10B981, // Emerald
    0xFFF59E0B, // Amber
    0xFF8B5CF6, // Violet
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.existingSession;
    _subjectController = TextEditingController(text: s?.subject ?? '');
    _roomController = TextEditingController(text: s?.room ?? '');
    _dayOfWeek = s?.dayOfWeek ?? widget.initialDayOfWeek;
    _startTime = s != null
        ? TimeOfDay(hour: s.startHour, minute: s.startMinute)
        : const TimeOfDay(hour: 9, minute: 0);
    _endTime = s != null
        ? TimeOfDay(hour: s.endHour, minute: s.endMinute)
        : const TimeOfDay(hour: 10, minute: 30);
    _defaultPoints = s?.defaultPoints ?? 1.0;
    _colorValue = s?.colorValue ?? _colorOptions.first;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    const days = [
      MapEntry(1, 'Monday'),
      MapEntry(2, 'Tuesday'),
      MapEntry(3, 'Wednesday'),
      MapEntry(4, 'Thursday'),
      MapEntry(5, 'Friday'),
      MapEntry(6, 'Saturday'),
      MapEntry(7, 'Sunday'),
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existingSession == null ? 'Add Class to Routine' : 'Edit Class',
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // Subject Name
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name *',
                  hintText: 'e.g. Data Structures & Algorithms',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Subject name is required';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Room / Location
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room / Hall (Optional)',
                  hintText: 'e.g. Hall 402, Lab 3',
                ),
              ),
              const SizedBox(height: 14),

              // Day of Week
              DropdownButtonFormField<int>(
                value: _dayOfWeek,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                decoration: InputDecoration(
                  labelText: 'Day of Week',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: days.map((d) {
                  return DropdownMenuItem(value: d.key, child: Text(d.value));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _dayOfWeek = val);
                },
              ),
              const SizedBox(height: 14),

              // Timing (Start & End)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _startTime);
                        if (picked != null) setState(() => _startTime = picked);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start Time', style: TextStyle(fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(_formatTime(_startTime), style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _endTime);
                        if (picked != null) setState(() => _endTime = picked);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('End Time', style: TextStyle(fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(_formatTime(_endTime), style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Default Points / Weight (1 to 5)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Default Attendance Points', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Text('${_defaultPoints.toInt()} pt${_defaultPoints > 1 ? "s" : ""}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: primary)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [1.0, 2.0, 3.0, 4.0, 5.0].map((pt) {
                  final isSel = _defaultPoints == pt;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ChoiceChip(
                        label: Center(child: Text('${pt.toInt()}')),
                        selected: isSel,
                        selectedColor: primary,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _defaultPoints = pt);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Color Tag & Color Picker Wheel
              // "Add a color picker wheel to the add class colour accent"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Color Accent', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    ),
                    icon: const Icon(Icons.colorize_rounded, size: 15),
                    label: const Text('Color Wheel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    onPressed: () async {
                      final picked = await ColorWheelPicker.show(context, initialColor: Color(_colorValue));
                      if (picked != null) {
                        setState(() => _colorValue = picked.value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ..._colorOptions.map((c) {
                    final isSel = _colorValue == c;
                    return GestureDetector(
                      onTap: () => setState(() => _colorValue = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: Color(c).withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: isSel ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                      ),
                    );
                  }),
                  // Custom picked color indicator if not in presets
                  if (!_colorOptions.contains(_colorValue))
                    GestureDetector(
                      onTap: () async {
                        final picked = await ColorWheelPicker.show(context, initialColor: Color(_colorValue));
                        if (picked != null) {
                          setState(() => _colorValue = picked.value);
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(_colorValue),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(_colorValue).withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check, size: 18, color: Colors.white),
                      ),
                    ),
                  // Dedicated Wheel Button icon
                  GestureDetector(
                    onTap: () async {
                      final picked = await ColorWheelPicker.show(context, initialColor: Color(_colorValue));
                      if (picked != null) {
                        setState(() => _colorValue = picked.value);
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const SweepGradient(
                          colors: [
                            Color(0xFFFF0000),
                            Color(0xFFFFFF00),
                            Color(0xFF00FF00),
                            Color(0xFF00FFFF),
                            Color(0xFF0000FF),
                            Color(0xFFFF00FF),
                            Color(0xFFFF0000),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.palette_outlined, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        final session = ClassSession(
                          id: widget.existingSession?.id ?? 'cs_${DateTime.now().millisecondsSinceEpoch}',
                          subject: _subjectController.text.trim(),
                          room: _roomController.text.trim(),
                          dayOfWeek: _dayOfWeek,
                          startHour: _startTime.hour,
                          startMinute: _startTime.minute,
                          endHour: _endTime.hour,
                          endMinute: _endTime.minute,
                          defaultPoints: _defaultPoints,
                          colorValue: _colorValue,
                        );
                        widget.onSave(session);
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(widget.existingSession == null ? 'Add Class' : 'Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
