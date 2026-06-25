class WishlistModel {
  final String id;
  final String coupleId;
  final String title;
  final String? description;
  final double? price;
  final String? imagePath;
  final String? link;
  final int isReserved;
  final String? reservedBy;
  final int isPurchased;
  final String createdAt;
  final String createdBy;

  WishlistModel({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    this.price,
    this.imagePath,
    this.link,
    this.isReserved = 0,
    this.reservedBy,
    this.isPurchased = 0,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'coupleId': coupleId,
        'title': title,
        'description': description,
        'price': price,
        'imagePath': imagePath,
        'link': link,
        'isReserved': isReserved,
        'reservedBy': reservedBy,
        'isPurchased': isPurchased,
        'createdAt': createdAt,
        'createdBy': createdBy,
      };

  factory WishlistModel.fromMap(Map<String, dynamic> map) => WishlistModel(
        id: map['id'],
        coupleId: map['coupleId'],
        title: map['title'],
        description: map['description'],
        price: map['price'],
        imagePath: map['imagePath'],
        link: map['link'],
        isReserved: map['isReserved'] ?? 0,
        reservedBy: map['reservedBy'],
        isPurchased: map['isPurchased'] ?? 0,
        createdAt: map['createdAt'],
        createdBy: map['createdBy'],
      );
}
