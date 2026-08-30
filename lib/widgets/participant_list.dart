import 'package:flutter/material.dart';

class ParticipantList extends StatelessWidget {
  final List<String> participants;

  const ParticipantList({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('まだ参加者はいません'),
      );
    }

    Widget participantTile(String name) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(name),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: participants.map(participantTile).toList(growable: false),
    );
  }
}
