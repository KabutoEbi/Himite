import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:himite/models/post.dart';
import 'package:himite/screens/main_screen.dart';

void main() {
  group('Post participant management', () {
    test('adds and removes a participant', () {
      final post = _post(capacity: 2);

      expect(post.addParticipant(userId: 'user-1', displayName: 'あなた'), isTrue);
      expect(post.participantCount, 1);
      expect(post.isParticipating('user-1'), isTrue);
      expect(post.participants, ['あなた']);

      expect(post.removeParticipant('user-1'), isTrue);
      expect(post.participantCount, 0);
    });

    test('does not exceed capacity', () {
      final post = _post(capacity: 1);

      expect(post.addParticipant(userId: 'user-1', displayName: 'あなた'), isTrue);
      expect(post.addParticipant(userId: 'user-2', displayName: '友達'), isFalse);
      expect(post.participantCount, 1);
      expect(post.hasCapacity, isFalse);
    });
  });

  testWidgets('shows participant count and participant list', (tester) async {
    final post = _post(capacity: 3)
      ..addParticipant(userId: 'user-1', displayName: 'あなた');

    await tester.pumpWidget(
      MaterialApp(
        home: MainScreen(
          posts: [post],
          currentUserId: 'user-1',
          onAddPost: (_) {},
          onUpdatePost: (_) {},
          onDeletePost: (_) {},
          onClosePost: (_) {},
          onToggleParticipate: (_) {},
        ),
      ),
    );

    expect(find.text('1/3人'), findsOneWidget);
    expect(find.text('残り2人'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('participants-${post.id}')));
    await tester.pumpAndSettle();

    expect(find.text('参加者（1人）'), findsOneWidget);
    expect(find.text('あなた'), findsOneWidget);
  });

  testWidgets('sorts posts by event date', (tester) async {
    final now = DateTime.now();
    final later = _post(capacity: 3);
    final sooner = Post(
      id: 'post-2',
      authorId: 'user-2',
      title: '朝ごはん',
      place: 'カフェ',
      time: now.add(const Duration(hours: 1)),
      number: 2,
      group: '全体',
      deadline: now.add(const Duration(minutes: 30)),
      createdAt: now.subtract(const Duration(days: 1)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MainScreen(
          posts: [later, sooner],
          currentUserId: 'user-1',
          onAddPost: (_) {},
          onUpdatePost: (_) {},
          onDeletePost: (_) {},
          onClosePost: (_) {},
          onToggleParticipate: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('新着順'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('開催日が近い順').last);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('朝ごはん')).dy,
      lessThan(tester.getTopLeft(find.text('昼ごはん')).dy),
    );
  });

  testWidgets('opens details and allows participation', (tester) async {
    final post = _post(capacity: 3);

    await tester.pumpWidget(
      MaterialApp(
        home: MainScreen(
          posts: [post],
          currentUserId: 'user-1',
          onAddPost: (_) {},
          onUpdatePost: (_) {},
          onDeletePost: (_) {},
          onClosePost: (_) {},
          onToggleParticipate: (_) {
            if (post.isParticipating('user-1')) {
              post.removeParticipant('user-1');
            } else {
              post.addParticipant(userId: 'user-1', displayName: 'あなた');
            }
          },
        ),
      ),
    );

    await tester.tap(find.text('昼ごはん'));
    await tester.pumpAndSettle();

    expect(find.text('募集詳細'), findsOneWidget);
    expect(find.text('開催日時'), findsOneWidget);
    expect(find.text('0/3人'), findsOneWidget);

    final participateButton = find.byKey(
      const ValueKey('detail-participate-button'),
    );
    await tester.ensureVisible(participateButton);
    await tester.tap(participateButton);
    await tester.pump();

    expect(find.text('1/3人'), findsOneWidget);
    expect(find.text('あなた'), findsOneWidget);
    expect(find.text('参加を取り消す'), findsOneWidget);
  });

  testWidgets('only the author sees the management menu', (tester) async {
    final post = _post(capacity: 3);

    await tester.pumpWidget(
      MaterialApp(
        home: MainScreen(
          posts: [post],
          currentUserId: 'another-user',
          onAddPost: (_) {},
          onUpdatePost: (_) {},
          onDeletePost: (_) {},
          onClosePost: (_) {},
          onToggleParticipate: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('昼ごはん'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('募集を管理'), findsNothing);
  });

  testWidgets('author can edit a post', (tester) async {
    final post = _post(capacity: 3);
    Post? savedPost;

    await tester.pumpWidget(
      MaterialApp(
        home: MainScreen(
          posts: [post],
          currentUserId: 'user-1',
          onAddPost: (_) {},
          onUpdatePost: (updatedPost) => savedPost = updatedPost,
          onDeletePost: (_) {},
          onClosePost: (_) {},
          onToggleParticipate: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('昼ごはん'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('募集を管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '夜ごはん');
    final saveButton = find.byKey(const ValueKey('save-post-button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedPost?.title, '夜ごはん');
    expect(find.text('夜ごはん'), findsOneWidget);
  });

  testWidgets('manual close requires confirmation and disables new joins', (
    tester,
  ) async {
    final post = _post(capacity: 3);
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MainScreen(
          posts: [post],
          currentUserId: 'user-1',
          onAddPost: (_) {},
          onUpdatePost: (_) {},
          onDeletePost: (_) {},
          onClosePost: (_) => closed = true,
          onToggleParticipate: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('昼ごはん'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('募集を管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('募集を終了'));
    await tester.pumpAndSettle();

    expect(find.text('募集を終了しますか？'), findsOneWidget);
    expect(closed, isFalse);
    await tester.tap(find.text('終了する'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(find.text('募集終了'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('detail-participate-button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('delete requires confirmation', (tester) async {
    final post = _post(capacity: 3);
    var deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MainScreen(
          posts: [post],
          currentUserId: 'user-1',
          onAddPost: (_) {},
          onUpdatePost: (_) {},
          onDeletePost: (_) => deleted = true,
          onClosePost: (_) {},
          onToggleParticipate: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('昼ごはん'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('募集を管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();

    expect(find.text('募集を削除しますか？'), findsOneWidget);
    expect(deleted, isFalse);
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
    expect(find.text('募集一覧'), findsOneWidget);
  });
}

Post _post({required int capacity}) {
  final now = DateTime.now();
  return Post(
    id: 'post-1',
    authorId: 'user-1',
    title: '昼ごはん',
    place: '食堂',
    time: now.add(const Duration(hours: 2)),
    number: capacity,
    group: '全体',
    deadline: now.add(const Duration(hours: 1)),
    createdAt: now,
  );
}
