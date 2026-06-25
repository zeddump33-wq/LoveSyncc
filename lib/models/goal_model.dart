class GoalModel {
  final String id;
  final String coupleId;
  final String title;
  final String? description;
  final String type;
  final double? targetValue;
  final double currentValue;
  final String? targetDate;
  final int isCompleted;
  final String createdAt;
  final String createdBy;

  GoalModel({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    this.type = 'savings',
    this.targetValue,
    this.currentValue = 0,
    this.targetDate,
    this.isCompleted = 0,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'coupleId': coupleId,
        'title': title,
        'description': description,
        'type': type,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'targetDate': targetDate,
        'isCompleted': isCompleted,
        'createdAt': createdAt,
        'createdBy': createdBy,
      };

  factory GoalModel.fromMap(Map<String, dynamic> map) => GoalModel(
        id: map['id'],
        coupleId: map['coupleId'],
        title: map['title'],
        description: map['description'],
        type: map['type'],
        targetValue: map['targetValue'],
        currentValue: map['currentValue'] ?? 0,
        targetDate: map['targetDate'],
        isCompleted: map['isCompleted'] ?? 0,
        createdAt: map['createdAt'],
        createdBy: map['createdBy'],
      );

  double get progress {
    if (targetValue == null || targetValue == 0) return 0;
    return (currentValue / targetValue!).clamp(0.0, 1.0);
  }
}

class GoalStepModel {
  final String id;
  final String goalId;
  final String title;
  final int isCompleted;
  final String createdAt;

  GoalStepModel({
    required this.id,
    required this.goalId,
    required this.title,
    this.isCompleted = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'goalId': goalId,
        'title': title,
        'isCompleted': isCompleted,
        'createdAt': createdAt,
      };

  factory GoalStepModel.fromMap(Map<String, dynamic> map) => GoalStepModel(
        id: map['id'],
        goalId: map['goalId'],
        title: map['title'],
        isCompleted: map['isCompleted'] ?? 0,
        createdAt: map['createdAt'],
      );
}
