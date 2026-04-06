import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'videoplayer.dart';

// ------------------------- Enums -------------------------
enum UserRole { admin, teacher, student }

// ------------------------- Models -------------------------
class User {
  final String id;
  final String username;
  String passwordHash;
  final UserRole role;
  double balance;
  List<String> purchasedCourseIds; // students: bought courses
  List<String> assignedCourseIds;  // teachers: courses they teach

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

  bool get isAdmin   => role == UserRole.admin;
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
    // Backwards-compat: old data used isAdmin bool instead of role string
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

class Course {
  final String id;
  final String title;
  final String description;
  final double price;
  final String videoUrl;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.videoUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'videoUrl': videoUrl,
  };

  static Course fromJson(Map<String, dynamic> j) => Course(
    id: j['id'],
    title: j['title'],
    description: j['description'],
    price: (j['price'] ?? 0.0) * 1.0,
    videoUrl: j['videoUrl'],
  );
}

class PaymentCode {
  final String code;
  final double amount;
  bool used;
  String? usedBy;
  String createdAt;
  String? usedAt;

  PaymentCode({
    required this.code,
    required this.amount,
    this.used = false,
    this.usedBy,
    required this.createdAt,
    this.usedAt,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'amount': amount,
    'used': used,
    'usedBy': usedBy,
    'createdAt': createdAt,
    'usedAt': usedAt,
  };

  static PaymentCode fromJson(Map<String, dynamic> j) => PaymentCode(
    code: j['code'],
    amount: (j['amount'] ?? 0.0) * 1.0,
    used: j['used'] ?? false,
    usedBy: j['usedBy'],
    createdAt: j['createdAt'],
    usedAt: j['usedAt'],
  );
}

// ------------------------- Storage -------------------------
class AppStorage {
  static late SharedPreferences _prefs;
  // Bump to v2 so old isAdmin-bool data does not conflict
  static const _usersKey   = 'app_users_v2';
  static const _coursesKey = 'app_courses_v1';
  static const _codesKey   = 'app_codes_v1';

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

  static String _simpleHash(String s) => base64Encode(utf8.encode(s));

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

// ------------------------- Provider -------------------------
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

  // ── Convenience getters ──────────────────────────────────────
  List<User> get students => users.where((u) => u.isStudent).toList();
  List<User> get teachers => users.where((u) => u.isTeacher).toList();

  // ── User management ──────────────────────────────────────────

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

  /// Removes any non-admin user.
  Future<bool> removeUser(String userId) async {
    final index = users.indexWhere((u) => u.id == userId && !u.isAdmin);
    if (index == -1) return false;
    users.removeAt(index);
    await AppStorage.saveUsers(users);
    notifyListeners();
    return true;
  }

  /// Updates the list of courses assigned to a teacher.
  Future<void> updateTeacherCourses(
      String teacherId, List<String> courseIds) async {
    final t = users.firstWhere((u) => u.id == teacherId);
    t.assignedCourseIds
      ..clear()
      ..addAll(courseIds);
    await AppStorage.saveUsers(users);
    notifyListeners();
  }

  // ── Student actions ──────────────────────────────────────────

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

  /// Returns redeemed amount, or null if code is invalid/used.
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

  // ── Course management ────────────────────────────────────────

  Future<void> addCourse(Course course) async {
    courses.add(course);
    await AppStorage.saveCourses(courses);
    notifyListeners();
  }

  // ── Payment codes ────────────────────────────────────────────

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

// ========================= UI =========================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.init();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Courses App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[100],
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.indigo),
            ),
            labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        home: const LoginPage(),
      ),
    );
  }
}

// ─────────────────────────── Helpers ───────────────────────────

void _doLogout(BuildContext context) {
  Provider.of<AppProvider>(context, listen: false).logout();
  Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const LoginPage()));
}

Widget _roleBadge(UserRole role) {
  final (label, color) = switch (role) {
    UserRole.admin   => ('Admin',   Colors.red),
    UserRole.teacher => ('Teacher', Colors.teal),
    UserRole.student => ('Student', Colors.indigo),
  };
  return Chip(
    label: Text(label,
        style: const TextStyle(color: Colors.white, fontSize: 11)),
    backgroundColor: color,
    padding: EdgeInsets.zero,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

// ─────────────────────────── Login Page ────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AppProvider>(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 70, color: Colors.indigo),
                  const SizedBox(height: 16),
                  const Text('Welcome Back',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Login to your account',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  TextField(
                      controller: _userCtrl,
                      decoration:
                      const InputDecoration(labelText: 'Username')),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration:
                      const InputDecoration(labelText: 'Password')),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Login'),
                    onPressed: () {
                      final u =
                      prov.login(_userCtrl.text.trim(), _passCtrl.text);
                      if (u == null) {
                        setState(() =>
                        _error = 'Invalid username or password');
                        return;
                      }
                      final dest = switch (u.role) {
                        UserRole.admin   => const AdminHome(),
                        UserRole.teacher => const TeacherHome(),
                        UserRole.student => const StudentHome(),
                      };
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => dest));
                    },
                  ),
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_error,
                          style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Student Home ──────────────────────
class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _newPassCtrl = TextEditingController();
  final _redeemCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _newPassCtrl.dispose();
    _redeemCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AppProvider>(context);
    final user = prov.currentUser!;
    final myCourses = prov.courses
        .where((c) => user.purchasedCourseIds.contains(c.id))
        .toList();
    final available = prov.courses
        .where((c) => !user.purchasedCourseIds.contains(c.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.username}!'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: () => _doLogout(context)),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.book),      text: 'My Courses'),
            Tab(icon: Icon(Icons.menu_book), text: 'Available'),
            Tab(icon: Icon(Icons.person),    text: 'Profile'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ---- My Courses ----
          myCourses.isEmpty
              ? const Center(
              child: Text("You haven't purchased any courses yet."))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: myCourses.length,
            itemBuilder: (_, i) {
              final c = myCourses[i];
              return _CourseCard(
                course: c,
                trailing: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => VideoPlayerPage(
                                videoUrl: c.videoUrl,
                                title: c.title)));
                    await SystemChrome.setPreferredOrientations(
                        [DeviceOrientation.portraitUp]);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green),
                  child: const Text('Watch'),
                ),
              );
            },
          ),

          // ---- Available ----
          available.isEmpty
              ? const Center(child: Text('No available courses to buy.'))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: available.length,
            itemBuilder: (_, i) {
              final c = available[i];
              return _CourseCard(
                course: c,
                trailing: ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (user.balance < c.price) {
                      messenger.showSnackBar(const SnackBar(
                          content: Text(
                              'Insufficient balance. Please redeem a code.')));
                      return;
                    }
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Purchase'),
                        content: Text(
                            'Buy "${c.title}" for \$${c.price.toStringAsFixed(2)}?'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, true),
                              child: const Text('Confirm')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await prov.purchaseCourse(c);
                      messenger.showSnackBar(SnackBar(
                          content: Text(
                              'You purchased "${c.title}" successfully!')));
                    }
                  },
                  child: Text('\$${c.price.toStringAsFixed(2)}'),
                ),
              );
            },
          ),

          // ---- Profile ----
          _ProfileTab(
            user: user,
            prov: prov,
            newPassCtrl: _newPassCtrl,
            redeemCtrl: _redeemCtrl,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Teacher Home ──────────────────────
class TeacherHome extends StatefulWidget {
  const TeacherHome({super.key});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _titleCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _priceCtrl   = TextEditingController();
  final _urlCtrl     = TextEditingController();
  final _newPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _urlCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  void _addCourse(AppProvider prov) async {
    final title     = _titleCtrl.text.trim();
    final desc      = _descCtrl.text.trim();
    final price     = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final url       = _urlCtrl.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (title.isEmpty || desc.isEmpty || url.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final course = Course(
        id: const Uuid().v4(),
        title: title,
        description: desc,
        price: price,
        videoUrl: url);

    // Add course globally then auto-assign to this teacher
    await prov.addCourse(course);
    await prov.updateTeacherCourses(
      prov.currentUser!.id,
      [...prov.currentUser!.assignedCourseIds, course.id],
    );

    messenger.showSnackBar(
        const SnackBar(content: Text('Course added and assigned to you!')));
    _titleCtrl.clear();
    _descCtrl.clear();
    _priceCtrl.clear();
    _urlCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final prov    = Provider.of<AppProvider>(context);
    final teacher = prov.currentUser!;
    final myCourses = prov.courses
        .where((c) => teacher.assignedCourseIds.contains(c.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher: ${teacher.username}'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: () => _doLogout(context)),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book),  text: 'My Courses'),
            Tab(icon: Icon(Icons.add_circle), text: 'Add Course'),
            Tab(icon: Icon(Icons.person),     text: 'Profile'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ---- My Courses ----
          myCourses.isEmpty
              ? const Center(
              child: Text('No courses assigned to you yet.'))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: myCourses.length,
            itemBuilder: (_, i) {
              final c = myCourses[i];
              return _CourseCard(
                course: c,
                trailing: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => VideoPlayerPage(
                                videoUrl: c.videoUrl,
                                title: c.title)));
                    await SystemChrome.setPreferredOrientations(
                        [DeviceOrientation.portraitUp]);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal),
                  child: const Text('Preview'),
                ),
              );
            },
          ),

          // ---- Add Course ----
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add New Course',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Course Title')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _descCtrl,
                        decoration:
                        const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                      const InputDecoration(labelText: 'Price (\$)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _urlCtrl,
                        decoration:
                        const InputDecoration(labelText: 'Video URL')),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _addCourse(prov),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Course'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---- Profile ----
          _TeacherProfileTab(
              teacher: teacher, prov: prov, newPassCtrl: _newPassCtrl),
        ],
      ),
    );
  }
}

// ─────────────────────────── Admin Home ────────────────────────
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _urlCtrl   = TextEditingController();

  final _newUserCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  final _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _urlCtrl.dispose();
    _newUserCtrl.dispose();
    _newPassCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // ── Add Course ──────────────────────────────────────────────
  void _addCourse(AppProvider prov) async {
    final title     = _titleCtrl.text.trim();
    final desc      = _descCtrl.text.trim();
    final price     = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final url       = _urlCtrl.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (title.isEmpty || desc.isEmpty || url.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    await prov.addCourse(Course(
        id: const Uuid().v4(),
        title: title,
        description: desc,
        price: price,
        videoUrl: url));

    messenger.showSnackBar(
        const SnackBar(content: Text('Course added successfully!')));
    _titleCtrl.clear();
    _descCtrl.clear();
    _priceCtrl.clear();
    _urlCtrl.clear();
  }

  // ── Add Student ─────────────────────────────────────────────
  void _showAddStudentDialog(AppProvider prov) {
    _newUserCtrl.clear();
    _newPassCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _newUserCtrl,
                decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 12),
            TextField(
                controller: _newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create'),
            onPressed: () => _addUser(
                Provider.of<AppProvider>(context, listen: false),
                ctx,
                UserRole.student),
          ),
        ],
      ),
    );
  }

  // ── Add Teacher ─────────────────────────────────────────────
  void _showAddTeacherDialog(AppProvider prov) {
    _newUserCtrl.clear();
    _newPassCtrl.clear();
    final selectedIds = <String>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Add New Teacher'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                    controller: _newUserCtrl,
                    decoration:
                    const InputDecoration(labelText: 'Username')),
                const SizedBox(height: 12),
                TextField(
                    controller: _newPassCtrl,
                    obscureText: true,
                    decoration:
                    const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 16),
                const Text('Assign Courses:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...prov.courses.map((c) => CheckboxListTile(
                  dense: true,
                  title: Text(c.title),
                  value: selectedIds.contains(c.id),
                  onChanged: (v) => setDlg(() => v == true
                      ? selectedIds.add(c.id)
                      : selectedIds.remove(c.id)),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create'),
              style:
              ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () => _addUser(
                Provider.of<AppProvider>(context, listen: false),
                ctx,
                UserRole.teacher,
                assignedCourseIds: selectedIds.toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared add-user logic ────────────────────────────────────
  void _addUser(
      AppProvider prov,
      BuildContext dialogCtx,
      UserRole role, {
        List<String> assignedCourseIds = const [],
      }) async {
    final username  = _newUserCtrl.text.trim();
    final password  = _newPassCtrl.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final nav       = Navigator.of(dialogCtx);

    if (username.isEmpty || password.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final bool ok;
    if (role == UserRole.teacher) {
      ok = await prov.addTeacher(username, password, assignedCourseIds);
    } else {
      ok = await prov.addStudent(username, password);
    }

    if (!ok) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Username already exists!')));
      return;
    }

    nav.pop();
    final label = role == UserRole.teacher ? 'Teacher' : 'Student';
    messenger.showSnackBar(
        SnackBar(content: Text('$label created successfully!')));
  }

  // ── Edit teacher course assignments ─────────────────────────
  void _showEditTeacherCoursesDialog(AppProvider prov, User teacher) {
    final selectedIds = <String>{...teacher.assignedCourseIds};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('Courses for ${teacher.username}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: prov.courses
                  .map((c) => CheckboxListTile(
                dense: true,
                title: Text(c.title),
                value: selectedIds.contains(c.id),
                onChanged: (v) => setDlg(() => v == true
                    ? selectedIds.add(c.id)
                    : selectedIds.remove(c.id)),
              ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                final nav = Navigator.of(ctx);
                await prov.updateTeacherCourses(
                    teacher.id, selectedIds.toList());
                nav.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Remove user ──────────────────────────────────────────────
  void _confirmRemove(AppProvider prov, User u) async {
    final messenger = ScaffoldMessenger.of(context);
    final typeLabel = u.isTeacher ? 'Teacher' : 'Student';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $typeLabel'),
        content:
        Text('Remove "${u.username}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await prov.removeUser(u.id);
      messenger.showSnackBar(SnackBar(
          content: Text(ok
              ? '${u.username} removed.'
              : 'Could not remove user.')));
    }
  }

  // ── Generate code ────────────────────────────────────────────
  void _showGenerateCodeDialog(AppProvider prov) {
    final outerMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate Payment Code'),
        content: TextField(
          controller: _amountCtrl,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount (\$)'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _amountCtrl.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            child: const Text('Generate'),
            onPressed: () async {
              final amount =
                  double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
              if (amount <= 0) {
                outerMessenger.showSnackBar(const SnackBar(
                    content: Text('Enter a valid amount')));
                return;
              }
              final nav     = Navigator.of(ctx);
              final newCode = await prov.generateCode(amount);
              _amountCtrl.clear();
              nav.pop();
              outerMessenger.showSnackBar(SnackBar(
                  content: Text(
                      'Code: ${newCode.code}  (\$${newCode.amount.toStringAsFixed(2)})')));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov     = Provider.of<AppProvider>(context);
    final students = prov.students;
    final teachers = prov.teachers;
    final courses  = prov.courses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: () => _doLogout(context)),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: const [
            Tab(icon: Icon(Icons.people),          text: 'Students'),
            Tab(icon: Icon(Icons.school),          text: 'Teachers'),
            Tab(icon: Icon(Icons.menu_book),       text: 'Courses'),
            Tab(icon: Icon(Icons.add),             text: 'Add Course'),
            Tab(icon: Icon(Icons.monetization_on), text: 'Codes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [

          // ── Students ────────────────────────────────────────
          Column(children: [
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Add Student'),
              onPressed: () => _showAddStudentDialog(prov),
            ),
            Expanded(
              child: students.isEmpty
                  ? const Center(child: Text('No students yet.'))
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: students.length,
                itemBuilder: (_, i) {
                  final u = students[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.person,
                          color: Colors.indigo),
                      title: Text(u.username),
                      subtitle: Text(
                          'Balance: \$${u.balance.toStringAsFixed(2)}'
                              '  •  ${u.purchasedCourseIds.length} course(s)'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _roleBadge(u.role),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            tooltip: 'Remove',
                            onPressed: () =>
                                _confirmRemove(prov, u),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),

          // ── Teachers ────────────────────────────────────────
          Column(children: [
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Add Teacher'),
              style:
              ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () => _showAddTeacherDialog(prov),
            ),
            Expanded(
              child: teachers.isEmpty
                  ? const Center(child: Text('No teachers yet.'))
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: teachers.length,
                itemBuilder: (_, i) {
                  final u = teachers[i];
                  final assigned = prov.courses
                      .where(
                          (c) => u.assignedCourseIds.contains(c.id))
                      .map((c) => c.title)
                      .join(', ');
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.school,
                          color: Colors.teal),
                      title: Text(u.username),
                      subtitle: Text(assigned.isEmpty
                          ? 'No courses assigned'
                          : assigned),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _roleBadge(u.role),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.teal),
                            tooltip: 'Edit courses',
                            onPressed: () =>
                                _showEditTeacherCoursesDialog(
                                    prov, u),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            tooltip: 'Remove',
                            onPressed: () =>
                                _confirmRemove(prov, u),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),

          // ── Courses list ─────────────────────────────────────
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: courses.length,
            itemBuilder: (_, i) {
              final c = courses[i];
              final teacherName = prov.teachers
                  .where((t) => t.assignedCourseIds.contains(c.id))
                  .map((t) => t.username)
                  .join(', ');
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.play_circle_fill,
                      color: Colors.indigo),
                  title: Text(c.title),
                  subtitle: Text(teacherName.isEmpty
                      ? c.description
                      : '${c.description}\nTeacher: $teacherName'),
                  isThreeLine: teacherName.isNotEmpty,
                  trailing: Text('\$${c.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),

          // ── Add Course ────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add New Course',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Course Title')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _descCtrl,
                        decoration:
                        const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                      const InputDecoration(labelText: 'Price (\$)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _urlCtrl,
                        decoration:
                        const InputDecoration(labelText: 'Video URL')),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _addCourse(prov),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Course'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Payment Codes ─────────────────────────────────────
          Column(children: [
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Generate Code'),
              onPressed: () => _showGenerateCodeDialog(prov),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: prov.codes.isEmpty
                  ? const Center(child: Text('No payment codes yet.'))
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: prov.codes.length,
                itemBuilder: (context, i) {
                  final pc = prov.codes[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        pc.used
                            ? Icons.check_circle
                            : Icons.pending,
                        color: pc.used
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: Text('Code: ${pc.code}'),
                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Amount: \$${pc.amount.toStringAsFixed(2)}'),
                          Text('Created: ${pc.createdAt}'),
                          if (pc.used)
                            Text(
                                'Used by: ${pc.usedBy} on ${pc.usedAt}'),
                        ],
                      ),
                      trailing: pc.used
                          ? null
                          : IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                              content: Text(
                                  'Code: ${pc.code}')));
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────── Shared Widgets ────────────────────

/// Reusable course card.
class _CourseCard extends StatelessWidget {
  final Course course;
  final Widget trailing;

  const _CourseCard({required this.course, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading:
        const Icon(Icons.play_circle_fill, color: Colors.indigo),
        title: Text(course.title),
        subtitle: Text(course.description),
        trailing: trailing,
      ),
    );
  }
}

/// Profile tab for students (change password + redeem code).
class _ProfileTab extends StatelessWidget {
  final User user;
  final AppProvider prov;
  final TextEditingController newPassCtrl;
  final TextEditingController redeemCtrl;

  const _ProfileTab({
    required this.user,
    required this.prov,
    required this.newPassCtrl,
    required this.redeemCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.account_circle,
                  color: Colors.indigo, size: 40),
              title: Text(user.username,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  _roleBadge(user.role),
                  const SizedBox(height: 4),
                  Text('Balance: \$${user.balance.toStringAsFixed(2)}'),
                ],
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Change Password',
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: newPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.lock_reset),
            label: const Text('Update Password'),
            onPressed: () async {
              if (newPassCtrl.text.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              await prov.updatePassword(newPassCtrl.text.trim());
              messenger.showSnackBar(const SnackBar(
                  content: Text('Password updated successfully!')));
              newPassCtrl.clear();
            },
          ),
          const SizedBox(height: 30),
          const Text('Redeem Payment Code',
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: redeemCtrl,
            decoration: const InputDecoration(
                labelText: 'Enter payment code',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.redeem),
            label: const Text('Redeem'),
            onPressed: () async {
              final code      = redeemCtrl.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              if (code.isEmpty) {
                messenger.showSnackBar(const SnackBar(
                    content: Text('Please enter a code')));
                return;
              }
              final idx = prov.codes.indexWhere((x) => x.code == code);
              if (idx == -1) {
                messenger.showSnackBar(
                    const SnackBar(content: Text('Invalid code')));
                return;
              }
              if (prov.codes[idx].used) {
                messenger.showSnackBar(const SnackBar(
                    content: Text('This code has already been used')));
                return;
              }
              final amount = await prov.redeemCode(code);
              if (amount != null) {
                messenger.showSnackBar(SnackBar(
                    content: Text(
                        'Redeemed +\$${amount.toStringAsFixed(2)}')));
                redeemCtrl.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Profile tab for teachers (change password only — no balance/redeem).
class _TeacherProfileTab extends StatelessWidget {
  final User teacher;
  final AppProvider prov;
  final TextEditingController newPassCtrl;

  const _TeacherProfileTab({
    required this.teacher,
    required this.prov,
    required this.newPassCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.account_circle,
                  color: Colors.teal, size: 40),
              title: Text(teacher.username,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _roleBadge(teacher.role),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Change Password',
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: newPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.lock_reset),
            label: const Text('Update Password'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              if (newPassCtrl.text.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              await prov.updatePassword(newPassCtrl.text.trim());
              messenger.showSnackBar(const SnackBar(
                  content: Text('Password updated successfully!')));
              newPassCtrl.clear();
            },
          ),
        ],
      ),
    );
  }
}