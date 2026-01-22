/// User model for IntelCrypt messaging application
class User {
  final String id;
  final String username;
  final String email;
  final String? profileImageUrl;
  final List<String> roles;
  final String clearanceLevel;
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    required this.roles,
    required this.clearanceLevel,
    this.isOnline = false,
    required this.lastSeen,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      roles: List<String>.from(json['roles'] as List? ?? []),
      clearanceLevel: json['clearanceLevel'] as String? ?? 'LOW',
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Create an empty user placeholder
  factory User.empty() {
    return User(
      id: '',
      username: 'Unknown',
      email: '',
      roles: [],
      clearanceLevel: 'LOW',
      lastSeen: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'roles': roles,
      'clearanceLevel': clearanceLevel,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? profileImageUrl,
    List<String>? roles,
    String? clearanceLevel,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      roles: roles ?? this.roles,
      clearanceLevel: clearanceLevel ?? this.clearanceLevel,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ username.hashCode ^ email.hashCode;

  @override
  String toString() => 'User(id: $id, username: $username, email: $email)';
}
