import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../storage/app_storage.dart';

class AppProvider extends ChangeNotifier {
  User? _currentUser;
  List<User>        users   = [];
  List<Course>      courses = [];
  List<PaymentCode> codes   = [];

  AppProvider() {
    _loadAll();
    _secureScreen();
  }

  Future<void> _secureScreen() async {
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }

  void _loadAll() {
    users   = AppStorage.loadUsers();
    courses = AppStorage.loadCourses();
    codes   = AppStorage.loadCodes();
    notifyListeners();
  }

  String _hash(String s) => base64Encode(utf8.encode(s));

  User? login(String username, String password) {
    final h = _hash(password);
    try {
      final u = users.firstWhere(
              (u) => u.username == username && u.passwordHash == h);
      _currentUser = u;
      notifyListeners();
      return u;
    } catch (_) {
      return null;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  User? get currentUser => _currentUser;

  List<User> get students => users.where((u) => u.isStudent).toList();
  List<User> get teachers => users.where((u) => u.isTeacher).toList();

  Future<bool> _addUser(
      String username,
      String password,
      UserRole role, {
        List<String> assignedCourseIds = const [],
      }) async {
    if (users.any((u) => u.username == username)) return false;
    users.add(User(
      id: const Uuid().v4(),
      username: username,
      passwordHash: base64Encode(utf8.encode(password)),
      role: role,
      assignedCourseIds: List<String>.from(assignedCourseIds),
    ));
    await AppStorage.saveUsers(users);
    notifyListeners();
    return true;
  }

  Future<bool> addStudent(String username, String password) =>
      _addUser(username, password, UserRole.student);

  Future<bool> addTeacher(
      String username,
      String password,
      List<String> assignedCourseIds,
      ) =>
      _addUser(username, password, UserRole.teacher,
          assignedCourseIds: assignedCourseIds);

  Future<bool> removeUser(String userId) async {
    final index = users.indexWhere((u) => u.id == userId && !u.isAdmin);
    if (index == -1) return false;
    users.removeAt(index);
    await AppStorage.saveUsers(users);
    notifyListeners();
    return true;
  }

  Future<void> updateTeacherCourses(
      String teacherId, List<String> courseIds) async {
    final t = users.firstWhere((u) => u.id == teacherId);
    t.assignedCourseIds
      ..clear()
      ..addAll(courseIds);
    await AppStorage.saveUsers(users);
    notifyListeners();
  }

  Future<void> purchaseCourse(Course course) async {
    final user = _currentUser!;
    user.balance -= course.price;
    user.purchasedCourseIds.add(course.id);
    await AppStorage.saveUsers(users);
    notifyListeners();
  }

  Future<void> updatePassword(String newPassword) async {
    _currentUser!.passwordHash = base64Encode(utf8.encode(newPassword));
    await AppStorage.saveUsers(users);
    notifyListeners();
  }

  Future<double?> redeemCode(String code) async {
    final pcIndex = codes.indexWhere((x) => x.code == code);
    if (pcIndex == -1) return null;
    final pc = codes[pcIndex];
    if (pc.used) return null;
    pc.used   = true;
    pc.usedBy = _currentUser!.username;
    pc.usedAt = DateTime.now().toIso8601String();
    _currentUser!.balance += pc.amount;
    await AppStorage.saveCodes(codes);
    await AppStorage.saveUsers(users);
    notifyListeners();
    return pc.amount;
  }

  Future<void> addCourse(Course course) async {
    courses.add(course);
    await AppStorage.saveCourses(courses);
    notifyListeners();
  }

  Future<PaymentCode> generateCode(double amount) async {
    final code = PaymentCode(
      code: const Uuid().v4().substring(0, 8),
      amount: amount,
      createdAt: DateTime.now().toIso8601String(),
    );
    codes.add(code);
    await AppStorage.saveCodes(codes);
    notifyListeners();
    return code;
  }
}
