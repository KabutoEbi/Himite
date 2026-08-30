import 'package:flutter/material.dart';

import 'models/post.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _currentUserId = 'local-user';
  static const _currentUserName = 'あなた';
  final List<Post> _posts = [];

  void _addPost(Post p) {
    setState(() {
      _posts.insert(0, p);
    });
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
  }

  void _updatePost(Post updatedPost) {
    setState(() {
      final index = _posts.indexWhere((post) => post.id == updatedPost.id);
      if (index != -1) _posts[index] = updatedPost;
    });
  }

  void _deletePost(String id) {
    setState(() => _posts.removeWhere((post) => post.id == id));
  }

  void _closePost(String id) {
    setState(() {
      final index = _posts.indexWhere((post) => post.id == id);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(isManuallyClosed: true);
      }
    });
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
