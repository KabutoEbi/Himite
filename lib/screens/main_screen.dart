import 'package:flutter/material.dart';

import '../models/post.dart';
import '../utils/date_time_format.dart';
import '../widgets/participant_list.dart';
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
    final filteredPosts = _filterPosts(now);

    return Scaffold(
      appBar: AppBar(title: const Text('募集一覧')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                _filterChip('募集中', PostFilter.open),
                _filterChip('参加予定', PostFilter.joining),
                _filterChip('募集終了', PostFilter.closed),
              ],
            ),
          ),
          Expanded(
            child: filteredPosts.isEmpty
                ? const Center(child: Text('募集ないよ'))
                : ListView.builder(
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post = filteredPosts[index];
                      final isParticipating = post.isParticipating(
                        widget.currentUserId,
                      );
                      final isClosed = post.isClosedAt(now);
                      final canJoin = post.canToggleParticipation(
                        widget.currentUserId,
                        now,
                      );
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(
                                post: post,
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
                          title: Text(post.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                [
                                  post.place,
                                  post.group,
                                  formatDateTime(post.time),
                                ].join(' • '),
                              ),
                              TextButton.icon(
                                key: ValueKey('participants-${post.id}'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 32),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _showParticipants(post),
                                icon: const Icon(Icons.group, size: 16),
                                label: Text(
                                  post.number > 0
                                      ? '参加 ${post.participantCount}/${post.number}人'
                                      : '参加 ${post.participantCount}人',
                                ),
                              ),
                              _CapacityIndicator(post: post),
                              const SizedBox(height: 6),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  '締切 ${formatDateTime(post.deadline)}',
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
                                    ? () => widget.onToggleParticipate(post.id)
                                    : null,
                                tooltip: isParticipating
                                    ? '参加を取り消す'
                                    : isClosed
                                    ? '募集は終了しました'
                                    : !post.hasCapacity
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

  List<Post> _filterPosts(DateTime now) {
    final posts = widget.posts.where((post) {
      return switch (_filter) {
        null => true,
        PostFilter.open => !post.isClosedAt(now),
        PostFilter.joining => post.isParticipating(widget.currentUserId),
        PostFilter.closed => post.isClosedAt(now),
      };
    }).toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Widget _filterChip(String label, PostFilter filter) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == filter,
      showCheckmark: false,
      onSelected: (_) {
        setState(() => _filter = _filter == filter ? null : filter);
      },
    );
  }

  Future<void> _showParticipants(Post post) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text('参加者（${post.participantCount}人）'),
        content: ParticipantList(participants: post.participants),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final Post post;

  const _CapacityIndicator({required this.post});

  @override
  Widget build(BuildContext context) {
    if (post.number <= 0) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.all_inclusive_rounded, size: 15, color: Color(0xFF66736D)),
          SizedBox(width: 5),
          Text(
            '定員なし',
            style: TextStyle(fontSize: 12, color: Color(0xFF66736D)),
          ),
        ],
      );
    }

    final remaining = (post.number - post.participantCount).clamp(
      0,
      post.number,
    );
    final isFull = remaining == 0;
    final color = isFull
        ? const Color(0xFF8B9691)
        : Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: ValueKey('capacity-progress-${post.id}'),
              value: (post.participantCount / post.number).clamp(0, 1),
              minHeight: 6,
              color: color,
              backgroundColor: const Color(0xFFE1E7E4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          isFull ? '満員' : '残り$remaining人',
          key: ValueKey('remaining-capacity-${post.id}'),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
