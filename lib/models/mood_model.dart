class MoodModel {
  final String id;
  final String userId;
  final String mood;
  final String? note;
  final String date;
  final String createdAt;

  MoodModel({
    required this.id,
    required this.userId,
    required this.mood,
    this.note,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'mood': mood,
        'note': note,
        'date': date,
        'createdAt': createdAt,
      };

  factory MoodModel.fromMap(Map<String, dynamic> map) => MoodModel(
        id: map['id'],
        userId: map['userId'],
        mood: map['mood'],
        note: map['note'],
        date: map['date'],
        createdAt: map['createdAt'],
      );
}

class CheckInModel {
  final String id;
  final String coupleId;
  final String question;
  final String? answer;
  final String userId;
  final String date;
  final String createdAt;

  CheckInModel({
    required this.id,
    required this.coupleId,
    required this.question,
    this.answer,
    required this.userId,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'coupleId': coupleId,
        'question': question,
        'answer': answer,
        'userId': userId,
        'date': date,
        'createdAt': createdAt,
      };

  factory CheckInModel.fromMap(Map<String, dynamic> map) => CheckInModel(
        id: map['id'],
        coupleId: map['coupleId'],
        question: map['question'],
        answer: map['answer'],
        userId: map['userId'],
        date: map['date'],
        createdAt: map['createdAt'],
      );
}
