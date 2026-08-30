class Post {
  final String id;
  final String authorId;
  final String title;
  final String place;
  final DateTime time;
  final int number;
  final String group;
  final DateTime deadline;
  final DateTime createdAt;
  final bool isManuallyClosed;
  final Set<String> participantIds;
  final Map<String, String> participantNames;

  Post({
    required this.id,
    required this.authorId,
    Set<String>? participantIds,
    Map<String, String>? participantNames,
    required this.title,
    required this.place,
    required this.time,
    required this.number,
    required this.group,
    required this.deadline,
    required this.createdAt,
    this.isManuallyClosed = false,
  }) : participantIds = participantIds ?? <String>{},
       participantNames = participantNames ?? <String, String>{};

  int get participantCount => participantIds.length;

  bool get hasCapacity => number <= 0 || participantCount < number;

  bool isClosedAt(DateTime dateTime) =>
      isManuallyClosed || !dateTime.isBefore(deadline);

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
    required String authorId,
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
      authorId: authorId,
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

  Post copyWith({
    String? title,
    String? place,
    DateTime? time,
    int? number,
    String? group,
    DateTime? deadline,
    bool? isManuallyClosed,
  }) {
    return Post(
      id: id,
      authorId: authorId,
      title: title ?? this.title,
      place: place ?? this.place,
      time: time ?? this.time,
      number: number ?? this.number,
      group: group ?? this.group,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt,
      isManuallyClosed: isManuallyClosed ?? this.isManuallyClosed,
      participantIds: Set<String>.of(participantIds),
      participantNames: Map<String, String>.of(participantNames),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'title': title,
      'place': place,
      'time': time.toIso8601String(),
      'number': number,
      'group': group,
      'deadline': deadline.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isManuallyClosed': isManuallyClosed,
      'participantIds': participantIds.toList(),
      'participantNames': participantNames,
    };
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    final rawNames = json['participantNames'] as Map? ?? const {};
    return Post(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      title: json['title'] as String,
      place: json['place'] as String,
      time: DateTime.parse(json['time'] as String),
      number: json['number'] as int,
      group: json['group'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isManuallyClosed: json['isManuallyClosed'] as bool? ?? false,
      participantIds: (json['participantIds'] as List? ?? const [])
          .map((id) => id as String)
          .toSet(),
      participantNames: rawNames.map(
        (id, name) => MapEntry(id as String, name as String),
      ),
    );
  }
}
