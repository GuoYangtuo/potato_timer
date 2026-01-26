class User {
  final int id;
  final String phoneNumber;
  final String? nickname;
  final String? avatarUrl;

  User({
    required this.id,
    required this.phoneNumber,
    this.nickname,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      phoneNumber: json['phoneNumber'] as String,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
    };
  }

  User copyWith({
    int? id,
    String? phoneNumber,
    String? nickname,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}


