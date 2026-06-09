class Post {
  final String id;
  final String title;
  final String place;
  final DateTime time;
  final int number;
  final String group;
  final DateTime deadline;
  final DateTime createdAt;
  bool isParticipating;

  Post({
    required this.id,
    this.isParticipating = false,
    required this.title,
    required this.place,
    required this.time,
    required this.number,
    required this.group,
    required this.deadline,
    required this.createdAt,
  });

  factory Post.create({
    required String title,
    required String place,
    required DateTime time,
    required int number,
    required String group,
    required DateTime deadline,
    bool isParticipating = false,
  }) {
    final now = DateTime.now();
    return Post(
      id: now.millisecondsSinceEpoch.toString(),
      isParticipating: isParticipating,
      title: title,
      place: place,
      time: time,
      number: number,
      group: group,
      deadline: deadline,
      createdAt: now,
    );
  }
}
