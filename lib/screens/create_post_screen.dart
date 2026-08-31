import 'package:flutter/material.dart';

import '../models/post.dart';
import '../utils/date_time_format.dart';

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
            padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset + 28),
            children: [
              const Text(
                '募集内容',
                style: TextStyle(
                  color: Color(0xFF17211D),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '予定を入力して、仲間を集めましょう。',
                style: TextStyle(color: Color(0xFF66736D), fontSize: 14),
              ),
              const SizedBox(height: 22),
              _FormCard(
                children: [
                  const _FieldLabel('基本情報'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'タイトル',
                      hintText: '例：週末フットサル',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _placeController,
                    decoration: const InputDecoration(
                      labelText: '場所',
                      hintText: '開催場所を入力',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGroup,
                    decoration: const InputDecoration(
                      labelText: '公開グループ',
                      prefixIcon: Icon(Icons.group_outlined),
                    ),
                    items: _availableGroups
                        .map(
                          (group) => DropdownMenuItem(
                            value: group,
                            child: Text(group),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedGroup = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _numberController,
                    decoration: const InputDecoration(
                      labelText: '募集人数（任意）',
                      hintText: '例：5',
                      prefixIcon: Icon(Icons.people_outline),
                      suffixText: '人',
                    ),
                    keyboardType: TextInputType.number,
                    validator: _capacityValidator,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FormCard(
                children: [
                  const _FieldLabel('日時設定'),
                  const SizedBox(height: 10),
                  _DateTimeField(
                    label: '開催日時',
                    icon: Icons.calendar_today_outlined,
                    value: _selectedTime,
                    errorText: _timeError,
                    onPressed: () => _selectDateTime(isDeadline: false),
                  ),
                  _DateTimeField(
                    label: '締切日時',
                    icon: Icons.schedule_outlined,
                    value: _selectedDeadline,
                    errorText: _deadlineError,
                    onPressed: () => _selectDateTime(isDeadline: true),
                  ),
                ],
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

  Future<void> _selectDateTime({required bool isDeadline}) async {
    final currentValue = isDeadline ? _selectedDeadline : _selectedTime;
    final dateTime = await _pickDateTime(currentValue);
    if (dateTime == null || !mounted) return;
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
  final IconData icon;
  final DateTime? value;
  final String? errorText;
  final VoidCallback onPressed;

  const _DateTimeField({
    required this.label,
    required this.icon,
    required this.value,
    required this.errorText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: errorText == null
                    ? const Color(0xFFE1E7E4)
                    : Theme.of(context).colorScheme.error,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF16835B), size: 21),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF66736D),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value == null ? '日時を選択' : formatDateTime(value!),
                        style: TextStyle(
                          color: value == null
                              ? const Color(0xFF8B9691)
                              : const Color(0xFF17211D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8B9691),
                ),
              ],
            ),
          ),
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
        const SizedBox(height: 12),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;

  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EBE9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A17211D),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF2D3A34),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
