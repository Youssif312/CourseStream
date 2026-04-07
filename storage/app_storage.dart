import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AppStorage {
  static late SharedPreferences _prefs;

  static const _usersKey   = 'app_users_v2';
  static const _coursesKey = 'app_courses_v1';
  static const _codesKey   = 'app_codes_v1';

  static String _simpleHash(String s) => base64Encode(utf8.encode(s));

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    if (!_prefs.containsKey(_usersKey)) {
      final admin = User(
        id: 'admin-1',
        username: 'admin',
        passwordHash: _simpleHash('admin123'),
        role: UserRole.admin,
      );
      _prefs.setString(_usersKey, jsonEncode([admin.toJson()]));
    }

    if (!_prefs.containsKey(_coursesKey)) {
      final c1 = Course(
        id: 'c1',
        title: 'Intro to Dart',
        description: 'Learn the basics of Dart programming.',
        price: 50.0,
        videoUrl: 'https://youtu.be/lX29yGCBqak?si=NjbgGGkKtNBH77P5',
      );
      final c2 = Course(
        id: 'c2',
        title: 'Flutter Widgets',
        description: 'Build beautiful UIs using Flutter widgets.',
        price: 75.0,
        videoUrl: 'https://youtu.be/fq4N0hgOWzU?si=R0EV6GfRWj3xB7cS',
      );
      _prefs.setString(_coursesKey, jsonEncode([c1.toJson(), c2.toJson()]));
    }

    if (!_prefs.containsKey(_codesKey)) {
      _prefs.setString(_codesKey, jsonEncode([]));
    }
  }

  static List<User> loadUsers() {
    final raw = _prefs.getString(_usersKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => User.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<Course> loadCourses() {
    final raw = _prefs.getString(_coursesKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Course.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<PaymentCode> loadCodes() {
    final raw = _prefs.getString(_codesKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => PaymentCode.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> saveUsers(List<User> users) async =>
      _prefs.setString(
          _usersKey, jsonEncode(users.map((e) => e.toJson()).toList()));

  static Future<void> saveCourses(List<Course> courses) async =>
      _prefs.setString(
          _coursesKey, jsonEncode(courses.map((e) => e.toJson()).toList()));

  static Future<void> saveCodes(List<PaymentCode> codes) async =>
      _prefs.setString(
          _codesKey, jsonEncode(codes.map((e) => e.toJson()).toList()));
}
