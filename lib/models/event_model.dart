class EventModel {
  final String id;
  final String coupleId;
  final String title;
  final String? description;
  final String date;
  final String? endDate;
  final String type;
  final int reminderEnabled;
  final String createdAt;
  final String createdBy;

  EventModel({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    required this.date,
    this.endDate,
    this.type = 'custom',
    this.reminderEnabled = 1,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'coupleId': coupleId,
        'title': title,
        'description': description,
        'date': date,
        'endDate': endDate,
        'type': type,
        'reminderEnabled': reminderEnabled,
        'createdAt': createdAt,
        'createdBy': createdBy,
      };

  factory EventModel.fromMap(Map<String, dynamic> map) => EventModel(
        id: map['id'],
        coupleId: map['coupleId'],
        title: map['title'],
        description: map['description'],
        date: map['date'],
        endDate: map['endDate'],
        type: map['type'],
        reminderEnabled: map['reminderEnabled'] ?? 1,
        createdAt: map['createdAt'],
        createdBy: map['createdBy'],
      );
}
