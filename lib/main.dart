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
        _posts[i].isParticipating = !_posts[i].isParticipating;
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
      home: MainScreen(posts: _posts, onAddPost: _addPost, onToggleParticipate: _toggleParticipating),
    );
  }
}
