import 'package:flutter/material.dart';

class AddEditTimetableDialog extends StatefulWidget {
  final String? initialName;
  final bool isRename;
  final Function(String name) onSave;

  const AddEditTimetableDialog({
    super.key,
    this.initialName,
    this.isRename = false,
    required this.onSave,
  });

  @override
  State<AddEditTimetableDialog> createState() => _AddEditTimetableDialogState();
}

class _AddEditTimetableDialogState extends State<AddEditTimetableDialog> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isRename ? 'Rename Timetable' : 'Create New Timetable',
        style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Timetable Name',
            hintText: 'e.g. Semester 5 Routine, Lab Schedule',
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Please enter a name';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.onSave(_nameController.text.trim());
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.isRename ? 'Rename' : 'Create'),
        ),
      ],
    );
  }
}
