import 'package:flutter/material.dart';

class PostStatusChip extends StatelessWidget {
  final bool isClosed;
  final bool isFull;

  const PostStatusChip({
    super.key,
    required this.isClosed,
    required this.isFull,
  });

  @override
  Widget build(BuildContext context) {
    final label = isClosed
        ? '募集終了'
        : isFull
        ? '満員'
        : '募集中';
    final color = isClosed || isFull ? Colors.grey : Colors.green;

    return Chip(
      label: Text(label),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}
