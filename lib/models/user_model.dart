class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String role; // 'student', 'staff', 'officer', 'admin'
  final String? profilePictureUrl;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    this.profilePictureUrl,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String? ?? 'student',
      profilePictureUrl: json['profile_picture_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'profile_picture_url': profilePictureUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

