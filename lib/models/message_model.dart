class MessageModel {
  final String id;
  final String coupleId;
  final String senderId;
  final String? text;
  final String? imagePath;
  final String? voicePath;
  final int? voiceDuration;
  final String? emoji;
  final String type;
  final String createdAt;
  final int isRead;
  final String? replyToId;
  final String? replyToText;
  final String? replyToType;

  MessageModel({
    required this.id,
    required this.coupleId,
    required this.senderId,
    this.text,
    this.imagePath,
    this.voicePath,
    this.voiceDuration,
    this.emoji,
    required this.type,
    required this.createdAt,
    this.isRead = 0,
    this.replyToId,
    this.replyToText,
    this.replyToType,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'coupleId': coupleId,
        'senderId': senderId,
        'text': text,
        'imagePath': imagePath,
        'voicePath': voicePath,
        'voiceDuration': voiceDuration,
        'emoji': emoji,
        'type': type,
        'createdAt': createdAt,
        'isRead': isRead,
        'replyToId': replyToId,
        'replyToText': replyToText,
        'replyToType': replyToType,
      };

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
        id: map['id'],
        coupleId: map['coupleId'],
        senderId: map['senderId'],
        text: map['text'],
        imagePath: map['imagePath'],
        voicePath: map['voicePath'],
        voiceDuration: map['voiceDuration'],
        emoji: map['emoji'],
        type: map['type'],
        createdAt: map['createdAt'],
        isRead: map['isRead'] ?? 0,
        replyToId: map['replyToId'],
        replyToText: map['replyToText'],
        replyToType: map['replyToType'],
      );
}
