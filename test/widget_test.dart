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
          onToggleParticipate: (_) {},
        ),
      ),
    );

    expect(find.text('参加 1/3人'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('participants-${post.id}')));
    await tester.pumpAndSettle();

    expect(find.text('参加者（1人）'), findsOneWidget);
    expect(find.text('あなた'), findsOneWidget);
  });

  testWidgets('opens details and allows participation', (tester) async {
    final post = _post(capacity: 3);

    await tester.pumpWidget(
      MaterialApp(
        home: MainScreen(
          posts: [post],
          currentUserId: 'user-1',
          onAddPost: (_) {},
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
}

Post _post({required int capacity}) {
  final now = DateTime.now();
  return Post(
    id: 'post-1',
    title: '昼ごはん',
    place: '食堂',
    time: now.add(const Duration(hours: 2)),
    number: capacity,
    group: '全体',
    deadline: now.add(const Duration(hours: 1)),
    createdAt: now,
  );
}
