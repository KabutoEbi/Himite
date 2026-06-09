import 'package:flutter/material.dart';

import '../models/post.dart';
import 'create_post_screen.dart';

enum PostFilter { open, joining, closed }

class MainScreen extends StatefulWidget {
  final List<Post> posts;
  final void Function(Post) onAddPost;
  final void Function(String) onToggleParticipate;

  const MainScreen({
    super.key,
    required this.posts,
    required this.onAddPost,
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
      if (_filter == PostFilter.open) return now.isBefore(p.deadline);
      if (_filter == PostFilter.joining) return p.isParticipating;
      // closed
      return !now.isBefore(p.deadline);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('募集一覧'),
      ),
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
                    _filter = (_filter == PostFilter.open) ? null : PostFilter.open;
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('参加予定'),
                  selected: _filter == PostFilter.joining,
                  showCheckmark: false,
                  onSelected: (selected) => setState(() {
                    _filter = (_filter == PostFilter.joining) ? null : PostFilter.joining;
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('募集終了'),
                  selected: _filter == PostFilter.closed,
                  showCheckmark: false,
                  onSelected: (selected) => setState(() {
                    _filter = (_filter == PostFilter.closed) ? null : PostFilter.closed;
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('該当する募集はありません'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(p.title),
                          subtitle: Text([
                            p.place,
                            p.group,
                            if (p.number > 0) '${p.number}人',
                            _formatDateTime(p.time)
                          ].join(' • ')),
                          trailing: SizedBox(
                            width: 96,
                            height: 48,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(child: Text('締切 ${_formatDateTime(p.deadline)}', overflow: TextOverflow.ellipsis)),
                                const SizedBox(height: 4),
                                IconButton(
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                  icon: Icon(
                                    p.isParticipating ? Icons.check_circle : Icons.check_circle_outline,
                                    color: p.isParticipating ? Colors.green : null,
                                  ),
                                  onPressed: () => widget.onToggleParticipate(p.id),
                                  tooltip: p.isParticipating ? '参加を取り消す' : '参加予定にする',
                                ),
                              ],
                            ),
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
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (result != null) widget.onAddPost(result);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${_two(dt.month)}/${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
