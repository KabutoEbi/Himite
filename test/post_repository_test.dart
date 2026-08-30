import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:himite/models/post.dart';
import 'package:himite/repositories/post_repository.dart';

void main() {
  late Directory temporaryDirectory;

  setUpAll(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'himite_repository_test_',
    );
    Hive.init(temporaryDirectory.path);
  });

  tearDown(() async {
    if (Hive.isBoxOpen(PostRepository.boxName)) {
      await Hive.box<dynamic>(PostRepository.boxName).close();
    }
    await Hive.deleteBoxFromDisk(PostRepository.boxName);
  });

  tearDownAll(() async {
    await Hive.close();
    await temporaryDirectory.delete(recursive: true);
  });

  test('persists and restores every Post field', () async {
    final repository = await PostRepository.open();
    final post = _post()..addParticipant(userId: 'user-2', displayName: '友達');

    await repository.savePost(post);
    await Hive.box<dynamic>(PostRepository.boxName).close();

    final reopenedRepository = await PostRepository.open();
    final restored = reopenedRepository.loadPosts().single;

    expect(restored.id, post.id);
    expect(restored.authorId, post.authorId);
    expect(restored.title, post.title);
    expect(restored.place, post.place);
    expect(restored.time, post.time);
    expect(restored.number, post.number);
    expect(restored.group, post.group);
    expect(restored.deadline, post.deadline);
    expect(restored.createdAt, post.createdAt);
    expect(restored.isManuallyClosed, isTrue);
    expect(restored.participantIds, {'user-2'});
    expect(restored.participantNames, {'user-2': '友達'});
  });

  test('deletes a persisted post', () async {
    final repository = await PostRepository.open();
    final post = _post();
    await repository.savePost(post);

    await repository.deletePost(post.id);

    expect(repository.loadPosts(), isEmpty);
  });
}

Post _post() {
  final createdAt = DateTime(2026, 8, 30, 10);
  return Post(
    id: 'post-1',
    authorId: 'user-1',
    title: '昼ごはん',
    place: '食堂',
    time: DateTime(2026, 8, 31, 12),
    number: 4,
    group: '大学の友達',
    deadline: DateTime(2026, 8, 31, 11),
    createdAt: createdAt,
    isManuallyClosed: true,
  );
}
