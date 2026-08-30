import 'package:flutter/material.dart';

import '../models/post.dart';

class CreatePostScreen extends StatefulWidget {
  final String currentUserId;
  final Post? initialPost;

  const CreatePostScreen({
    super.key,
    required this.currentUserId,
    this.initialPost,
  });

  bool get isEditing => initialPost != null;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _placeController;
  late final TextEditingController _numberController;
  final List<String> _availableGroups = ['全体', '親しい友達', 'サッカー部', '大学の友達'];
  late String _selectedGroup;
  DateTime? _selectedTime;
  DateTime? _selectedDeadline;
  String? _timeError;
  String? _deadlineError;

  @override
  void initState() {
    super.initState();
    final post = widget.initialPost;
    _titleController = TextEditingController(text: post?.title);
    _placeController = TextEditingController(text: post?.place);
    _numberController = TextEditingController(
      text: post == null || post.number <= 0 ? '' : post.number.toString(),
    );
    _selectedGroup = post?.group ?? _availableGroups.first;
    _selectedTime = post?.time;
    _selectedDeadline = post?.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? now),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _timeError = null;
      _deadlineError = null;
    });
    if (_selectedTime == null || _selectedDeadline == null) {
      setState(() {
        if (_selectedTime == null) _timeError = '開催日時を選択してください';
        if (_selectedDeadline == null) _deadlineError = '締切日時を選択してください';
      });
      return;
    }
    if (_selectedTime!.isBefore(_selectedDeadline!)) {
      setState(() => _deadlineError = '開催日時が締切日時より前になっています');
      return;
    }

    final number = _numberController.text.trim().isEmpty
        ? 0
        : int.parse(_numberController.text);
    final existing = widget.initialPost;
    final post = existing == null
        ? Post.create(
            authorId: widget.currentUserId,
            title: _titleController.text.trim(),
            place: _placeController.text.trim(),
            time: _selectedTime!,
            number: number,
            group: _selectedGroup,
            deadline: _selectedDeadline!,
          )
        : existing.copyWith(
            title: _titleController.text.trim(),
            place: _placeController.text.trim(),
            time: _selectedTime,
            number: number,
            group: _selectedGroup,
            deadline: _selectedDeadline,
          );
    Navigator.of(context).pop(post);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? '募集を編集' : '募集作成')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'タイトル'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _placeController,
                decoration: const InputDecoration(labelText: '場所'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedGroup,
                decoration: const InputDecoration(labelText: 'グループ'),
                items: _availableGroups
                    .map(
                      (group) =>
                          DropdownMenuItem(value: group, child: Text(group)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedGroup = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: '人数（任意）'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) return '1以上の数値を入力してください';
                  final participants =
                      widget.initialPost?.participantCount ?? 0;
                  if (number < participants) return '現在の参加者数以上にしてください';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _DateTimeField(
                label: '開催日時',
                value: _selectedTime,
                errorText: _timeError,
                onPressed: () async {
                  final dateTime = await _pickDateTime(_selectedTime);
                  if (dateTime != null && mounted) {
                    setState(() {
                      _selectedTime = dateTime;
                      _timeError = null;
                    });
                  }
                },
              ),
              _DateTimeField(
                label: '締切日時',
                value: _selectedDeadline,
                errorText: _deadlineError,
                onPressed: () async {
                  final dateTime = await _pickDateTime(_selectedDeadline);
                  if (dateTime != null && mounted) {
                    setState(() {
                      _selectedDeadline = dateTime;
                      _deadlineError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('save-post-button'),
                onPressed: _submit,
                child: Text(widget.isEditing ? '変更を保存' : '作成'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? '必須項目です' : null;
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final String? errorText;
  final VoidCallback onPressed;

  const _DateTimeField({
    required this.label,
    required this.value,
    required this.errorText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(label),
          subtitle: Text(value == null ? '未選択' : _formatDateTime(value!)),
          trailing: TextButton(onPressed: onPressed, child: const Text('選択')),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${dateTime.year}/${two(dateTime.month)}/${two(dateTime.day)} '
        '${two(dateTime.hour)}:${two(dateTime.minute)}';
  }
}
