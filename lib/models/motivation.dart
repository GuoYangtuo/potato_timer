enum MotivationType { positive, negative }

class MediaItem {
  final int id;
  final String type; // 'image' or 'video'
  final String url;
  final String? thumbnailUrl;

  MediaItem({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnailUrl,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as int,
      type: json['type'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

class Author {
  final int id;
  final String? nickname;
  final String? avatarUrl;

  Author({
    required this.id,
    this.nickname,
    this.avatarUrl,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] as int,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class Motivation {
  final int id;
  final String? title;
  final String? content;
  final MotivationType type;
  final bool isPublic;
  final int viewCount;
  final int likeCount;
  final DateTime createdAt;
  final Author? author;
  final List<MediaItem> media;
  final List<String> tags;
  final bool isLiked;
  final bool isFavorited;

  Motivation({
    required this.id,
    this.title,
    this.content,
    required this.type,
    this.isPublic = false,
    this.viewCount = 0,
    this.likeCount = 0,
    required this.createdAt,
    this.author,
    this.media = const [],
    this.tags = const [],
    this.isLiked = false,
    this.isFavorited = false,
  });

  factory Motivation.fromJson(Map<String, dynamic> json) {
    return Motivation(
      id: json['id'] as int,
      title: json['title'] as String?,
      content: json['content'] as String?,
      type: json['type'] == 'positive' 
          ? MotivationType.positive 
          : MotivationType.negative,
      isPublic: _parseBool(json['isPublic']),
      viewCount: json['viewCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      author: json['author'] != null 
          ? Author.fromJson(json['author'] as Map<String, dynamic>) 
          : null,
      media: (json['media'] as List<dynamic>?)
          ?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      isLiked: _parseBool(json['isLiked']),
      isFavorited: _parseBool(json['isFavorited']),
    );
  }

  /// 解析 bool 值，兼容 MySQL 返回的 0/1 和 true/false
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type == MotivationType.positive ? 'positive' : 'negative',
      'isPublic': isPublic,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'createdAt': createdAt.toIso8601String(),
      'media': media.map((e) => e.toJson()).toList(),
      'tags': tags,
      'isLiked': isLiked,
      'isFavorited': isFavorited,
    };
  }

  Motivation copyWith({
    int? id,
    String? title,
    String? content,
    MotivationType? type,
    bool? isPublic,
    int? viewCount,
    int? likeCount,
    DateTime? createdAt,
    Author? author,
    List<MediaItem>? media,
    List<String>? tags,
    bool? isLiked,
    bool? isFavorited,
  }) {
    return Motivation(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      isPublic: isPublic ?? this.isPublic,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
      media: media ?? this.media,
      tags: tags ?? this.tags,
      isLiked: isLiked ?? this.isLiked,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }
}


