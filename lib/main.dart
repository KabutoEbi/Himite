import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'models/post.dart';
import 'repositories/post_repository.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final repository = await PostRepository.open();
  runApp(MyApp(repository: repository, initialPosts: repository.loadPosts()));
}

class MyApp extends StatefulWidget {
  final PostRepository repository;
  final List<Post> initialPosts;

  const MyApp({
    super.key,
    required this.repository,
    this.initialPosts = const [],
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _currentUserId = 'local-user';
  static const _currentUserName = 'あなた';
  late final List<Post> _posts;

  @override
  void initState() {
    super.initState();
    _posts = List<Post>.of(widget.initialPosts);
  }

  void _addPost(Post p) {
    setState(() {
      _posts.insert(0, p);
    });
    unawaited(_savePost(p));
  }

  void _toggleParticipating(String id) {
    setState(() {
      final i = _posts.indexWhere((p) => p.id == id);
      if (i != -1) {
        final post = _posts[i];
        if (post.isParticipating(_currentUserId)) {
          post.removeParticipant(_currentUserId);
        } else if (!post.isClosedAt(DateTime.now())) {
          post.addParticipant(
            userId: _currentUserId,
            displayName: _currentUserName,
          );
        }
      }
    });
    final post = _posts.where((post) => post.id == id).firstOrNull;
    if (post != null) unawaited(_savePost(post));
  }

  void _updatePost(Post updatedPost) {
    setState(() {
      final index = _posts.indexWhere((post) => post.id == updatedPost.id);
      if (index != -1) _posts[index] = updatedPost;
    });
    unawaited(_savePost(updatedPost));
  }

  void _deletePost(String id) {
    setState(() => _posts.removeWhere((post) => post.id == id));
    unawaited(_deleteSavedPost(id));
  }

  void _closePost(String id) {
    setState(() {
      final index = _posts.indexWhere((post) => post.id == id);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(isManuallyClosed: true);
      }
    });
    final post = _posts.where((post) => post.id == id).firstOrNull;
    if (post != null) unawaited(_savePost(post));
  }

  Future<void> _savePost(Post post) async {
    try {
      await widget.repository.savePost(post);
    } on Object catch (error) {
      debugPrint('募集の保存に失敗しました: $error');
    }
  }

  Future<void> _deleteSavedPost(String id) async {
    try {
      await widget.repository.deletePost(id);
    } on Object catch (error) {
      debugPrint('募集の削除に失敗しました: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Himite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MainScreen(
        posts: _posts,
        currentUserId: _currentUserId,
        onAddPost: _addPost,
        onUpdatePost: _updatePost,
        onDeletePost: _deletePost,
        onClosePost: _closePost,
        onToggleParticipate: _toggleParticipating,
      ),
    );
  }
}
