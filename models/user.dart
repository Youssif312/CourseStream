import 'dart:convert';

enum UserRole { admin, teacher, student }

class User {
  final String id;
  final String username;
  String passwordHash;
  final UserRole role;
  double balance;
  List<String> purchasedCourseIds;
  List<String> assignedCourseIds;

  User({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    this.balance = 0.0,
    List<String>? purchasedCourseIds,
    List<String>? assignedCourseIds,
  })  : purchasedCourseIds = purchasedCourseIds ?? [],
        assignedCourseIds = assignedCourseIds ?? [];

  bool get isAdmin => role == UserRole.admin;
  bool get isTeacher => role == UserRole.teacher;
  bool get isStudent => role == UserRole.student;

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'passwordHash': passwordHash,
    'role': role.name,
    'balance': balance,
    'purchasedCourseIds': purchasedCourseIds,
    'assignedCourseIds': assignedCourseIds,
  };

  static User fromJson(Map<String, dynamic> j) {
    UserRole role;
    if (j.containsKey('role')) {
      role = UserRole.values.firstWhere(
            (r) => r.name == j['role'],
        orElse: () => UserRole.student,
      );
    } else {
      role = (j['isAdmin'] == true) ? UserRole.admin : UserRole.student;
    }
    return User(
      id: j['id'],
      username: j['username'],
      passwordHash: j['passwordHash'],
      role: role,
      balance: (j['balance'] ?? 0.0) * 1.0,
      purchasedCourseIds: List<String>.from(j['purchasedCourseIds'] ?? []),
      assignedCourseIds: List<String>.from(j['assignedCourseIds'] ?? []),
    );
  }
}
