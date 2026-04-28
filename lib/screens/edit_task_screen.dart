import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';

class EditTaskScreen extends StatefulWidget {
  const EditTaskScreen({super.key, required this.task});

  final TaskModel task;

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _dueDateCtrl;
  late DateTime? _selectedDueDate;
  late bool _isCompleted;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t.title);
    _descCtrl = TextEditingController(text: t.description);
    _selectedDueDate = t.dueDate;
    _isCompleted = t.isCompleted;
    _dueDateCtrl = TextEditingController(
      text: t.dueDate != null
          ? DateFormat('MMM d, yyyy').format(t.dueDate!)
          : '',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _dueDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: 'Select due date',
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
        _dueDateCtrl.text = DateFormat('MMM d, yyyy').format(picked);
      });
    }
  }

  void _clearDate() {
    setState(() {
      _selectedDueDate = null;
      _dueDateCtrl.clear();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final updated = widget.task.copyWith(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      isCompleted: _isCompleted,
      dueDate: _selectedDueDate,
      clearDueDate: _selectedDueDate == null,
    );

    final ok = await context.read<TaskProvider>().updateTask(updated);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task updated successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      final error =
          context.read<TaskProvider>().errorMessage ?? 'Failed to update task';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LoadingOverlay(
      isLoading: _saving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Task'),
          actions: [
            TextButton(
              onPressed: _submit,
              child: Text(
                'Save',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Details ──
                Text(
                  'Task Details',
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _titleCtrl,
                  label: 'Title',
                  hint: 'Task title',
                  prefixIcon: Icons.title_rounded,
                  validator: Validators.taskTitle,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descCtrl,
                  label: 'Description',
                  hint: 'Task details (optional)',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 4,
                  minLines: 3,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 28),

                // ── Schedule ──
                Text(
                  'Schedule',
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _dueDateCtrl,
                  label: 'Due Date',
                  hint: 'Select a due date (optional)',
                  prefixIcon: Icons.calendar_today_rounded,
                  readOnly: true,
                  onTap: _pickDate,
                  suffixIcon: _selectedDueDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: _clearDate,
                          tooltip: 'Clear date',
                        )
                      : const Icon(Icons.arrow_drop_down_rounded),
                ),
                const SizedBox(height: 20),

                // ── Status toggle ──
                Card(
                  child: SwitchListTile(
                    title: const Text(
                      'Mark as Completed',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      _isCompleted
                          ? 'This task is completed'
                          : 'This task is still active',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    secondary: Icon(
                      _isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: _isCompleted
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    value: _isCompleted,
                    onChanged: (v) => setState(() => _isCompleted = v),
                    activeThumbColor: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Submit ──
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text(
                      'Save Changes',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                // ── Metadata ──
                if (widget.task.createdAt != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Created: ${DateFormat('MMM d, yyyy · h:mm a').format(widget.task.createdAt!.toLocal())}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
