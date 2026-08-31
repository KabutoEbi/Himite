import 'package:flutter/material.dart';

import '../models/post.dart';
import '../utils/date_time_format.dart';
import 'post_detail_screen.dart';

class ArchiveScreen extends StatelessWidget {
  final List<Post> posts;
  final String currentUserId;
  final void Function(Post) onUpdatePost;
  final void Function(String) onDeletePost;
  final void Function(String) onClosePost;
  final void Function(String) onToggleParticipate;

  const ArchiveScreen({
    super.key,
    required this.posts,
    required this.currentUserId,
    required this.onUpdatePost,
    required this.onDeletePost,
    required this.onClosePost,
    required this.onToggleParticipate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final archivedPosts = posts.where((post) => post.isClosedAt(now)).toList()
      ..sort((a, b) => b.time.compareTo(a.time));

    return Scaffold(
      appBar: AppBar(title: const Text('アーカイブ')),
      body: archivedPosts.isEmpty
          ? const _EmptyArchive()
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: archivedPosts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final post = archivedPosts[index];
                return Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(
                          post: post,
                          currentUserId: currentUserId,
                          onToggleParticipate: onToggleParticipate,
                          onUpdatePost: onUpdatePost,
                          onDeletePost: onDeletePost,
                          onClosePost: onClosePost,
                        ),
                      ),
                    ),
                    title: Text(
                      post.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${post.place} • ${formatDateTime(post.time)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyArchive extends StatelessWidget {
  const _EmptyArchive();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF8B9691)),
          SizedBox(height: 12),
          Text('終了した募集はありません'),
        ],
      ),
    );
  }
}
