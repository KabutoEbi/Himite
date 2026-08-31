import 'package:flutter/material.dart';

import '../models/post.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

enum PostFilter { open, joining, closed }

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
            null => true,
            PostFilter.open => !p.isClosedAt(now),
            PostFilter.joining => p.isParticipating(widget.currentUserId),
            PostFilter.closed => p.isClosedAt(now),
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
    final hasDetailedFilter = _group != null || _eventDate != null;

    return Scaffold(
      appBar: AppBar(title: const Text('募集一覧')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
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
                const SizedBox(width: 8),
                ActionChip(
                  avatar: Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: hasDetailedFilter
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  label: Text(hasDetailedFilter ? '絞り込み中' : '絞り込み'),
                  onPressed: () => _showFilterSheet(groups),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
            child: Row(
              children: [
                Text(
                  '${filtered.length}件',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
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

  Future<void> _showFilterSheet(List<String> groups) async {
    var selectedGroup = _group;
    var selectedDate = _eventDate;
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
                        : '${selectedDate!.year}/${_two(selectedDate!.month)}/${_two(selectedDate!.day)}',
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
