import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'models/post.dart';
import 'repositories/post_repository.dart';
import 'screens/main_screen.dart';
import 'utils/app_messenger.dart';

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

  void _addPost(Post post) {
    setState(() => _posts.insert(0, post));
    _persistPost(post);
  }

  void _toggleParticipating(String id) {
    final post = _postById(id);
    if (post == null) return;

    var changed = false;
    setState(() {
      if (post.isParticipating(_currentUserId)) {
        changed = post.removeParticipant(_currentUserId);
      } else if (post.canToggleParticipation(_currentUserId, DateTime.now())) {
        changed = post.addParticipant(
          userId: _currentUserId,
          displayName: _currentUserName,
        );
      }
    });
    if (changed) _persistPost(post);
  }

  void _updatePost(Post updatedPost) {
    if (!_replacePost(updatedPost)) return;
    _persistPost(updatedPost);
  }

  void _deletePost(String id) {
    if (_postById(id) == null) return;
    setState(() => _posts.removeWhere((post) => post.id == id));
    unawaited(
      _runPersistence(
        widget.repository.deletePost(id),
        errorMessage: '募集の削除に失敗しました',
      ),
    );
  }

  void _closePost(String id) {
    final post = _postById(id);
    if (post == null || post.isManuallyClosed) return;
    final closedPost = post.copyWith(isManuallyClosed: true);
    _replacePost(closedPost);
    _persistPost(closedPost);
  }

  Post? _postById(String id) {
    return _posts.where((post) => post.id == id).firstOrNull;
  }

  bool _replacePost(Post updatedPost) {
    final index = _posts.indexWhere((post) => post.id == updatedPost.id);
    if (index == -1) return false;
    setState(() => _posts[index] = updatedPost);
    return true;
  }

  void _persistPost(Post post) {
    unawaited(
      _runPersistence(
        widget.repository.savePost(post),
        errorMessage: '募集の保存に失敗しました',
      ),
    );
  }

  Future<void> _runPersistence(
    Future<void> operation, {
    required String errorMessage,
  }) async {
    try {
      await operation;
    } on Object catch (error) {
      debugPrint('$errorMessage: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF16835B);
    const backgroundGray = Color(0xFFF4F6F5);
    return MaterialApp(
      scaffoldMessengerKey: appScaffoldMessengerKey,
      title: 'Himite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          surface: Colors.white,
          surfaceContainerLowest: Colors.white,
        ),
        scaffoldBackgroundColor: backgroundGray,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF17211D),
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Color(0xFF17211D),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F9F8),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E7E4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E7E4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryGreen, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
