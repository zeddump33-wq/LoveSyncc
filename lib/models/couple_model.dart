class CoupleModel {
  final String id;
  final String partner1Id;
  final String? partner2Id;
  final String? anniversaryDate;
  final String status;
  final String? inviteCode;
  final String createdAt;
  final String updatedAt;

  CoupleModel({
    required this.id,
    required this.partner1Id,
    this.partner2Id,
    this.anniversaryDate,
    required this.status,
    this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'partner1Id': partner1Id,
        'partner2Id': partner2Id,
        'anniversaryDate': anniversaryDate,
        'status': status,
        'inviteCode': inviteCode,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory CoupleModel.fromMap(Map<String, dynamic> map) => CoupleModel(
        id: map['id'],
        partner1Id: map['partner1Id'],
        partner2Id: map['partner2Id'],
        anniversaryDate: map['anniversaryDate'],
        status: map['status'],
        inviteCode: map['inviteCode'],
        createdAt: map['createdAt'],
        updatedAt: map['updatedAt'],
      );
}
