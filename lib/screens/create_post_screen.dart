import 'package:flutter/cupertino.dart';
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
  static const _availableGroups = ['全体', '親しい友達', 'サッカー部', '大学の友達'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _placeController;
  late final TextEditingController _numberController;
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

  DateTime _defaultDateTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  Future<DateTime?> _pickDate(DateTime? initial) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialValue = initial ?? _defaultDateTime();
    final selected = initialValue.isBefore(today)
        ? _defaultDateTime()
        : initialValue;
    return showModalBottomSheet<DateTime>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: 420,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '日付を選択',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '閉じる',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CalendarDatePicker(
                  initialDate: selected,
                  firstDate: today,
                  lastDate: now.add(const Duration(days: 365 * 5)),
                  onDateChanged: (date) => Navigator.of(sheetContext).pop(date),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickTime(DateTime? initial) async {
    var selected = initial ?? _defaultDateTime();
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (sheetContext) => Container(
        height: 330,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('キャンセル'),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.of(sheetContext).pop(selected),
                      child: const Text(
                        '完了',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: selected,
                  use24hFormat: true,
                  minuteInterval: 5,
                  onDateTimeChanged: (value) => selected = value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final now = DateTime.now();
    if (!_selectedTime!.isAfter(now) || !_selectedDeadline!.isAfter(now)) {
      setState(() {
        if (!_selectedTime!.isAfter(now)) {
          _timeError = '開催日時は現在より後にしてください';
        }
        if (!_selectedDeadline!.isAfter(now)) {
          _deadlineError = '締切日時は現在より後にしてください';
        }
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '募集を編集' : '募集を作成'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE7EBE9)),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 20, 16, bottomInset + 28),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  hintText: '例：週末フットサル',
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _placeController,
                decoration: const InputDecoration(
                  labelText: '場所',
                  hintText: '開催場所を入力',
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 24),
              const _SectionLabel('日時'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE1E7E4)),
                ),
                child: Column(
                  children: [
                    _DateTimeField(
                      label: '開催',
                      value: _selectedTime,
                      errorText: _timeError,
                      onDatePressed: () => _selectDate(isDeadline: false),
                      onTimePressed: () => _selectTime(isDeadline: false),
                    ),
                    const Divider(height: 1, indent: 16),
                    _DateTimeField(
                      label: '締切',
                      value: _selectedDeadline,
                      errorText: _deadlineError,
                      onDatePressed: () => _selectDate(isDeadline: true),
                      onTimePressed: () => _selectTime(isDeadline: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('公開設定'),
              const SizedBox(height: 8),
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
                decoration: const InputDecoration(
                  labelText: '募集人数（任意）',
                  hintText: '例：5',
                  suffixText: '人',
                ),
                keyboardType: TextInputType.number,
                validator: _capacityValidator,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE7EBE9))),
          ),
          child: SafeArea(
            top: false,
            child: FilledButton(
              key: const ValueKey('save-post-button'),
              onPressed: _submit,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(widget.isEditing ? '変更を保存' : '募集を作成'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? '必須項目です' : null;

  String? _capacityValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final capacity = int.tryParse(value);
    if (capacity == null || capacity <= 0) return '1以上の数値を入力してください';
    final participantCount = widget.initialPost?.participantCount ?? 0;
    if (capacity < participantCount) return '現在の参加者数以上にしてください';
    return null;
  }

  Future<void> _selectDate({required bool isDeadline}) async {
    final currentValue = isDeadline ? _selectedDeadline : _selectedTime;
    final date = await _pickDate(currentValue);
    if (date == null || !mounted) return;
    final base = currentValue ?? _defaultDateTime();
    _setDateTime(
      DateTime(date.year, date.month, date.day, base.hour, base.minute),
      isDeadline: isDeadline,
    );
  }

  Future<void> _selectTime({required bool isDeadline}) async {
    final currentValue = isDeadline ? _selectedDeadline : _selectedTime;
    final time = await _pickTime(currentValue);
    if (time == null || !mounted) return;
    final base = currentValue ?? _defaultDateTime();
    _setDateTime(
      DateTime(base.year, base.month, base.day, time.hour, time.minute),
      isDeadline: isDeadline,
    );
  }

  void _setDateTime(DateTime dateTime, {required bool isDeadline}) {
    setState(() {
      if (isDeadline) {
        _selectedDeadline = dateTime;
        _deadlineError = null;
      } else {
        _selectedTime = dateTime;
        _timeError = null;
      }
    });
  }
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final String? errorText;
  final VoidCallback onDatePressed;
  final VoidCallback onTimePressed;

  const _DateTimeField({
    required this.label,
    required this.value,
    required this.errorText,
    required this.onDatePressed,
    required this.onTimePressed,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = value == null
        ? '日付'
        : '${value!.year}/${value!.month}/${value!.day}';
    final timeText = value == null
        ? '時刻'
        : TimeOfDay.fromDateTime(value!).format(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              _DateValue(
                text: dateText,
                selected: value != null,
                onTap: onDatePressed,
              ),
              const SizedBox(width: 6),
              _DateValue(
                text: timeText,
                selected: value != null,
                onTap: onTimePressed,
              ),
            ],
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateValue extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _DateValue({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : const Color(0xFFF0F3F1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFF8B9691),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF66736D),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
