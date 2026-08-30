import 'package:flutter/material.dart';

import '../models/post.dart';
import 'create_post_screen.dart';

enum _OwnerAction { edit, close, delete }

class PostDetailScreen extends StatefulWidget {
  final Post post;
  final String currentUserId;
  final void Function(String) onToggleParticipate;
  final void Function(Post) onUpdatePost;
  final void Function(String) onDeletePost;
  final void Function(String) onClosePost;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onToggleParticipate,
    required this.onUpdatePost,
    required this.onDeletePost,
    required this.onClosePost,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Post _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final isOwner = post.authorId == widget.currentUserId;
    final isClosed = post.isClosedAt(DateTime.now());
    final isParticipating = post.isParticipating(widget.currentUserId);
    final isFull = !post.hasCapacity;
    final canToggle = isParticipating || (!isClosed && !isFull);

    return Scaffold(
      appBar: AppBar(
        title: const Text('募集詳細'),
        actions: [
          if (isOwner)
            PopupMenuButton<_OwnerAction>(
              tooltip: '募集を管理',
              onSelected: _handleOwnerAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _OwnerAction.edit,
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('編集'),
                  ),
                ),
                if (!isClosed)
                  const PopupMenuItem(
                    value: _OwnerAction.close,
                    child: ListTile(
                      leading: Icon(Icons.stop_circle_outlined),
                      title: Text('募集を終了'),
                    ),
                  ),
                const PopupMenuItem(
                  value: _OwnerAction.delete,
                  child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('削除'),
                  ),
                ),
              ],
            ),
        ],
      ),
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

  Future<void> _handleOwnerAction(_OwnerAction action) async {
    switch (action) {
      case _OwnerAction.edit:
        await _editPost();
      case _OwnerAction.close:
        await _closePost();
      case _OwnerAction.delete:
        await _deletePost();
    }
  }

  Future<void> _editPost() async {
    final updatedPost = await Navigator.of(context).push<Post>(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          currentUserId: widget.currentUserId,
          initialPost: _post,
        ),
      ),
    );
    if (updatedPost == null || !mounted) return;
    widget.onUpdatePost(updatedPost);
    setState(() => _post = updatedPost);
  }

  Future<void> _closePost() async {
    final confirmed = await _showConfirmation(
      title: '募集を終了しますか？',
      message: '終了後は新しく参加できません。',
      actionLabel: '終了する',
    );
    if (!confirmed || !mounted) return;
    widget.onClosePost(_post.id);
    setState(() => _post = _post.copyWith(isManuallyClosed: true));
  }

  Future<void> _deletePost() async {
    final confirmed = await _showConfirmation(
      title: '募集を削除しますか？',
      message: '削除した募集は元に戻せません。',
      actionLabel: '削除する',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    widget.onDeletePost(_post.id);
    Navigator.of(context).pop();
  }

  Future<bool> _showConfirmation({
    required String title,
    required String message,
    required String actionLabel,
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: isDestructive
                    ? TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      )
                    : null,
                child: Text(actionLabel),
              ),
            ],
          ),
        ) ??
        false;
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
