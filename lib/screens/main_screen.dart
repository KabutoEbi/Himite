import 'package:flutter/material.dart';

import '../models/post.dart';
import '../utils/date_time_format.dart';
import '../utils/app_messenger.dart';
import '../widgets/participant_list.dart';
import 'archive_screen.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

enum PostFilter { joining }

enum PostSort { newest, eventDate, deadline }

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
  PostSort _sort = PostSort.newest;
  String? _group;
  DateTime? _eventDate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filtered =
        widget.posts.where((p) {
          final matchesGroup = _group == null || p.group == _group;
          final matchesDate =
              _eventDate == null || _isSameDay(p.time, _eventDate!);
          final matchesStatus = switch (_filter) {
            null => !p.isClosedAt(now),
            PostFilter.joining =>
              !p.isClosedAt(now) && p.isParticipating(widget.currentUserId),
          };
          return matchesGroup && matchesDate && matchesStatus;
        }).toList()..sort(
          (a, b) => switch (_sort) {
            PostSort.newest => b.createdAt.compareTo(a.createdAt),
            PostSort.eventDate => a.time.compareTo(b.time),
            PostSort.deadline => a.deadline.compareTo(b.deadline),
          },
        );

    final groups = widget.posts.map((post) => post.group).toSet().toList()
      ..sort();
    final hasDetailedFilter =
        _filter == PostFilter.joining || _group != null || _eventDate != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '募集を作成',
          onPressed: _openCreatePost,
          icon: const Icon(Icons.add_rounded),
        ),
        title: const Text('Himite'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'アーカイブ',
            onPressed: _openArchive,
            icon: const Icon(Icons.inventory_2_outlined),
          ),
          IconButton(
            tooltip: '通知',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
            child: Row(
              children: [
                Text(
                  '${filtered.length}件',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                IconButton(
                  tooltip: '絞り込み',
                  style: IconButton.styleFrom(
                    backgroundColor: hasDetailedFilter
                        ? Theme.of(context).colorScheme.primaryContainer
                        : const Color(0xFFF0F3F1),
                  ),
                  onPressed: () => _showFilterSheet(groups),
                  icon: Icon(
                    Icons.tune_rounded,
                    color: hasDetailedFilter
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF66736D),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<PostSort>(
                  initialValue: _sort,
                  tooltip: '並び替え',
                  onSelected: (value) => setState(() => _sort = value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: PostSort.newest, child: Text('新着順')),
                    PopupMenuItem(
                      value: PostSort.eventDate,
                      child: Text('開催日が近い順'),
                    ),
                    PopupMenuItem(
                      value: PostSort.deadline,
                      child: Text('締切が近い順'),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_vert_rounded, size: 18),
                        const SizedBox(width: 4),
                        Text(_sortLabel(_sort)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyResults(
                    hasFilters: _filter != null || hasDetailedFilter,
                    onClear: _clearFilters,
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final post = filtered[index];
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
                          vertical: 6,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(
                                post: post,
                                currentUserId: widget.currentUserId,
                                onToggleParticipate: _toggleParticipation,
                                onUpdatePost: _updatePost,
                                onDeletePost: _deletePost,
                                onClosePost: _closePost,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        post.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      post.group,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _PostMetaRow(
                                  icon: Icons.location_on_outlined,
                                  text: post.place,
                                ),
                                const SizedBox(height: 5),
                                _PostMetaRow(
                                  icon: Icons.calendar_today_outlined,
                                  text: formatDateTime(post.time),
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      key: ValueKey('participants-${post.id}'),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 32),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () => _showParticipants(post),
                                      icon: const Icon(
                                        Icons.group_outlined,
                                        size: 17,
                                      ),
                                      label: Text(
                                        post.number > 0
                                            ? '${post.participantCount}/${post.number}人'
                                            : '${post.participantCount}人',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    _CapacityIndicator(post: post),
                                    const Spacer(),
                                    Text(
                                      '締切 ${formatDateTime(post.deadline)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      iconSize: 21,
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        isParticipating
                                            ? Icons.check_circle
                                            : Icons.check_circle_outline,
                                        color: isParticipating
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : null,
                                      ),
                                      onPressed: canJoin
                                          ? () => _toggleParticipation(post.id)
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
    );
  }

  Future<void> _openCreatePost() async {
    final result = await Navigator.of(context).push<Post>(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(currentUserId: widget.currentUserId),
      ),
    );
    if (result == null || !mounted) return;
    widget.onAddPost(result);
    _showSnackBar('募集を作成しました');
  }

  Future<void> _openArchive() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ArchiveScreen(
          posts: widget.posts,
          currentUserId: widget.currentUserId,
          onUpdatePost: _updatePost,
          onDeletePost: _deletePost,
          onClosePost: _closePost,
          onToggleParticipate: _toggleParticipation,
        ),
      ),
    );
  }

  void _toggleParticipation(String id) {
    final post = _postById(id);
    if (post == null) return;
    final wasParticipating = post.isParticipating(widget.currentUserId);
    widget.onToggleParticipate(id);
    _showSnackBar(wasParticipating ? '参加を取り消しました' : '募集に参加しました');
  }

  void _updatePost(Post post) {
    widget.onUpdatePost(post);
    _showSnackBar('変更を保存しました');
  }

  void _deletePost(String id) {
    widget.onDeletePost(id);
    _showSnackBar('募集を削除しました');
  }

  void _closePost(String id) {
    widget.onClosePost(id);
    _showSnackBar('募集を終了しました');
  }

  Post? _postById(String id) {
    for (final post in widget.posts) {
      if (post.id == id) return post;
    }
    return null;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    showSuccessMessage(context, message);
  }

  Future<void> _showFilterSheet(List<String> groups) async {
    var selectedGroup = _group;
    var selectedDate = _eventDate;
    var joiningOnly = _filter == PostFilter.joining;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5DBD8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '絞り込み',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: const Text('参加予定のみ'),
                  secondary: const Icon(Icons.check_circle_outline_rounded),
                  value: joiningOnly,
                  onChanged: (value) =>
                      setSheetState(() => joiningOnly = value),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: selectedGroup,
                  decoration: const InputDecoration(
                    labelText: 'グループ',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('すべてのグループ'),
                    ),
                    ...groups.map(
                      (group) => DropdownMenuItem<String?>(
                        value: group,
                        child: Text(group),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => selectedGroup = value),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE1E7E4)),
                  ),
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('開催日'),
                  subtitle: Text(
                    selectedDate == null
                        ? 'すべての日付'
                        : formatDateTime(selectedDate!).split(' ').first,
                  ),
                  trailing: selectedDate == null
                      ? const Icon(Icons.chevron_right_rounded)
                      : IconButton(
                          tooltip: '開催日をクリア',
                          onPressed: () =>
                              setSheetState(() => selectedDate = null),
                          icon: const Icon(Icons.close_rounded),
                        ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setSheetState(() {
                          joiningOnly = false;
                          selectedGroup = null;
                          selectedDate = null;
                        }),
                        child: const Text('リセット'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _filter = joiningOnly ? PostFilter.joining : null;
                            _group = selectedGroup;
                            _eventDate = selectedDate;
                          });
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('適用する'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _filter = null;
      _group = null;
      _eventDate = null;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _sortLabel(PostSort sort) => switch (sort) {
    PostSort.newest => '新着順',
    PostSort.eventDate => '開催日が近い順',
    PostSort.deadline => '締切が近い順',
  };

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
    return Text(
      isFull ? '満員' : '残り$remaining人',
      key: ValueKey('remaining-capacity-${post.id}'),
      style: TextStyle(
        color: isFull
            ? const Color(0xFF8B9691)
            : Theme.of(context).colorScheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PostMetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PostMetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF66736D)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF66736D)),
          ),
        ),
      ],
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClear;

  const _EmptyResults({required this.hasFilters, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters ? Icons.search_off_rounded : Icons.event_note_rounded,
              size: 48,
              color: const Color(0xFF8B9691),
            ),
            const SizedBox(height: 12),
            Text(hasFilters ? '条件に合う募集がありません' : '募集はまだありません'),
            if (hasFilters) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onClear, child: const Text('条件をクリア')),
            ],
          ],
        ),
      ),
    );
  }
}
