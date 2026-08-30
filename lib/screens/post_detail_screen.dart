import 'package:flutter/material.dart';

import '../models/post.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  final String currentUserId;
  final void Function(String) onToggleParticipate;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onToggleParticipate,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isClosed = !DateTime.now().isBefore(post.deadline);
    final isParticipating = post.isParticipating(widget.currentUserId);
    final isFull = !post.hasCapacity;
    final canToggle = !isClosed && (isParticipating || !isFull);

    return Scaffold(
      appBar: AppBar(title: const Text('募集詳細')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  post.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              _StatusChip(isClosed: isClosed, isFull: isFull),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(icon: Icons.place_outlined, label: '場所', value: post.place),
          _InfoRow(
            icon: Icons.schedule,
            label: '開催日時',
            value: _formatDateTime(post.time),
          ),
          _InfoRow(
            icon: Icons.timer_outlined,
            label: '参加締切',
            value: _formatDateTime(post.deadline),
          ),
          _InfoRow(
            icon: Icons.groups_outlined,
            label: 'グループ',
            value: post.group,
          ),
          _InfoRow(
            icon: Icons.people_outline,
            label: '参加人数',
            value: post.number > 0
                ? '${post.participantCount}/${post.number}人'
                : '${post.participantCount}人（定員なし）',
          ),
          const Divider(height: 32),
          Text('参加者', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (post.participants.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('まだ参加者はいません'),
            )
          else
            ...post.participants.map(
              (name) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(name),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const ValueKey('detail-participate-button'),
            onPressed: canToggle
                ? () {
                    widget.onToggleParticipate(post.id);
                    setState(() {});
                  }
                : null,
            icon: Icon(isParticipating ? Icons.close : Icons.check),
            label: Text(
              isParticipating
                  ? '参加を取り消す'
                  : isClosed
                  ? '募集は終了しました'
                  : isFull
                  ? '定員に達しました'
                  : 'この募集に参加する',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${_two(dateTime.month)}/${_two(dateTime.day)} '
        '${_two(dateTime.hour)}:${_two(dateTime.minute)}';
  }

  String _two(int number) => number.toString().padLeft(2, '0');
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isClosed;
  final bool isFull;

  const _StatusChip({required this.isClosed, required this.isFull});

  @override
  Widget build(BuildContext context) {
    final label = isClosed
        ? '募集終了'
        : isFull
        ? '満員'
        : '募集中';
    final color = isClosed || isFull ? Colors.grey : Colors.green;

    return Chip(
      label: Text(label),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}
