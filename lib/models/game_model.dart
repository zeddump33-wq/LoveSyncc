class GameModel {
  final String id;
  final String coupleId;
  final String gameType;
  final String? player1Id;
  final String? player2Id;
  final int score1;
  final int score2;
  final String? data;
  final int isCompleted;
  final String createdAt;

  GameModel({
    required this.id,
    required this.coupleId,
    required this.gameType,
    this.player1Id,
    this.player2Id,
    this.score1 = 0,
    this.score2 = 0,
    this.data,
    this.isCompleted = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'coupleId': coupleId,
        'gameType': gameType,
        'player1Id': player1Id,
        'player2Id': player2Id,
        'score1': score1,
        'score2': score2,
        'data': data,
        'isCompleted': isCompleted,
        'createdAt': createdAt,
      };

  factory GameModel.fromMap(Map<String, dynamic> map) => GameModel(
        id: map['id'],
        coupleId: map['coupleId'],
        gameType: map['gameType'],
        player1Id: map['player1Id'],
        player2Id: map['player2Id'],
        score1: map['score1'] ?? 0,
        score2: map['score2'] ?? 0,
        data: map['data'],
        isCompleted: map['isCompleted'] ?? 0,
        createdAt: map['createdAt'],
      );
}
