class MilestoneModel {
  final String id;
  final String coupleId;
  final String title;
  final String? description;
  final String date;
  final String? icon;
  final String createdAt;

  MilestoneModel({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    required this.date,
    this.icon,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'coupleId': coupleId,
        'title': title,
        'description': description,
        'date': date,
        'icon': icon,
        'createdAt': createdAt,
      };

  factory MilestoneModel.fromMap(Map<String, dynamic> map) => MilestoneModel(
        id: map['id'],
        coupleId: map['coupleId'],
        title: map['title'],
        description: map['description'],
        date: map['date'],
        icon: map['icon'],
        createdAt: map['createdAt'],
      );
}
