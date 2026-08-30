import 'package:flutter/material.dart';

import '../models/post.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

enum PostFilter { open, joining, closed }

class MainScreen extends StatefulWidget {
  final List<Post> posts;
  final String currentUserId;
  final void Function(Post) onAddPost;
  final void Function(Post) onUpdatePost;
  final void Function(String) onDeletePost;
  final void Function(String) onClosePost;
  final void Function(String) onToggleParticipate;

  const MainScreen({
    super.key,
    required this.posts,
    required this.currentUserId,
    required this.onAddPost,
    required this.onUpdatePost,
    required this.onDeletePost,
    required this.onClosePost,
    required this.onToggleParticipate,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  PostFilter? _filter;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Filter and sort posts by createdAt desc
    final filtered = widget.posts.where((p) {
      if (_filter == null) return true;
      if (_filter == PostFilter.open) return !p.isClosedAt(now);
      if (_filter == PostFilter.joining) {
        return p.isParticipating(widget.currentUserId);
      }
      // closed
      return p.isClosedAt(now);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('募集一覧')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('募集中'),
                  selected: _filter == PostFilter.open,
                  showCheckmark: false,
                  onSelected: (selected) => setState(() {
                    _filter = (_filter == PostFilter.open)
                        ? null
                        : PostFilter.open;
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('参加予定'),
                  selected: _filter == PostFilter.joining,
                  showCheckmark: false,
                  onSelected: (selected) => setState(() {
                    _filter = (_filter == PostFilter.joining)
                        ? null
                        : PostFilter.joining;
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('募集終了'),
                  selected: _filter == PostFilter.closed,
                  showCheckmark: false,
                  onSelected: (selected) => setState(() {
                    _filter = (_filter == PostFilter.closed)
                        ? null
                        : PostFilter.closed;
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('募集ないよ'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      final isParticipating = p.isParticipating(
                        widget.currentUserId,
                      );
                      final isClosed = p.isClosedAt(now);
                      final canJoin =
                          isParticipating || (!isClosed && p.hasCapacity);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(
                                post: p,
                                currentUserId: widget.currentUserId,
                                onToggleParticipate: widget.onToggleParticipate,
                                onUpdatePost: widget.onUpdatePost,
                                onDeletePost: widget.onDeletePost,
                                onClosePost: widget.onClosePost,
                              ),
                            ),
                          ),
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          title: Text(p.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                [
                                  p.place,
                                  p.group,
                                  _formatDateTime(p.time),
                                ].join(' • '),
                              ),
                              TextButton.icon(
                                key: ValueKey('participants-${p.id}'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 32),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _showParticipants(p),
                                icon: const Icon(Icons.group, size: 16),
                                label: Text(
                                  p.number > 0
                                      ? '参加 ${p.participantCount}/${p.number}人'
                                      : '参加 ${p.participantCount}人',
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  '締切 ${_formatDateTime(p.deadline)}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                iconSize: 20,
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                icon: Icon(
                                  isParticipating
                                      ? Icons.check_circle
                                      : Icons.check_circle_outline,
                                  color: isParticipating ? Colors.green : null,
                                ),
                                onPressed: canJoin
                                    ? () => widget.onToggleParticipate(p.id)
                                    : null,
                                tooltip: isParticipating
                                    ? '参加を取り消す'
                                    : isClosed
                                    ? '募集は終了しました'
                                    : !p.hasCapacity
                                    ? '定員に達しました'
                                    : '参加予定にする',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<Post>(
            MaterialPageRoute(
              builder: (_) =>
                  CreatePostScreen(currentUserId: widget.currentUserId),
            ),
          );
          if (result != null) widget.onAddPost(result);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showParticipants(Post post) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('参加者（${post.participantCount}人）'),
        content: post.participants.isEmpty
            ? const Text('まだ参加者はいません')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: post.participants
                    .map(
                      (name) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(name),
                      ),
                    )
                    .toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${_two(dt.month)}/${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
