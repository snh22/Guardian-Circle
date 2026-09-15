/// Matches the JSON shape returned by GET /api/v1/users/me and
/// GET /api/v1/users/{user_id} in the real backend:
/// { "user_id": 1, "name": "...", "email": "...", "role": "caretaker" }
class AppUser {
  final int userId;
  final String name;
  final String email;
  final String role;

  const AppUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      userId: json['user_id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }
}