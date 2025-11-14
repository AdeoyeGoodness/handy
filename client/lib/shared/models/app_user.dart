class AppUser {
  AppUser({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.email,
    this.avatarUrl,
    this.bio,
    this.ratingAvg,
  });

  final int id;
  final String phone;
  final String firstName;
  final String lastName;
  final String role;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final double? ratingAvg;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      phone: json['phone'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      role: json['role'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'avatar_url': avatarUrl,
      'bio': bio,
      'rating_avg': ratingAvg,
    };
  }

  String get fullName => '$firstName $lastName';
}

