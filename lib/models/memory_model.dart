class MemoryModel {
  final String id;
  final String coupleId;
  final String? albumId;
  final String? imagePath;
  final String? caption;
  final String date;
  final int isFavorite;
  final String createdAt;

  MemoryModel({
    required this.id,
    required this.coupleId,
    this.albumId,
    this.imagePath,
    this.caption,
    required this.date,
    this.isFavorite = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'coupleId': coupleId,
        'albumId': albumId,
        'imagePath': imagePath,
        'caption': caption,
        'date': date,
        'isFavorite': isFavorite,
        'createdAt': createdAt,
      };

  factory MemoryModel.fromMap(Map<String, dynamic> map) => MemoryModel(
        id: map['id'],
        coupleId: map['coupleId'],
        albumId: map['albumId'],
        imagePath: map['imagePath'],
        caption: map['caption'],
        date: map['date'],
        isFavorite: map['isFavorite'] ?? 0,
        createdAt: map['createdAt'],
      );
}

class MemoryAlbumModel {
  final String id;
  final String coupleId;
  final String name;
  final String? coverImagePath;
  final String createdAt;

  MemoryAlbumModel({
    required this.id,
    required this.coupleId,
    required this.name,
    this.coverImagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'coupleId': coupleId,
        'name': name,
        'coverImagePath': coverImagePath,
        'createdAt': createdAt,
      };

  factory MemoryAlbumModel.fromMap(Map<String, dynamic> map) =>
      MemoryAlbumModel(
        id: map['id'],
        coupleId: map['coupleId'],
        name: map['name'],
        coverImagePath: map['coverImagePath'],
        createdAt: map['createdAt'],
      );
}
