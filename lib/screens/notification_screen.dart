import 'package:flutter/material.dart';

import '../models/post.dart';
import '../utils/date_time_format.dart';
import 'post_detail_screen.dart';

enum _NotificationType { deadlineSoon, eventSoon, closed, full }

class _PostNotification {
  final Post post;
  final _NotificationType type;

  const _PostNotification({required this.post, required this.type});
}

List<_PostNotification> _notificationsFor(
  List<Post> posts,
  String currentUserId,
  DateTime now,
) {
  final limit = now.add(const Duration(hours: 24));
  final notifications = <_PostNotification>[];

  for (final post in posts) {
    final isParticipating = post.isParticipating(currentUserId);
    final isOwner = post.authorId == currentUserId;
    final isClosed = post.isClosedAt(now);

    if (isParticipating && isClosed) {
      notifications.add(
        _PostNotification(post: post, type: _NotificationType.closed),
      );
      continue;
    }
    if (!isClosed &&
        post.deadline.isAfter(now) &&
        !post.deadline.isAfter(limit)) {
      notifications.add(
        _PostNotification(post: post, type: _NotificationType.deadlineSoon),
      );
    }
    if (isParticipating &&
        post.time.isAfter(now) &&
        !post.time.isAfter(limit)) {
      notifications.add(
        _PostNotification(post: post, type: _NotificationType.eventSoon),
      );
    }
    if (isOwner && !isClosed && !post.hasCapacity) {
      notifications.add(
        _PostNotification(post: post, type: _NotificationType.full),
      );
    }
  }
  return notifications;
}

int notificationCountFor(List<Post> posts, String currentUserId) =>
    _notificationsFor(posts, currentUserId, DateTime.now()).length;

class NotificationScreen extends StatelessWidget {
  final List<Post> posts;
  final String currentUserId;
  final void Function(Post) onUpdatePost;
  final void Function(String) onDeletePost;
  final void Function(String) onClosePost;
  final void Function(String) onToggleParticipate;

  const NotificationScreen({
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
    final notifications = _notificationsFor(
      posts,
      currentUserId,
      DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('通知')),
      body: notifications.isEmpty
          ? const _EmptyNotifications()
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(_iconFor(notification.type), size: 21),
                    ),
                    title: Text(_titleFor(notification.type)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_messageFor(notification)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(
                          post: notification.post,
                          currentUserId: currentUserId,
                          onToggleParticipate: onToggleParticipate,
                          onUpdatePost: onUpdatePost,
                          onDeletePost: onDeletePost,
                          onClosePost: onClosePost,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _iconFor(_NotificationType type) => switch (type) {
    _NotificationType.deadlineSoon => Icons.timer_outlined,
    _NotificationType.eventSoon => Icons.event_available_outlined,
    _NotificationType.closed => Icons.event_busy_outlined,
    _NotificationType.full => Icons.groups_outlined,
  };

  String _titleFor(_NotificationType type) => switch (type) {
    _NotificationType.deadlineSoon => '締切が近づいています',
    _NotificationType.eventSoon => '開催が近づいています',
    _NotificationType.closed => '参加予定の募集が終了しました',
    _NotificationType.full => '募集が満員になりました',
  };

  String _messageFor(_PostNotification notification) {
    final post = notification.post;
    return switch (notification.type) {
      _NotificationType.deadlineSoon =>
        '${post.title} • 締切 ${formatDateTime(post.deadline)}',
      _NotificationType.eventSoon =>
        '${post.title} • 開催 ${formatDateTime(post.time)}',
      _NotificationType.closed => post.title,
      _NotificationType.full => '${post.title} • ${post.participantCount}人参加',
    };
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: Color(0xFF8B9691),
          ),
          SizedBox(height: 12),
          Text('新しい通知はありません'),
        ],
      ),
    );
  }
}
