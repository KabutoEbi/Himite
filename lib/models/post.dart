class Post {
  final String id;
  final String title;
  final String place;
  final DateTime time;
  final int number;
  final String group;
  final DateTime deadline;
  final DateTime createdAt;
  final Set<String> participantIds;
  final Map<String, String> participantNames;

  Post({
    required this.id,
    Set<String>? participantIds,
    Map<String, String>? participantNames,
    required this.title,
    required this.place,
    required this.time,
    required this.number,
    required this.group,
    required this.deadline,
    required this.createdAt,
  }) : participantIds = participantIds ?? <String>{},
       participantNames = participantNames ?? <String, String>{};

  int get participantCount => participantIds.length;

  bool get hasCapacity => number <= 0 || participantCount < number;

  bool isParticipating(String userId) => participantIds.contains(userId);

  bool addParticipant({required String userId, required String displayName}) {
    if (isParticipating(userId) || !hasCapacity) return false;
    participantIds.add(userId);
    participantNames[userId] = displayName;
    return true;
  }

  bool removeParticipant(String userId) {
    participantNames.remove(userId);
    return participantIds.remove(userId);
  }

  List<String> get participants => participantIds
      .map((id) => participantNames[id] ?? '名前未設定')
      .toList(growable: false);

  factory Post.create({
    required String title,
    required String place,
    required DateTime time,
    required int number,
    required String group,
    required DateTime deadline,
    Set<String>? participantIds,
    Map<String, String>? participantNames,
  }) {
    final now = DateTime.now();
    return Post(
      id: now.millisecondsSinceEpoch.toString(),
      participantIds: participantIds,
      participantNames: participantNames,
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
