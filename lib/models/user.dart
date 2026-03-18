// lib/models/user.dart

class User {
  final int? id;
  final String username;
  final String passwordHash; // never store plain-text passwords
  final String createdAt;

  User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'passwordHash': passwordHash,
        'createdAt': createdAt,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as int?,
        username: map['username'] as String,
        passwordHash: map['passwordHash'] as String,
        createdAt: map['createdAt'] as String,
      );
}
