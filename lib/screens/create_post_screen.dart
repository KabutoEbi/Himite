import 'package:flutter/material.dart';

import '../models/post.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  final _groupController = TextEditingController();
  final _numberController = TextEditingController();
  final List<String> _availableGroups = ['全体', '親しい友達', 'サッカー部', '大学の友達'];
  String? _selectedGroup;

  DateTime? _selectedTime;
  DateTime? _selectedDeadline;
  String? _timeError;
  String? _deadlineError;

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _groupController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
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
    var hasError = false;
    if (_selectedTime == null) {
      setState(() => _timeError = '開催日時を選択してください');
      hasError = true;
    }
    if (_selectedDeadline == null) {
      setState(() => _deadlineError = '締切日時を選択してください');
      hasError = true;
    }
    if (hasError) return;
    if (_selectedTime!.isBefore(_selectedDeadline!)) {
      setState(() => _deadlineError = '開催日時が締切日時より前になっています');
      return;
    }
    final number = _numberController.text.trim().isEmpty
      ? 0
      : (int.tryParse(_numberController.text) ?? 0);
    final post = Post.create(
      title: _titleController.text.trim(),
      place: _placeController.text.trim(),
      time: _selectedTime!,
      number: number,
      group: (_selectedGroup ?? _availableGroups[0]).trim(),
      deadline: _selectedDeadline!,
    );
    Navigator.of(context).pop(post);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('募集作成')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'タイトル'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '必須項目です' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _placeController,
                decoration: const InputDecoration(labelText: '場所'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '必須項目です' : null,
              ),
              const SizedBox(height: 12),
              // Group selection: predefined only
              DropdownButtonFormField<String>(
                value: (_selectedGroup != null && _availableGroups.contains(_selectedGroup))
                    ? _selectedGroup
                    : _availableGroups[0],
                decoration: const InputDecoration(labelText: 'グループ'),
                items: _availableGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selectedGroup = v);
                },
                validator: (v) => (v == null || v.trim().isEmpty) ? '必須項目です' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: '人数（任意）'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return '1以上の数値を入力してください';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('開催日時'),
                    subtitle: Text(_selectedTime == null ? '未選択' : _formatDateTime(_selectedTime!)),
                    trailing: TextButton(
                      onPressed: () async {
                        final dt = await _pickDateTime(_selectedTime);
                        if (dt != null) setState(() {
                          _selectedTime = dt;
                          _timeError = null;
                        });
                      },
                      child: const Text('選択'),
                    ),
                  ),
                  if (_timeError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(_timeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('締切日時'),
                    subtitle: Text(_selectedDeadline == null ? '未選択' : _formatDateTime(_selectedDeadline!)),
                    trailing: TextButton(
                      onPressed: () async {
                        final dt = await _pickDateTime(_selectedDeadline);
                        if (dt != null) setState(() {
                          _selectedDeadline = dt;
                          _deadlineError = null;
                        });
                      },
                      child: const Text('選択'),
                    ),
                  ),
                  if (_deadlineError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(_deadlineError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('作成'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) => '${dt.year}/${_two(dt.month)}/${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
  String _two(int n) => n.toString().padLeft(2, '0');
}
