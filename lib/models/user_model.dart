class UserModel {
  final String id;
  final String name;
  final String? email;
  final String? photoPath;
  final String? partnerId;
  final String? coupleId;
  final String? inviteCode;
  final String createdAt;
  final String updatedAt;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.photoPath,
    this.partnerId,
    this.coupleId,
    this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'photoPath': photoPath,
        'partnerId': partnerId,
        'coupleId': coupleId,
        'inviteCode': inviteCode,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'],
        name: map['name'],
        email: map['email'],
        photoPath: map['photoPath'],
        partnerId: map['partnerId'],
        coupleId: map['coupleId'],
        inviteCode: map['inviteCode'],
        createdAt: map['createdAt'],
        updatedAt: map['updatedAt'],
      );
}
