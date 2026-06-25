class LoveNoteModel {
  final String id;
  final String coupleId;
  final String senderId;
  final String title;
  final String content;
  final String type;
  final String? scheduledDate;
  final int isDelivered;
  final int isFavorite;
  final String createdAt;

  LoveNoteModel({
    required this.id,
    required this.coupleId,
    required this.senderId,
    required this.title,
    required this.content,
    this.type = 'note',
    this.scheduledDate,
    this.isDelivered = 1,
    this.isFavorite = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'coupleId': coupleId,
        'senderId': senderId,
        'title': title,
        'content': content,
        'type': type,
        'scheduledDate': scheduledDate,
        'isDelivered': isDelivered,
        'isFavorite': isFavorite,
        'createdAt': createdAt,
      };

  factory LoveNoteModel.fromMap(Map<String, dynamic> map) => LoveNoteModel(
        id: map['id'],
        coupleId: map['coupleId'],
        senderId: map['senderId'],
        title: map['title'],
        content: map['content'],
        type: map['type'],
        scheduledDate: map['scheduledDate'],
        isDelivered: map['isDelivered'] ?? 1,
        isFavorite: map['isFavorite'] ?? 0,
        createdAt: map['createdAt'],
      );
}
