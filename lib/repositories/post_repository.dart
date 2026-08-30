import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/post.dart';

class PostRepository {
  static const boxName = 'posts';

  final Box<dynamic> _box;

  PostRepository(this._box);

  static Future<PostRepository> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return PostRepository(box);
  }

  List<Post> loadPosts() {
    final posts = <Post>[];
    for (final value in _box.values) {
      try {
        final json = Map<String, dynamic>.from(value as Map);
        posts.add(Post.fromJson(json));
      } on Object {
        // Skip malformed entries so one damaged record does not prevent launch.
      }
    }
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<void> savePost(Post post) => _box.put(post.id, post.toJson());

  Future<void> deletePost(String id) => _box.delete(id);
}
